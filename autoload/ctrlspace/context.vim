let s:currentList         = "buffer"
let s:modes               = { "Zoom": 0 }
let s:files               = []
let s:keyEscSequence      = 0
let s:activeWorkspace     = { "Name": "", "Digest": "" }
let s:workspaceNames      = []
let s:lastActiveWorkspace = ""
let s:updateSearchResults = 0
let s:lastProjectRoot     = ""
let s:projectRoot         = ""
let s:symbolSizes         = {}
let s:separator           = "|CS_###_CS|"
let s:pluginBuffer        = -1
let s:projectRoots        = {}
let s:bookmarks           = []
let s:keyNames            = []
let s:jumpCounter         = 0

let ctrlspace#context#Configuration = {
      \ "defaultSymbols": {
        \ "unicode": {
          \ "cs":      "⌗",
          \ "tab":     "∙",
          \ "all":     "፨",
          \ "vis":     "★",
          \ "file":    "⊚",
          \ "tabs":    "○",
          \ "c_tab":   "●",
          \ "ntm":     "⁺",
          \ "load":    "|∷|",
          \ "save":    "[∷]",
          \ "zoom":    "⌕",
          \ "s_left":  "›",
          \ "s_right": "‹",
          \ "bm":      "♥",
          \ "help":    "?",
          \ "iv":      "☆",
          \ "ia":      "★",
          \ "im":      "+",
          \ "dots":    "…"
          \ },
        \ "ascii": {
          \ "cs":      "#",
          \ "tab":     "TAB",
          \ "all":     "ALL",
          \ "vis":     "VIS",
          \ "file":    "FILE",
          \ "tabs":    "-",
          \ "c_tab":   "+",
          \ "ntm":     "+",
          \ "load":    "|::|",
          \ "save":    "[::]",
          \ "zoom":    "*",
          \ "s_left":  "[",
          \ "s_right": "]",
          \ "bm":      "BM",
          \ "help":    "?",
          \ "iv":      "-",
          \ "ia":      "*",
          \ "im":      "+",
          \ "dots":    "..."
          \ }
        \ },
        \ "Height":                   1,
        \ "MaxHeight":                0,
        \ "SetDefaultMapping":        1,
        \ "DefaultMappingKey":        "<C-Space>",
        \ "GlobCommand":              "",
        \ "UseTabline":               1,
        \ "UseMouseAndArrowsInTerm":  0,
        \ "StatuslineFunction":       "ctrlspace#api#statusline()",
        \ "SaveWorkspaceOnExit":      0,
        \ "SaveWorkspaceOnSwitch":    0,
        \ "LoadLastWorkspaceOnStart": 0,
        \ "CacheDir":                 expand($HOME),
        \ "ProjectRootMarkers":       [".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"],
        \ "UnicodeFont":              1,
        \ "IgnoredFiles":             '\v(tmp|temp)[\/]',
        \ "MaxFiles":                 500,
        \ "MaxSearchResults":         200,
        \ "SearchTiming":             [50, 500],
        \ "SearchResonators":         ['.', '/', '\', '_', '-'],
      \ }

function! ctrlspace#context#Configuration.new() dict
  let instance = copy(self)

  for name in keys(instance)
    if exists("g:CtrlSpace" . name)
      let instance.name = g:{"CtrlSpace" . name}
    endif
  endfor

  let instance.Symbols = copy(instance.UnicodeFont ? instance.defaultSymbols.unicode : instance.defaultSymbols.ascii)

  if exists("g:CtrlSpaceSymbols")
    call extend(instance.Symbols, g:CtrlSpaceSymbols)
  endif

  return instance
endfunction

function! ctrlspace#context#Configuration.Instance() dict
  if !exists("s:configuration")
    let s:configuration = ctrlspace#context#Configuration.new()
  endif

  return s:configuration
endfunction

function! ctrlspace#context#SetDefaultMapping(key, action)
  let s:defaultKey = a:key
  if !empty(s:defaultKey)
    if s:defaultKey ==? "<C-Space>" && !has("gui_running") && !has("win32")
      let s:defaultKey = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . s:defaultKey . ' ' . a:action
  endif
endfunction

function! ctrlspace#context#IsDefaultKey()
  return exists("s:defaultKey")
endfunction

function! ctrlspace#context#DefaultKey()
  return s:defaultKey
endfunction

function! ctrlspace#context#Files()
  return s:files
endfunction

function! ctrlspace#context#SetFiles(files)
  let s:files = a:files
endfunction

function! ctrlspace#context#CurrentList()
  return s:currentList
endfunction

function! ctrlspace#context#SetCurrentList(type)
  let s:currentList = a:type
endfunction

function! ctrlspace#context#Modes()
  return s:modes
endfunction

function! ctrlspace#context#SetModes(modes)
  call extend(s:modes, a:modes)
endfunction

function! ctrlspace#context#KeyEscSequence()
  return s:keyEscSequence
endfunction

function! ctrlspace#context#SetKeyEscSequence(value)
  let s:keyEscSequence = a:value
endfunction

function! ctrlspace#context#ActiveWorkspace()
  return s:activeWorkspace
endfunction

function! ctrlspace#context#SetActiveWorkspace(workspace)
  call extend(s:activeWorkspace, a:workspace)
endfunction

function! ctrlspace#context#WorkspaceNames()
  return s:workspaceNames
endfunction

function! ctrlspace#context#SetWorkspaceNames(names)
  let s:workspaceNames = a:names
endfunction

function! ctrlspace#context#LastActiveWorkspace()
  return s:lastActiveWorkspace
endfunction

function! ctrlspace#context#SetLastActiveWorkspace(name)
  let s:lastActiveWorkspace = a:name
endfunction

function! ctrlspace#context#UpdateSearchResults()
  return s:updateSearchResults
endfunction

function! ctrlspace#context#SetUpdateSearchResults(value)
  let s:updateSearchResults = a:value
endfunction

function! ctrlspace#context#LastProjectRoot()
  return s:lastProjectRoot
endfunction

function! ctrlspace#context#SetLastProjectRoot(value)
  let s:lastProjectRoot = a:value
endfunction

function! ctrlspace#context#ProjectRoot()
  return s:projectRoot
endfunction

function! ctrlspace#context#SetProjectRoot(value)
  let s:projectRoot = a:value
endfunction

function! ctrlspace#context#SymbolSizes()
  return s:symbolSizes
endfunction

function! ctrlspace#context#SetSymbolSizes(value)
  let s:symbolSizes = a:value
endfunction

function! ctrlspace#context#Separator()
  return s:separator
endfunction

function! ctrlspace#context#PluginBuffer()
  return s:pluginBuffer
endfunction

function! ctrlspace#context#SetPluginBuffer(value)
  let s:pluginBuffer = a:value
endfunction

function! ctrlspace#context#ProjectRoots()
  return s:projectRoots
endfunction

function! ctrlspace#context#SetProjectRoots(value)
  let s:projectRoots = a:value
endfunction

function! ctrlspace#context#Bookmarks()
  return s:bookmarks
endfunction

function! ctrlspace#context#SetBookmarks(value)
  let s:bookmarks = a:value
endfunction

function! ctrlspace#context#KeyNames()
  return s:keyNames
endfunction

function! ctrlspace#context#SetKeyNames(value)
  let s:keyNames = a:value
endfunction

function! ctrlspace#context#JumpCounter()
  return s:jumpCounter
endfunction

function! ctrlspace#context#IncrementJumpCounter()
  let s:jumpCounter += 1
  return s:jumpCounter
endfunction
