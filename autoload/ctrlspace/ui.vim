let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#ui#Msg(message)
	echo s:config.Symbols.CS . "  " . a:message
endfunction

function! ctrlspace#ui#DelayedMsg(...)
	if !empty(a:000)
		let s:delayedMessage = a:1
	elseif exists("s:delayedMessage") && !empty(s:delayedMessage)
		redraw
		call ctrlspace#ui#Msg(s:delayedMessage)
		unlet s:delayedMessage
	endif
endfunction

function! ctrlspace#ui#GetInput(msg, ...)
	let msg = s:config.Symbols.CS . "  " . a:msg

	call inputsave()

	if a:0 >= 2
		let answer = input(msg, a:1, a:2)
	elseif a:0 == 1
		let answer = input(msg, a:1)
	else
		let answer = input(msg)
	endif

	call inputrestore()
	redraw!

	return answer
endfunction

function! ctrlspace#ui#Confirmed(msg)
	return ctrlspace#ui#GetInput(a:msg . " (yN): ") =~? "y"
endfunction

function! ctrlspace#ui#ProceedIfModified()
	for i in range(1, bufnr("$"))
		if getbufvar(i, "&modified")
			return ctrlspace#ui#Confirmed("Some buffers not saved. Proceed anyway?")
		endif
	endfor

	return 1
endfunction
