let s:config    = ctrlspace#context#Configuration()
let s:modes     = ctrlspace#modes#Modes()
let s:bookmarks = []

function! ctrlspace#bookmarks#Bookmarks()
    return s:bookmarks
endfunction

function! ctrlspace#bookmarks#SetBookmarks(value)
    let s:bookmarks = a:value
    return s:bookmarks
endfunction

function! ctrlspace#bookmarks#AddToBookmarks(directory, name)
    let directory   = ctrlspace#util#NormalizeDirectory(a:directory)
    let jumpCounter = 0

    for i in range(0, len(s:bookmarks) - 1)
        if s:bookmarks[i].Directory == directory
            let jumpCounter = s:bookmarks[i].JumpCounter
            call remove(s:bookmarks, i)
            break
        endif
    endfor

    let bookmark = { "Name": a:name, "Directory": directory, "JumpCounter": jumpCounter }

    call add(s:bookmarks, bookmark)

    let lines     = []
    let bmRoots   = {}
    let cacheFile = s:config.CacheDir . "/.cs_cache"

    if filereadable(cacheFile)
        for oldLine in readfile(cacheFile)
            if (oldLine !~# "CS_BOOKMARK: ") && (oldLine !~# "CS_PROJECT_ROOT: ")
                call add(lines, oldLine)
            endif
        endfor
    endif

    for bm in s:bookmarks
        call add(lines, "CS_BOOKMARK: " . bm.Directory . ctrlspace#context#Separator() . bm.Name)
        let bmRoots[bm.Directory] = 1
    endfor

    for root in keys(ctrlspace#roots#ProjectRoots())
        if !has_key(bmRoots, root)
            call add(lines, "CS_PROJECT_ROOT: " . root)
        endif
    endfor

    call writefile(lines, cacheFile)
    call extend(ctrlspace#roots#ProjectRoots(), { bookmark.Directory: 1 })

    return bookmark
endfunction

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
