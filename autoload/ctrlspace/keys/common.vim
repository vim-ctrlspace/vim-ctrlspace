let s:config       = ctrlspace#context#Configuration()
let s:modes        = ctrlspace#modes#Modes()
let s:commonMap    = {}
let s:helpMap      = {}
let s:lastListView = {}

function! ctrlspace#keys#common#Init()
  call s:map("ToggleHelp", "?")
  call s:map("PreviousListView", "BS")
  call s:map("ToggleFileMode", "o")
  call s:map("Down", "j")
  call s:map("Up", "k")
  call s:map("Previous", "p")
  call s:map("PreviousCR", "P")
  call s:map("Next", "n")
  call s:map("MouseDown", "MouseDown")
  call s:map("MouseUp", "MouseUp")
  call s:map("LeftRelease", "LeftRelease")
  call s:map("LeftMouse2", '2-LeftMouse')
  call s:map("DownArrow", "Down")
  call s:map("UpArrow", "Up")
  call s:map("Home", "Home")
  call s:map("Top", "K")
  call s:map("End", "End")
  call s:map("Bottom", "J")
  call s:map("PageDown", "PageDown")
  call s:map("ScrollDown", 'C-f')
  call s:map("PageUp", "PageUp")
  call s:map("ScrollUp", 'C-b')
  call s:map("HalfScrollDown", 'C-d')
  call s:map("HalfScrollUp", 'C-u')
  call s:map("Close", "q", "Esc", 'C-c')
  call s:map("Quit", "Q")

  let keyMap  = ctrlspace#keys#KeyMap()
  let helpMap = ctrlspace#help#HelpMap()

  for m in ["Buffer", "File", "Tablist", "Workspace", "Bookmark"]
    call extend(keyMap[m], s:commonMap)
    call extend(helpMap[m], s:helpMap)
  endfor
endfunction

function! s:map(func, ...)
  let fn = "ctrlspace#keys#common#" . a:func
  let Ref = function(fn)

  for k in a:000
    let s:helpMap[k] = fn
    let s:commonMap[k] = Ref
  endfor
endfunction

function! ctrlspace#keys#common#ToggleHelp(k, t)
  call ctrlspace#window#Kill(0, 0)

  if s:modes.Help.Enabled
    call s:modes.Help.Disable()
  else
    call s:modes.Help.Enable()
  endif

  call ctrlspace#window#Toggle(1)
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

function! ctrlspace#keys#common#EnableFileModeAndSearch(k, t)
  if a:k ==# "O"
    call ctrlspace#search#SwitchSearchMode(1)
    return
  endif
endfunction

function! ctrlspace#keys#common#ToggleFileMode(k, t)
  if !ctrlspace#roots#ProjectRootFound()
    return
  endif

  let clv = ctrlspace#modes#CurrentListView()

  if clv.Name ==# "File"
    if empty(s:lastListView)
      return
    else
      let nextListView = s:lastListView
    endif
  else
    let nextListView = s:modes.File
  endif

  let s:lastListView = clv

  call ctrlspace#window#Kill(0, 0)
  call nextListView.Enable()
  call ctrlspace#window#Toggle(1)
endfunction

" function! ctrlspace#keys#common#ToggleWorkspaceMode(k, t)
"   if s:workspace_mode
"     call <SID>kill(0, 0)
"     let s:workspace_mode = 0
"     call <SID>ctrlspace_toggle(1)
"   elseif empty(s:workspace_names)
"     call <SID>save_first_workspace()
"   else
"     call <SID>kill(0, 0)
"     let s:file_mode      = 0
"     let s:tablist_mode   = 0
"     let s:bookmark_mode  = 0
"     let s:workspace_mode = 1
"     call <SID>ctrlspace_toggle(1)
"   endif
" endfunction

function! ctrlspace#keys#common#PreviousListView(k, t)
  if !empty(s:lastListView)
    let clv = ctrlspace#modes#CurrentListView()

    if clv == s:lastListView
      return
    endif

    let nextListView = s:lastListView
    let s:lastListView = clv

    call ctrlspace#window#Kill(0, 0)
    call nextListView.Enable()
    call ctrlspace#window#Toggle(1)
  endif
endfunction
