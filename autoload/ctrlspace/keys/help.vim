let s:config    = ctrlspace#context#Configuration()
let s:modes     = ctrlspace#modes#Modes()

function! ctrlspace#keys#help#Init()
  call ctrlspace#keys#AddMapping("Help", ["BS", "?"], "ctrlspace#keys#common#ToggleHelp")
  call ctrlspace#keys#AddMapping("Help", ["q", "Esc", "C-c"], "ctrlspace#keys#common#Close")
  call ctrlspace#keys#AddMapping("Help", ["Q"], "ctrlspace#keys#common#Quit")
  call s:map("j", "Down")
  call s:map("k", "Up")
  call s:map("MouseDown", "MouseDown")
  call s:map("MouseUp", "MouseUp")
  call s:map("LeftRelease", "LeftRelease")
  call s:map("2-LeftMouse", "LeftMouse2")
  call s:map("Down", "DownArrow")
  call s:map("Up", "UpArrow")
  call s:map("Home", "Home")
  call s:map("K", "Top")
  call s:map("End", "End")
  call s:map("J", "Bottom")
  call s:map("PageDown", "PageDown")
  call s:map("C-f", "ScrollDown")
  call s:map("PageUp", "PageUp")
  call s:map("C-b", "ScrollUp")
  call s:map("C-d", "HalfScrollDown")
  call s:map("C-u", "HalfScrollUp")
endfunction

function! s:map(key, fn)
  call ctrlspace#keys#AddMapping("Help", [a:key], "ctrlspace#keys#help#" . a:fn)
endfunction

function! ctrlspace#keys#help#Up(k, t)
  call ctrlspace#window#MoveCursor("up")
endfunction

function! ctrlspace#keys#help#Down(k, t)
  call ctrlspace#window#MoveCursor("down")
endfunction

function! ctrlspace#keys#help#MouseUp(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("down")
  endif
endfunction

function! ctrlspace#keys#help#MouseDown(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("up")
  endif
endfunction

function! ctrlspace#keys#help#LeftRelease(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("mouse")
  endif
endfunction

function! ctrlspace#keys#help#LeftMouse2(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("mouse")
    call feedkeys("\<CR>")
  endif
endfunction

function! ctrlspace#keys#help#DownArrow(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("down")
  endif
endfunction

function! ctrlspace#keys#help#UpArrow(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("up")
  endif
endfunction

function! ctrlspace#keys#help#Home(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor(1)
  endif
endfunction

function! ctrlspace#keys#help#Top(k, t)
  call ctrlspace#window#MoveCursor(1)
endfunction

function! ctrlspace#keys#help#End(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor(line("$"))
  endif
endfunction

function! ctrlspace#keys#help#Bottom(k, t)
  call ctrlspace#window#MoveCursor(line("$"))
endfunction

function! ctrlspace#keys#help#PageDown(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("pgdown")
  endif
endfunction

function! ctrlspace#keys#help#ScrollDown(k, t)
  call ctrlspace#window#MoveCursor("pgdown")
endfunction

function! ctrlspace#keys#help#PageUp(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveCursor("pgup")
  endif
endfunction

function! ctrlspace#keys#help#ScrollUp(k, t)
  call ctrlspace#window#MoveCursor("pgup")
endfunction

function! ctrlspace#keys#help#HalfScrollDown(k, t)
  call ctrlspace#window#MoveCursor("half_pgdown")
endfunction

function! ctrlspace#keys#help#HalfScrollUp(k, t)
  call ctrlspace#window#MoveCursor("half_pgup")
endfunction
