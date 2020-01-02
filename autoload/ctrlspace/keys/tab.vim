let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#tab#Init()
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#GoToTab",               "Tab", ["Tab", "CR", "Space"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#CloseTab",              "Tab", ["c"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#AddTab",                "Tab", ["t", "a"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#CopyTab",               "Tab", ["y"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#SwitchTab",             "Tab", ["[", "]"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#MoveTab",               "Tab", ["{", "}", "+", "-"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#NewTabLabel",           "Tab", ["=", "m"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#RemoveTabLabel",        "Tab", ["_"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#CollectUnsavedBuffers", "Tab", ["u"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#CollectForeignBuffers", "Tab", ["f"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#tab#NewWorkspace",          "Tab", ["N"])
endfunction

function! ctrlspace#keys#tab#GoToTab(k)
    let nr = ctrlspace#window#SelectedIndex()
    call ctrlspace#window#Kill(0, 1)
    silent! exe "normal! " . nr . "gt"

    if a:k ==# "CR"
        call ctrlspace#window#Toggle(0)
    elseif a:k ==# "Space"
        call ctrlspace#window#Toggle(0)
        call ctrlspace#window#Kill(0, 0)
        call s:modes.Tab.Enable()
        call ctrlspace#window#Toggle(1)
    endif
endfunction

function! ctrlspace#keys#tab#CloseTab(k)
    let nr = ctrlspace#window#SelectedIndex()
    call ctrlspace#window#Kill(0, 1)
    silent! exe "normal! " . nr . "gt"
    call ctrlspace#window#Toggle(0)
    call ctrlspace#tabs#CloseTab()
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#keys#tab#AddTab(k)
    let nr = ctrlspace#window#SelectedIndex()
    call ctrlspace#window#Kill(0, 1)
    silent! exe "normal! " . nr . "gt"
    silent! exe "tabnew"
    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#keys#tab#CopyTab(k)
    let nr = ctrlspace#window#SelectedIndex()
    call ctrlspace#window#Kill(0, 1)
    silent! exe "normal! " . nr . "gt"

    let sourceLabel = exists("t:CtrlSpaceLabel") ? t:CtrlSpaceLabel : ""
    let sourceList = copy(t:CtrlSpaceList)

    silent! exe "tabnew"

    let label = empty(sourceLabel) ? ("Copy of tab " . nr) : (sourceLabel . " (copy)")
    call ctrlspace#tabs#SetTabLabel(tabpagenr(), label, 1)

    let t:CtrlSpaceList = sourceList

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 1)
    call ctrlspace#window#Toggle(0)
    call ctrlspace#buffers#CloseBuffer()
    call ctrlspace#jumps#Jump("previous")
    call ctrlspace#buffers#LoadBuffer()
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#keys#tab#SwitchTab(k)
    call ctrlspace#window#MoveSelectionBar(tabpagenr())
    let dir = {'[': 'BWD', ']': 'FWD'}[a:k]
    call ctrlspace#changebuftab#Execute("SwitchTabInTabMode", dir)
endfunction

function! ctrlspace#keys#tab#NewTabLabel(k)
    let l = line(".")

    if ctrlspace#tabs#NewTabLabel(ctrlspace#window#SelectedIndex())
        call ctrlspace#window#Kill(0, 0)
        call ctrlspace#window#Toggle(1)
        call ctrlspace#window#MoveSelectionBar(l)
    endif
endfunction

function! ctrlspace#keys#tab#RemoveTabLabel(k)
    let l = line(".")

    if ctrlspace#tabs#RemoveTabLabel(ctrlspace#window#SelectedIndex())
        call ctrlspace#window#Kill(0, 0)
        call ctrlspace#window#Toggle(1)
        redraw!

        call ctrlspace#window#MoveSelectionBar(l)
    endif
endfunction

" this function is also used to move tabs in Buffer mode
function! ctrlspace#keys#tab#MoveHelper(k)
    let dir = {'-': 'BWD', '+': 'FWD', '{': 'BWD', '}': 'FWD'}[a:k]
    if v:version < 704
        " NOTE: the tabmove cmds used here are directly copied from the existing code,
        " and are assumed to work for <704 on faith, as they don't work for newer vers.
        call ctrlspace#changebuftab#Execute("MoveTabLegacy", dir)
    else
        call ctrlspace#changebuftab#Execute("MoveTab", dir)
    endif
endfunction

function! ctrlspace#keys#tab#MoveTab(k)
    let nr = ctrlspace#window#SelectedIndex()
    call ctrlspace#window#Kill(0, 1)
    silent! exe "normal! " . nr . "gt"
    call ctrlspace#keys#tab#MoveHelper(a:k)
    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#keys#tab#CollectUnsavedBuffers(k)
    call ctrlspace#tabs#CollectUnsavedBuffers()
endfunction

function! ctrlspace#keys#tab#CollectForeignBuffers(k)
    call ctrlspace#tabs#CollectForeignBuffers()
endfunction

function! ctrlspace#keys#tab#NewWorkspace(k)
    if !ctrlspace#keys#buffer#NewWorkspace(a:k)
        return
    endif

    call ctrlspace#window#Kill(0, 0)
    call s:modes.Tab.Enable()
    call ctrlspace#window#Toggle(1)
endfunction
