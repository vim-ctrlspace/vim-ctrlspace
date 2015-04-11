let s:config = g:ctrlspace#context#Configuration.Instance()

function! g:ctrlspace#bookmarks#AddToBookmarks(directory, name)
  let directory   = g:ctrlspace#util#NormalizeDirectory(a:directory)
  let jumpCounter = 0

  for i in range(0, len(g:ctrlspace#context#Bookmarks) - 1)
    if g:ctrlspace#context#Bookmarks[i].Directory == directory
      let jumpCounter = g:ctrlspace#context#Bookmarks[i].JumpCounter
      call remove(g:ctrlspace#context#Bookmarks, i)
      break
    endif
  endfor

  let bookmark = { "Name": a:name, "Directory": directory, "JumpCounter": jumpCounter }

  call add(g:ctrlspace#context#Bookmarks, bookmark)

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

  for bm in g:ctrlspace#context#Bookmarks
    call add(lines, "CS_BOOKMARK: " . bm.Directory . g:ctrlspace#context#Separator . bm.Name)
    let bmRoots[bm.Directory] = 1
  endfor

  for root in keys(g:ctrlspace#context#ProjectRoots)
    if !exists("bmRoots[root]")
      call add(lines, "CS_PROJECT_ROOT: " . root)
    endif
  endfor

  call writefile(lines, cacheFile)

  let g:ctrlspace#context#ProjectRoots[bookmark.Directory] = 1

  return bookmark
endfunction

function! g:ctrlspace#bookmarks#FindActiveBookmark()
  let projectRoot = g:ctrlspace#util#NormalizeDirectory(empty(g:ctrlspace#context#ProjectRoot) ? fnamemodify(".", ":p:h") : g:ctrlspace#context#ProjectRoot)

  for bookmark in g:ctrlspace#context#Bookmarks
    if g:ctrlspace#util#NormalizeDirectory(bookmark.Directory) == projectRoot
      let bookmark.JumpCounter = g:ctrlspace#context#IncrementJumpCounter()
      return bookmark
    endif
  endfor

  return {}
endfunction
