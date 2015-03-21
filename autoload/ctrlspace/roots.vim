let s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#roots#RemoveProjectRoot(directory)
  let directory = ctrlspace#util#NormalizeDirectory(a:directory)

  if exists("ctrlspace#context#ProjectRoots[directory]")
    unlet ctrlspace#context#ProjectRoots[directory]
  endif

  let lines     = []
  let cacheFile = s:config.CacheDir . "/.cs_cache"

  if filereadable(cacheFile)
    for oldLine in readfile(cacheFile)
      if oldLine !~# "CS_PROJECT_ROOT: "
        call add(lines, oldLine)
      endif
    endfor
  endif

  for root in keys(ctrlspace#context#ProjectRoots)
    call add(lines, "CS_PROJECT_ROOT: " . root)
  endfor

  call writefile(lines, cacheFile)
endfunction

function! ctrlspace#roots#AddProjectRoot(directory)
  let directory = ctrlspace#util#NormalizeDirectory(a:directory)

  let ctrlspace#context#ProjectRoots[directory] = 1

  let lines     = []
  let bmRoots   = {}
  let cacheFile = s:config.CacheDir . "/.cs_cache"

  for bookmark in ctrlspace#context#Bookmarks
    let bmRoots[bookmark.Directory] = 1
  endfor

  if filereadable(cacheFile)
    for oldLine in readfile(cacheFile)
      if oldLine !~# "CS_PROJECT_ROOT: "
        call add(lines, oldLine)
      endif
    endfor
  endif

  for root in keys(ctrlspace#context#ProjectRoots)
    if !exists("bmRoots[root]")
      call add(lines, "CS_PROJECT_ROOT: " . root)
    endif
  endfor

  call writefile(lines, cacheFile)
endfunction

function! ctrlspace#roots#FindProjectRoot()
  let projectRoot = fnamemodify(".", ":p:h")

  if !empty(s:config.ProjectRootMarkers)
    let rootFound     = 0
    let candidate     = fnamemodify(projectRoot, ":p:h")
    let lastCandidate = ""

    while candidate != lastCandidate
      for marker in s:config.ProjectRootMarkers
        let markerPath = candidate . "/" . marker
        if filereadable(markerPath) || isdirectory(markerPath)
          let rootFound = 1
          break
        endif
      endfor

      if !rootFound
        let rootFound = exists("ctrlspace#context#ProjectRoots[candidate]")
      endif

      if rootFound
        let projectRoot = candidate
        break
      endif

      let lastCandidate = candidate
      let candidate = fnamemodify(candidate, ":p:h:h")
    endwhile

    return rootFound ? projectRoot : ""
  endif

  return projectRoot
endfunction

function! ctrlspace#roots#ProjectRootFound()
  if empty(ctrlspace#context#ProjectRoot)
    let ctrlspace#context#ProjectRoot = ctrlspace#roots#FindProjectRoot()

    if empty(ctrlspace#context#ProjectRoot)
      let projectRoot = ctrlspace#ui#GetInput("No project root found. Set the project root: ", fnamemodify(".", ":p:h"), "dir")

      if !empty(projectRoot) && isdirectory(projectRoot)
        let ctrlspace#context#Files = [] " clear current files - force reload
        call ctrlspace#roots#AddProjectRoot(project_root)
      else
        call ctrlspace#ui#Msg("Cannot continue with the project root not set.")
        return 0
      endif
    endif
  endif
  return 1
endfunction
