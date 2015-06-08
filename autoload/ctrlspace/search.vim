let s:config = g:ctrlspace#context#Configuration.Instance()
let s:updateSearchResults = 0

function! ctrlspace#search#UpdateSearchResults()
  if s:updateSearchResults
    let s:updateSearchResults = 0
    call ctrlspace#window#Kill(0, 0)
    call ctrlspace#window#Toggle(1)
  endif
endfunction

function! ctrlspace#search#ClearSearchMode()
  call g:ctrlspace#modes#Search.Disable()
  let g:ctrlspace#modes#Search.Data.Letters = []
  let t:CtrlSpaceSearchHistoryIndex = -1
  let g:ctrlspace#modes#Search.Data.HistoryIndex = -1

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  call ctrlspace#window#Kill(0, 0)
  call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#search#AddSearchLetter(letter)
  call add(g:ctrlspace#modes#Search.Data.Letters, a:letter)
  let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 1
  let s:updateSearchResults = 1

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  call ctrlspace#util#SetStatusline()
  redraws
endfunction

function! ctrlspace#search#RemoveSearchLetter()
  call remove(g:ctrlspace#modes#Search.Data.Letters, -1)
  let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 1
  let s:updateSearchResults = 1

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  call ctrlspace#util#SetStatusline()
  redraws
endfunction

function! ctrlspace#search#ClearSearchLetters()
  if !empty(g:ctrlspace#modes#Search.Data.Letters)
    let g:ctrlspace#modes#Search.Data.Letters = []
    let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 1
    let s:updateSearchResults = 1

    if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
      unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
    endif

    call ctrlspace#util#SetStatusline()
    redraws
  endif
endfunction

function! ctrlspace#search#SwitchSearchMode(switch)
  if (a:switch == 0) && !empty(g:ctrlspace#modes#Search.Data.Letters)
    call g:ctrlspace#search#AppendToSearchHistory()
  endif

  if a:switch
    call g:ctrlspace#modes#Search.Enable()
  else
    call g:ctrlspace#modes#Search.Disable()
  endif

  let s:updateSearchResults = 1
  call ctrlspace#search#UpdateSearchResults()
endfunction

function! ctrlspace#search#InsertSearchText(text)
  let letters = []

  for i in range(0, strlen(a:text) - 1)
    if a:text[i] =~? "^[A-Z0-9]$"
      call add(letters, a:text[i])
    endif
  endfor

  if !empty(letters)
    let g:ctrlspace#modes#Search.Data.Letters = letters
    call ctrlspace#search#AppendToSearchHistory()
    let t:CtrlSpaceSearchHistoryIndex = 0
    let g:ctrlspace#modes#Search.Data.HistoryIndex = 0
    let s:updateSearchResults = 1
    call ctrlspace#search#UpdateSearchResults()
    return 1
  endif

  return 0
endfunction

function! ctrlspace#search#SearchHistoryIndex()
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

function! ctrlspace#search#SetSearchHistoryIndex(value)
  if !g:ctrlspace#modes#Buffer.Enabled
    let g:ctrlspace#modes#Search.Data.HistoryIndex = a:value
  else
    let t:CtrlSpaceSearchHistoryIndex = a:value
  endif
endfunction

function! ctrlspace#search#AppendToSearchHistory()
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

  let historyStore[join(g:ctrlspace#modes#Search.Data.Letters)] = ctrlspace#jumps#IncrementJumpCounter()
endfunction

function! ctrlspace#search#RestoreSearchLetters(direction)
  let historyStores = []

  if exists("g:ctrlspace#modes#Search.Data.History") && !empty(g:ctrlspace#modes#Search.Data.History)
    call add(historyStores, g:ctrlspace#modes#Search.Data.History)
  endif

  if g:ctrlspace#modes#Buffer.Enabled
    if g:ctrlspace#modes#Buffer.Data.SubMode ==? "single"
      let currentTab = tabpagenr()
      let tabRange = range(currentTab, currentTab)
    else
      let tabRange = range(1, tabpagenr("$"))
    endif

    for t in tabRange
      let tabStore = ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceSearchHistory", {})

      if !empty(tabStore)
        call add(historyStores, tabStore)
      endif
    endfor
  endif

  let historyStore = {}

  for store in historyStores
    for [letters, counter] in items(store)
      if exists("historyStore." . letters) && historyStore[letters] >= counter
        continue
      endif

      let historyStore[letters] = counter
    endfor
  endfor

  if empty(historyStore)
    return
  endif

  let historyEntries = []

  for [letters, counter] in items(historyStore)
    call add(historyEntries, { "letters": letters, "counter": counter })
  endfor

  call sort(historyEntries, function("s:compareEntries"))


  let historyIndex = ctrlspace#search#SearchHistoryIndex()

  if a:direction == "previous"
    let historyIndex += 1

    if historyIndex == len(historyEntries)
      let historyIndex = len(historyEntries) - 1
    endif
  elseif a:direction == "next"
    let historyIndex -= 1

    if historyIndex < -1
      let historyIndex = -1
    endif
  endif

  if historyIndex < 0
    let g:ctrlspace#modes#Search.Data.Letters = []
  else
    let g:ctrlspace#modes#Search.Data.Letters = split(historyEntries[historyIndex]["letters"])
    let g:ctrlspace#modes#Search.Data.Restored = 1
  endif

  call ctrlspace#search#SetSearchHistoryIndex(historyIndex)

  call ctrlspace#window#Kill(0, 0)
  call ctrlspace#window#Toggle(1)
endfunction

function! s:compareEntries(a, b)
  if a:a.counter > a:b.counter
    return -1
  elseif a:a.counter < a:b.counter
    return 1
  else
    return 0
  endif
endfunction
