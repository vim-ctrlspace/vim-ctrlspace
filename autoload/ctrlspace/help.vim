let s:config     = ctrlspace#context#Configuration()
let s:modes      = ctrlspace#modes#Modes()
let s:sizes      = ctrlspace#context#SymbolSizes()
let s:textBuffer = []

let s:helpMap = {
      \ "Search":    {},
      \ "Nop":       {},
      \ "Buffer":    {},
      \ "File":      {},
      \ "Tablist":   {},
      \ "Workspace": {},
      \ "Bookmark":  {}
      \ }

let s:titles = {
      \ "Search":    "SEARCH MODE",
      \ "Nop":       "NOP MODE",
      \ "Buffer":    "BUFFER LIST",
      \ "File":      "FILE LIST",
      \ "Tablist":   "TAB LIST",
      \ "Workspace": "WORKSPACE LIST",
      \ "Bookmark":  "BOOKMARK LIST"
      \ }

let s:functionHelp = {
      \ "ctrlspace#keys#common#ToggleHelp":         "Toggle the Help view",
      \ "ctrlspace#keys#common#Down":               "Move the selection bar down",
      \ "ctrlspace#keys#common#Up":                 "Move the selection bar up",
      \ "ctrlspace#keys#common#Previous":           "Move the selection bar to the previously opened item",
      \ "ctrlspace#keys#common#PreviousCR":         "Move the selection bar to the previously opened item and open it",
      \ "ctrlspace#keys#common#Next":               "Move the selection bar to the next opened item",
      \ "ctrlspace#keys#common#Top":                "Move the selection bar to the top of the list",
      \ "ctrlspace#keys#common#Bottom":             "Move the selection bar to the bottom of the list",
      \ "ctrlspace#keys#common#ScrollDown":         "Move the selection bar one screen down",
      \ "ctrlspace#keys#common#ScrollUp":           "Move the selection bar one screen up",
      \ "ctrlspace#keys#common#HalfScrollDown":     "Move the selection bar a half screen down",
      \ "ctrlspace#keys#common#HalfScrollUp":       "Move the selection bar a half screen up",
      \ "ctrlspace#keys#common#Close":              "Close the list",
      \ "ctrlspace#keys#common#Quit":               "Quit Vim with a prompt if unsaved changes found",
      \ "ctrlspace#keys#common#PreviousListView":   "Return to the previous list (if any)",
      \ "ctrlspace#keys#common#ToggleFileMode":     "Toggle File List view",
      \ "ctrlspace#keys#common#FileModeWithSearch": "Open File List in Search Mode"
      \ }

function! ctrlspace#help#AddMapping(funcName, mapName, entry)
  if has_key(s:helpMap, a:mapName)
    let s:helpMap[a:mapName][a:entry] = a:funcName
  endif
endfunction

function! ctrlspace#help#HelpMap()
  return s:helpMap
endfunction

function! ctrlspace#help#FunctionHelp()
  return s:functionHelp
endfunction

function! s:init()
  call extend(s:functionHelp, s:config.FunctionHelp)
endfunction

call s:init()

function! ctrlspace#help#DisplayHelp(fill)
  if s:modes.Nop.Enabled
    let mapName = "Nop"
  elseif s:modes.Search.Enabled
    let mapName = "Search"
  else
    let mapName = ctrlspace#modes#CurrentListView().Name
  endif

  call s:collectKeysInfo(mapName)

  call s:puts("Context help for " . s:titles[mapName])
  call s:puts("")

  for info in b:helpKeyDescriptions
    call s:puts(info.key . " | " . info.description)
  endfor

  call s:puts("")
  call s:puts(s:config.Symbols.CS . " CtrlSpace 5.0.0 (c) 2013-2015 Szymon Wrozynski and Contributors")

  setlocal modifiable

  let b:size = len(s:textBuffer)

  if b:size > s:config.Height
    let maxHeight = ctrlspace#window#MaxHeight()

    if b:size < maxHeight
      silent! exe "resize " . b:size
    else
      silent! exe "resize " . maxHeight
    endif
  endif

  silent! put! =s:flushTextBuffer()
  normal! GkJ

  while winheight(0) > line(".")
    silent! put =a:fill
  endwhile

  normal! 0
  normal! gg

  setlocal nomodifiable
endfunction

function! s:puts(str)
  let str = "  " . a:str

  if &columns < (strwidth(str) + 2)
    let str = strpart(str, 0, &columns - 2 - s:sizes.Dots) . s:config.Symbols.Dots
  endif

  while strwidth(str) < &columns
    let str .= " "
  endwhile

  call add(s:textBuffer, str)
endfunction

function! s:flushTextBuffer()
  let text = join(s:textBuffer, "\n")
  let s:textBuffer = []
  return text
endfunction

function! s:keyHelp(key, description)
  if !exists("b:helpKeyDescriptions")
    let b:helpKeyDescriptions = []
    let b:helpKeyWidth = 0
  endif

  call add(b:helpKeyDescriptions, { "key": a:key, "description": a:description })

  if strwidth(a:key) > b:helpKeyWidth
    let b:helpKeyWidth = strwidth(a:key)
  else
    for keyInfo in b:helpKeyDescriptions
      while strwidth(keyInfo.key) < b:helpKeyWidth
        let keyInfo.key .= " "
      endwhile
    endfor
  endif
endfunction

function! s:collectKeysInfo(mapName)
  for key in sort(keys(s:helpMap[a:mapName]))
    let fn = s:helpMap[a:mapName][key]

    if has_key(s:functionHelp, fn) && !empty(s:functionHelp[fn])
      call s:keyHelp(key, s:functionHelp[fn])
    endif
  endfor
endfunction
