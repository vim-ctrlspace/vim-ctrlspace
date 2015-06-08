let g:ctrlspace#keys#KeyNames = []
let s:keyEscSequence          = 0

let s:config = g:ctrlspace#context#Configuration.Instance()

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

  let g:ctrlspace#keys#KeyNames = keyNames
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
  if !g:ctrlspace#modes#Help.Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleNopKey(key)
  if !g:ctrlspace#modes#Nop.Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleSearchKey(key)
  if !g:ctrlspace#modes#Search.Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleCommonKeys(key)
  if g:ctrlspace#modes#Workspace.Enabled
    let g:ctrlspace#modes#Workspace.Data.LastBrowsed = line(".")
  endif

  if a:key ==# "j"
    call ctrlspace#window#MoveSelectionBar("down")
  elseif a:key ==# "k"
    call ctrlspace#window#MoveSelectionBar("up")
  elseif a:key ==# "p"
    call <SID>jump("previous")
  elseif a:key ==# "P"
    call <SID>jump("previous")
    " call <SID>load_buffer()
  elseif a:key ==# "n"
    call <SID>jump("next")
  elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      call <SID>load_buffer()
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
  if (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
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
