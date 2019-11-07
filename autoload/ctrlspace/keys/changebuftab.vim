" script for managing buffer & tab change (switch, move, copy)

let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

let s:wrapOn = s:config.EnableWraparound

function! ctrlspace#keys#changebuftab#RegisterCmds(cmds)
    let change_cmds = copy(a:cmds)

    func! s:_changeCmdFunc(changeType) closure
        if a:changeType ==# 'nb'
            echo change_cmds.nb
            execute change_cmds.nb
        elseif a:changeType ==# 'nf'
            echo change_cmds.nf
            execute change_cmds.nf
        elseif a:changeType ==# 'wb'
            echo change_cmds.wb
            execute change_cmds.wb
        elseif a:changeType ==# 'wf'
            echo change_cmds.wf
            execute change_cmds.wf
        endif
    endfunc

    return function('s:_changeCmdFunc')
endfunc


function! ctrlspace#keys#changebuftab#Changer(CmdFnRef, changeDir)
    " let FuncRef = a:ChangeActionFunc
    " let currTab = tabpagenr()
    " let lastTab = tabpagenr('$')

    if s:wrapOn && a:changeDir ==# 'B' && tabpagenr() == 1
        call a:CmdFnRef('wb')
    elseif s:wrapOn && a:changeDir ==# 'F' && tabpagenr() == tabpagenr('$')
        call a:CmdFnRef('wf')
    elseif a:changeDir ==# 'B'
        call a:CmdFnRef('nb')
    elseif a:changeDir ==# 'F'
        call a:CmdFnRef('nf')
    endif
endfunction

" TODO: wrap the whole RegisterCmds & calling the Registered FuncRef step


" let s:changer = {}

" function! s:changer.RegisterCmds() dict
"     let cmds = copy(self)
"
"     func! ChangeActionFunc(changeType)
"         if a:changeType ==# 'wb'
"             return cmds.wb
"         elseif a:changeType ==# 'wf'
"             return cmds.wf
"           elseif a:changeType ==# 'nw'
"             return cmds.nw
"     endfunc
"
"     return ChangeActionFunc
" endfunc
