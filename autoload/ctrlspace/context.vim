let ctrlspace#context#PluginFolder        = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let ctrlspace#context#PluginBuffer        = -1

let ctrlspace#context#Files               = []
let ctrlspace#context#Workspaces          = []
let ctrlspace#context#Bookmarks           = []
let ctrlspace#context#ProjectRoots        = {}
let ctrlspace#context#KeyEscSequence      = 0
let ctrlspace#context#UpdateSearchResults = 0
let ctrlspace#context#LastProjectRoot     = ""
let ctrlspace#context#ProjectRoot         = ""
let ctrlspace#context#SymbolSizes         = {}
let ctrlspace#context#Separator           = "|CS_###_CS|"
let ctrlspace#context#KeyNames            = []
let ctrlspace#context#JumpCounter         = 0

let ctrlspace#context#Configuration = {
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

function! ctrlspace#context#Configuration.Instance() dict
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

function! ctrlspace#context#IncrementJumpCounter()
  let ctrlspace#context#JumpCounter += 1
  return ctrlspace#context#JumpCounter
endfunction
