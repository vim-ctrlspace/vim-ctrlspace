s:config = g:ctrlspace#context#Configuration.Instance()

function! ctrlspace#keys#Keypressed(key)
  let termSTab = g:ctrlspace#context#KeyEscSequence && (a:key ==# "Z")
  let g:ctrlspace#context#KeyEscSequence = 0

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

  if (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
    call ctrlspace#window#Kill(0, 1)
  elseif a:key ==# "Q"
    call ctrlspace#window#QuitVim()
  endif
endfunction
