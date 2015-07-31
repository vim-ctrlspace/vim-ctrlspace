let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#workspace#Init()
    call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#LoadOrSave", "Workspace", ["Tab", "CR", "Space"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Append", "Workspace", ["a"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#NewWorkspace", "Workspace", ["n", "N"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#ToggleSubmode", "Workspace", ["s"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Delete", "Workspace", ["d"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#workspace#Rename", "Workspace", ["="])
endfunction

function! ctrlspace#keys#workspace#Delete(k)
    call ctrlspace#workspaces#DeleteWorkspace(ctrlspace#workspaces#SelectedWorkspaceName())
endfunction

function! ctrlspace#keys#workspace#Rename(k)
    call ctrlspace#workspaces#RenameWorkspace(ctrlspace#workspaces#SelectedWorkspaceName())
endfunction

function! ctrlspace#keys#workspace#LoadOrSave(k)
    if s:modes.Workspace.Data.SubMode ==# "load"
        if !s:loadWorkspace(0, ctrlspace#workspaces#SelectedWorkspaceName())
            return
        endif
    elseif s:modes.Workspace.Data.SubMode ==# "save"
        if !s:saveWorkspace(ctrlspace#workspaces#SelectedWorkspaceName())
            return
        endif
    endif

    if a:k ==# "CR"
        call ctrlspace#window#Toggle(0)
    elseif a:k ==# "Space"
        call ctrlspace#window#StartAndFeedkeys("w")
    endif
endfunction

function! ctrlspace#keys#workspace#Append(k)
    call s:loadWorkspace(1, ctrlspace#workspaces#SelectedWorkspaceName())
endfunction

function! ctrlspace#keys#workspace#NewWorkspace(k)
    let saveWorkspaceBefore = 0
    let active = s:modes.Workspace.Data.Active

    if !empty(active.Name) && (active.Digest !=# ctrlspace#workspaces#CreateDigest())
        if s:config.SaveWorkspaceOnSwitch
            let saveWorkspaceBefore = 1
        elseif !ctrlspace#ui#Confirmed("Current workspace ('" . active.Name . "') not saved. Proceed anyway?")
            return
        endif
    endif

    if !ctrlspace#ui#ProceedIfModified()
        return
    endif

    call ctrlspace#window#Kill(0, 1)

    if saveWorkspaceBefore
        call ctrlspace#workspaces#SaveWorkspace("")
    endif

    call ctrlspace#workspaces#NewWorkspace()

    if a:k ==# "N"
        call ctrlspace#window#StartAndFeedkeys("w")
    endif
endfunction

function! ctrlspace#keys#workspace#ToggleSubmode(k)
    call s:modes.Workspace.SetData("LastBrowsed", line("."))
    call ctrlspace#window#Kill(0, 0)

    if s:modes.Workspace.Data.SubMode == "load"
        call s:modes.Workspace.SetData("SubMode", "save")
    else
        call s:modes.Workspace.SetData("SubMode", "load")
    endif

    call ctrlspace#window#Toggle(1)
endfunction

function! s:saveWorkspace(name)
    let name = ctrlspace#ui#GetInput("Save current workspace as: ", a:name)

    if empty(name)
        return 0
    endif

    call ctrlspace#window#Kill(0, 1)
    return ctrlspace#workspaces#SaveWorkspace(name)
endfunction

function! s:loadWorkspace(bang, name)
    let saveWorkspaceBefore = 0
    let active = s:modes.Workspace.Data.Active

    if !empty(active.Name) && !a:bang
        let msg = ""

        if a:name ==# active.Name
            let msg = "Reload current workspace: '" . a:name . "'?"
        elseif !empty(active.Name)
            if active.Digest !=# ctrlspace#workspaces#CreateDigest()
                if s:config.SaveWorkspaceOnSwitch
                    let saveWorkspaceBefore = 1
                else
                    let msg = "Current workspace ('" . active.Name . "') not saved. Proceed anyway?"
                endif
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

    if saveWorkspaceBefore && !ctrlspace#workspaces#SaveWorkspace("")
        return 0
    endif

    if !ctrlspace#workspaces#LoadWorkspace(a:bang, a:name)
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
