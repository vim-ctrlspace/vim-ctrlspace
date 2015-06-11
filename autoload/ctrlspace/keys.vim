let s:config         = ctrlspace#context#Configuration()
let s:keyNames       = []
let s:keyEscSequence = 0

function! ctrlspace#keys#KeyNames()
  return s:keyNames
endfunction

function! ctrlspace#keys#MarkKeyEscSequence()
  let s:keyEscSequence = 1
endfunction

function! ctrlspace#keys#InitKeyNames()
  let lowercase = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
  let uppercase = toupper(lowercase)

  let controlList = []

  for l in split(lowercase, " ")
    call add(controlList, "C-" . l)
  endfor

  let controls = join(controlList, " ")

  let numbers  = "1 2 3 4 5 6 7 8 9 0"
  let specials = "Space CR BS Tab S-Tab / ? ; : , . < > [ ] { } ( ) ' ` ~ + - _ = ! @ # $ % ^ & * C-f C-b C-u C-d C-h C-w " .
               \ "Bar BSlash MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse " .
               \ "Down Up Home End Left Right PageUp PageDown " .
               \ 'F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 "'

  if !s:config.UseMouseAndArrowsInTerm || has("gui_running")
    let specials .= " Esc"
  endif

  let specials .= (has("gui_running") || has("win32")) ? " C-Space" : " Nul"

  let keyNames = split(join([lowercase, uppercase, controls, numbers, specials], " "), " ")

  " won't work with leader mappings
  if ctrlspace#keys#IsDefaultKey()
    for i in range(0, len(keyNames) - 1)
      let fullKeyName = (strlen(keyNames[i]) > 1) ? ("<" . keyNames[i] . ">") : keyNames[i]

      if fullKeyName ==# ctrlspace#keys#DefaultKey()
        call remove(keyNames, i)
        break
      endif
    endfor
  endif

  let s:keyNames = keyNames
endfunction

function! ctrlspace#keys#Keypressed(key)
  let termSTab = s:keyEscSequence && (a:key ==# "Z")
  let s:keyEscSequence = 0

  if s:handleHelpKey(a:key)
    return 1
  elseif s:handleNopKey(a:key)
    return 1
  elseif s:handleSearchKey(a:key)
    return 1
  elseif s:handleCommonKeys(a:key)
    return 1
  else
    return 0
  endif
endfunction

function! s:handleHelpKey(key)
  if !ctrlspace#modes#Help().Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleNopKey(key)
  if !ctrlspace#modes#Nop().Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleSearchKey(key)
  if !ctrlspace#modes#Search().Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleCommonKeys(key)
  let wm = ctrlspace#modes#Workspace()

  if wm.Enabled
    call wm.SetData("LastBrowsed", line("."))
  endif

  if a:key ==# "j"
    call ctrlspace#window#MoveSelectionBar("down")
  elseif a:key ==# "k"
    call ctrlspace#window#MoveSelectionBar("up")
  elseif a:key ==# "p"
    call ctrlspace#jumps#Jump("previous")
  elseif a:key ==# "n"
    call ctrlspace#jumps#Jump("next")
  elseif (a:key ==# "MouseDown") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))
    call ctrlspace#window#MoveSelectionBar("up")
  elseif (a:key ==# "MouseUp") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))
    call ctrlspace#window#MoveSelectionBar("down")
  elseif (a:key ==# "LeftRelease") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))
    call ctrlspace#window#MoveSelectionBar("mouse")
  elseif (a:key ==# "2-LeftMouse") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))
    call ctrlspace#window#MoveSelectionBar("mouse")
    " call <SID>load_buffer()
  elseif (a:key ==# "Down") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))
    call feedkeys("j")
  elseif (a:key ==# "Up") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))
    call feedkeys("k")
  elseif ((a:key ==# "Home") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))) || (a:key ==# "K")
    call ctrlspace#window#MoveSelectionBar(1)
  elseif ((a:key ==# "End") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))) || (a:key ==# "J")
    call ctrlspace#window#MoveSelectionBar(line("$"))
  elseif ((a:key ==# "PageDown") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))) || (a:key ==# "C-f")
    call ctrlspace#window#MoveSelectionBar("pgdown")
  elseif ((a:key ==# "PageUp") && (s:config.UseMouseAndArrowsInTerm || has("gui_running"))) || (a:key ==# "C-b")
    call ctrlspace#window#MoveSelectionBar("pgup")
  elseif a:key ==# "C-d"
    call ctrlspace#window#MoveSelectionBar("half_pgdown")
  elseif a:key ==# "C-u"
    call ctrlspace#window#MoveSelectionBar("half_pgup")
  elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
    call ctrlspace#window#Kill(0, 1)
  elseif a:key ==# "Q"
    call ctrlspace#window#QuitVim()
  endif
endfunction

function! ctrlspace#keys#SetDefaultMapping(key, action)
  let s:defaultKey = a:key
  if !empty(s:defaultKey)
    if s:defaultKey ==? "<C-Space>" && !has("gui_running") && !has("win32")
      let s:defaultKey = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . s:defaultKey . ' ' . a:action
  endif
endfunction

function! ctrlspace#keys#IsDefaultKey()
  return exists("s:defaultKey")
endfunction

function! ctrlspace#keys#DefaultKey()
  return s:defaultKey
endfunction
