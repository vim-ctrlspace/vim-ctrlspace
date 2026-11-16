let s:config     = ctrlspace#context#Configuration()
let s:modes      = ctrlspace#modes#Modes()
let s:workspaces = []

function! ctrlspace#workspaces#Workspaces() abort
    return s:workspaces
endfunction

function! ctrlspace#workspaces#SetWorkspaceNames() abort
    let filename     = ctrlspace#util#WorkspaceFile()
    let s:workspaces = []

    call s:modes.Workspace.SetData("LastActive", "")

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

function! ctrlspace#workspaces#SetActiveWorkspaceName(name, ...) abort
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

function! ctrlspace#workspaces#ActiveWorkspace() abort
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

function! ctrlspace#workspaces#NewWorkspace() abort
    tabe
    tabo!
    call ctrlspace#buffers#DeleteHiddenNonameBuffers(1)
    call ctrlspace#buffers#DeleteForeignBuffers(1)
    call s:modes.Workspace.SetData("Active", { "Name": "", "Digest": "", "Root": "" })
endfunction

function! ctrlspace#workspaces#SelectedWorkspaceName() abort
    return s:modes.Workspace.Enabled ? s:workspaces[ctrlspace#window#SelectedIndex()] : ""
endfunction

function! ctrlspace#workspaces#RenameWorkspace(name) abort
    let newName = ctrlspace#ui#GetInput("Rename workspace '" . a:name . "' to: ", a:name)

    if empty(newName)
        return 0
    endif

    for existingName in s:workspaces
        if newName ==# existingName
            call ctrlspace#ui#Msg("Workspace '" . newName . "' already exists.")
            return 0
        endif
    endfor

    let filename = ctrlspace#util#WorkspaceFile()
    let lines    = []

    let workspaceStartMarker = "CS_WORKSPACE_BEGIN: " . a:name
    let workspaceEndMarker   = "CS_WORKSPACE_END: " . a:name
    let lastWorkspaceMarker  = "CS_LAST_WORKSPACE: " . a:name

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

    if s:modes.Workspace.Data.Active.Name ==# a:name && s:modes.Workspace.Data.Active.Root ==# ctrlspace#roots#CurrentProjectRoot()
        call ctrlspace#workspaces#SetActiveWorkspaceName(newName)
    endif

    call ctrlspace#workspaces#SetWorkspaceNames()
    call ctrlspace#window#Kill(0, 0)
    call ctrlspace#window#Toggle(1)

    call ctrlspace#ui#DelayedMsg("Workspace '" . a:name . "' has been renamed to '" . newName . "'.")
    return 1
endfunction

function! ctrlspace#workspaces#DeleteWorkspace(name) abort
    if !ctrlspace#ui#Confirmed("Delete workspace '" . a:name . "'?")
        return 0
    endif

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

    if empty(s:workspaces)
        call ctrlspace#window#Kill(0, 1)
    else
        call ctrlspace#window#Kill(0, 0)
        call ctrlspace#window#Toggle(1)
    endif

    call ctrlspace#ui#DelayedMsg("Workspace '" . a:name . "' has been deleted.")

    return 1
endfunction

" bang == 0) load
" bang == 1) append
function! ctrlspace#workspaces#LoadWorkspace(bang, name) abort
    if !ctrlspace#roots#ProjectRootFound()
        return 0
    endif

    call ctrlspace#util#HandleVimSettings("start")

    let cwdSave = fnamemodify(".", ":p:h")
    silent! exe "cd " . fnameescape(ctrlspace#roots#CurrentProjectRoot())

    try
        return s:loadWorkspace(a:bang, a:name)
    finally
        silent! exe "cd " . fnameescape(cwdSave)
        call ctrlspace#util#HandleVimSettings("stop")
    endtry
endfunction

function! s:loadWorkspace(bang, name) abort
    let filename = ctrlspace#util#WorkspaceFile()

    if !filereadable(filename)
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
            call add(lines, s:tabVariableCommand(ol))
        endif
    endfor

    if empty(lines)
        call ctrlspace#ui#Msg("Workspace '" . name . "' not found in file '" . filename . "'.")
        call ctrlspace#workspaces#SetWorkspaceNames()
        return 0
    endif

    " Sessions written as Vim9 script must start with :vim9script, but a
    " custom workspace file precedes the session by a :cd command.
    let vim9 = index(lines, "vim9script")

    if vim9 > 0
        call insert(lines, remove(lines, vim9))
    endif

    call s:execWorkspaceCommands(a:bang, name, lines)

    if !a:bang
        let s:modes.Workspace.Data.Active.Digest = ctrlspace#workspaces#CreateDigest()
        let msg = "Workspace '" . name . "' has been loaded."
    else
        let s:modes.Workspace.Data.Active.Digest = ""
        let msg = "Workspace '" . name . "' has been appended."
    endif

    call ctrlspace#ui#Msg(msg)
    call ctrlspace#ui#DelayedMsg(msg)

    return 1
endfunction

" Turn a tab variable assignment saved by older versions, such as
" 'let t:CtrlSpaceLabel = ...' or 'let t:ctrlspace_label = ...', into a
" settabvar() call, which is valid in both legacy and Vim9 sessions.
function! s:tabVariableCommand(line) abort
    let parts = matchlist(a:line, '\C^let t:\%(CtrlSpace\(Label\|Autotab\)\|ctrlspace_\(label\|autotab\)\) = \(.*\)$')

    if empty(parts)
        return a:line
    endif

    let name = empty(parts[1]) ? toupper(parts[2][0]) . parts[2][1:] : parts[1]
    return "call settabvar(tabpagenr(), 'CtrlSpace" . name . "', " . parts[3] . ")"
endfunction

" Commands restoring the CtrlSpace buffer list, label and kind of a tab.
function! s:tabCommands(data) abort
    let commands = map(copy(a:data.bufs), '"edit " . fnameescape(v:val)')

    if !empty(a:data.label)
        call add(commands, "call settabvar(tabpagenr(), 'CtrlSpaceLabel', '" . substitute(a:data.label, "'", "''", "g") . "')")
    endif

    if !empty(a:data.autotab)
        call add(commands, "call settabvar(tabpagenr(), 'CtrlSpaceAutotab', " . a:data.autotab . ")")
    endif

    return commands
endfunction

function! s:execWorkspaceCommands(bang, name, lines) abort
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

    try
        for c in commands
            silent exe c
        endfor

        call ctrlspace#util#ChDir(fnamemodify(".", ":p:h"))
    finally
        call delete("CS_SESSION")
    endtry
endfunction

function! ctrlspace#workspaces#SaveWorkspace(name) abort
    if !ctrlspace#roots#ProjectRootFound()
        return 0
    endif

    call ctrlspace#util#HandleVimSettings("start")

    let cwdSave  = fnamemodify(".", ":p:h")
    let ssopSave = &ssop
    let root     = ctrlspace#roots#CurrentProjectRoot()

    silent! exe "cd " . fnameescape(root)

    try
        return s:saveWorkspace(a:name, root)
    finally
        call delete("CS_SESSION")
        silent! exe "cd " . fnameescape(cwdSave)
        let &ssop = ssopSave
        call ctrlspace#util#HandleVimSettings("stop")
    endtry
endfunction

function! s:saveWorkspace(name, root) abort
    if empty(a:name)
        if !empty(s:modes.Workspace.Data.Active.Name) && s:modes.Workspace.Data.Active.Root ==# a:root
            let name = s:modes.Workspace.Data.Active.Name
        else
            call ctrlspace#ui#Msg("Nothing to save.")
            return 0
        endif
    else
        let name = a:name
    endif

    let filename = ctrlspace#util#WorkspaceFile()

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

    set ssop=winsize,tabpages,buffers,sesdir

    let tabData = []

    for t in range(1, tabpagenr("$"))
        let bufs = []

        for bname in values(ctrlspace#api#Buffers(t))
            let bufname = fnamemodify(bname, ":.")

            if filereadable(bufname)
                call add(bufs, bufname)
            endif
        endfor

        call add(tabData, {
                    \ "label": ctrlspace#util#Gettabvar(t, "CtrlSpaceLabel"),
                    \ "autotab": ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceAutotab", 0),
                    \ "bufs": bufs
                    \ })
    endfor

    silent! exe "mksession! CS_SESSION"

    if !filereadable("CS_SESSION")
        call ctrlspace#ui#Msg("Workspace '" . name . "' cannot be saved at this moment.")
        return 0
    endif

    let useWorkspaceFile = filereadable(ctrlspace#context#Configuration().WorkspaceFile)

    if useWorkspaceFile
        call add(lines, "cd " . fnameescape(a:root))
    endif

    " Restore the buffer list of the first tab after the argument list has
    " been cleared, and that of each following tab where the session enters
    " it by a plain 'tabnext'. Sessions without those commands fall back to
    " the first 'edit'.
    let tabIndex = 0

    for cmd in readfile("CS_SESSION")
        if useWorkspaceFile && cmd =~# '^exe "cd " \.\.\? escape(expand("<sfile>:p:h"), '' '')$'
            continue
        elseif cmd =~# "^lcd "
            continue
        elseif cmd =~# "^badd\>"
            let baddList = matchlist(cmd, '\v^badd \+\d+ (\f+)$')
            if exists("baddList[1]") && filereadable(baddList[1])
                call add(lines, cmd)
            endif
        elseif tabIndex < len(tabData) && (cmd ==# 'tabnext' || (tabIndex == 0 && cmd =~# '^\%(:\?%argdel\|tabrewind\)$'))
            call add(lines, cmd)
            call extend(lines, s:tabCommands(tabData[tabIndex]))
            let tabIndex += 1
        elseif tabIndex == 0 && cmd =~# '^edit \f\+'
            call extend(lines, s:tabCommands(tabData[tabIndex]))
            call add(lines, cmd)
            let tabIndex += 1
        else
            call add(lines, cmd)
        endif
    endfor

    call add(lines, endMarker)

    call writefile(lines, filename)

    call ctrlspace#workspaces#SetActiveWorkspaceName(name, ctrlspace#workspaces#CreateDigest())
    call ctrlspace#workspaces#SetWorkspaceNames()

    let msg = "Workspace '" . name . "' has been saved."
    call ctrlspace#ui#Msg(msg)
    call ctrlspace#ui#DelayedMsg(msg)

    return 1
endfunction

function! ctrlspace#workspaces#CreateDigest() abort
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
