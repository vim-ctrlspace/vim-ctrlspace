let s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#util#NormalizeDirectory(directory)
  let directory = resolve(expand(a:directory))

  while directory[strlen(directory) - 1] == "/" || directory[strlen(directory) - 1] == "\\"
    let directory = directory[0:-2]
  endwhile

  return directory
endfunction

function! ctrlspace#util#HandleVimSettings(switch)
  call s:handleSwitchbuf(a:switch)
  call s:handleAutochdir(a:switch)
endfunction

function! s:handleSwitchbuf(switch)
  if (a:switch == "start") && !empty(&swb)
    let s:swbSave = &swb
    set swb=
  elseif (a:switch == "stop") && exists("s:swbSave")
    let &swb = s:swbSave
    unlet s:swbSave
  endif
endfunction

function! s:handleAutochdir(switch)
  if (a:switch == "start") && &acd
    let s:acdWasOn = 1
    set noacd
  elseif (a:switch == "stop") && exists("s:acdWasOn")
    set acd
    unlet s:acdWasOn
  endif
endfunction

function! ctrlspace#util#WorkspaceFile()
  return s:internalFilePath("cs_workspaces")
endfunction

function! ctrlspace#util#FilesCache()
  return s:internalFilePath("cs_files")
endfunction

function! s:internalFilePath(name)
  let root = ctrlspace#context#ProjectRoot()
  let fullPart = empty(root) ? "" : (root . "/")

  if !empty(s:config.ProjectRootMarkers)
    for candidate in s:config.ProjectRootMarkers
      let candidatePath = fullPart . candidate

      if isdirectory(candidatePath)
        return candidatePath . "/" . a:name
      endif
    endfor
  endif

  return fullPart . "." . a:name
endfunction

function! ctrlspace#util#PluginFolder()
  if !exists("s:pluginFolder")
    let s:pluginFolder = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
  endif

  return s:pluginFolder
endfunction

function! ctrlspace#util#GetbufvarWithDefault(nr, name, default)
  let value = getbufvar(a:nr, a:name)
  return type(value) == type("") && empty(value) ? a:default : value
endfunction

function! ctrlspace#util#GettabvarWithDefault(nr, name, default)
  let value = gettabvar(a:nr, a:name)
  return type(value) == type("") && empty(value) ? a:default : value
endfunction
