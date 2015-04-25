s:config = g:ctrlspace#context#Configuration.Instance()

call <SID>clear_search_mode()
call <SID>switch_search_mode(1)
call <SID>restore_search_letters("next")
call <SID>remove_search_letter()
call <SID>add_search_letter(a:key)

function! g:ctlrspace#search#ClearSearchMode()
  call g:ctrlspace#modes#Search.Disable()
  let g:ctrlspace#modes#Search.Data.Letters = []
  let t:CtrlSpaceSearchHistoryIndex = -1
  let g:ctrlspace#modes#Search.Data.HistoryIndex = -1

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  call g:ctrlspace#window#Kill(0, 0)
  call g:ctrlspace#window#Toggle(1)
endfunction

function! g:ctrlspace#search#UpdateSearchResults()
  if g:ctrlspace#context#UpdateSearchResults
    let g:ctrlspace#context#UpdateSearchResults = 0
    call g:ctrlspace#window#Kill(0, 0)
    call g:ctrlspace#window#Toggle(1)
  endif
endfunction

function! g:ctrlspace#search#AddSearchLetter(letter)
  call add(g:ctrlspace#modes#Search.Data.Letters, a:letter)
  let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 1
  let g:ctrlspace#context#UpdateSearchResults = 1

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  call g:ctrlspace#util#SetStatusline()
  redraws
endfunction

function! g:ctrlspace#search#RemoveSearchLetter()
  call remove(g:ctrlspace#modes#Search.Data.Letters, -1)
  let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 1
  let g:ctrlspace#context#UpdateSearchResults = 1

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  call g:ctrlspace#util#SetStatusline()
  redraws
endfunction

function! g:ctrlspace#search#ClearSearchLetters()
  if !empty(g:ctrlspace#modes#Search.Data.Letters)
    let g:ctrlspace#modes#Search.Data.Letters = []
    let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 1
    let g:ctrlspace#context#UpdateSearchResults = 1

    if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
      unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
    endif

    call g:ctrlspace#util#SetStatusline()
    redraws
  endif
endfunction

function! g:ctrlspace#search#SwitchSearchMode(switch)
  if (a:switch == 0) && !empty(g:ctrlspace#modes#Search.Data.Letters)
    call g:ctrlspace#search#AppendToSearchHistory()
  endif

  if a:switch
    call g:ctrlspace#modes#Search.Enable()
  else
    call g:ctrlspace#modes#Search.Disable()
  endif

  let g:ctrlspace#context#UpdateSearchResults = 1
  call g:ctrlspace#search#UpdateSearchResults()
endfunction

function! g:ctrlspace#search#InsertSearchText(text)
  let letters = []

  for i in range(0, strlen(a:text) - 1)
    if a:text[i] =~? "^[A-Z0-9]$"
      call add(letters, a:text[i])
    endif
  endfor

  if !empty(letters)
    let g:ctrlspace#modes#Search.Data.Letters = letters
    call g:ctrlspace#search#AppendToSearchHistory()
    let t:CtrlSpaceSearchHistoryIndex = 0
    let g:ctrlspace#modes#Search.Data.HistoryIndex = 0
    let g:ctrlspace#context#UpdateSearchResults = 1
    call g:ctrlspace#search#UpdateSearchResults()
    return 1
  endif

  return 0
endfunction

function! g:ctrlspace#search#SearchHistoryIndex()
  if !g:ctrlspace#modes#Buffer.Enabled
    if !exists("g:ctrlspace#modes#Search.Data.HistoryIndex")
      let g:ctrlspace#modes#Search.Data.HistoryIndex = -1
    endif

    return g:ctrlspace#modes#Search.Data.HistoryIndex
  else
    if !exists("t:CtrlSpaceSearchHistoryIndex")
      let t:CtrlSpaceSearchHistoryIndex = -1
    endif

    return t:CtrlSpaceSearchHistoryIndex
  endif
endfunction

function! g:ctrlspace#search#SetSearchHistoryIndex(value)
  if !g:ctrlspace#modes#Buffer.Enabled
    let g:ctrlspace#modes#Search.Data.HistoryIndex = a:value
  else
    let t:CtrlSpaceSearchHistoryIndex = a:value
  endif
endfunction

function! g:ctrlspace#search#AppendToSearchHistory()
  if empty(g:ctrlspace#modes#Search.Data.Letters)
    return
  endif

  if !g:ctrlspace#modes#Buffer.Enabled
    if !exists("g:ctrlspace#modes#Search.Data.History")
      let g:ctrlspace#modes#Search.Data.History = {}
    endif

    let historyStore = g:ctrlspace#modes#Search.Data.History
  else
    if !exists("t:CtrlSpaceSearchHistory")
      let t:CtrlSpaceSearchHistory = {}
    endif

    let historyStore = t:CtrlSpaceSearchHistory
  endif

  let historyStore[join(g:ctrlspace#modes#Search.Data.Letters)] = g:ctrlspace#context#IncrementJumpCounter()
endfunction

function! g:ctrlspace#search#RestoreSearchLetters(direction)
  let history_stores = []

  if exists("s:search_history") && !empty(s:search_history)
    call add(history_stores, s:search_history)
  endif

  if !s:file_mode && !s:workspace_mode && !s:tablist_mode && !s:bookmark_mode
    let tab_range = s:single_mode ? range(tabpagenr(), tabpagenr()) : range(1, tabpagenr("$"))

    for t in tab_range
      let tab_store = <SID>gettabvar_with_default(t, "ctrlspace_search_history", {})
      if !empty(tab_store)
        call add(history_stores, tab_store)
      endif
    endfor
  endif

  let history_store = {}

  for store in history_stores
    for [letters, counter] in items(store)
      if exists("history_store." . letters) && history_store[letters] >= counter
        continue
      endif

      let history_store[letters] = counter
    endfor
  endfor

  if empty(history_store)
    return
  endif

  let history_entries = []

  for [letters, counter] in items(history_store)
    call add(history_entries, { "letters": letters, "counter": counter })
    endfor

  call sort(history_entries, function("s:compare_jumps"))

  let history_index = <SID>get_search_history_index()

  if a:direction == "previous"
    let history_index += 1

    if history_index == len(history_entries)
      let history_index = len(history_entries) - 1
    endif
  elseif a:direction == "next"
    let history_index -= 1

    if history_index < -1
      let history_index = -1
    endif
  endif

  if history_index < 0
    let s:search_letters = []
  else
    let s:search_letters = split(history_entries[history_index]["letters"])
    let s:restored_search_mode = 1
  endif

  call <SID>set_search_history_index(history_index)

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction
