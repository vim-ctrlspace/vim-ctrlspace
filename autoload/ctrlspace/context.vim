let g:ctrlspace#context#PluginFolder = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:ctrlspace#context#PluginBuffer = -1

let g:ctrlspace#context#SymbolSizes  = {}
let g:ctrlspace#context#Separator    = "|CS_###_CS|"

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

function! g:ctrlspace#context#Configuration.Instance() dict
  if !exists("s:conf")
    let s:conf = copy(self)

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
