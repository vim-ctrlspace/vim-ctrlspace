let s:pluginBuffer = -1
let s:pluginFolder = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

let s:configuration = {
			\ "defaultSymbols": {
				\ "unicode": {
					\ "CS":     "⌗",
					\ "Sin":    "•",
					\ "All":    "፨",
					\ "Vis":    "★",
					\ "File":   "○",
					\ "Tabs":   "▫",
					\ "CTab":   "▪",
					\ "NTM":    "⁺",
					\ "WLoad":  "⬆",
					\ "WSave":  "⬇",
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
					\ "WLoad":  "|*|",
					\ "WSave":  "[*]",
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
			\ "Keys":                     {},
			\ "Help":                     {},
			\ "GlobCommand":              "",
			\ "UseTabline":               1,
			\ "UseMouseAndArrowsInTerm":  0,
			\ "StatuslineFunction":       "ctrlspace#api#Statusline()",
			\ "SaveWorkspaceOnExit":      0,
			\ "SaveWorkspaceOnSwitch":    0,
			\ "LoadLastWorkspaceOnStart": 0,
			\ "CacheDir":                 expand($HOME),
			\ "ProjectRootMarkers":       [".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"],
			\ "UseUnicode":               1,
			\ "IgnoredFiles":             '\v(tmp|temp)[\/]',
			\ "SearchTiming":             200,
			\ "FileEngine":               "auto",
		\ }

function! s:init()
	let s:conf = copy(s:configuration)

	for name in keys(s:conf)
		if exists("g:CtrlSpace" . name)
			let s:conf[name] = g:{"CtrlSpace" . name}
		endif
	endfor

	let s:conf.Symbols = copy(s:conf.UseUnicode ? s:conf.defaultSymbols.unicode : s:conf.defaultSymbols.ascii)

	if exists("g:CtrlSpaceSymbols")
		call extend(s:conf.Symbols, g:CtrlSpaceSymbols)
	endif

	let s:symbolSizes = {
				\ "IAV":  max([strwidth(s:conf.Symbols.IV), strwidth(s:conf.Symbols.IA)]),
				\ "IM":   strwidth(s:conf.Symbols.IM),
				\ "Dots": strwidth(s:conf.Symbols.Dots)
				\ }

	if s:conf.FileEngine ==# "auto"
		let s:conf.FileEngine = s:detectEngine()
	endif

	if !empty(s:conf.FileEngine)
		let s:conf.FileEngineName = s:conf.FileEngine
		let ebin = s:pluginFolder . "/bin/" . s:conf.FileEngine
		let s:conf.FileEngine = executable(ebin) ? ebin : ""
	endif

	if empty(s:conf.FileEngine)
		let s:conf.FileEngineName = "VIM"
	endif
endfunction

function! s:detectEngine()
	let [os, arch] = ["", ""]

	if has("win32")
		let os   = "windows"
		let arch = empty(system('set | find "ProgramFiles(x86)"')) ? "386" : "amd64"
	else
		let uname = system("uname -a")

		for sys in ["darwin", "linux", "freebsd", "netbsd", "openbsd"]
			if uname =~? sys
				let os = sys
				break
			endif
		endfor

		if uname =~? "64"
			let arch = "amd64"
		elseif uname =~? "arm"
			let arch = "arm"
		else
			let arch = "386"
		endif
	endif

	if empty(os) || empty(arch)
		return ""
	endif

	return join(["file_engine", os, arch], "_")
endfunction

call s:init()

function! ctrlspace#context#PluginFolder()
	return s:pluginFolder
endfunction

function! ctrlspace#context#Separator()
	return "|CS_###_CS|"
endfunction

function! ctrlspace#context#PluginBuffer()
	return s:pluginBuffer
endfunction

function! ctrlspace#context#SetPluginBuffer(value)
	let s:pluginBuffer = a:value
	return s:pluginBuffer
endfunction

function! ctrlspace#context#SymbolSizes()
	return s:symbolSizes
endfunction

function! ctrlspace#context#Configuration()
	return s:conf
endfunction
