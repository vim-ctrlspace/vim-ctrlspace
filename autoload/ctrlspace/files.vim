let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()
let s:files  = []
let s:items  = []

function! ctrlspace#files#Files()
	return s:files
endfunction

function! ctrlspace#files#ClearAll()
	let s:files = []
	let s:items = []
endfunction

function! ctrlspace#files#Items()
	return s:items
endfunction

function! ctrlspace#files#SelectedFileName()
	return s:modes.File.Enabled ? s:files[ctrlspace#window#SelectedIndex()] : ""
endfunction

function! ctrlspace#files#CollectFiles()
	if empty(s:files)
		let s:items = []

		" try to pick up files from cache
		call s:loadFilesFromCache()

		if empty(s:files)
			let action = "Collecting files..."
			call ctrlspace#ui#Msg(action)

			let uniqueFiles = {}

			for fname in empty(s:config.GlobCommand) ? split(globpath('.', '**'), '\n') : split(system(s:config.GlobCommand), '\n')
				let fnameModified = fnamemodify(has("win32") ? substitute(fname, "\r$", "", "") : fname, ":.")

				if isdirectory(fnameModified) || (fnameModified =~# s:config.IgnoredFiles)
					continue
				endif

				let uniqueFiles[fnameModified] = 1
			endfor

			let s:files = keys(uniqueFiles)
			call s:saveFilesInCache()
		else
			let action = "Loading files..."
			call ctrlspace#ui#Msg(action)
		endif

		let s:items = map(copy(s:files), '{ "index": v:key, "text": v:val, "indicators": "" }')

		redraw!

		call ctrlspace#ui#Msg(action . " Done (" . len(s:files) . ").")
	endif

	return s:files
endfunction

function! ctrlspace#files#LoadFile(...)
	let idx = ctrlspace#window#SelectedIndex()
	let file = fnamemodify(s:files[idx], ":p")

	call ctrlspace#window#Kill(0, 1)

	let commands = len(a:000)

	if commands > 0
		exec ":" . a:1
	endif

	call s:loadFileOrBuffer(file)

	if commands > 1
		silent! exe ":" . a:2
	endif
endfunction

function! ctrlspace#files#LoadManyFiles(...)
	let idx   = ctrlspace#window#SelectedIndex()
	let file  = fnamemodify(s:files[idx], ":p")
	let curln = line(".")

	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#GoToStartWindow()

	let commands = len(a:000)

	if commands > 0
		exec ":" . a:1
	endif

	call s:loadFileOrBuffer(file)
	normal! zb

	if commands > 1
		silent! exe ":" . a:2
	endif

	call ctrlspace#window#Toggle(1)
	call ctrlspace#window#MoveSelectionBar(curln)
endfunction

function! ctrlspace#files#RefreshFiles()
	let s:files = []
	call s:saveFilesInCache()
	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#files#RemoveFile()
	let nr   = ctrlspace#window#SelectedIndex()
	let path = fnamemodify(s:modes.File.Enabled ? s:files[nr] : resolve(bufname(nr)), ":.")

	if empty(path) || !filereadable(path) || isdirectory(path)
		return
	endif

	if !ctrlspace#ui#Confirmed("Remove file '" . path . "'?")
		return
	endif

	call ctrlspace#buffers#DeleteBuffer()
	call s:updateFileList(path, "")
	call delete(resolve(expand(path)))

	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#files#ZoomFile()
	if !s:modes.Zoom.Enabled
		call s:modes.Zoom.Enable()
		call s:modes.Zoom.SetData("Buffer", winbufnr(t:CtrlSpaceStartWindow))
		call s:modes.Zoom.SetData("Mode", "File")
		call s:modes.Zoom.SetData("Line", line("."))
		call s:modes.Zoom.SetData("Letters", copy(s:modes.Search.Data.Letters))
	endif

	let nr = ctrlspace#window#SelectedIndex()
	let curln = line(".")

	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#GoToStartWindow()
	call s:loadFileOrBuffer(fnamemodify(s:files[nr], ":p"))

	silent! exe "normal! zb"

	call ctrlspace#window#Toggle(1)
	call ctrlspace#window#MoveSelectionBar(curln)
endfunction

function! ctrlspace#files#CopyFileOrBuffer()
	let root = ctrlspace#roots#CurrentProjectRoot()

	if !empty(root)
		call ctrlspace#util#ChDir(root)
	endif

	let nr   = ctrlspace#window#SelectedIndex()
	let path = fnamemodify(s:modes.File.Enabled ? s:files[nr] : resolve(bufname(nr)), ":.")

	let bufOnly = !filereadable(path) && !s:modes.File.Enabled

	if !(filereadable(path) || bufOnly) || isdirectory(path)
		return
	endif

	let newFile = ctrlspace#ui#GetInput((bufOnly ? "Copy buffer as: " : "Copy file to: "), path, "file")

	if empty(newFile) || isdirectory(newFile) || !s:ensurePath(newFile)
		return
	endif

	if bufOnly
		call ctrlspace#buffers#ZoomBuffer(str2nr(nr), ['normal! G""ygg'])
		call ctrlspace#window#Kill(0, 1)
		silent! exe "e " . fnameescape(newFile)
		silent! exe 'normal! ""pgg"_dd'
	else
		let newFile = fnamemodify(newFile, ":p")

		let lines = readfile(path, "b")
		call writefile(lines, newFile, "b")

		call s:updateFileList("", newFile)

		call ctrlspace#window#Kill(0, 1)

		if !s:modes.File.Enabled
			silent! exe "e " . fnameescape(newFile)
		endif
	endif

	call ctrlspace#window#Toggle(1)

	if !s:modes.File.Enabled
		if !bufOnly
			let newFile = fnamemodify(newFile, ":.")
		endif

		let names = ctrlspace#api#Buffers(tabpagenr())

		for i in range(b:size)
			if names[b:indices[i]] ==# newFile
				call ctrlspace#window#MoveSelectionBar(i + 1)
				break
			endif
		endfor
	endif
endfunction

function! ctrlspace#files#RenameFileOrBuffer()
	let root = ctrlspace#roots#CurrentProjectRoot()

	if !empty(root)
		call ctrlspace#util#ChDir(root)
	endif

	let nr   = ctrlspace#window#SelectedIndex()
	let path = fnamemodify(s:modes.File.Enabled ? s:files[nr] : resolve(bufname(nr)), ":.")

	let bufOnly = !filereadable(path) && !s:modes.File.Enabled

	if !(filereadable(path) || bufOnly) || isdirectory(path)
		return
	endif

	let newFile = ctrlspace#ui#GetInput((bufOnly ? "New buffer name: " : "Move file to: "), path, "file")

	if empty(newFile) || !s:ensurePath(newFile)
		return
	endif

	if isdirectory(newFile)
		if newFile !~ "/$"
			let newFile .= "/"
		endif

		let newFile .= fnamemodify(path, ":t")
	endif

	let bufNames = {}

	" must be collected BEFORE actual file renaming
	for b in range(1, bufnr("$"))
		let bufNames[b] = fnamemodify(resolve(bufname(b)), ":.")
	endfor

	if !bufOnly
		call rename(resolve(expand(path)), resolve(expand(newFile)))
	endif

	for [b, name] in items(bufNames)
		if name == path
			let commands = ["f " . fnameescape(newFile)]

			if !bufOnly
				call add(commands, "w!")
			elseif !getbufvar(b, "&modified")
				call add(commands, "e") "reload filetype and syntax
			endif

			call ctrlspace#buffers#ZoomBuffer(str2nr(b), commands)
		endif
	endfor

	if !bufOnly
		call s:updateFileList(path, newFile)
	endif

	call ctrlspace#window#Kill(0, 1)
	call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#files#GoToDirectory(back)
	if !exists("s:goToDirectorySave")
		let s:goToDirectorySave = []
	endif

	if a:back
		if !empty(s:goToDirectorySave)
			let path = s:goToDirectorySave[-1]
		else
			return
		endif
	else
		let nr   = ctrlspace#window#SelectedIndex()
		let path = s:modes.File.Enabled ? s:files[nr] : resolve(bufname(nr))
	endif

	let oldBufferSubMode = s:modes.Buffer.Data.SubMode
	let directory        = ctrlspace#util#NormalizeDirectory(fnamemodify(path, ":p:h"))

	if !isdirectory(directory)
		return
	endif

	call ctrlspace#window#Kill(0, 1)

	let cwd = ctrlspace#util#NormalizeDirectory(fnamemodify(getcwd(), ":p:h"))

	if cwd !=# directory
		if a:back
			call remove(s:goToDirectorySave, -1)
		else
			call add(s:goToDirectorySave, cwd)
		endif
	endif

	call ctrlspace#util#ChDir(directory)

	call ctrlspace#ui#DelayedMsg("CWD is now: " . directory)

	call ctrlspace#window#Toggle(0)
	call ctrlspace#window#Kill(0, 0)

	call s:modes.Buffer.SetData("SubMode", oldBufferSubMode)

	call ctrlspace#window#Toggle(1)
	call ctrlspace#ui#DelayedMsg()
endfunction

function! ctrlspace#files#ExploreDirectory()
	let nr   = ctrlspace#window#SelectedIndex()
	let path = fnamemodify(s:modes.File.Enabled ? s:files[nr] : resolve(bufname(nr)), ":.:h")

	if !isdirectory(path)
		return
	endif

	let path = fnamemodify(path, ":p")

	call ctrlspace#window#Kill(0, 1)
	silent! exe "e " . fnameescape(path)
endfunction

function! ctrlspace#files#EditFile()
	let nr   = ctrlspace#window#SelectedIndex()
	let path = fnamemodify(s:modes.File.Enabled ? s:files[nr] : resolve(bufname(nr)), ":.:h")

	if !isdirectory(path)
		return
	endif

	let newFile = ctrlspace#ui#GetInput("Edit a new file: ", path . '/', "file")

	if empty(newFile)
		return
	endif

	let newFile = expand(newFile)

	if isdirectory(newFile)
		call ctrlspace#window#Kill(0, 1)
		enew
		return
	endif

	if !s:ensurePath(newFile)
		return
	endif

	let newFile = fnamemodify(newFile, ":p")

	call ctrlspace#window#Kill(0, 1)
	silent! exe "e " . fnameescape(newFile)
endfunction

function! s:saveFilesInCache()
	let filename = ctrlspace#util#FilesCache()

	if empty(filename)
		return
	endif

	call writefile(s:files, filename)
endfunction

function! s:loadFilesFromCache()
	let filename = ctrlspace#util#FilesCache()

	if empty(filename) || !filereadable(filename)
		return
	endif

	let s:files = readfile(filename)
endfunction

function! s:loadFileOrBuffer(file)
	if buflisted(a:file)
		silent! exe ":b " . bufnr(a:file)
	else
		exec ":e " . fnameescape(a:file)
	endif
endfunction

function! s:updateFileList(path, newPath)
	if empty(s:files)
		call s:loadFilesFromCache()

		if empty(s:files)
			return
		else
			let s:items = map(copy(s:files), '{ "index": v:key, "text": v:val, "indicators": "" }')
		endif
	endif

	let newPath = empty(a:newPath) ? "" : fnamemodify(a:newPath, ":.")

	if !empty(a:path)
		let index = index(s:files, a:path)

		if index >= 0
			call remove(s:files, index)
			call remove(s:items, index)
		endif
	endif

	if !empty(newPath)
		call add(s:files, newPath)
		call add(s:items, { "index": len(s:items), "text": newPath, "indicators": "" })
	endif

	call s:saveFilesInCache()
endfunction

function! s:ensurePath(file)
	let directory = fnamemodify(a:file, ":.:h")

	if !isdirectory(directory)
		if !ctrlspace#ui#Confirmed("Directory '" . directory . "' will be created. Continue?")
			return 0
		endif

		call mkdir(fnamemodify(directory, ":p"), "p")
	endif

	return 1
endfunction
