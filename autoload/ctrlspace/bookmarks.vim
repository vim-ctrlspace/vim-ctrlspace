
let s:config    = ctrlspace#context#Configuration()
let s:modes     = ctrlspace#modes#Modes()
" s:bookmarks is for cache_bookmarks
let s:bookmarks = []

function! ctrlspace#bookmarks#Bookmarks()
    return s:bookmarks
endfunction

function! ctrlspace#bookmarks#SetBookmarks(value)
    let s:bookmarks = a:value
    return s:bookmarks
endfunction

" FUNCTION: ctrlspace#bookmarks#GoToBookmark(nr) {{{
function! ctrlspace#bookmarks#GoToBookmark(nr)
    let newBookmark = s:bookmarks[a:nr]

    " Edit bookmarked file
    execute "edit " . newBookmark.Directory. "/" . newBookmark.Name
    call ctrlspace#ui#DelayedMsg("Directory: " . newBookmark.Directory)
endfunction
" }}}

" FUNCTION: ctrlspace#bookmarks#RemoveBookmark(nr) {{{
function! ctrlspace#bookmarks#RemoveBookmark(nr)
    let name = s:bookmarks[a:nr].Name

    if !ctrlspace#ui#Confirmed("Delete bookmark '" . name . "'?")
        return
    endif

    call remove(s:bookmarks, a:nr)

    let lines     = []
    let cacheFile = s:config.CacheDir . "/.cs_cache"

    if filereadable(cacheFile)
        for oldLine in readfile(cacheFile)
            " cache non-bookmark lines
            if oldLine !~# "CS_BOOKMARK: "
                call add(lines, oldLine)
            endif
        endfor
    endif

    for bm in s:bookmarks
        call add(lines, "CS_BOOKMARK: " . bm.Directory . ctrlspace#context#Separator() . bm.Name)
    endfor

    call writefile(lines, cacheFile)

    call ctrlspace#ui#DelayedMsg("Bookmark '" . name . "' has been deleted.")
endfunction
" }}}

" FUNCTION: ctrlspace#bookmarks#AddFirstBookmark() {{{
function! ctrlspace#bookmarks#AddFirstBookmark()
    if ctrlspace#bookmarks#AddNewBookmark()
        call ctrlspace#window#Kill(0, 1)
        call ctrlspace#window#Toggle(0)
        call ctrlspace#window#Kill(0, 0)
        call s:modes.Bookmark.Enable()
        call ctrlspace#window#Toggle(1)
    endif
endfunction
" }}}

" FUNCTION: ctrlspace#bookmarks#AddNewBookmark() {{{
function! ctrlspace#bookmarks#AddNewBookmark()
    " Get current filename and directory.
    let l:start_file = ctrlspace#util#NormalizeDirectory(ctrlspace#window#GetStartFile())
    let l:filename = fnamemodify(l:start_file, ":p:t")
    let l:directory = fnamemodify(l:start_file, ":p:h")

    " Detect whether existing
    for bm in s:bookmarks
        if ctrlspace#util#IsSameDirectory(bm.Directory, l:directory) && bm.Name == l:filename
            call ctrlspace#ui#Msg("'" . l:filename . "' bookmark has been already existed")
            return 0
        endif
    endfor

    if !ctrlspace#ui#Confirmed("Add to bookmarks: " . l:start_file . " ?")
        return 0
    endif

    call ctrlspace#bookmarks#AddToBookmarks(l:directory, l:filename)
    call ctrlspace#ui#DelayedMsg("'" . l:filename . "' was bookmarked successful")

    return 1
endfunction
" }}}

" FUNCTION: ctrlspace#bookmarks#AddToBookmarks(directory, name) {{{
function! ctrlspace#bookmarks#AddToBookmarks(directory, name)
    let directory   = ctrlspace#util#NormalizeDirectory(a:directory)
    let jumpCounter = 0

    let bookmark = { "Name": a:name,
                   \ "Directory": ctrlspace#util#UseSlashDir(directory),
                   \ "JumpCounter": jumpCounter }

    call add(s:bookmarks, bookmark)

    let lines     = []
    let cacheFile = s:config.CacheDir . "/.cs_cache"

    if filereadable(cacheFile)
        for oldLine in readfile(cacheFile)
            " cache non-bookmark lines
            if (oldLine !~# "CS_BOOKMARK: ")
                call add(lines, oldLine)
            endif
        endfor
    endif

    for bm in s:bookmarks
        call add(lines, "CS_BOOKMARK: " . bm.Directory . ctrlspace#context#Separator() . bm.Name)
    endfor

    call writefile(lines, cacheFile)

    return bookmark
endfunction
" }}}

" FUNCTION: ctrlspace#bookmarks#FindActiveBookmark() {{{
function! ctrlspace#bookmarks#FindActiveBookmark()
    let root = ctrlspace#roots#CurrentProjectRoot()

    if empty(root)
        let root = fnamemodify(".", ":p:h")
    endif

    let root = ctrlspace#util#NormalizeDirectory(root)

    for bm in s:bookmarks
        if ctrlspace#util#NormalizeDirectory(bm.Directory) == root
            let bm.JumpCounter = ctrlspace#jumps#IncrementJumpCounter()
            return bm
        endif
    endfor

    return {}
endfunction
" }}}
