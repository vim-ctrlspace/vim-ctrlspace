" Keep the dispatch in legacy Vimscript: Neovim must never source Vim9 code.

function! ctrlspace#matcher#Search(items, query, ...) abort
    let limit = a:0 ? a:1 : 200
    if has('nvim')
        return luaeval("require('ctrlspace.matcher').search(_A[1], _A[2], _A[3])",
                    \ [a:items, a:query, limit])
    endif
    return ctrlspace#vendor#fuzzbox#Search(a:items, a:query, limit)
endfunction

function! ctrlspace#matcher#HighlightPositions(text, positions, lnum) abort
    if has('nvim')
        return luaeval("require('ctrlspace.matcher').highlight_positions(_A[1], _A[2], _A[3])",
                    \ [a:text, a:positions, a:lnum])
    endif
    return ctrlspace#vendor#fuzzbox#HighlightPositions(a:text, a:positions, a:lnum)
endfunction
