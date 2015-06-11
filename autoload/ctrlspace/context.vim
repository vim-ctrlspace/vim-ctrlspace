function! ctrlspace#context#PluginFolder()
  if !exists("s:pluginFolder")
    let s:pluginFolder = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
  endif

  return s:pluginFolder
endfunction

function! ctrlspace#context#Separator()
  return "|CS_###_CS|"
endfunction

let s:symbolSizes = {}

function! ctrlspace#context#SymbolSizes(...)
  return ctrlspace#util#GetWithOptionalIndex(s:symbolSizes, a:000)
endfunction

function! ctrlspace#context#SetSymbolSizes(value)
  let s:symbolSizes = a:value
  return s:symbolSizes
endfunction

let s:pluginBuffer = -1

function! ctrlspace#context#PluginBuffer()
  return s:pluginBuffer
endfunction

function! ctrlspace#context#SetPluginBuffer(value)
  let s:pluginBuffer = a:value
  return s:pluginBuffer
endfunction

let s:configuration = {
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
        \ "StatuslineFunction":       "ctrlspace#api#Statusline()",
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

function! ctrlspace#context#Configuration()
  if !exists("s:conf")
    let s:conf = copy(s:configuration)

    for name in keys(s:conf)
      if exists("g:CtrlSpace" . name)
        let s:conf[name] = g:{"CtrlSpace" . name}
      endif
    endfor

    let s:conf.Symbols = copy(s:conf.UnicodeFont ? s:conf.defaultSymbols.unicode : s:conf.defaultSymbols.ascii)

    if exists("g:CtrlSpaceSymbols")
      call extend(s:conf.Symbols, g:CtrlSpaceSymbols)
    endif
  endif

  return s:conf
endfunction
