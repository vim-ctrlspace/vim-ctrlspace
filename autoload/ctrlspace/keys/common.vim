let s:config    = ctrlspace#context#Configuration()
let s:commonMap = {}

function! ctrlspace#keys#common#Init()
  call s:map("j", "Down")
  call s:map("k", "Up")
  call s:map("p", "Previous")
  call s:map("P", "PreviousCR")
  call s:map("n", "Next")
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
  call s:map("q", "Close")
  call s:map("Esc", "Close")
  call s:map("C-c", "Close")
  call s:map("Q", "Quit")

  let keyMap = ctrlspace#keys#KeyMap()

  for m in ["Buffer", "File", "Tablist", "Workspace", "Bookmark"]
    call extend(keyMap[m], s:commonMap)
  endfor
endfunction

function s:map(key, func)
  let s:commonMap[a:key] = function("ctrlspace#keys#common#" . a:func)
endfunction

function! ctrlspace#keys#common#Up(k, t)
  call ctrlspace#window#MoveSelectionBar("up")
endfunction

function! ctrlspace#keys#common#Down(k, t)
  call ctrlspace#window#MoveSelectionBar("down")
endfunction

function! ctrlspace#keys#common#Previous(k, t)
  call ctrlspace#jumps#Jump("previous")
endfunction

function! ctrlspace#keys#common#PreviousCR(k, t)
  call ctrlspace#jumps#Jump("previous")
  call feedkeys("\<CR>")
endfunction

function! ctrlspace#keys#common#Next(k, t)
  call ctrlspace#jumps#Jump("next")
endfunction

function! ctrlspace#keys#common#MouseUp(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("down")
  endif
endfunction

function! ctrlspace#keys#common#MouseDown(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("up")
  endif
endfunction

function! ctrlspace#keys#common#LeftRelease(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("mouse")
  endif
endfunction

function! ctrlspace#keys#common#LeftMouse2(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("mouse")
    call feedkeys("\<CR>")
  endif
endfunction

function! ctrlspace#keys#common#DownArrow(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("down")
  endif
endfunction

function! ctrlspace#keys#common#UpArrow(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("up")
  endif
endfunction

function! ctrlspace#keys#common#Home(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar(1)
  endif
endfunction

function! ctrlspace#keys#common#Top(k, t)
  call ctrlspace#window#MoveSelectionBar(1)
endfunction

function! ctrlspace#keys#common#End(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar(line("$"))
  endif
endfunction

function! ctrlspace#keys#common#Bottom(k, t)
  call ctrlspace#window#MoveSelectionBar(line("$"))
endfunction

function! ctrlspace#keys#common#PageDown(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("pgdown")
  endif
endfunction

function! ctrlspace#keys#common#ScrollDown(k, t)
  call ctrlspace#window#MoveSelectionBar("pgdown")
endfunction

function! ctrlspace#keys#common#PageUp(k, t)
  if s:config.UseMouseAndArrowsInTerm || has("gui_running")
    call ctrlspace#window#MoveSelectionBar("pgup")
  endif
endfunction

function! ctrlspace#keys#common#ScrollUp(k, t)
  call ctrlspace#window#MoveSelectionBar("pgup")
endfunction

function! ctrlspace#keys#common#HalfScrollDown(k, t)
  call ctrlspace#window#MoveSelectionBar("half_pgdown")
endfunction

function! ctrlspace#keys#common#HalfScrollUp(k, t)
  call ctrlspace#window#MoveSelectionBar("half_pgup")
endfunction

function! ctrlspace#keys#common#Close(k, t)
  call ctrlspace#window#Kill(0, 1)
endfunction

function! ctrlspace#keys#common#Quit(k, t)
  call ctrlspace#window#QuitVim()
endfunction
