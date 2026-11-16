let s:modes     = ctrlspace#modes#Modes()
let s:bookmarks = []

function! ctrlspace#bookmarks#Bookmarks() abort
    return s:bookmarks
endfunction

function! ctrlspace#bookmarks#SetBookmarks(value) abort
    let s:bookmarks = a:value
    return s:bookmarks
endfunction

function! ctrlspace#bookmarks#GoToBookmark(nr) abort
    let newBookmark = s:bookmarks[a:nr]
    call ctrlspace#util#ChDir(newBookmark.Directory)
    call ctrlspace#ui#DelayedMsg("CWD is now: " . newBookmark.Directory)
endfunction

function! ctrlspace#bookmarks#ChangeBookmarkName(nr) abort
    let bookmark = s:bookmarks[a:nr]
    let newName = ctrlspace#ui#GetInput("New bookmark name: ", bookmark.Name)

    if !empty(newName)
        call ctrlspace#bookmarks#AddToBookmarks(bookmark.Directory, newName)
        call ctrlspace#ui#DelayedMsg("Bookmark '" . bookmark.Name . "' has been renamed to '" . newName . "'.")
    endif
endfunction

function! ctrlspace#bookmarks#ChangeBookmarkDirectory(nr) abort
    let bookmark  = s:bookmarks[a:nr]
    let current   = bookmark.Directory
    let name      = bookmark.Name
    let directory = ctrlspace#ui#GetInput("Edit directory for bookmark '" . name . "': ", current, "dir")

    if empty(directory)
        return 0
    endif

    let directory = ctrlspace#util#NormalizeDirectory(directory)

    if !isdirectory(directory)
        call ctrlspace#ui#Msg("Directory incorrect.")
        return 0
    endif

    for bm in s:bookmarks
        if bm.Directory ==# directory
            call ctrlspace#ui#Msg("This directory has been already bookmarked under name '" . bm.Name . "'.")
            return 0
        endif
    endfor

    call remove(s:bookmarks, a:nr)
    call s:forgetProjectRoot(current)

    call ctrlspace#bookmarks#AddToBookmarks(directory, name)
    call ctrlspace#ui#DelayedMsg("Directory '" . directory . "' has been bookmarked under name '" . name . "'.")

    return 1
endfunction

function! ctrlspace#bookmarks#RemoveBookmark(nr) abort
    let name = s:bookmarks[a:nr].Name

    if !ctrlspace#ui#Confirmed("Delete bookmark '" . name . "'?")
        return
    endif

    call s:forgetProjectRoot(remove(s:bookmarks, a:nr).Directory)
    call ctrlspace#roots#SaveCacheFile()

    call ctrlspace#ui#DelayedMsg("Bookmark '" . name . "' has been deleted.")
endfunction

function! ctrlspace#bookmarks#AddFirstBookmark() abort
    if ctrlspace#bookmarks#AddNewBookmark()
        call ctrlspace#window#Kill(0, 1)
        call ctrlspace#window#Toggle(0)
        call ctrlspace#window#Kill(0, 0)
        call s:modes.Bookmark.Enable()
        call ctrlspace#window#Toggle(1)
    endif
endfunction

function! ctrlspace#bookmarks#AddNewBookmark(...) abort
    if a:0
        let current = s:bookmarks[a:1].Directory
    else
        let root    = ctrlspace#roots#CurrentProjectRoot()
        let current = empty(root) ? fnamemodify(".", ":p:h") : root
    endif

    let directory = ctrlspace#ui#GetInput("Add directory to bookmarks: ", current, "dir")

    if empty(directory)
        return 0
    endif

    let directory = ctrlspace#util#NormalizeDirectory(directory)

    if !isdirectory(directory)
        call ctrlspace#ui#Msg("Directory incorrect.")
        return 0
    endif

    for bm in s:bookmarks
        if bm.Directory ==# directory
            call ctrlspace#ui#Msg("This directory has been already bookmarked under name '" . bm.Name . "'.")
            return 0
        endif
    endfor

    let name = ctrlspace#ui#GetInput("New bookmark name: ", fnamemodify(directory, ":t"))

    if empty(name)
        return 0
    endif

    call ctrlspace#bookmarks#AddToBookmarks(directory, name)
    call ctrlspace#ui#DelayedMsg("Directory '" . directory . "' has been bookmarked under name '" . name . "'.")
    return 1
endfunction

function! ctrlspace#bookmarks#AddToBookmarks(directory, name) abort
    let directory   = ctrlspace#util#NormalizeDirectory(a:directory)
    let jumpCounter = 0

    for i in range(len(s:bookmarks))
        if s:bookmarks[i].Directory ==# directory
            let jumpCounter = s:bookmarks[i].JumpCounter
            call remove(s:bookmarks, i)
            break
        endif
    endfor

    let bookmark = { "Name": a:name, "Directory": directory, "JumpCounter": jumpCounter }

    call add(s:bookmarks, bookmark)

    let roots = ctrlspace#roots#ProjectRoots()
    let roots[bookmark.Directory] = 1
    call ctrlspace#roots#SaveCacheFile()

    return bookmark
endfunction

function! ctrlspace#bookmarks#FindActiveBookmark() abort
    let root = ctrlspace#roots#CurrentProjectRoot()

    if empty(root)
        let root = fnamemodify(".", ":p:h")
    endif

    let root = ctrlspace#util#NormalizeDirectory(root)

    for bm in s:bookmarks
        if ctrlspace#util#NormalizeDirectory(bm.Directory) ==# root
            let bm.JumpCounter = ctrlspace#jumps#IncrementJumpCounter()
            return bm
        endif
    endfor

    return {}
endfunction

" A directory stops being a project root together with its bookmark.
function! s:forgetProjectRoot(directory) abort
    let roots = ctrlspace#roots#ProjectRoots()

    if has_key(roots, a:directory)
        call remove(roots, a:directory)
    endif
endfunction
