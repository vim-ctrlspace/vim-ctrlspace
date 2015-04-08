s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#keys#Keypressed(key)
  let termSTab = ctrlspace#context#KeyEscSequence && (a:key ==# "Z")
  let ctrlspace#context#KeyEscSequence = 0
endfunction
