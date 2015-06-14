let s:config              = ctrlspace#context#Configuration()
let s:modes               = ctrlspace#modes#Modes()
let s:updateSearchResults = 0

function! ctrlspace#search#UpdateSearchResults()
    if s:updateSearchResults
        let s:updateSearchResults = 0
        call ctrlspace#window#Kill(0, 0)
        call ctrlspace#window#Toggle(1)
    endif
endfunction

function! ctrlspace#search#ClearSearchMode()
    call s:modes.Search.Disable()
    call s:modes.Search.SetData("Letters", [])

    let t:CtrlSpaceSearchHistoryIndex = -1

    call s:modes.Search.SetData("HistoryIndex", -1)
    call s:modes.Search.RemoveData("LastSearchedDirectory")

    call ctrlspace#window#Kill(0, 0)
    call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#search#AddSearchLetter(letter)
    call add(s:modes.Search.Data.Letters, a:letter)
    call s:modes.Search.SetData("NewSearchPerformed", 1)

    let s:updateSearchResults = 1

    call s:modes.Search.RemoveData("LastSearchedDirectory")

    call ctrlspace#util#SetStatusline()
    redraws
endfunction

function! ctrlspace#search#RemoveSearchLetter()
    call remove(s:modes.Search.Data.Letters, -1)
    call s:modes.Search.SetData("NewSearchPerformed", 1)

    let s:updateSearchResults = 1

    call s:modes.Search.RemoveData("LastSearchedDirectory")

    call ctrlspace#util#SetStatusline()
    redraws
endfunction

function! ctrlspace#search#ClearSearchLetters()
    if !empty(s:modes.Search.Data.Letters)
        call s:modes.Search.SetData("Letters", [])
        call s:modes.Search.SetData("NewSearchPerformed", 1)

        let s:updateSearchResults = 1

        call s:modes.Search.RemoveData("LastSearchedDirectory")

        call ctrlspace#util#SetStatusline()
        redraws
    endif
endfunction

function! ctrlspace#search#SwitchSearchMode(switch)
    if (a:switch == 0) && !empty(s:modes.Search.Data.Letters)
        call ctrlspace#search#AppendToSearchHistory()
    endif

    if a:switch
        call s:modes.Search.Enable()
    else
        call s:modes.Search.Disable()
    endif

    let s:updateSearchResults = 1
    call ctrlspace#search#UpdateSearchResults()
endfunction

function! ctrlspace#search#InsertSearchText(text)
    let letters = []

    for i in range(strlen(a:text))
        if a:text[i] =~? "^[A-Z0-9]$"
            call add(letters, a:text[i])
        endif
    endfor

    if !empty(letters)
        call s:modes.Search.SetData("Letters", letters)
        call ctrlspace#search#AppendToSearchHistory()
        let t:CtrlSpaceSearchHistoryIndex = 0
        call s:modes.Search.SetData("HistoryIndex", 0)
        let s:updateSearchResults = 1
        call ctrlspace#search#UpdateSearchResults()
        return 1
    endif

    return 0
endfunction

function! ctrlspace#search#SearchHistoryIndex()
    if !s:modes.Buffer.Enabled
        if !s:modes.Search.HasData("HistoryIndex")
            call s:modes.Search.SetData("HistoryIndex", -1)
        endif

        return s:modes.Search.Data.HistoryIndex
    else
        if !exists("t:CtrlSpaceSearchHistoryIndex")
            let t:CtrlSpaceSearchHistoryIndex = -1
        endif

        return t:CtrlSpaceSearchHistoryIndex
    endif
endfunction

function! ctrlspace#search#SetSearchHistoryIndex(value)
    if !s:modes.Buffer.Enabled
        call s:modes.Search.SetData("HistoryIndex", a:value)
    else
        let t:CtrlSpaceSearchHistoryIndex = a:value
    endif
endfunction

function! ctrlspace#search#AppendToSearchHistory()
    if empty(s:modes.Search.Data.Letters)
        return
    endif

    if !s:modes.Buffer.Enabled
        if !s:modes.Search.HasData("History")
            call s:modes.Search.SetData("History", {})
        endif

        let historyStore = s:modes.Search.Data.History
    else
        if !exists("t:CtrlSpaceSearchHistory")
            let t:CtrlSpaceSearchHistory = {}
        endif

        let historyStore = t:CtrlSpaceSearchHistory
    endif

    let historyStore[join(s:modes.Search.Data.Letters)] = ctrlspace#jumps#IncrementJumpCounter()
endfunction

function! ctrlspace#search#RestoreSearchLetters(direction)
    let historyStores = []

    if s:modes.Search.HasData("History")
        let history = s:modes.Search.Data.History
        if !empty(history)
            call add(historyStores, history)
        endif
    endif

    if s:modes.Buffer.Enabled
        if s:modes.Buffer.Data.SubMode ==? "single"
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
        call s:modes.Search.SetData("Letters", [])
    else
        call s:modes.Search.SetData("Letters", split(historyEntries[historyIndex]["letters"]))
        call s:modes.Search.SetData("Restored", 1)
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
