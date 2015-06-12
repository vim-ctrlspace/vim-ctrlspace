let s:config     = ctrlspace#context#Configuration()
let s:modes      = ctrlspace#modes#Modes()
let s:allBuffers = {}

function! ctrlspace#buffers#Init()
  for current in range(1, bufnr("$"))
    if !getbufvar(current, "&modifiable") || !getbufvar(current, "&buflisted") || getbufvar(current, "&ft") ==? "ctrlspace"
      break
    endif

    if !has_key(s:allBuffers, current)
      let s:allBuffers[current] = len(s:allBuffers) + 1
    endif
  endfor
endfunction

function! ctrlspace#buffers#AddBuffer()
  let current = bufnr('%')

  if !getbufvar(current, "&modifiable") || !getbufvar(current, "&buflisted") || getbufvar(current, "&ft") ==? "ctrlspace"
    return
  endif

  if !has_key(s:allBuffers, current)
    let s:allBuffers[current] = len(s:allBuffers) + 1
  endif

  if s:modes.Zoom.Enabled
    return
  endif

  let b:CtrlSpaceJumpCounter = ctrlspace#jumps#IncrementJumpCounter()

  if !exists("t:CtrlSpaceList")
    let t:CtrlSpaceList = {}
  endif

  if !has_key(t:CtrlSpaceList, current)
    let t:CtrlSpaceList[current] = len(t:CtrlSpaceList) + 1
  endif
endfunction

function! ctrlspace#buffers#Buffers(tabnr)
  if a:tabnr
    let buffers = gettabvar(a:tabnr, "CtrlSpaceList")
    if type(buffers) != type({})
      return {}
    endif
  else
    let buffers = s:allBuffers
  endif

  return filter(buffers, "buflisted(str2nr(v:key))") " modify proper dictionary and return it
endfunction
