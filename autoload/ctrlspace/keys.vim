s:config = g:ctrlspace#context#Configuration.Instance()

function! g:ctrlspace#keys#Keypressed(key)
  let termSTab = g:ctrlspace#context#KeyEscSequence && (a:key ==# "Z")
  let g:ctrlspace#context#KeyEscSequence = 0
endfunction
