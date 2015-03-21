let s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#bookmarks#AddToBookmarks(directory, name)
  let directory   = ctrlspace#util#NormalizeDirectory(a:directory)
  let jumpCounter = 0

  for i in range(0, len(ctrlspace#context#Bookmarks) - 1)
    if ctrlspace#context#Bookmarks[i].Directory == directory
      let jumpCounter = ctrlspace#context#Bookmarks[i].JumpCounter
      call remove(ctrlspace#context#Bookmarks, i)
      break
    endif
  endfor

  let bookmark = { "Name": a:name, "Directory": directory, "JumpCounter": jumpCounter }

  call add(ctrlspace#context#Bookmarks, bookmark)

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

  for bm in ctrlspace#context#Bookmarks
    call add(lines, "CS_BOOKMARK: " . bm.Directory . ctrlspace#context#Separator . bm.Name)
    let bmRoots[bm.Directory] = 1
  endfor

  for root in keys(ctrlspace#context#ProjectRoots)
    if !exists("bmRoots[root]")
      call add(lines, "CS_PROJECT_ROOT: " . root)
    endif
  endfor

  call writefile(lines, cacheFile)

  let ctrlspace#context#ProjectRoots[bookmark.Directory] = 1

  return bookmark
endfunction

function! ctrlspace#bookmarks#FindActiveBookmark()
  let projectRoot = ctrlspace#util#NormalizeDirectory(empty(ctrlspace#context#ProjectRoot) ? fnamemodify(".", ":p:h") : ctrlspace#context#ProjectRoot)

  for bookmark in ctrlspace#context#Bookmarks
    if ctrlspace#util#NormalizeDirectory(bookmark.Directory) == projectRoot
      let bookmark.JumpCounter = ctrlspace#context#IncrementJumpCounter
      return bookmark
    endif
  endfor

  return {}
endfunction
