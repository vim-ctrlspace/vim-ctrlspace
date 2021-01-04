let s:config = ctrlspace#context#Configuration()


" public API exporting the appropriate cache system

function! ctrlspace#cache#Init() abort
  let cache = s:config.EnableFilesCache ? s:file_cache : s:null_cache
  call s:cache_common(cache)
  return cache
endfunction

function! s:cache_common(cache) abort
  let a:cache.files = []
  let a:cache.items = []
  let a:cache.clear_all = function('s:clear_all')
  let a:cache.get_files = function('s:get_files')
  let a:cache.get_items = function('s:get_items')
  let a:cache.map_files2items = function('s:map_files2items')
endfunction

function! s:clear_all() dict abort
    let self.files = []
    let self.items = []
endfunction

function! s:get_files() dict abort
    return self.files
endfunction

function! s:get_items() dict abort
    return self.items
endfunction

function! s:map_files2items() dict abort
    let self.items = map(copy(self.files), '{ "index": v:key, "text": v:val, "indicators": "" }')
endfunction


" script local helper used for globbing in both cache systems

function! s:glob_project_files() abort
    let uniqueFiles = {}
    for fname in empty(s:glob_cmd) ? split(globpath('.', '**'), '\n') : split(ctrlspace#util#system(s:glob_cmd), '\n')
        let fnameModified = fnamemodify(fname, ":.")
        if isdirectory(fnameModified) || (fnameModified =~# s:config.IgnoredFiles)
            continue
        endif
        let uniqueFiles[fnameModified] = 1
    endfor
    return keys(uniqueFiles)
endfunction


" detect available system glob command and set

function! s:set_globber() abort
  if !empty(s:config.GlobCommand)
      let glob_cmd = s:config.GlobCommand
  elseif executable('rg')
      let glob_cmd = 'rg --color=never --files'
  elseif executable('fd')
      let glob_cmd = 'fd --color=never --type=file'
  elseif executable('ag')
      let glob_cmd = 'ag -l --nocolor -g ""'
  else
      let glob_cmd = ''
  endif
  return [glob_cmd, s:get_glob_bin_name(glob_cmd)]
endfunction

function! s:get_glob_bin_name(glob_cmd) abort
  if empty(a:glob_cmd)
      return "Vim's globpath()"
  elseif len(a:glob_cmd) > 1
      let bin = a:glob_cmd[:1]
      if index(['rg', 'fd', 'ag'], bin) >= 0
          return { 'rg': 'rg (ripgrep)',
                 \ 'fd': 'fd (fd-find)',
                 \ 'ag': 'ag (The Silver Searcher)', }[bin]
      endif
  endif
  return "unknown grepper/finder"
endfunction

let [s:glob_cmd, s:glob_bin] = s:set_globber()


" CtrlSpace's default built-in file cache
let s:file_cache = {}

function! s:file_cache.save() dict abort
    let filename = ctrlspace#util#FilesCache()
    if empty(filename) || !filewritable(filename)
        return
    endif
    call writefile(self.files, filename)
endfunction

function! s:file_cache.load() dict abort
    let filename = ctrlspace#util#FilesCache()
    if empty(filename) || !filereadable(filename)
        return
    endif
    let self.files = readfile(filename)
endfunction

function! s:file_cache.collect() dict abort
    if empty(self.files)
        let self.items = []

        " try to pick up files from cache
        call self.load()  " calls s:file_cache.load()
        if empty(self.files)
            let action = "Collecting & caching files..."
            call ctrlspace#ui#Msg(action)
            let self.files = s:glob_project_files()
            call self.save()  " calls s:file_cache.save()
        else
            let action = "Loading cached files..."
            call ctrlspace#ui#Msg(action)
        endif
        call self.map_files2items()

        redraw!
        call ctrlspace#ui#Msg(action . " Done (" . len(self.files) . ").")
    endif
endfunction

function! s:file_cache.refresh() dict abort
    let self.files = []
    call self.save()  " calls s:file_cache.save()
endfunction


" no operations cache: functionally equivalent to disabling the cache
let s:null_cache = {}

function! s:null_cache.save() abort
    return
endfunction

function! s:null_cache.load() dict abort
    let self.files = s:glob_project_files()
endfunction

function! s:null_cache.collect() dict abort
    if !exists('s:null_cache_alerted')
        let action = "Collecting files using " . s:glob_bin . "..."
        call ctrlspace#ui#Msg(action)
    endif

    call self.load()  " calls s:null_cache.load()
    call self.map_files2items()

    if !exists('s:null_cache_alerted')
        redraw!
        call ctrlspace#ui#Msg(action . " Done (" . len(self.files) . ").")
        let s:null_cache_alerted = 'DEFINED'  " defined to suppress future status message
    endif
endfunction

function! s:null_cache.refresh() abort
    unlet s:null_cache_alerted
endfunction
