let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#api#BufferList(tabnr)
	let bufferList     = []
	let singleList     = ctrlspace#buffers#Buffers(a:tabnr)
	let visibleBuffers = tabpagebuflist(a:tabnr)

	for i in keys(singleList)
		let i = str2nr(i)

		let bufname = bufname(i)
		let bufVisible = index(visibleBuffers, i) != -1
		let bufModified = (getbufvar(i, '&modified'))

		if !strlen(bufname) && (bufModified || bufVisible)
			let bufname = '[' . i . '*No Name]'
		endif

		if strlen(bufname)
			call add(bufferList, { "index": i, "text": bufname, "visible": bufVisible, "modified": bufModified })
		endif
	endfor

	call sort(bufferList, function("ctrlspace#engine#CompareByText"))

	return bufferList
endfunction

function! ctrlspace#api#Buffers(tabnr)
	let bufferList     = {}
	let ctrlspaceList  = ctrlspace#buffers#Buffers(a:tabnr)
	let visibleBuffers = tabpagebuflist(a:tabnr)

	for i in keys(ctrlspaceList)
		let i = str2nr(i)

		let bufname = bufname(i)

		if !strlen(bufname) && (getbufvar(i, '&modified') || (index(visibleBuffers, i) != -1))
			let bufname = '[' . i . '*No Name]'
		endif

		if strlen(bufname)
			let bufferList[i] = bufname
		endif
	endfor

	return bufferList
endfunction

