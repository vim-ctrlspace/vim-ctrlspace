" This script manages changing (switching, moving & copying) buffers & tabs
" In particular, it implements an optional wraparound for all such actions

let s:wrapOn = ctrlspace#context#Configuration().EnableWraparound


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

function! s:genMoveTabCmdmap(tmvBwd, tmvFwd)
    return {
           \ 'nb': {-> tabpagenr() != 1              ? a:tmvBwd : ''}(),
           \ 'nf': {-> tabpagenr() != tabpagenr('$') ? a:tmvFwd : ''}(),
           \ 'wb': 'tabm $',
           \ 'wf': 'tabm 0',
           \ }
endfunction

" Table of Funcrefs: each Funref when called, returns a dict of 4 nonoverlapping
" movement commands (nowrap backwards, nowrap forwards, wrap backwards, wrap forwads)
" for their corresponding change action type (move buffer to tab, switch tab, etc.)
let s:CmdmapGenerators = {
                       \ "CopyBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#CopyBufferToTab']),
                       \ "MoveBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#MoveBufferToTab']),
                       \ "SwitchTabInBufMode" : function('s:genSwitchTabCmdmap', ['normal! gT', 'normal! gt']),
                       \ "SwitchTabInTabMode" : function('s:genSwitchTabCmdmap', ['call feedkeys("k\<Space>")', 'call feedkeys("j\<Space>")']),
                       \ "MoveTab"            : function('s:genMoveTabCmdmap', ['tabm-1', 'tabm+1']),
                       \ "MoveTabLegacy"      : function('s:genMoveTabCmdmap', ['tabm'.(tabpagenr()-2), 'tabm'.tabpagenr()]),
                       \ }



" generates a Funcref for the passed change cmdmap, which when called with 
" an action type (nb, nf, wb OR wf) will execute the correct action + movement
function! s:genCmdmapFuncref(cmdmap)
    func! s:_cmdmapFn(action) closure
        if a:action ==# 'nb'      " nb: nowrap backwards
            execute a:cmdmap.nb
        elseif a:action ==# 'nf'  " nf: nowrap forwards
            execute a:cmdmap.nf
        elseif a:action ==# 'wb'  " wb: wrap backwards
            execute a:cmdmap.wb
        elseif a:action ==# 'wf'  " wf: wrap forwards
            execute a:cmdmap.wf
        endif
    endfunc
    return function('s:_cmdmapFn')
endfunc

" determines based on user-input for direction, current tab & whether wraparound is enabled,
" which type of action (nb, nf, wb OR wf) to call the passed Funcref with
function! s:cmdmapFnCaller(CmdFnRef, dir)
    if s:wrapOn && a:dir ==# 'BWD' && tabpagenr() == 1
        call a:CmdFnRef('wb')
    elseif s:wrapOn && a:dir ==# 'FWD' && tabpagenr() == tabpagenr('$')
        call a:CmdFnRef('wf')
    elseif a:dir ==# 'BWD'
        call a:CmdFnRef('nb')
    elseif a:dir ==# 'FWD'
        call a:CmdFnRef('nf')
    endif
endfunction

" publicly exposed wrapper, which sets-up and calls the appropriate functions, given
" the type of change required (move tab, copy buffer, etc.) & its direction of movement
function! ctrlspace#changebuftab#Execute(changeType, dir)
    let cmdMap = s:CmdmapGenerators[a:changeType]()
    let CmdFnRef = s:genCmdmapFuncref(cmdMap)
    call s:cmdmapFnCaller(CmdFnRef, a:dir)
endfunction
