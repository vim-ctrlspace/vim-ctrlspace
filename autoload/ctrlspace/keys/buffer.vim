let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#buffer#Init()
    call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#SearchParentDirectory", "Buffer", ["BSlash"])
    call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#SearchParentDirectoryInFile", "Buffer", ["Bar"])
endfunction

function! ctrlspace#keys#buffer#SearchParentDirectory(k)
    call ctrlspace#search#SearchParentDirectoryCycle()
endfunction

function! ctrlspace#keys#buffer#SearchParentDirectoryInFile(k)
    call ctrlspace#search#SearchParentDirectoryCycle()
    call ctrlspace#keys#common#ToggleFileMode(a:k)
endfunction
