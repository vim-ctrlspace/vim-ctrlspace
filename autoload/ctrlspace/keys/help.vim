let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#help#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#ToggleHelp", "Help", ["BS", "?"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#Close",      "Help", ["q", "Esc", "C-c"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#common#Quit",       "Help", ["Q"])

	call s:map("Down",            "j")
	call s:map("Up",              "k")
	call s:map("MouseDown",       "MouseDown")
	call s:map("MouseUp",         "MouseUp")
	call s:map("LeftRelease",     "LeftRelease")
	call s:map("LeftMouse2",      '2-LeftMouse')
	call s:map("DownArrow",       "Down")
	call s:map("UpArrow",         "Up")
	call s:map("Home",            "Home")
	call s:map("Top",             "K")
	call s:map("End",             "End")
	call s:map("Bottom",          "J")
	call s:map("PageDown",        "PageDown")
	call s:map("ScrollDown",      'C-f')
	call s:map("PageUp",          "PageUp")
	call s:map("ScrollUp",        'C-b')
	call s:map("HalfScrollDown",  'C-d')
	call s:map("HalfScrollUp",    'C-u')
	call s:map("OpenInNewWindow", "CR")
endfunction

function! s:map(fn, ...)
	call ctrlspace#keys#AddMapping("ctrlspace#keys#help#" . a:fn, "Help", a:000)
endfunction

function! ctrlspace#keys#help#OpenInNewWindow(k)
	call ctrlspace#help#OpenInNewWindow()
endfunction

function! ctrlspace#keys#help#Up(k)
	call ctrlspace#window#MoveCursor("up")
endfunction

function! ctrlspace#keys#help#Down(k)
	call ctrlspace#window#MoveCursor("down")
endfunction

function! ctrlspace#keys#help#MouseUp(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("down")
	endif
endfunction

function! ctrlspace#keys#help#MouseDown(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("up")
	endif
endfunction

function! ctrlspace#keys#help#LeftRelease(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("mouse")
	endif
endfunction

function! ctrlspace#keys#help#LeftMouse2(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("mouse")
		call feedkeys("\<CR>")
	endif
endfunction

function! ctrlspace#keys#help#DownArrow(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("down")
	endif
endfunction

function! ctrlspace#keys#help#UpArrow(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("up")
	endif
endfunction

function! ctrlspace#keys#help#Home(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor(1)
	endif
endfunction

function! ctrlspace#keys#help#Top(k)
	call ctrlspace#window#MoveCursor(1)
endfunction

function! ctrlspace#keys#help#End(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor(line("$"))
	endif
endfunction

function! ctrlspace#keys#help#Bottom(k)
	call ctrlspace#window#MoveCursor(line("$"))
endfunction

function! ctrlspace#keys#help#PageDown(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("pgdown")
	endif
endfunction

function! ctrlspace#keys#help#ScrollDown(k)
	call ctrlspace#window#MoveCursor("pgdown")
endfunction

function! ctrlspace#keys#help#PageUp(k)
	if s:config.UseMouseAndArrowsInTerm || has("gui_running")
		call ctrlspace#window#MoveCursor("pgup")
	endif
endfunction

function! ctrlspace#keys#help#ScrollUp(k)
	call ctrlspace#window#MoveCursor("pgup")
endfunction

function! ctrlspace#keys#help#HalfScrollDown(k)
	call ctrlspace#window#MoveCursor("half_pgdown")
endfunction

function! ctrlspace#keys#help#HalfScrollUp(k)
	call ctrlspace#window#MoveCursor("half_pgup")
endfunction
