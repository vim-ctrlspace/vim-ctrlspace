let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#nop#Init()
    call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleHelp",                "Nop", ["?"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ClearLetters",                 "Nop", ['C-u', 'C-w'])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#BackOrClearSearch",            "Nop", ["BS", 'C-h'])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleFileMode",               "Nop", ["o"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleFileModeAndSearch",      "Nop", ["O"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleBufferMode",             "Nop", ["h"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleBufferModeAndSearch",    "Nop", ["H"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleWorkspaceMode",          "Nop", ["w"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleWorkspaceModeAndSearch", "Nop", ["W"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleTabMode",                "Nop", ["l"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleTabModeAndSearch",       "Nop", ["L"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleBookmarkMode",           "Nop", ["b"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleBookmarkModeAndSearch",  "Nop", ["B"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#Close",                        "Nop", ["q", "Esc", 'C-c'])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#Quit",                         "Nop", ["Q"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#RestorePreviousSearch",        "Nop", ['C-p'])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#RestoreNextSearch",            "Nop", ['C-n'])
endfunction

function! ctrlspace#keys#nop#ClearLetters(k)
    if s:modes.Search.Enabled
        call ctrlspace#search#ClearSearchLetters()
    endif
endfunction

function! ctrlspace#keys#nop#BackOrClearSearch(k)
    if s:modes.Search.Enabled
        if empty(s:modes.Search.Data.Letters)
            call ctrlspace#search#ClearSearchMode()
        else
            call ctrlspace#search#RemoveSearchLetter()
        endif
    else
        call ctrlspace#keys#common#BackOrClearSearch(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleFileModeAndSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleFileModeAndSearch(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleFileMode(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleFileMode(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleBufferModeAndSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleBufferModeAndSearch(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleBufferMode(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleBufferMode(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleWorkspaceModeAndSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleWorkspaceModeAndSearch(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleWorkspaceMode(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleWorkspaceMode(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleTabModeAndSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleTabModeAndSearch(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleTabMode(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleTabMode(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleBookmarkModeAndSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleBookmarkModeAndSearch(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#ToggleBookmarkMode(k)
    if !s:modes.Search.Enabled
        call ctrlspace#keys#common#ToggleBookmarkMode(a:k)
    endif
endfunction

function! ctrlspace#keys#nop#Close(k)
    if a:k ==# "q" && s:modes.Search.Enabled
        return
    endif

    call ctrlspace#window#Kill(0, 1)
endfunction

function! ctrlspace#keys#nop#Quit(k)
    if !s:modes.Search.Enabled
        call ctrlspace#window#QuitVim()
    endif
endfunction

function! ctrlspace#keys#nop#RestorePreviousSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#search#RestoreSearchLetters("previous")
    endif
endfunction

function! ctrlspace#keys#nop#RestoreNextSearch(k)
    if !s:modes.Search.Enabled
        call ctrlspace#search#RestoreSearchLetters("next")
    endif
endfunction
