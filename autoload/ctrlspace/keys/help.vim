let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#help#Init() abort
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

function! s:map(fn, ...) abort
    call ctrlspace#keys#AddMapping("ctrlspace#keys#help#" . a:fn, "Help", a:000)
endfunction

function! ctrlspace#keys#help#OpenInNewWindow(k) abort
    call ctrlspace#help#OpenInNewWindow()
endfunction

function! ctrlspace#keys#help#Up(k) abort
    call ctrlspace#window#MoveCursor("up")
endfunction

function! ctrlspace#keys#help#Down(k) abort
    call ctrlspace#window#MoveCursor("down")
endfunction

function! ctrlspace#keys#help#MouseUp(k) abort
    if s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("down")
    endif
endfunction

function! ctrlspace#keys#help#MouseDown(k) abort
    if s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("up")
    endif
endfunction

function! ctrlspace#keys#help#LeftRelease(k) abort
    if s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("mouse")
    endif
endfunction

function! ctrlspace#keys#help#LeftMouse2(k) abort
    if s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("mouse")
        call feedkeys("\<CR>")
    endif
endfunction

function! ctrlspace#keys#help#DownArrow(k) abort
    if s:config.UseArrowsInTerm || s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("down")
    endif
endfunction

function! ctrlspace#keys#help#UpArrow(k) abort
    if s:config.UseArrowsInTerm || s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("up")
    endif
endfunction

function! ctrlspace#keys#help#Home(k) abort
    if s:config.UseArrowsInTerm || s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor(1)
    endif
endfunction

function! ctrlspace#keys#help#Top(k) abort
    call ctrlspace#window#MoveCursor(1)
endfunction

function! ctrlspace#keys#help#End(k) abort
    if s:config.UseArrowsInTerm || s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor(line("$"))
    endif
endfunction

function! ctrlspace#keys#help#Bottom(k) abort
    call ctrlspace#window#MoveCursor(line("$"))
endfunction

function! ctrlspace#keys#help#PageDown(k) abort
    if s:config.UseArrowsInTerm || s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("pgdown")
    endif
endfunction

function! ctrlspace#keys#help#ScrollDown(k) abort
    call ctrlspace#window#MoveCursor("pgdown")
endfunction

function! ctrlspace#keys#help#PageUp(k) abort
    if s:config.UseArrowsInTerm || s:config.UseMouseAndArrowsInTerm || has("gui_running")
        call ctrlspace#window#MoveCursor("pgup")
    endif
endfunction

function! ctrlspace#keys#help#ScrollUp(k) abort
    call ctrlspace#window#MoveCursor("pgup")
endfunction

function! ctrlspace#keys#help#HalfScrollDown(k) abort
    call ctrlspace#window#MoveCursor("half_pgdown")
endfunction

function! ctrlspace#keys#help#HalfScrollUp(k) abort
    call ctrlspace#window#MoveCursor("half_pgup")
endfunction
