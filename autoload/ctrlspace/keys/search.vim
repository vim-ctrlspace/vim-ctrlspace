let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#search#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleHelp",          "Search", ["?"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#Close",               "Search", ["Esc", 'C-c'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#search#ClearOrRemoveLetter", "Search", ["BS", 'C-h'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#search#SwitchOff",           "Search", ["/", "CR"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#search#SwitchOffCR",         "Search", ["Tab"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#search#SwitchOffSpace",      "Search", ["Space"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#search#ClearLetters",        "Search", ['C-u', 'C-w'])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#search#AddLetter",           "Search", ["lowercase", "uppercase", "numbers"])
endfunction

function! ctrlspace#keys#search#ClearOrRemoveLetter(k)
	if empty(s:modes.Search.Data.Letters)
		call ctrlspace#search#ClearSearchMode()
	else
		call ctrlspace#search#RemoveSearchLetter()
	endif
endfunction

function! ctrlspace#keys#search#AddLetter(k)
	call ctrlspace#search#AddSearchLetter(a:k)
endfunction

function! ctrlspace#keys#search#SwitchOff(k)
	call ctrlspace#search#SwitchSearchMode(0)
endfunction

function! ctrlspace#keys#search#SwitchOffCR(k)
	call ctrlspace#search#SwitchSearchMode(0)
	if !s:modes.Nop.Enabled
		call feedkeys("\<CR>")
	endif
endfunction

function! ctrlspace#keys#search#SwitchOffSpace(k)
	call ctrlspace#search#SwitchSearchMode(0)
	if !s:modes.Nop.Enabled
		call feedkeys("\<Space>")
	endif
endfunction

function! ctrlspace#keys#search#ClearLetters(k)
	call ctrlspace#search#ClearSearchLetters()
endfunction
