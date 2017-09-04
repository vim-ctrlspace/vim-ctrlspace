
let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#workspace#Init()
	"call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#LoadOrSave"    , "Workspace" , ["Tab" , "CR"  , "Space"])
	"call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Append"        , "Workspace" , ["a"])
	"call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#NewWorkspace"  , "Workspace" , ["N"])
	"call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#ToggleSubmode" , "Workspace" , ["s"])
	"call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Delete"        , "Workspace" , ["d"])
	"call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Rename"        , "Workspace" , ["="   , "m"])

	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Load"          , "Workspace" , ["CR"  , "Space"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Append"        , "Workspace" , ["Tab"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Add"           , "Workspace" , ["a"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Save"          , "Workspace" , ["s"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Delete"        , "Workspace" , ["d"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Rename"        , "Workspace" , ["="   , "m"])
endfunction

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

	if a:bang
		call ctrlspace#window#Toggle(0)
		call s:modes.Workspace.Enable()
		call ctrlspace#window#Kill(0, 0)
		call ctrlspace#window#Toggle(1)
	endif

	return 1
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Load(k) {{{
function! ctrlspace#keys#workspace#Load(k)
    " preload workspace form cs_cache file
    call ctrlspace#workspaces#PreloadWorkspaces(ctrlspace#window#SelectedIndex())

    " load workspace from cs_workspace file
    if !s:loadWorkspace(0, ctrlspace#workspaces#SelectedWorkspaceName())
        return
    endif

	if a:k ==# "CR"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#ui#DelayedMsg()
	elseif a:k ==# "Space"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#Kill(0, 0)
		call s:modes.Workspace.Enable()
		call ctrlspace#window#Toggle(1)
		call ctrlspace#ui#DelayedMsg()
	endif
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Save(k) {{{
function! ctrlspace#keys#workspace#Save(k)
    " preload workspace form cs_cache file
    call ctrlspace#workspaces#PreloadWorkspaces(ctrlspace#window#SelectedIndex())

    " Confirme saving
    let l:name = ctrlspace#workspaces#SelectedWorkspaceName()
    if !ctrlspace#ui#Confirmed("Save workspace '" . l:name . "' ?")
        return
    endif
	call ctrlspace#window#Kill(0, 1)

    " save workspace to cs_workspace file
    if !ctrlspace#workspaces#SaveWorkspaceFile(l:name)
        return
    endif

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Workspace.Enable()
    call ctrlspace#window#Toggle(1)
    call ctrlspace#ui#Msg("Workspace '" . l:name . "' has been saved")
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Append(k) {{{
function! ctrlspace#keys#workspace#Append(k)
    " preload workspace form cs_cache file
    call ctrlspace#workspaces#PreloadWorkspaces(ctrlspace#window#SelectedIndex())

	call s:loadWorkspace(1, ctrlspace#workspaces#SelectedWorkspaceName())
	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Delete(k) {{{
function! ctrlspace#keys#workspace#Delete(k)
	call ctrlspace#workspaces#DeleteWorkspace(ctrlspace#workspaces#SelectedWorkspaceName())
	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#workspace#Rename(k) {{{
function! ctrlspace#keys#workspace#Rename(k)
	call ctrlspace#workspaces#RenameWorkspace(ctrlspace#workspaces#SelectedWorkspaceName())
	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}



function! ctrlspace#keys#workspace#NewWorkspace(k)
	if !ctrlspace#keys#buffer#NewWorkspace(a:k)
		return
	endif

	call ctrlspace#window#Kill(0, 0)
	call s:modes.Workspace.Enable()
	call ctrlspace#window#Toggle(1)
endfunction