function! ctrlspace#api#TabModified(tabnr)
	for b in map(keys(ctrlspace#buffers#Buffers(a:tabnr)), "str2nr(v:val)")
		if getbufvar(b, '&modified')
			return 1
		endif
	endfor
	return 0
endfunction

function! ctrlspace#api#Statusline()
	hi def link User1 CtrlSpaceStatus

	let statusline = "%1*" . s:config.Symbols.CS . "    " . ctrlspace#api#StatuslineModeSegment("    ")

	if !&showtabline
		let statusline .= " %=%1* %<" . ctrlspace#api#StatuslineTabSegment()
	endif

	return statusline
endfunction

function! ctrlspace#api#StatuslineTabSegment()
	let currentTab = tabpagenr()
	let winnr      = tabpagewinnr(currentTab)
	let buflist    = tabpagebuflist(currentTab)
	let bufnr      = buflist[winnr - 1]
	let bufname    = bufname(bufnr)
	let bufsNumber = ctrlspace#api#TabBuffersNumber(currentTab)
	let title      = ctrlspace#api#TabTitle(currentTab, bufnr, bufname)

	if !s:config.UseUnicode && !empty(bufsNumber)
		let bufsNumber = ":" . bufsNumber
	end

	let tabinfo = string(currentTab) . bufsNumber . " "

	if ctrlspace#api#TabModified(currentTab)
		let tabinfo .= "+ "
	endif

	let tabinfo .= title

	return tabinfo
endfunction

function! s:createStatusTabline()
	let current = tabpagenr()
	let line    = ""

	for i in range(1, tabpagenr("$"))
		let line .= (current == i ? s:config.Symbols.CTab : s:config.Symbols.Tabs)
	endfor

	return line
endfunction

function! ctrlspace#api#StatuslineModeSegment(...)
	let statuslineElements = []

	let clv = ctrlspace#modes#CurrentListView()

	if clv.Name ==# "Workspace"
		if clv.Data.SubMode ==# "load"
			call add(statuslineElements, s:config.Symbols.WLoad)
		elseif clv.Data.SubMode ==# "save"
			call add(statuslineElements, s:config.Symbols.WSave)
		endif
	elseif clv.Name ==# "Tab"
		call add(statuslineElements, s:createStatusTabline())
	elseif clv.Name ==# "Bookmark"
		call add(statuslineElements, s:config.Symbols.BM)
	else
		if clv.Name ==# "File"
			let symbol = s:config.Symbols.File
		elseif clv.Name ==# "Buffer"
			if clv.Data.SubMode == "visible"
				let symbol = s:config.Symbols.Vis
			elseif clv.Data.SubMode == "single"
				let symbol = s:config.Symbols.Sin
			elseif clv.Data.SubMode == "all"
				let symbol = s:config.Symbols.All
			endif
		endif

		if s:modes.NextTab.Enabled
			let symbol .= " " . s:config.Symbols.NTM . ctrlspace#api#TabBuffersNumber(tabpagenr() + 1)
		endif

		call add(statuslineElements, symbol)

		if s:modes.Zoom.Enabled
			call add(statuslineElements, s:config.Symbols.Zoom)
		endif
	endif

	if !empty(s:modes.Search.Data.Letters) || s:modes.Search.Enabled
		let searchElement = s:config.Symbols.SLeft . join(s:modes.Search.Data.Letters, "")

		if s:modes.Search.Enabled
			let searchElement .= "_"
		endif

		let searchElement .= s:config.Symbols.SRight

		call add(statuslineElements, searchElement)
	endif

	if s:modes.Help.Enabled
		call add(statuslineElements, s:config.Symbols.Help)
	endif

	let separator = (a:0 > 0) ? a:1 : "  "

	return join(statuslineElements, separator)
endfunction

function! ctrlspace#api#TabBuffersNumber(tabnr)
	let buffersNumber = len(ctrlspace#api#Buffers(a:tabnr))
	let numberToShow  = ""

	if buffersNumber > 1
		if s:config.UseUnicode
			let smallNumbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
			let numberStr    = string(buffersNumber)

			for i in range(len(numberStr))
				let numberToShow .= smallNumbers[str2nr(numberStr[i])]
			endfor
		else
			let numberToShow = string(buffersNumber)
		endif
	endif

	return numberToShow
endfunction

function! ctrlspace#api#TabTitle(tabnr, bufnr, bufname)
	let bufname = a:bufname
	let bufnr   = a:bufnr
	let title   = ctrlspace#util#Gettabvar(a:tabnr, "CtrlSpaceLabel")

	if empty(title)
		if getbufvar(bufnr, "&ft") == "ctrlspace"
			if s:modes.Zoom.Enabled
				if s:modes.Zoom.Data.Buffer
					let bufnr = s:modes.Zoom.Data.Buffer
				endif
			else
				let bufnr = winbufnr(t:CtrlSpaceStartWindow)
			endif

			let bufname = bufname(bufnr)
		endif

		if empty(bufname)
			let title = "[" . bufnr . "*No Name]"
		else
			let title = "[" . fnamemodify(bufname, ':t') . "]"
		endif
	endif

	return title
endfunction

function! ctrlspace#api#Guitablabel()
	let winnr      = tabpagewinnr(v:lnum)
	let buflist    = tabpagebuflist(v:lnum)
	let bufnr      = buflist[winnr - 1]
	let bufname    = bufname(bufnr)
	let title      = ctrlspace#api#TabTitle(v:lnum, bufnr, bufname)
	let bufsNumber = ctrlspace#api#TabBuffersNumber(v:lnum)

	if !s:config.UseUnicode && !empty(bufsNumber)
		let bufsNumber = ":" . bufsNumber
	end

	let label = '' . v:lnum . bufsNumber . ' '

	if ctrlspace#api#TabModified(v:lnum)
		let label .= '+ '
	endif

	let label .= title . ' '

	return label
endfunction

function! ctrlspace#api#TabList()
	let tabList     = []
	let lastTab    = tabpagenr("$")
	let currentTab = tabpagenr()

	for t in range(1, lastTab)
		let winnr       = tabpagewinnr(t)
		let buflist     = tabpagebuflist(t)
		let bufnr       = buflist[winnr - 1]
		let bufname     = bufname(bufnr)
		let tabTitle    = ctrlspace#api#TabTitle(t, bufnr, bufname)
		let tabModified = ctrlspace#api#TabModified(t)
		let tabCurrent  = t == currentTab

		call add(tabList, { "index": t, "title": tabTitle, "current": tabCurrent, "modified": tabModified })
        endfor

        return tabList
endfunction

function! ctrlspace#api#Tabline()
	let lastTab    = tabpagenr("$")
	let currentTab = tabpagenr()
	let tabline    = ''

	for t in range(1, lastTab)
		let winnr      = tabpagewinnr(t)
		let buflist    = tabpagebuflist(t)
		let bufnr      = buflist[winnr - 1]
		let bufname    = bufname(bufnr)
		let bufsNumber = ctrlspace#api#TabBuffersNumber(t)
		let title      = ctrlspace#api#TabTitle(t, bufnr, bufname)

		if !s:config.UseUnicode && !empty(bufsNumber)
			let bufsNumber = ":" . bufsNumber
		end

		let tabline .= '%' . t . 'T'
		let tabline .= (t == currentTab ? '%#TabLineSel#' : '%#TabLine#')
		let tabline .= ' ' . t . bufsNumber . ' '

		if ctrlspace#api#TabModified(t)
			let tabline .= '+ '
		endif

		let tabline .= title . ' '
	endfor

	let tabline .= '%#TabLineFill#%T'

	if lastTab > 1
		let tabline .= '%='
		let tabline .= '%#TabLine#%999XX'
	endif

	return tabline
endfunction

function! ctrlspace#api#BufNr()
	return bufexists(ctrlspace#context#PluginBuffer()) ? ctrlspace#context#PluginBuffer() : -1
endfunction
