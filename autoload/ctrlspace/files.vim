let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()
let s:files  = []

function! ctrlspace#files#Files()
  return s:files
endfunction

function! ctrlspace#files#ClearAll()
  let s:files = []
endfunction
