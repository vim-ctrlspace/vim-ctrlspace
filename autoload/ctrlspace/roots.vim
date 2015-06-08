let s:config = g:ctrlspace#context#Configuration.Instance()

let g:ctrlspace#roots#ProjectRoots    = {}
let g:ctrlspace#roots#LastProjectRoot = ""
let g:ctrlspace#roots#ProjectRoot     = ""

function! ctrlspace#roots#AddProjectRoot(directory)
  let directory = ctrlspace#util#NormalizeDirectory(empty(a:directory) ? getcwd() : a:directory)

  if !isdirectory(directory)
    call ctrlspace#ui#Msg("Invalid directory: '" . directory . "'")
    return
  endif

  let roots = copy(g:ctrlspace#roots#ProjectRoots)

  for bookmark in g:ctrlspace#bookmarks#Bookmarks
    let roots[bookmark.directory] = 1
  endfor

  if exists("roots[directory]")
    call ctrlspace#ui#Msg("Directory is already a permanent project root!")
    return
  endif

  call s:addProjectRoot(directory)
  call ctrlspace#ui#Msg("Directory '" . directory . "' has been added as a permanent project root.")
endfunction

function! ctrlspace#roots#RemoveProjectRoot(directory)
  let directory = ctrlspace#util#NormalizeDirectory(empty(a:directory) ? getcwd() : a:directory)

  if !exists("g:ctrlspace#roots#ProjectRoots[directory]")
    call ctrlspace#ui#Msg("Directory '" . directory . "' is not a permanent project root!" )
    return
  endif

  call s:removeProjectRoot(directory)
  call ctrlspace#ui#Msg("The project root '" . directory . "' has been removed.")
endfunction

function! s:removeProjectRoot(directory)
  let directory = ctrlspace#util#NormalizeDirectory(a:directory)

  if exists("g:ctrlspace#roots#ProjectRoots[directory]")
    unlet g:ctrlspace#roots#ProjectRoots[directory]
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

  for root in keys(g:ctrlspace#roots#ProjectRoots)
    call add(lines, "CS_PROJECT_ROOT: " . root)
  endfor

  call writefile(lines, cacheFile)
endfunction

function! s:addProjectRoot(directory)
  let directory = ctrlspace#util#NormalizeDirectory(a:directory)

  let g:ctrlspace#roots#ProjectRoots[directory] = 1

  let lines     = []
  let bmRoots   = {}
  let cacheFile = s:config.CacheDir . "/.cs_cache"

  for bookmark in g:ctrlspace#bookmarks#Bookmarks
    let bmRoots[bookmark.Directory] = 1
  endfor

  if filereadable(cacheFile)
    for oldLine in readfile(cacheFile)
      if oldLine !~# "CS_PROJECT_ROOT: "
        call add(lines, oldLine)
      endif
    endfor
  endif

  for root in keys(g:ctrlspace#roots#ProjectRoots)
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
        let rootFound = exists("g:ctrlspace#roots#ProjectRoots[candidate]")
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
  if empty(g:ctrlspace#roots#ProjectRoot)
    let g:ctrlspace#roots#ProjectRoot = ctrlspace#roots#FindProjectRoot()

    if empty(g:ctrlspace#roots#ProjectRoot)
      let projectRoot = ctrlspace#ui#GetInput("No project root found. Set the project root: ", fnamemodify(".", ":p:h"), "dir")

      if !empty(projectRoot) && isdirectory(projectRoot)
        let g:ctrlspace#files#Files = [] " clear current files - force reload
        call s:addProjectRoot(project_root)
      else
        call ctrlspace#ui#Msg("Cannot continue with the project root not set.")
        return 0
      endif
    endif
  endif
  return 1
endfunction
