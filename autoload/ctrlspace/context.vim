let g:ctrlspace#context#PluginFolder        = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:ctrlspace#context#PluginBuffer        = -1

let g:ctrlspace#context#Files               = []
let g:ctrlspace#context#Workspaces          = []
let g:ctrlspace#context#Bookmarks           = []
let g:ctrlspace#context#ProjectRoots        = {}
let g:ctrlspace#context#KeyEscSequence      = 0
let g:ctrlspace#context#UpdateSearchResults = 0
let g:ctrlspace#context#LastProjectRoot     = ""
let g:ctrlspace#context#ProjectRoot         = ""
let g:ctrlspace#context#SymbolSizes         = {}
let g:ctrlspace#context#Separator           = "|CS_###_CS|"
let g:ctrlspace#context#KeyNames            = []
let g:ctrlspace#context#JumpCounter         = 0

let s:allBuffers                          = {}

let g:ctrlspace#context#Configuration = {
      \ "defaultSymbols": {
        \ "unicode": {
          \ "CS":     "⌗",
          \ "Sin":    "∙",
          \ "All":    "፨",
          \ "Vis":    "★",
          \ "File":   "⊚",
          \ "Tabs":   "○",
          \ "CTab":   "●",
          \ "NTM":    "⁺",
          \ "WLoad":  "|∷|",
          \ "WSave":  "[∷]",
          \ "Zoom":   "⌕",
          \ "SLeft":  "›",
          \ "SRight": "‹",
          \ "BM":     "♥",
          \ "Help":   "?",
          \ "IV":     "☆",
          \ "IA":     "★",
          \ "IM":     "+",
          \ "Dots":   "…"
          \ },
        \ "ascii": {
          \ "CS":     "#",
          \ "Sin":    "SIN",
          \ "All":    "ALL",
          \ "Vis":    "VIS",
          \ "File":   "FILE",
          \ "Tabs":   "-",
          \ "CTab":   "+",
          \ "NTM":    "+",
          \ "WLoad":  "|::|",
          \ "WSave":  "[::]",
          \ "Zoom":   "*",
          \ "SLeft":  "[",
          \ "SRight": "]",
          \ "BM":     "BM",
          \ "Help":   "?",
          \ "IV":     "-",
          \ "IA":     "*",
          \ "IM":     "+",
          \ "Dots":   "..."
          \ }
        \ },
        \ "Height":                   1,
        \ "MaxHeight":                0,
        \ "SetDefaultMapping":        1,
        \ "DefaultMappingKey":        "<C-Space>",
        \ "GlobCommand":              "",
        \ "UseTabline":               1,
        \ "UseMouseAndArrowsInTerm":  0,
        \ "StatuslineFunction":       "g:ctrlspace#api#Statusline()",
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
        \ "Engine":                   "",
      \ }

function! g:ctrlspace#context#Configuration.Instance() dict
  if !exists("s:configuration")
    let s:configuration = copy(self)

    for name in keys(s:configuration)
      if exists("g:CtrlSpace" . name)
        let s:configuration[name] = g:{"CtrlSpace" . name}
      endif
    endfor

    let s:configuration.Symbols = copy(s:configuration.UnicodeFont ? s:configuration.defaultSymbols.unicode : s:configuration.defaultSymbols.ascii)

    if exists("g:CtrlSpaceSymbols")
      call extend(s:configuration.Symbols, g:CtrlSpaceSymbols)
    endif
  endif

  return s:configuration
endfunction

function! g:ctrlspace#context#SetDefaultMapping(key, action)
  let s:defaultKey = a:key
  if !empty(s:defaultKey)
    if s:defaultKey ==? "<C-Space>" && !has("gui_running") && !has("win32")
      let s:defaultKey = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . s:defaultKey . ' ' . a:action
  endif
endfunction

function! g:ctrlspace#context#IsDefaultKey()
  return exists("s:defaultKey")
endfunction

function! g:ctrlspace#context#DefaultKey()
  return s:defaultKey
endfunction

function! g:ctrlspace#context#IncrementJumpCounter()
  let g:ctrlspace#context#JumpCounter += 1
  return g:ctrlspace#context#JumpCounter
endfunction

function! g:ctrlspace#context#MaxHeight()
  let maxFromConfig = g:ctrlspace#context#Configuration.Instance().MaxHeight

  if maxFromConfig
    return maxFromConfig
  else
    return &lines / 3
  endif
endfunction

function! g:ctrlspace#context#InitializeBuffers()
  for current in range(1, bufnr("$"))
    if !getbufvar(current, "&modifiable") || !getbufvar(current, "&buflisted") || getbufvar(current, "&ft") ==? "ctrlspace"
      break
    endif

    if !exists("s:allBuffers[current]")
      let s:allBuffers[current] = len(s:allBuffers) + 1
    endif
  endfor
endfunction

function! g:ctrlspace#context#AddBuffer()
  let current = bufnr('%')

  if !getbufvar(current, "&modifiable") || !getbufvar(current, "&buflisted") || getbufvar(current, "&ft") ==? "ctrlspace"
    return
  endif

  if !exists("s:allBuffers[current]")
    let s:allBuffers[current] = len(s:allBuffers) + 1
  endif

  if g:ctrlspace#modes#Zoom.Enabled
    return
  endif

  let b:CtrlSpaceJumpCounter = g:ctrlspace#context#IncrementJumpCounter()

  if !exists("t:CtrlSpaceList")
    let t:CtrlSpaceList = {}
  endif

  if !exists("t:CtrlSpaceList[current]")
    let t:CtrlSpaceList[current] = len(t:CtrlSpaceList) + 1
  endif
endfunction

function! g:ctrlspace#context#Buffers(tabnr)
  if a:tabnr
    let buffers = gettabvar(a:tabnr, "CtrlSpaceList")
    if type(buffers) != type({})
      return {}
    endif
  else
    let buffers = s:allBuffers
  endif

  return filter(buffers, "buflisted(str2nr(v:key))") " modify proper dictionary and return it
endfunction
