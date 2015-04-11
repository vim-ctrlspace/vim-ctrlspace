let s:config = g:ctrlspace#context#Configuration.Instance()
let s:fileItems = []

function! g:ctrlspace#files#SaveInCache()
  let filename = g:ctrlspace#util#FilesCache()

  if empty(filename)
    return
  endif

  call writefile(g:ctrlspace#context#Files, filename)
endfunction

function! g:ctrlspace#files#LoadFromCache()
  let filename = g:ctrlspace#util#FilesCache()

  if empty(filename) || !filereadable(filename)
    return
  endif

  let g:ctrlspace#context#Files = readfile(filename)
endfunction

function! g:ctrlspace#files#Files()
  if empty(g:ctrlspace#context#Files)

    " try to pick up files from cache
    call g:ctrlspace#files#LoadFromCache()

    if empty(g:ctrlspace#context#Files)
      let action = "Collecting files..."
      call g:ctrlspace#ui#Msg(action)

      let uniqueFiles = {}

      for fname in empty(s:config.GlobCommand) ? split(globpath('.', '**'), '\n') : split(system(s:config.GlobCommand), '\n')
        let fnameModified = fnamemodify(has("win32") ? substitute(fname, "\r$", "", "") : fname, ":.")

        if isdirectory(fnameModified) || (fnameModified =~# s:config.IgnoredFiles)
          continue
        endif

        let uniqueFiles[fnameModified] = 1
      endfor

      let g:ctrlspace#context#Files = keys(uniqueFiles)

      call g:ctrlspace#files#SaveInCache()
    else
      let action = "Loading files..."
      call g:ctrlspace#ui#Msg(action)
    endif

    redraw!
    call g:ctrlspace#ui#Msg(action . " Done (" . len(g:ctrlspace#context#Files) . " files).")
  endif

  return g:ctrlspace#context#Files
endfunction

function! g:ctrlspace#files#FileItems()
  let files = g:ctrlspace#files#Files()

  if !empty(files) && empty(s:fileItems)
    for i in range(0, len(files) - 1)
      call add(s:fileItems, { "index": i, "text": files[i], "indicators": "" })
    endfor
  endif

  return s:fileItems
endfunction
