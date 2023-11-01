let s:config     = ctrlspace#context#Configuration()
let s:modes      = ctrlspace#modes#Modes()
let s:workspaces = []
let s:cache_workspaces = []


" FUNCTION: ctrlspace#workspaces#CacheWorkspaces() {{{
function! ctrlspace#workspaces#CacheWorkspaces()
    return s:cache_workspaces
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#SetCacheWorkspaces() {{{
function! ctrlspace#workspaces#SetCacheWorkspaces(value)
    let s:cache_workspaces = a:value
    call s:clearAllWorkspaceRedundance()
    return s:cache_workspaces
endfunction
" }}}

" FUNCTION: s:writeCacheWorkspaces() {{{
function! s:writeCacheWorkspaces()
    " Wirte s:cache_workspaces to cs_cache file
    let lines     = []
    let cacheFile = s:config.CacheDir . "/.cs_cache"
    if filereadable(cacheFile)
        for oldLine in readfile(cacheFile)
            " Cache non-workspace lines
            if oldLine !~# "CS_WORKSPACE: " 
                call add(lines, oldLine)
            endif
        endfor
    endif
    for ws in s:cache_workspaces
        call add(lines, "CS_WORKSPACE: " . ws.Directory . ctrlspace#context#Separator() . ws.Name)
    endfor
    call writefile(lines, cacheFile)
endfunctio
" }}}

" FUNCTION: s:clearAllWorkspaceRedundance() {{{
function! s:clearAllWorkspaceRedundance()
    " save old project root
    let l:root_old = ctrlspace#roots#CurrentProjectRoot()

    " clear redundance workspace for each directory
    let l:cache_dir = []
    for item in s:cache_workspaces
        if -1 == match(l:cache_dir, '\C^' . item.Directory . '$')
            call add(l:cache_dir, item.Directory)
        endif
    endfor
    for item in l:cache_dir
        call s:clearWorkspaceRedundance(item)
    endfor

    call s:writeCacheWorkspaces()

    " recover project root
    call ctrlspace#roots#SetCurrentProjectRoot(l:root_old)
endfunction
" }}}

" FUNCTION: s:clearWorkspaceRedundance(root) {{{
" @param root: Project root where workspace redundance will be cleared.
function! s:clearWorkspaceRedundance(root)
    call ctrlspace#roots#SetCurrentProjectRoot(a:root)
    call ctrlspace#workspaces#SetWorkspaceNames()
	let l:root_dir = ctrlspace#roots#CurrentProjectRoot()

    let l:cache_new = []
    let l:cache_ws = []
    let l:cache_ws_name = []
    for item in s:cache_workspaces
        if ctrlspace#util#IsSameDirectory(item.Directory, l:root_dir)
            " workspace that is in current project root
            call add(l:cache_ws, item)
            call add(l:cache_ws_name, item.Name)
        else
            " workspace that is not in current project root
            call add(l:cache_new, item)
        endif
    endfor

    if empty(l:cache_ws) && empty(s:workspaces)
        return 0
    endif

    " Clear the redundance of workspaces that is in current project root
    for item in l:cache_ws
        if -1 != match(s:workspaces, '\C^' . item.Name . '$')
            " workspace that is in cs_cache file and also in cs_workspace file
            call add(l:cache_new, item)
        endif
    endfor
    for name in s:workspaces
        if -1 == match(l:cache_ws_name, '\C^' . name . '$')
            " workspace that is in cs_workspace file but NOT in cs_cache file
            " will be added to cs_cache file
            call add(l:cache_new, { "Name" : name,
                                  \ "Directory" : l:root_dir})
        endif
    endfor

    let s:cache_workspaces = l:cache_new
    return 1
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#FindExistedWorkspace() {{{
function! ctrlspace#workspaces#FindExistedWorkspace()
    if s:clearWorkspaceRedundance(ctrlspace#util#UseSlashDir(expand("%:p:h")))
        call s:writeCacheWorkspaces()
    endif
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#SetWorkspaceNames() {{{
function! ctrlspace#workspaces#SetWorkspaceNames()
	let filename     = ctrlspace#util#WorkspaceFile()
	let s:workspaces = []

	call s:modes.Workspace.SetData("LastActive", "")

    " Get workspace name from cs_workspace file
	if filereadable(filename)
		for line in readfile(filename)
			if line =~? "CS_WORKSPACE_BEGIN: "
				call add(s:workspaces, line[20:])
			elseif line =~? "CS_LAST_WORKSPACE: "
				call s:modes.Workspace.SetData("LastActive", line[19:])
			endif
		endfor
	endif
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#SetActiveWorkspaceName(name, ...) {{{
function! ctrlspace#workspaces#SetActiveWorkspaceName(name, ...)
	if a:0 > 0
		let digest = a:1
	else
		let digest = s:modes.Workspace.Data.Active.Digest
	end

	call s:modes.Workspace.SetData("Active", { "Name": a:name, "Digest": digest, "Root": ctrlspace#roots#CurrentProjectRoot() })
	call s:modes.Workspace.SetData("LastActive", a:name)

	let filename = ctrlspace#util#WorkspaceFile()
	let lines    = []

	if filereadable(filename)
		for line in readfile(filename)
			if !(line =~? "CS_LAST_WORKSPACE: ")
				call add(lines, line)
			endif
		endfor
	endif

	if !empty(a:name)
		call insert(lines, "CS_LAST_WORKSPACE: " . a:name)
	endif

	call writefile(lines, filename)
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#ActiveWorkspace() {{{
function! ctrlspace#workspaces#ActiveWorkspace()
	let aw = s:modes.Workspace.Data.Active
	let aw.Status = 0

	if !empty(aw.Name) && aw.Root ==# ctrlspace#roots#CurrentProjectRoot()
		let aw.Status = 1

		if aw.Digest !=# ctrlspace#workspaces#CreateDigest()
			let aw.Status = 2
		endif
	endif

	return aw
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#ClearWorkspace() {{{
function! ctrlspace#workspaces#ClearWorkspace()
	tabe
	tabo!
	call ctrlspace#buffers#DeleteHiddenNonameBuffers(1)
	call ctrlspace#buffers#DeleteForeignBuffers(1)
	call s:modes.Workspace.SetData("Active", { "Name": "", "Digest": "", "Root": "" })
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#SelectedWorkspaceName() {{{
function! ctrlspace#workspaces#SelectedWorkspaceName()
    " Get workspace name form cs_cache file
	return s:modes.Workspace.Enabled ? s:cache_workspaces[ctrlspace#window#SelectedIndex()]["Name"] : ""
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#LoadWorkspaceFile(bang, name) {{{
" bang == 0) load, bang == 1) append
function! ctrlspace#workspaces#LoadWorkspaceFile(bang, name)
	if !ctrlspace#roots#ProjectRootFound()
		return 0
	endif

	call ctrlspace#util#HandleVimSettings("start")

	let cwdSave = fnamemodify(".", ":p:h")
	silent! exe "cd " . fnameescape(ctrlspace#roots#CurrentProjectRoot())

	let filename = ctrlspace#util#WorkspaceFile()

	if !filereadable(filename)
		silent! exe "cd " . fnameescape(cwdSave)
		return 0
	endif

	let oldLines = readfile(filename)

	if empty(a:name)
		let name = ""

		for line in oldLines
			if line =~? "CS_LAST_WORKSPACE: "
				let name = line[19:]
				break
			endif
		endfor

		if empty(name)
			silent! exe "cd " . fnameescape(cwdSave)
			return 0
		endif
	else
		let name = a:name
	endif

	let startMarker = "CS_WORKSPACE_BEGIN: " . name
	let endMarker   = "CS_WORKSPACE_END: " . name

	let lines       = []
	let inWorkspace = 0

	for ol in oldLines
		if ol ==# startMarker
			let inWorkspace = 1
		elseif ol ==# endMarker
			let inWorkspace = 0
		elseif inWorkspace
			let ol = substitute(ol, "let t:ctrlspace_label", "let t:CtrlSpaceLabel", "")
			let ol = substitute(ol, "let t:ctrlspace_autotab", "let t:CtrlSpaceAutotab", "")
			call add(lines, ol)
		endif
	endfor

	if empty(lines)
		call ctrlspace#ui#Msg("Workspace '" . name . "' not found in file '" . filename . "'.")
		call ctrlspace#workspaces#SetWorkspaceNames()
		silent! exe "cd " . fnameescape(cwdSave)
		return 0
	endif

	call s:execWorkspaceFileCommands(a:bang, name, lines)

	if !a:bang
		let s:modes.Workspace.Data.Active.Digest = ctrlspace#workspaces#CreateDigest()
		let msg = "Workspace '" . name . "' has been loaded."
	else
		let s:modes.Workspace.Data.Active.Digest = ""
		let msg = "Workspace '" . name . "' has been appended."
	endif

	call ctrlspace#ui#Msg(msg)
	call ctrlspace#ui#DelayedMsg(msg)

	silent! exe "cd " . fnameescape(cwdSave)

	call ctrlspace#util#HandleVimSettings("stop")

	return 1
endfunction
" }}}

" FUNCTION: s:execWorkspaceFileCommands(bang, name, lines) {{{
function! s:execWorkspaceFileCommands(bang, name, lines)
	let commands = []

	if !a:bang
		call ctrlspace#ui#Msg("Loading workspace '" . a:name . "'...")
		call add(commands, "tabe")
		call add(commands, "tabo!")
		call add(commands, "call ctrlspace#buffers#DeleteHiddenNonameBuffers(1)")
		call add(commands, "call ctrlspace#buffers#DeleteForeignBuffers(1)")
		call ctrlspace#workspaces#SetActiveWorkspaceName(a:name)
	else
		let curTab = tabpagenr()
		call ctrlspace#ui#Msg("Appending workspace '" . a:name . "'...")
		call add(commands, "tabe")
	endif

	call writefile(a:lines, "CS_SESSION")

	call add(commands, "source CS_SESSION")
	call add(commands, "redraw!")

	if a:bang
		call add(commands, "normal! " . curTab . "gt")
	endif

	for c in commands
		silent exe c
	endfor

	call delete("CS_SESSION")
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#SaveWorkspaceFile(name) {{{
" Save the file cs_workspace in project root
function! ctrlspace#workspaces#SaveWorkspaceFile(name)
	if !ctrlspace#roots#ProjectRootFound()
		return 0
	endif

	call ctrlspace#util#HandleVimSettings("start")

	let cwdSave = fnamemodify(".", ":p:h")
	let root    = ctrlspace#roots#CurrentProjectRoot()

	silent! exe "cd " . fnameescape(root)

	if empty(a:name)
		if !empty(s:modes.Workspace.Data.Active.Name) && s:modes.Workspace.Data.Active.Root ==# root
			let name = s:modes.Workspace.Data.Active.Name
		else
			silent! exe "cd " . fnameescape(cwdSave)
			call ctrlspace#util#HandleVimSettings("stop")
			call ctrlspace#ui#Msg("Nothing to save.")
			return 0
		endif
	else
		let name = a:name
	endif

	let filename = ctrlspace#util#WorkspaceFile()
	let lastTab  = tabpagenr("$")

	let lines       = []
	let inWorkspace = 0

	let startMarker = "CS_WORKSPACE_BEGIN: " . name
	let endMarker   = "CS_WORKSPACE_END: " . name

	if filereadable(filename)
		for oldLine in readfile(filename)
			if oldLine ==# startMarker
				let inWorkspace = 1
			endif

			if !inWorkspace
				call add(lines, oldLine)
			endif

			if oldLine ==# endMarker
				let inWorkspace = 0
			endif
		endfor
	endif

	call add(lines, startMarker)

	let ssopSave = &ssop
	set ssop=winsize,tabpages,buffers,sesdir

	let tabData = []

	for t in range(1, lastTab)
		let data = {
					\ "label": ctrlspace#util#Gettabvar(t, "CtrlSpaceLabel"),
					\ "autotab": ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceAutotab", 0)
					\ }

		let ctrlspaceList = ctrlspace#api#Buffers(t)

		let bufs = []

		for [nr, bname] in items(ctrlspaceList)
			let bufname = fnamemodify(bname, ":.")

			if !filereadable(bufname)
				continue
			endif

			call add(bufs, bufname)
		endfor

		let data.bufs = bufs
		call add(tabData, data)
	endfor

	silent! exe "mksession! CS_SESSION"

	if !filereadable("CS_SESSION")
		silent! exe "cd " . fnameescape(cwdSave)
		silent! exe "set ssop=" . ssopSave

		call ctrlspace#util#HandleVimSettings("stop")
		call ctrlspace#ui#Msg("Workspace '" . name . "' cannot be saved at this moment.")
		return 0
	endif

	let tabIndex = 0

	for cmd in readfile("CS_SESSION")
		if cmd =~# "^lcd"
			continue
		elseif ((cmd =~# "^edit") && (tabIndex == 0)) || (cmd =~# "^tabnew") || (cmd =~# "^tabedit")
			let data = tabData[tabIndex]

			if tabIndex > 0
				call add(lines, cmd)
			endif

			for b in data.bufs
				call add(lines, "edit " . fnameescape(b))
			endfor

			if !empty(data.label)
				call add(lines, "let t:CtrlSpaceLabel = '" . substitute(data.label, "'", "''","g") . "'")
			endif

			if !empty(data.autotab)
				call add(lines, "let t:CtrlSpaceAutotab = " . data.autotab)
			endif

			if tabIndex == 0
				call add(lines, cmd)
			elseif cmd =~# "^tabedit"
				call add(lines, cmd[3:]) "make edit from tabedit
			endif

			let tabIndex += 1
		else
			let baddList = matchlist(cmd, "\\m^badd \+\\d* \\(.*\\)$")

			if !(exists("baddList[1]") && !empty(baddList[1]) && !filereadable(baddList[1]))
				call add(lines, cmd)
			endif
		endif
	endfor

	call add(lines, endMarker)

	call writefile(lines, filename)
	call delete("CS_SESSION")

	call ctrlspace#workspaces#SetActiveWorkspaceName(name, ctrlspace#workspaces#CreateDigest())
	call ctrlspace#workspaces#SetWorkspaceNames()

	silent! exe "cd " . fnameescape(cwdSave)
	silent! exe "set ssop=" . ssopSave

	call ctrlspace#util#HandleVimSettings("stop")

	return 1
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#CreateDigest() {{{
function! ctrlspace#workspaces#CreateDigest()
	let useNossl = exists("b:nosslSave") && b:nosslSave

	if useNossl
		set nossl
	endif

	let cpoSave = &cpo

	set cpo&vim

	let lines = []

	for t in range(1, tabpagenr("$"))
		let line     = [t, ctrlspace#util#Gettabvar(t, "CtrlSpaceLabel")]
		let bufs     = []
		let visibles = []

		let tabBuffers = ctrlspace#api#Buffers(t)

		for bname in values(tabBuffers)
			let bufname = fnamemodify(bname, ":p")

			if !filereadable(bufname)
				continue
			endif

			call add(bufs, bufname)
		endfor

		for visibleBuf in tabpagebuflist(t)
			if exists("tabBuffers[visibleBuf]")
				let bufname = fnamemodify(tabBuffers[visibleBuf], ":p")

				if !filereadable(bufname)
					continue
				endif

				call add(visibles, bufname)
			endif
		endfor

		call add(line, join(bufs, "|"))
		call add(line, join(visibles, "|"))
		call add(lines, join(line, ","))
	endfor

	let digest = join(lines, "&&&")

	if useNossl
		set ssl
	endif

	let &cpo = cpoSave

	return digest
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#PreloadWorkspaces() {{{
" @param type: the type of preload
function! ctrlspace#workspaces#PreloadWorkspaces(type)
    let l:cache_ws = s:cache_workspaces[ctrlspace#window#SelectedIndex()]

    " Special preload
    if "Save" == a:type
        if !ctrlspace#util#IsSameDirectory(ctrlspace#roots#CurrentProjectRoot(), l:cache_ws.Directory)
            let l:cur_project = ctrlspace#roots#CurrentProjectRoot()
            if !empty(l:cur_project)
                let l:cur_project = "(" . l:cur_project . ")."
            endif
            call ctrlspace#ui#Msg("The workspace you choose is not in Current Project". l:cur_project)
            return 0
        endif
    endif

    call ctrlspace#roots#SetCurrentProjectRoot(l:cache_ws.Directory)
    return 1
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#AddNewWorkspace() {{{
function! ctrlspace#workspaces#AddNewWorkspace()
    " Project root must exists first
	if !ctrlspace#roots#ProjectRootFound()
		return 0
	endif
    let l:root_directory = ctrlspace#roots#CurrentProjectRoot()
    let l:name = ""

	let labels = []
	for t in range(1, tabpagenr("$"))
		let label = ctrlspace#util#Gettabvar(t, "CtrlSpaceLabel")
		if !empty(label)
			call add(labels, label)
		endif
	endfor
	let l:name = ctrlspace#ui#GetInput("Save workspace name: ", join(labels, " "))
	if empty(l:name)
		return 0
	endif

    " Detect whether workspace is existing
    for wsname in s:workspaces
        if wsname ==# l:name
            call ctrlspace#ui#Msg("Workspace '" . l:name . "' has already existed in root directory'" . l:root_directory . "'")
            return 0
        endif
    endfor

	call ctrlspace#window#Kill(0, 1)

    " add cs_workspace file to project root
	let l:ok = ctrlspace#workspaces#SaveWorkspaceFile(l:name)

    if l:ok
        " add ctrlspace item to cs_cache file with directory been project root
        call s:addToCacheWorkspaces(l:root_directory, l:name)
    endif

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Workspace.Enable()
    call ctrlspace#window#Toggle(1)

    " Show message
    if l:ok
        call ctrlspace#ui#Msg("Workspace '" . l:name . "' was added successful")
    else
        call ctrlspace#ui#Msg("Failed to add Workspace '" . l:name . "'")
    endif

    return l:ok
endfunction
" }}}

" FUNCTION: s:addToCacheWorkspaces(directory, name) {{{
" @param directory: Must be project root
function! s:addToCacheWorkspaces(directory, name)
    let l:workspace = { "Name" : a:name,
                      \ "Directory" : ctrlspace#util#UseSlashDir(a:directory)
                      \ }

    call add(s:cache_workspaces, l:workspace)

    call s:writeCacheWorkspaces()

    return l:workspace
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#DeleteWorkspace(nr) {{{
function! ctrlspace#workspaces#DeleteWorkspace(nr)
    let l:name = s:cache_workspaces[a:nr].Name
    if !ctrlspace#ui#Confirmed("Delete workspace '" . l:name . "'?")
        return 0
    endif

    " Delete workspace from cs_workspace file
	call s:deleteWorkspaceFile(l:name)

    " Delete workspace from cs_cache file
    call remove(s:cache_workspaces, a:nr)

    call s:writeCacheWorkspaces()

    call ctrlspace#ui#DelayedMsg("Workspace '" . l:name . "' has been deleted.")
    return 1
endfunction
" }}}

" FUNCTION: s:deleteWorkspaceFile(name) {{{
function! s:deleteWorkspaceFile(name)
	let filename    = ctrlspace#util#WorkspaceFile()
	let lines       = []
	let inWorkspace = 0

	let workspaceStartMarker = "CS_WORKSPACE_BEGIN: " . a:name
	let workspaceEndMarker   = "CS_WORKSPACE_END: " . a:name

	if filereadable(filename)
		for oldLine in readfile(filename)
			if oldLine ==# workspaceStartMarker
				let inWorkspace = 1
			endif

			if !inWorkspace
				call add(lines, oldLine)
			endif

			if oldLine ==# workspaceEndMarker
				let inWorkspace = 0
			endif
		endfor
	endif

	call writefile(lines, filename)

	if s:modes.Workspace.Data.Active.Name ==# a:name && s:modes.Workspace.Data.Active.Root ==# ctrlspace#roots#CurrentProjectRoot()
		call ctrlspace#workspaces#SetActiveWorkspaceName(a:name, "")
	endif

	call ctrlspace#workspaces#SetWorkspaceNames()
endfunction
" }}}

" FUNCTION: ctrlspace#workspaces#RenameWorkspace(nr) {{{
function! ctrlspace#workspaces#RenameWorkspace(nr)
    let l:new_name = ctrlspace#ui#GetInput("Input new workspace name: ")
	if empty(l:new_name)
		return 0
	endif

    " Rename workspace in cs_workspace file
    call ctrlspace#workspaces#SetWorkspaceNames()
    if !s:renameWorkspaceFile(l:new_name, s:cache_workspaces[a:nr].Name)
       return 0
    endif

    " Rename workspace in cs_cache file
    let s:cache_workspaces[a:nr]["Name"] = l:new_name
    call s:writeCacheWorkspaces()

	call ctrlspace#ui#DelayedMsg("'" . l:new_name . "' has been set.")

    return 1
endfunction
" }}}

" FUNCTION: s:renameWorkspaceFile(name) {{{
function! s:renameWorkspaceFile(name, oldname)
	let newName = a:name

	for existingName in s:workspaces
		if newName ==# existingName
			call ctrlspace#ui#Msg("Workspace '" . newName . "' already exists.")
			return 0
		endif
	endfor

	let filename = ctrlspace#util#WorkspaceFile()
	let lines    = []

	let workspaceStartMarker = "CS_WORKSPACE_BEGIN: " . a:oldname
	let workspaceEndMarker   = "CS_WORKSPACE_END: " . a:oldname
	let lastWorkspaceMarker  = "CS_LAST_WORKSPACE: " . a:oldname

	if filereadable(filename)
		for line in readfile(filename)
			if line ==# workspaceStartMarker
				let line = "CS_WORKSPACE_BEGIN: " . newName
			elseif line ==# workspaceEndMarker
				let line = "CS_WORKSPACE_END: " . newName
			elseif line ==# lastWorkspaceMarker
				let line = "CS_LAST_WORKSPACE: " . newName
			endif

			call add(lines, line)
		endfor
	endif

	call writefile(lines, filename)

	if s:modes.Workspace.Data.Active.Name ==# a:oldname && s:modes.Workspace.Data.Active.Root ==# ctrlspace#roots#CurrentProjectRoot()
		call ctrlspace#workspaces#SetActiveWorkspaceName(newName)
	endif

	call ctrlspace#workspaces#SetWorkspaceNames()

	return 1
endfunction
" }}}


