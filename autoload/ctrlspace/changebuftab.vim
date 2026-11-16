" this script manages change movements (copy, move & switch) of buffers & tabs

let s:WrapEnabled = ctrlspace#context#Configuration().EnableBufferTabWrapAround

function! s:genCpOrMvBufToTabCmdmap(funcstr) abort
    let l:ct = tabpagenr()      " ct: current tab
    let l:lt = tabpagenr('$')   " lt: last tab
    return  { 'nb': eval("l:ct-1 > 0      ? 'call '.a:funcstr.'('.(l:ct-1).')' : ''"),
            \ 'nf': eval("l:ct+1 < l:lt+1 ? 'call '.a:funcstr.'('.(l:ct+1).')' : ''"),
            \ 'wb': 'call '.a:funcstr.'('.l:lt.')',
            \ 'wf': 'call '.a:funcstr.'(1)', }
endfunction

function! s:genSwitchTabCmdmap(tabBwd, tabFwd) abort
    return  { 'nb': eval("tabpagenr() != 1              ? a:tabBwd : ''"),
            \ 'nf': eval("tabpagenr() != tabpagenr('$') ? a:tabFwd : ''"),
            \ 'wb': a:tabBwd,
            \ 'wf': a:tabFwd, }
endfunction

function! s:genMoveTabCmdmap(tmvBwd, tmvFwd) abort
    return { 'nb': eval("tabpagenr() != 1              ? a:tmvBwd : ''"),
           \ 'nf': eval("tabpagenr() != tabpagenr('$') ? a:tmvFwd : ''"),
           \ 'wb': 'tabm $',
           \ 'wf': 'tabm 0', }
endfunction

" keys: movement/action types
" values: Funcrefs that return one of the Cmdmaps above when called
let s:CmdmapGenerators = { "CopyBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#CopyBufferToTab']),
                         \ "MoveBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#MoveBufferToTab']),
                         \ "SwitchTabInBufMode" : function('s:genSwitchTabCmdmap', ['normal! gT', 'normal! gt']),
                         \ "SwitchTabInTabMode" : function('s:genSwitchTabCmdmap', ['call feedkeys("k\<Space>")', 'call feedkeys("j\<Space>")']),
                         \ "MoveTab"            : function('s:genMoveTabCmdmap', ['tabm-1', 'tabm+1']), }

function! s:genCmdmapFuncref(cmdmap) abort
    func! s:_execute_oriented_cmd(orientation) closure abort
        execute a:cmdmap[a:orientation]
    endfunc
    return function('s:_execute_oriented_cmd')
endfunction

function! s:orientCmdmap(Cmfr, dir) abort
    if     s:WrapEnabled && a:dir ==# 'BWD' && tabpagenr() == 1
        let orientation = 'wb'    " wb: wrap backwards
    elseif s:WrapEnabled && a:dir ==# 'FWD' && tabpagenr() == tabpagenr('$')
        let orientation = 'wf'    " wf: wrap forwards
    elseif a:dir ==# 'BWD'
        let orientation = 'nb'    " nb: nowrap backwards
    elseif a:dir ==# 'FWD'
        let orientation = 'nf'    " nf: nowrap forwards
    endif
    call a:Cmfr(orientation)
endfunction

" public API
function! ctrlspace#changebuftab#Execute(changeType, dir) abort
    let cmdmap = s:CmdmapGenerators[a:changeType]()
    let Cmfr   = s:genCmdmapFuncref(cmdmap)
    call s:orientCmdmap(Cmfr, a:dir)
endfunction
