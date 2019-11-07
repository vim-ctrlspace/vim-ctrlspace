" script for managing buffer & tab change (switch, move, copy)

" let s:config = ctrlspace#context#Configuration()
" let s:modes  = ctrlspace#modes#Modes()
" let s:wrapOn = s:config.EnableWraparound
let s:wrapOn = ctrlspace#context#Configuration().EnableWraparound

" convenient shorthands for the various tab switching commands
" let s:tabL = 'normal! gT'
" let s:tabR = 'normal! gt'
" let s:tabU = 'call feedkeys("k\<Space>")'
" let s:tabD = 'call feedkeys("j\<Space>")'

function! s:genCpOrMvBufToTabCmdmap(funcstr)
    let l:ct = tabpagenr()      " ct: current tab
    let l:lt = tabpagenr('$')   " lt: last tab
    return  {
          \ 'nb': {-> l:ct-1 > 0      ? 'call '.a:funcstr.'('.(l:ct-1).')' : ''}(),
          \ 'nf': {-> l:ct+1 < l:lt+1 ? 'call '.a:funcstr.'('.(l:ct+1).')' : ''}(),
          \ 'wb': 'call '.a:funcstr.'('.l:lt.')',
          \ 'wf': 'call '.a:funcstr.'(1)',
          \ }
endfunction

function! s:genSwitchTabCmdmap(tabBwd, tabFwd)
    return  {
          \ 'nb': {-> tabpagenr() != 1              ? a:tabBwd : ''}(),
          \ 'nf': {-> tabpagenr() != tabpagenr('$') ? a:tabFwd : ''}(),
          \ 'wb': a:tabBwd,
          \ 'wf': a:tabFwd,
          \ }
endfunction

function! s:genMoveTabCmdmap()
    return {
           \ 'nb': {-> tabpagenr() != 1              ? 'tabm-1' : ''}(),
           \ 'nf': {-> tabpagenr() != tabpagenr('$') ? 'tabm+1' : ''}(),
           \ 'wb': 'tabm $',
           \ 'wf': 'tabm 0',
           \ }
endfunction

let s:CmdmapGenerators = {
                       \ "CopyBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#CopyBufferToTab']),
                       \ "MoveBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#MoveBufferToTab']),
                       \ "SwitchTabInBufMode" : function('s:genSwitchTabCmdmap', ['normal! gT', 'normal! gt']),
                       \ "SwitchTabInTabMode" : function('s:genSwitchTabCmdmap', ['call feedkeys("k\<Space>")', 'call feedkeys("j\<Space>")']),
                       \ "MoveTab"            : function('s:genMoveTabCmdmap'),
                       \ }



function! s:genCmdmapFuncref(cmdmap)
    func! s:_cmdmapFn(action) closure
        if a:action ==# 'nb'      " nb: normal backwards
            " echo a:cmdmap.nb
            execute a:cmdmap.nb
        elseif a:action ==# 'nf'  " nf: normal forwards
            " echo a:cmdmap.nf
            execute a:cmdmap.nf
        elseif a:action ==# 'wb'  " wb: wrap backwards
            " echo a:cmdmap.wb
            execute a:cmdmap.wb
        elseif a:action ==# 'wf'  " wf: wrap forwards
            " echo a:cmdmap.wf
            execute a:cmdmap.wf
        endif
    endfunc
    return function('s:_cmdmapFn')
endfunc


function! s:cmdmapFnCaller(CmdFnRef, dir)
    " echo function('s:cmdmapFnCaller')
    " echo 'current tab: ' . tabpagenr()
    " echo 'last tab: ' . tabpagenr('$')
    if s:wrapOn && a:dir ==# 'B' && tabpagenr() == 1
        call a:CmdFnRef('wb')
    elseif s:wrapOn && a:dir ==# 'F' && tabpagenr() == tabpagenr('$')
        call a:CmdFnRef('wf')
    elseif a:dir ==# 'B'        " B for backwards
        call a:CmdFnRef('nb')
    elseif a:dir ==# 'F'        " F for forwards
        call a:CmdFnRef('nf')
    endif
endfunction


function! ctrlspace#changebuftab#Execute(changeType, dir)
    let cmdMap = s:CmdmapGenerators[a:changeType]()
    " echo cmdMap
    let CmdFnRef = s:genCmdmapFuncref(cmdMap)
    call s:cmdmapFnCaller(CmdFnRef, a:dir)
endfunction

" function! ctrlspace#keys#changebuftab#RegisterCmds(cmds)
"     let change_cmds = copy(a:cmds)
"
"     func! s:_changeCmdFunc(changeType) closure
"         if a:changeType ==# 'nb'      " nb: normal backwards
"             echo change_cmds.nb
"             execute change_cmds.nb
"         elseif a:changeType ==# 'nf'  " nf: normal forwards
"             echo change_cmds.nf
"             execute change_cmds.nf
"         elseif a:changeType ==# 'wb'  " wb: wrap backwards
"             echo change_cmds.wb
"             execute change_cmds.wb
"         elseif a:changeType ==# 'wf'  " wf: wrap forwards
"             echo change_cmds.wf
"             execute change_cmds.wf
"         endif
"     endfunc
"
"     return function('s:_changeCmdFunc')
" endfunc


" function! ctrlspace#keys#changebuftab#Changer(CmdFnRef, changeDir)
"     " let FuncRef = a:ChangeActionFunc
"     " let currTab = tabpagenr()
"     " let lastTab = tabpagenr('$')
"
"     if s:wrapOn && a:changeDir ==# 'B' && tabpagenr() == 1
"         call a:CmdFnRef('wb')
"     elseif s:wrapOn && a:changeDir ==# 'F' && tabpagenr() == tabpagenr('$')
"         call a:CmdFnRef('wf')
"     elseif a:changeDir ==# 'B'
"         call a:CmdFnRef('nb')
"     elseif a:changeDir ==# 'F'
"         call a:CmdFnRef('nf')
"     endif
" endfunction

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
