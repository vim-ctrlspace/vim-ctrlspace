let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#nop#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleHelp",                   "Nop", ["?"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#BackOrClearSearch",            "Nop", ["BS", 'C-h'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#EnterSearchMode",              "Nop", ["/"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleFileMode",               "Nop", ["o"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleFileModeAndSearch",      "Nop", ["O"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleBufferMode",             "Nop", ["h"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleBufferModeAndSearch",    "Nop", ["H"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleWorkspaceMode",          "Nop", ["w"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleWorkspaceModeAndSearch", "Nop", ["W"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleTabMode",                "Nop", ["l"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleTabModeAndSearch",       "Nop", ["L"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleBookmarkMode",           "Nop", ["b"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleBookmarkModeAndSearch",  "Nop", ["B"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#Close",                        "Nop", ["q", "Esc", 'C-c'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#Quit",                         "Nop", ["Q"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#RestorePreviousSearch",        "Nop", ['C-p'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#RestoreNextSearch",            "Nop", ['C-n'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#NewWorkspace",                 "Nop", ["N"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleAllMode",                   "Nop", ["a"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#nop#ToggleAllModeAndSearch",          "Nop", ["A"])
endfunction

function! ctrlspace#keys#nop#ToggleAllMode(k)
	if s:modes.Buffer.Enabled
		call ctrlspace#keys#buffer#ToggleAllMode(a:k)
	endif
endfunction

function! ctrlspace#keys#nop#ToggleAllModeAndSearch(k)
	if s:modes.Buffer.Enabled
		call ctrlspace#keys#buffer#ToggleAllModeAndSearch(a:k)
	endif
endfunction
