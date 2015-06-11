let s:config = ctrlspace#context#Configuration()
let s:updateSearchResults = 0

function! ctrlspace#search#UpdateSearchResults()
  if s:updateSearchResults
    let s:updateSearchResults = 0
    call ctrlspace#window#Kill(0, 0)
    call ctrlspace#window#Toggle(1)
  endif
endfunction

function! ctrlspace#search#ClearSearchMode()
  let sm = ctrlspace#modes#Search()

  call sm.Disable()
  call sm.SetData("Letters", [])

  let t:CtrlSpaceSearchHistoryIndex = -1

  call sm.SetData("HistoryIndex", -1)
  call sm.RemoveData("LastSearchedDirectory")

  call ctrlspace#window#Kill(0, 0)
  call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#search#AddSearchLetter(letter)
  let sm = ctrlspace#modes#Search()

  call add(sm.Data.Letters, a:letter)
  call sm.SetData("NewSearchPerformed", 1)

  let s:updateSearchResults = 1

  call sm.RemoveData("LastSearchedDirectory")

  call ctrlspace#util#SetStatusline()
  redraws
endfunction

function! ctrlspace#search#RemoveSearchLetter()
  let sm = ctrlspace#modes#Search()

  call remove(sm.Data.Letters, -1)
  call sm.SetData("NewSearchPerformed", 1)

  let s:updateSearchResults = 1

  call sm.RemoveData("LastSearchedDirectory")

  call ctrlspace#util#SetStatusline()
  redraws
endfunction

function! ctrlspace#search#ClearSearchLetters()
  let sm = ctrlspace#modes#Search()

  if !empty(sm.Data.Letters)
    call sm.SetData("Letters", [])
    call sm.SetData("NewSearchPerformed", 1)

    let s:updateSearchResults = 1

    call sm.RemoveData("LastSearchedDirectory")

    call ctrlspace#util#SetStatusline()
    redraws
  endif
endfunction

function! ctrlspace#search#SwitchSearchMode(switch)
  let sm = ctrlspace#modes#Search()

  if (a:switch == 0) && !empty(sm.Data.Letters)
    call ctrlspace#search#AppendToSearchHistory()
  endif

  if a:switch
    call sm.Enable()
  else
    call sm.Disable()
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
    let sm = ctrlspace#modes#Search()
    call sm.SetData("Letters", letters)
    call ctrlspace#search#AppendToSearchHistory()
    let t:CtrlSpaceSearchHistoryIndex = 0
    call sm.SetData("HistoryIndex", 0)
    let s:updateSearchResults = 1
    call ctrlspace#search#UpdateSearchResults()
    return 1
  endif

  return 0
endfunction

function! ctrlspace#search#SearchHistoryIndex()
  let sm = ctrlspace#modes#Search()

  if !ctrlspace#modes#Buffer().Enabled
    if !sm.HasData("HistoryIndex")
      call sm.SetData("HistoryIndex", -1)
    endif

    return sm.Data.HistoryIndex
  else
    if !exists("t:CtrlSpaceSearchHistoryIndex")
      let t:CtrlSpaceSearchHistoryIndex = -1
    endif

    return t:CtrlSpaceSearchHistoryIndex
  endif
endfunction

function! ctrlspace#search#SetSearchHistoryIndex(value)
  if !ctrlspace#modes#Buffer().Enabled
    call ctrlspace#modes#Search().SetData("HistoryIndex", a:value)
  else
    let t:CtrlSpaceSearchHistoryIndex = a:value
  endif
endfunction

function! ctrlspace#search#AppendToSearchHistory()
  let sm = ctrlspace#modes#Search()

  if empty(sm.Data.Letters)
    return
  endif

  if !ctrlspace#modes#Buffer().Enabled
    if !sm.HasData("History")
      call sm.SetData("History", {})
    endif

    let historyStore = sm.Data.History
  else
    if !exists("t:CtrlSpaceSearchHistory")
      let t:CtrlSpaceSearchHistory = {}
    endif

    let historyStore = t:CtrlSpaceSearchHistory
  endif

  let historyStore[join(sm.Data.Letters)] = ctrlspace#jumps#IncrementJumpCounter()
endfunction

function! ctrlspace#search#RestoreSearchLetters(direction)
  let sm = ctrlspace#modes#Search()
  let historyStores = []

  if sm.HasData("History")
    let history = sm.Data.History
    if !empty(history)
      call add(historyStores, history)
    endif
  endif

  if ctrlspace#modes#Buffer().Enabled
    if ctrlspace#modes#Buffer("SubMode") ==? "single"
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
      if has_key(historyStore, letters) && historyStore[letters] >= counter
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
    call sm.SetData("Letters", [])
  else
    call sm.SetData("Letters", split(historyEntries[historyIndex]["letters"]))
    call sm.SetData("Restored", 1)
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
