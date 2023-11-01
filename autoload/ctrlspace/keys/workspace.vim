
let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

" FUNCTION: ctrlspace#keys#workspace#Init() {{{
function! ctrlspace#keys#workspace#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Load"          , "Workspace" , ["CR"  , "Space", "Tab"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Append"        , "Workspace" , ["t"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Add"           , "Workspace" , ["a"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Save"          , "Workspace" , ["s"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Delete"        , "Workspace" , ["d"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Rename"        , "Workspace" , ["="   , "m"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Clear"         , "Workspace" , ["C"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Sort"          , "Workspace" , ["g"])
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Add(k) {{{
function! ctrlspace#keys#workspace#Add(k)
    call ctrlspace#workspaces#AddNewWorkspace()
endfunction
" }}}

" FUNCTION: s:loadWorkspace(bang, name) {{{
function! s:loadWorkspace(bang, name)
	let saveWorkspaceBefore = 0
	let active = ctrlspace#workspaces#ActiveWorkspace()

	if active.Status && !a:bang
		let msg = ""

		if a:name ==# active.Name
			let msg = "Reload current workspace: '" . a:name . "'?"
		elseif active.Status == 2
			if s:config.SaveWorkspaceOnSwitch
				let saveWorkspaceBefore = 1
			else
				let msg = "Current workspace ('" . active.Name . "') not saved. Proceed anyway?"
			endif
		endif

		if !empty(msg) && !ctrlspace#ui#Confirmed(msg)
			return 0
		endif
	endif

	if !a:bang && !ctrlspace#ui#ProceedIfModified()
		return 0
	endif

	call ctrlspace#window#Kill(0, 1)

	if saveWorkspaceBefore && !ctrlspace#workspaces#SaveWorkspaceFile("")
		return 0
	endif

	if !ctrlspace#workspaces#LoadWorkspaceFile(a:bang, a:name)
		return 0
	endif

	return 1
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Load(k) {{{
function! ctrlspace#keys#workspace#Load(k)
    " preload workspace form cs_cache file
    if !ctrlspace#workspaces#PreloadWorkspaces("Load")
        return
    endif

    " load workspace from cs_workspace file
    if !s:loadWorkspace(0, ctrlspace#workspaces#SelectedWorkspaceName())
        return
    endif

	if a:k ==# "Tab"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#ui#DelayedMsg()
    "elseif a:k ==# "CR"
        " No need to open ctrlspace again when workspace was loaded.
	elseif a:k ==# "Space"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#Kill(0, 0)
		call s:modes.Workspace.Enable()
		call ctrlspace#window#Toggle(1)
		call ctrlspace#ui#DelayedMsg()
	endif
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Append(k) {{{
function! ctrlspace#keys#workspace#Append(k)
    " preload workspace form cs_cache file
    if !ctrlspace#workspaces#PreloadWorkspaces("Append")
        return
    endif

    " append workspace from cs_workspace file
	if !s:loadWorkspace(1, ctrlspace#workspaces#SelectedWorkspaceName())
        return
    endif

    call ctrlspace#window#Toggle(0)
    call s:modes.Workspace.Enable()
    call ctrlspace#window#Kill(0, 0)
    call ctrlspace#window#Toggle(1)
	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Save(k) {{{
function! ctrlspace#keys#workspace#Save(k)
    " preload workspace form cs_cache file
    if !ctrlspace#workspaces#PreloadWorkspaces("Save")
        return
    endif

    " Confirme saving
    let l:name = ctrlspace#workspaces#SelectedWorkspaceName()
    if !ctrlspace#ui#Confirmed("Save to workspace '" . l:name . "' ?")
        return
    endif

	call ctrlspace#window#Kill(0, 1)

    " save workspace to cs_workspace file
    if ctrlspace#workspaces#SaveWorkspaceFile(l:name)
        call ctrlspace#ui#DelayedMsg("Workspace '" . l:name . "' has been saved.")
    else
        call ctrlspace#ui#Msg("Failed to save Workspace '" . l:name . "'.")
        return
    endif

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Workspace.Enable()
    call ctrlspace#window#Toggle(1)
    call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Delete(k) {{{
function! ctrlspace#keys#workspace#Delete(k)
    " preload workspace form cs_cache file
    if !ctrlspace#workspaces#PreloadWorkspaces("Delete")
        return
    endif

    if ctrlspace#workspaces#DeleteWorkspace(ctrlspace#window#SelectedIndex())
        call ctrlspace#window#Kill(0, 1)
        call ctrlspace#window#Toggle(0)
        call ctrlspace#window#Kill(0, 0)
        call s:modes.Workspace.Enable()
        call ctrlspace#window#Toggle(1)
        call ctrlspace#ui#DelayedMsg()
    endif
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Rename(k) {{{
function! ctrlspace#keys#workspace#Rename(k)
    " preload workspace form cs_cache file
    if !ctrlspace#workspaces#PreloadWorkspaces("Rename")
        return
    endif

	call ctrlspace#workspaces#RenameWorkspace(ctrlspace#window#SelectedIndex())

	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#Toggle(1)
	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Clear(k) {{{
" Clear all buffers and tabs of one workspace
function! ctrlspace#keys#workspace#Clear(k)
	if !ctrlspace#keys#buffer#NewWorkspace(a:k)
		return
	endif

	call ctrlspace#window#Kill(0, 0)
	call s:modes.Workspace.Enable()
	call ctrlspace#window#Toggle(1)
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Sort(k) {{{
function! ctrlspace#keys#workspace#Sort(k)
	if s:modes.Workspace.Data.SortMode ==# "path"
        call s:modes.Workspace.SetData("SortMode", "name")
        call ctrlspace#ui#DelayedMsg("Workspace was sorted by name")
    elseif s:modes.Workspace.Data.SortMode ==# "name"
        call s:modes.Workspace.SetData("SortMode", "path")
        call ctrlspace#ui#DelayedMsg("Workspace was sorted by path")
    endif

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Workspace.Enable()
    call ctrlspace#window#Toggle(1)
    call ctrlspace#ui#DelayedMsg()
endfunction
" }}}
