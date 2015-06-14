let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#file#Init()
    call ctrlspace#keys#AddMapping("ctrlspace#keys#file#SearchParentDirectory", "File", ["BSlash", "Bar"])
endfunction

function! ctrlspace#keys#file#SearchParentDirectory(k)
    call ctrlspace#search#SearchParentDirectoryCycle()
endfunction
