" This script manages change movements (copy, move & switch) of buffers & tabs. Concretely,
" it implements an interface with optional wraparound for all these change movement types

let s:WrapEnabled = ctrlspace#context#Configuration().ChangeBufTabWrapsAround


function! s:genCpOrMvBufToTabCmdmap(funcstr)
    let l:ct = tabpagenr()      " ct: current tab
    let l:lt = tabpagenr('$')   " lt: last tab
    return  { 'nb': eval("l:ct-1 > 0      ? 'call '.a:funcstr.'('.(l:ct-1).')' : ''"),
            \ 'nf': eval("l:ct+1 < l:lt+1 ? 'call '.a:funcstr.'('.(l:ct+1).')' : ''"),
            \ 'wb': 'call '.a:funcstr.'('.l:lt.')',
            \ 'wf': 'call '.a:funcstr.'(1)', }
endfunction

function! s:genSwitchTabCmdmap(tabBwd, tabFwd)
    return  { 'nb': eval("tabpagenr() != 1              ? a:tabBwd : ''"),
            \ 'nf': eval("tabpagenr() != tabpagenr('$') ? a:tabFwd : ''"),
            \ 'wb': a:tabBwd,
            \ 'wf': a:tabFwd, }
endfunction

function! s:genMoveTabCmdmap(tmvBwd, tmvFwd)
    return { 'nb': eval("tabpagenr() != 1              ? a:tmvBwd : ''"),
           \ 'nf': eval("tabpagenr() != tabpagenr('$') ? a:tmvFwd : ''"),
           \ 'wb': 'tabm $',
           \ 'wf': 'tabm 0', }
endfunction

" Define a table of Funcrefs. Each Funcref when called, returns a map of 4 nonoverlapping
" oriented-commands (nowrap backwards, nowrap forwards, wrap backwards, wrap forwads) that 
" corresponds to the keyed Funcref's change movement type (MoveBufferToTab, SwitchTab, etc.)
let s:CmdmapGenerators = { "CopyBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#CopyBufferToTab']),
                         \ "MoveBufferToTab"    : function('s:genCpOrMvBufToTabCmdmap', ['ctrlspace#buffers#MoveBufferToTab']),
                         \ "SwitchTabInBufMode" : function('s:genSwitchTabCmdmap', ['normal! gT', 'normal! gt']),
                         \ "SwitchTabInTabMode" : function('s:genSwitchTabCmdmap', ['call feedkeys("k\<Space>")', 'call feedkeys("j\<Space>")']),
                         \ "MoveTab"            : function('s:genMoveTabCmdmap', ['tabm-1', 'tabm+1']),
                         \ "MoveTabLegacy"      : function('s:genMoveTabCmdmap', ['tabm'.(tabpagenr()-2), 'tabm'.tabpagenr()]), }



" Generates a Funcref of the passed change movement cmdmap. This Funcref when called
" w/ an orientation [nb|nf|wb|wf] will correctly execute the directed change movement
function! s:genCmdmapFuncref(cmdmap)
    func! s:_execute_oriented_cmd(orientation) closure
        if     a:orientation ==# 'nb'          " nb: nowrap backwards
            execute a:cmdmap.nb
        elseif a:orientation ==# 'nf'          " nf: nowrap forwards
            execute a:cmdmap.nf
        elseif a:orientation ==# 'wb'          " wb: wrap backwards
            execute a:cmdmap.wb
        elseif a:orientation ==# 'wf'          " wf: wrap forwards
            execute a:cmdmap.wf
        endif
    endfunc
    return function('s:_execute_oriented_cmd') " return the Cmdmap Funcref (Cmfr)
endfunc

" Based on user input for movement direction, their current tabpage number & whether wraparound is 
" enabled, determine which orientation [nb|nf|wb|wf] to call the passed Cmdmap Funcref (Cmfr) with
function! s:orientCmdmap(Cmfr, dir)
    if     s:WrapEnabled && a:dir ==# 'BWD' && tabpagenr() == 1
        call a:Cmfr('wb')
    elseif s:WrapEnabled && a:dir ==# 'FWD' && tabpagenr() == tabpagenr('$')
        call a:Cmfr('wf')
    elseif a:dir ==# 'BWD'
        call a:Cmfr('nb')
    elseif a:dir ==# 'FWD'
        call a:Cmfr('nf')
    endif
endfunction

" Publicly exposed wrapper, requiring only the passing of the desired change movement type (CopyBufferToTab,
" MoveTab, etc.) & its direction (backwards OR forwards), and it'll execute the correctly oriented Ex command
function! ctrlspace#changebuftab#Execute(changeType, dir)
    let cmdmap = s:CmdmapGenerators[a:changeType]()
    let Cmfr   = s:genCmdmapFuncref(cmdmap)
    call s:orientCmdmap(Cmfr, a:dir)
endfunction
