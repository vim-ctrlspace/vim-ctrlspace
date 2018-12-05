let s:config     = ctrlspace#context#Configuration()
let s:modes      = ctrlspace#modes#Modes()
let s:resonators = ['.', '/', '_', '-', ' ']

if has("win32")
	call add(s:resonators, '\')
endif

" returns [patterns, indices, size, text]
function! ctrlspace#engine#Content()
	if !empty(s:config.FileEngine) && s:modes.File.Enabled
		return s:contentFromFileEngine()
	endif

	let items = s:contentSource()

	if !empty(s:modes.Search.Data.Letters)
		let items = s:computeLowestNoises(items)
		call sort(items, function("ctrlspace#engine#CompareByNoiseAndText"))
	else
		if len(items) > 500
			let items = items[0:499]
		endif

		if s:modes.Tab.Enabled
			call sort(items, function("ctrlspace#engine#CompareByIndex"))
		else
			call sort(items, function("ctrlspace#engine#CompareByText"))
		endif
	endif

	" trim the list in search mode
	if s:modes.Search.Enabled
		let maxHeight = ctrlspace#window#MaxHeight()

		if len(items) > maxHeight
			let items = items[-maxHeight : -1]
		endif
	endif

	return s:prepareContent(items)
endfunction

function! s:contentFromFileEngine()
	call ctrlspace#files#CollectFiles()

	let context = '{"Query":"' . join(s:modes.Search.Data.Letters, "") . '","Columns":' . &columns .
				\ ',"Limit":' . (s:modes.Search.Enabled ? ctrlspace#window#MaxHeight() : 0) .
				\ ',"Source":"' . escape(fnamemodify(ctrlspace#util#FilesCache(), ":p"), '\"') .
				\ '","Dots":"' . s:config.Symbols.Dots . '","DotsSize":' . ctrlspace#context#SymbolSizes().Dots . '}'

	let results  = split(system(s:config.FileEngine, context), "\n")
	let patterns = eval(results[0])
	let indices  = eval(results[1])
	let size     = str2nr(results[2])
	let text     = join(results[3:], "\n")

	return [patterns, indices, size, text]
endfunction

function! ctrlspace#engine#CompareByText(a, b)
    let lhs = fnamemodify(a:a.text, ':p')
    let rhs = fnamemodify(a:b.text, ':p')
	if lhs < rhs
		return -1
	elseif lhs > rhs
		return 1
	else
		return 0
	endif
endfunction

function! ctrlspace#engine#CompareByIndex(a, b)
	if a:a.index < a:b.index
		return -1
	elseif a:a.index > a:b.index
		return 1
	else
		return 0
	endif
endfunction

function! ctrlspace#engine#CompareByNoiseAndText(a, b)
	if a:a.noise < a:b.noise
		return 1
	elseif a:a.noise > a:b.noise
		return -1
	elseif a:a.smallnoise < a:b.smallnoise
		return 1
	elseif a:a.smallnoise > a:b.smallnoise
		return -1
	elseif strlen(a:a.text) < strlen(a:b.text)
		return 1
	elseif strlen(a:a.text) > strlen(a:b.text)
		return -1
	elseif a:a.text < a:b.text
		return -1
	elseif a:a.text > a:b.text
		return 1
	else
		return 0
	endif
endfunction

function! s:computeLowestNoises(source)
	let results       = []
	let noises        = []
	let resultsCount  = 0

	for index in range(len(a:source))
		let item = a:source[index]
		let [noise, smallnoise, pattern] = s:findLowestSearchNoise(item.text)

		if noise == -1
			continue
		else
			let item.noise      = noise
			let item.smallnoise = smallnoise
			let item.pattern    = pattern

			if resultsCount < 200
				let resultsCount += 1
				call add(results, item)
				call add(noises, noise)
			else
				let maxIndex = index(noises, max(noises))

				if noises[maxIndex] > noise
					call remove(noises, maxIndex)
					call insert(noises, noise, maxIndex)
					call remove(results, maxIndex)
					call insert(results, item, maxIndex)
				endif
			endif
		endif
	endfor

	return results
endfunction

function! s:contentSource()
	let clv = ctrlspace#modes#CurrentListView()

	if clv.Name ==# "Buffer"
		return s:bufferListContent(clv)
	elseif clv.Name ==# "File"
		return s:fileListContent(clv)
	elseif clv.Name ==# "Tab"
		return s:tabContent(clv)
	elseif clv.Name ==# "Workspace"
		return s:workspaceListContent(clv)
	elseif clv.Name ==# "Bookmark"
		return s:bookmarkListContent(clv)
	endif
endfunction

function! s:bookmarkListContent(clv)
	let content   = []
	let bookmarks = ctrlspace#bookmarks#Bookmarks()

	for i in range(len(bookmarks))
		let indicators = ""

		if !empty(a:clv.Data.Active) && (bookmarks[i].Directory ==# a:clv.Data.Active.Directory)
			let indicators .= s:config.Symbols.IA
		endif

		call add(content, { "index": i, "text": bookmarks[i].Name, "indicators": indicators })
	endfor

	return content
endfunction

function! s:workspaceListContent(clv)
	let content    = []
	let workspaces = ctrlspace#workspaces#Workspaces()
	let active     = ctrlspace#workspaces#ActiveWorkspace()

	for i in range(len(workspaces))
		let name = workspaces[i]
		let indicators = ""

		if name ==# active.Name && active.Status
			if active.Status == 2
				let indicators .= s:config.Symbols.IM
			endif

			let indicators .= s:config.Symbols.IA
		elseif name ==# a:clv.Data.LastActive
			let indicators .= s:config.Symbols.IV
		endif

		call add(content, { "index": i, "text": name, "indicators": indicators })
	endfor

	return content
endfunction

function! s:tabContent(clv)
	let content    = []
	let currentTab = tabpagenr()

	for i in range(1, tabpagenr("$"))
		let winnr         = tabpagewinnr(i)
		let buflist       = tabpagebuflist(i)
		let bufnr         = buflist[winnr - 1]
		let bufname       = bufname(bufnr)
		let tabBufsNumber = ctrlspace#api#TabBuffersNumber(i)
		let title         = ctrlspace#api#TabTitle(i, bufnr, bufname)

		if !s:config.UseUnicode && !empty(tabBufsNumber)
			let tabBufsNumber = ":" . tabBufsNumber
		endif

		let indicators = ""

		if ctrlspace#api#TabModified(i)
			let indicators .= s:config.Symbols.IM
		endif

		if i == currentTab
			let indicators .= s:config.Symbols.IA
		endif

		call add(content, { "index": i, "text": string(i) . tabBufsNumber . " " . title, "indicators": indicators })
	endfor

	return content
endfunction

function! s:fileListContent(clv)
	call ctrlspace#files#CollectFiles()
	return deepcopy(ctrlspace#files#Items())
endfunction

function! s:bufferListContent(clv)
	let content = []

	if a:clv.Data.SubMode ==# "single"
		let buffers = map(keys(ctrlspace#buffers#Buffers(tabpagenr())), "str2nr(v:val)")
	elseif a:clv.Data.SubMode ==# "all"
		let buffers = map(keys(ctrlspace#buffers#Buffers(0)), "str2nr(v:val)")
	elseif a:clv.Data.SubMode ==# "visible"
		let buffers = filter(map(keys(ctrlspace#buffers#Buffers(tabpagenr())), "str2nr(v:val)"), "bufwinnr(v:val) != -1")
	endif

	for i in buffers
		let entry = s:bufferEntry(i)
		if !empty(entry)
			call add(content, entry)
		endif
	endfor

	return content
endfunction

function! s:bufferEntry(bufnr)
	let bufname  = fnamemodify(bufname(a:bufnr), ":.")
	let modified = getbufvar(a:bufnr, "&modified")
	let winnr    = bufwinnr(a:bufnr)

	if !strlen(bufname) && (modified || (winnr != -1))
		let bufname = "[" . a:bufnr . "*No Name]"
	endif

	if strlen(bufname)
		let indicators = ""

		if modified
			let indicators .= s:config.Symbols.IM
		endif

		if winnr == t:CtrlSpaceStartWindow
			let indicators .= s:config.Symbols.IA
		elseif winnr != -1
			let indicators .= s:config.Symbols.IV
		endif

		return { "index": a:bufnr, "text": bufname, "indicators": indicators }
	else
		return {}
	endif
endfunction

function! s:findSubsequence(text, offset)
	let positions     = []
	let noise         = 0
	let currentOffset = a:offset

	for letter in s:modes.Search.Data.Letters
		let matchedPosition = match(a:text, "\\m\\c" . letter, currentOffset)

		if matchedPosition == -1
			return [-1, []]
		else
			if !empty(positions)
				let noise += abs(matchedPosition - positions[-1]) - 1
			endif
			call add(positions, matchedPosition)
			let currentOffset = matchedPosition + 1
		endif
	endfor

	return [noise, positions]
endfunction

function! s:findLowestSearchNoise(text)
	let noise         = -1
	let smallnoise    = 0
	let matchedString = ""
	let ltrLen        = len(s:modes.Search.Data.Letters)
	let textLen       = strlen(a:text)

	if ltrLen == 1
		let noise = match(a:text, "\\m\\c" . s:modes.Search.Data.Letters[0])

		if noise > -1
			let matchedString = s:modes.Search.Data.Letters[0]
		endif
	else
		let offset    = 0
		let positions = []

		while ltrLen <= textLen - offset
			let subseq = s:findSubsequence(a:text, offset)

			if subseq[0] == -1
				break
			elseif (noise == -1) || (subseq[0] < noise)
				let [noise, positions] = subseq
				let offset = positions[0] + 1
			else
				let offset += 1
			endif
		endwhile

		if noise > -1
			let matchedString = a:text[positions[0]:positions[-1]]
			let smallnoise = 0

			if positions[0] != 0
				let smallnoise += 1

				if index(s:resonators, a:text[positions[0] - 1]) == -1
					let smallnoise += 1
				endif
			endif

			if positions[-1] != textLen - 1
				let smallnoise += 1

				if index(s:resonators, a:text[positions[-1] + 1]) == -1
					let smallnoise += 1
				endif
			endif
		endif
	endif

	let pattern = ""

	if (noise > -1) && !empty(matchedString)
		let pattern = matchedString
	endif

	return [noise, smallnoise, pattern]
endfunction

function! s:prepareContent(items)
	let sizes = ctrlspace#context#SymbolSizes()

	if s:modes.File.Enabled
		let itemSpace = 5
	elseif s:modes.Bookmark.Enabled
		let itemSpace = 5 + sizes.IAV
	else
		let itemSpace = 5 + sizes.IAV + sizes.IM
	endif

	let content  = ""
	let patterns = {}
	let indices  = []

	for item in a:items
		let line = item.text

		if strwidth(line) + itemSpace > &columns
			let line = s:config.Symbols.Dots . strpart(line, strwidth(line) - &columns + itemSpace + sizes.Dots)
		endif

		if !empty(item.indicators)
			let line .= " " . item.indicators
		endif

		while strwidth(line) < &columns
			let line .= " "
		endwhile

		let content .= "  " . line . "\n"

		if has_key(item, "pattern")
			let patterns[item.pattern] = 1
		endif

		call add(indices, item.index)
	endfor

	return [keys(patterns), indices, len(a:items), content]
endfunction
