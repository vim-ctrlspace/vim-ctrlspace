let s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#history#SearchHistoryIndex()
  if s:file_mode || s:tablist_mode || s:bookmark_mode || s:workspace_mode
    if !exists("s:search_history_index")
      let s:search_history_index = -1
    endif

    return s:search_history_index
  else
    if !exists("t:ctrlspace_search_history_index")
      let t:ctrlspace_search_history_index = -1
    endif

    return t:ctrlspace_search_history_index
  endif
endfunction

function! ctrlspace#history#SetSearchHistoryIndex(value)
  if s:file_mode || s:tablist_mode || s:bookmark_mode || s:workspace_mode
    let s:search_history_index = a:value
  else
    let t:ctrlspace_search_history_index = a:value
  endif
endfunction

function! ctrlspace#history#AppendToSearchHistory()
  if empty(s:search_letters)
    return
  endif

  if s:file_mode || s:tablist_mode || s:bookmark_mode || s:workspace_mode
    if !exists("s:search_history")
      let s:search_history = {}
    endif

    let history_store = s:search_history
  else
    if !exists("t:ctrlspace_search_history")
      let t:ctrlspace_search_history = {}
    endif

    let history_store = t:ctrlspace_search_history
  endif

  let s:jump_counter += 1
  let history_store[join(s:search_letters)] = s:jump_counter
endfunction

function! ctrlspace#history#RestoreSearchLetters(direction)
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

