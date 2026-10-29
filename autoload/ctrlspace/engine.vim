let s:config     = ctrlspace#context#Configuration()
let s:modes      = ctrlspace#modes#Modes()

" Returns [highlight positions, original indices, visible size, rendered text].
function! ctrlspace#engine#Content() abort
    let items = s:contentSource()

    if !empty(s:modes.Search.Data.Letters)
        " Native matchers return best first; CtrlSpace selects the bottom row.
        let items = reverse(ctrlspace#matcher#Search(items,
                    \ join(s:modes.Search.Data.Letters, ''), 200))
    else
        " Never sort the shared file cache in place: its indices identify files.
        let items = copy(items[:499])
        if s:modes.Tab.Enabled
            call sort(items, function("ctrlspace#engine#CompareByIndex"))
        else
            call sort(items, function("ctrlspace#engine#CompareByText"))
        endif
    endif

    if s:modes.Search.Enabled
        let maxHeight = max([1, ctrlspace#window#MaxHeight()])
        if len(items) > maxHeight
            let items = items[-maxHeight : -1]
        endif
    endif

    return s:prepareContent(items)
endfunction

function! ctrlspace#engine#CompareByText(a, b) abort
    let lhs = fnamemodify(a:a.text, ':p')
    let rhs = fnamemodify(a:b.text, ':p')
    if lhs < rhs
        return -1
    elseif lhs > rhs
        return 1
    else
        return 0
    endif
endfunction

function! ctrlspace#engine#CompareByIndex(a, b) abort
    if a:a.index < a:b.index
        return -1
    elseif a:a.index > a:b.index
        return 1
    else
        return 0
    endif
endfunction

function! s:contentSource() abort
    let clv = ctrlspace#modes#CurrentListView()

    if clv.Name ==# "Buffer"
        return s:bufferListContent(clv)
    elseif clv.Name ==# "File"
        return s:fileListContent(clv)
    elseif clv.Name ==# "Tab"
        return s:tabContent(clv)
    elseif clv.Name ==# "Workspace"
        return s:workspaceListContent(clv)
    elseif clv.Name ==# "Bookmark"
        return s:bookmarkListContent(clv)
    endif
endfunction

function! s:bookmarkListContent(clv) abort
    let content   = []
    let bookmarks = ctrlspace#bookmarks#Bookmarks()

    for i in range(len(bookmarks))
        let indicators = ""

        if !empty(a:clv.Data.Active) && (bookmarks[i].Directory ==# a:clv.Data.Active.Directory)
            let indicators .= s:config.Symbols.IA
        endif

        call add(content, { "index": i, "text": bookmarks[i].Name, "indicators": indicators })
    endfor

    return content
endfunction

function! s:workspaceListContent(clv) abort
    let content    = []
    let workspaces = ctrlspace#workspaces#Workspaces()
    let active     = ctrlspace#workspaces#ActiveWorkspace()

    for i in range(len(workspaces))
        let name = workspaces[i]
        let indicators = ""

        if name ==# active.Name && active.Status
            if active.Status == 2
                let indicators .= s:config.Symbols.IM
            endif

            let indicators .= s:config.Symbols.IA
        elseif name ==# a:clv.Data.LastActive
            let indicators .= s:config.Symbols.IV
        endif

        call add(content, { "index": i, "text": name, "indicators": indicators })
    endfor

    return content
endfunction

function! s:tabContent(clv) abort
    let content    = []
    let currentTab = tabpagenr()

    for i in range(1, tabpagenr("$"))
        let winnr         = tabpagewinnr(i)
        let buflist       = tabpagebuflist(i)
        let bufnr         = buflist[winnr - 1]
        let bufname       = bufname(bufnr)
        let tabBufsNumber = ctrlspace#api#TabBuffersNumber(i)
        let title         = ctrlspace#api#TabTitle(i, bufnr, bufname)

        if !s:config.UseUnicode && !empty(tabBufsNumber)
            let tabBufsNumber = ":" . tabBufsNumber
        endif

        let indicators = ""

        if ctrlspace#api#TabModified(i)
            let indicators .= s:config.Symbols.IM
        endif

        if i == currentTab
            let indicators .= s:config.Symbols.IA
        endif

        call add(content, { "index": i, "text": string(i) . tabBufsNumber . " " . title, "indicators": indicators })
    endfor

    return content
endfunction

function! s:fileListContent(clv) abort
    call ctrlspace#files#CollectFiles()
    return ctrlspace#files#Items()
endfunction

function! s:bufferListContent(clv) abort
    let content = []

    if a:clv.Data.SubMode ==# "single"
        let buffers = map(keys(ctrlspace#buffers#Buffers(tabpagenr())), "str2nr(v:val)")
    elseif a:clv.Data.SubMode ==# "all"
        let buffers = map(keys(ctrlspace#buffers#Buffers(0)), "str2nr(v:val)")
    elseif a:clv.Data.SubMode ==# "visible"
        let buffers = filter(map(keys(ctrlspace#buffers#Buffers(tabpagenr())), "str2nr(v:val)"), "bufwinnr(v:val) != -1")
    endif

    for i in buffers
        let entry = s:bufferEntry(i)
        if !empty(entry)
            call add(content, entry)
        endif
    endfor

    return content
endfunction

function! s:bufferEntry(bufnr) abort
    let bufname  = fnamemodify(bufname(a:bufnr), ":.")
    let modified = getbufvar(a:bufnr, "&modified")
    let winnr    = bufwinnr(a:bufnr)

    if !strlen(bufname) && (modified || (winnr != -1))
        let bufname = "[" . a:bufnr . "*No Name]"
    endif

    if strlen(bufname)
        let indicators = ""

        if modified
            let indicators .= s:config.Symbols.IM
        endif

        if winnr == t:CtrlSpaceStartWindow
            let indicators .= s:config.Symbols.IA
        elseif winnr != -1
            let indicators .= s:config.Symbols.IV
        endif

        return { "index": a:bufnr, "text": bufname, "indicators": indicators }
    else
        return {}
    endif
endfunction

" Return the visible suffix, removed byte count, and ellipsis byte count.
" Crop whole characters (including composing marks), using display cells for
" width and bytes for highlight positions. Never slice into a UTF-8 character.
function! s:clipText(text, width) abort
    let width = max([0, a:width])
    if strdisplaywidth(a:text) <= width
        return [a:text, 0, 0]
    endif

    let dots = s:config.Symbols.Dots
    while strdisplaywidth(dots) > width
        let dots = strpart(dots, 0, byteidx(dots, strchars(dots, 1) - 1))
    endwhile

    let start = strchars(a:text, 1)
    let tail = ''
    while start > 0
        let candidate = strpart(a:text, byteidx(a:text, start - 1))
        if strdisplaywidth(dots . candidate) > width
            break
        endif
        let tail = candidate
        let start -= 1
    endwhile
    return [dots . tail, byteidx(a:text, start), strlen(dots)]
endfunction

function! s:prepareContent(items) abort
    let sizes = ctrlspace#context#SymbolSizes()

    if s:modes.File.Enabled
        let itemSpace = 5
    elseif s:modes.Bookmark.Enabled
        let itemSpace = 5 + sizes.IAV
    else
        let itemSpace = 5 + sizes.IAV + sizes.IM
    endif

    let content = []
    let highlights = []
    let indices = []

    for item in a:items
        let [line, removed, prefix] = s:clipText(item.text, &columns - itemSpace)
        let lnum = len(content) + 1

        if has_key(item, 'positions')
            for pos in ctrlspace#matcher#HighlightPositions(item.text, item.positions, lnum)
                let start = pos[1] - 1
                let end = start + pos[2]
                if end > removed
                    let start = max([start, removed])
                    " Two columns are reserved for the selection marker.
                    call add(highlights, [lnum, 3 + prefix + start - removed, end - start])
                endif
            endfor
        endif

        if !empty(item.indicators)
            let line .= ' ' . item.indicators
        endif
        let line = '  ' . line
        let line .= repeat(' ', max([0, &columns - strdisplaywidth(line)]))
        call add(content, line)
        call add(indices, item.index)
    endfor

    return [highlights, indices, len(a:items), empty(content) ? '' : join(content, "\n") . "\n"]
endfunction
