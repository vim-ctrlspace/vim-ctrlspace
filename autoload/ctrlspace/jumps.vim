let s:config      = ctrlspace#context#Configuration()
let s:modes       = ctrlspace#modes#Modes()
let s:jumpCounter = 0

function! ctrlspace#jumps#IncrementJumpCounter()
	let s:jumpCounter += 1
	return s:jumpCounter
endfunction

function! s:compareJumps(a, b)
	if a:a.counter > a:b.counter
		return -1
	elseif a:a.counter < a:b.counter
		return 1
	else
		return 0
	endif
endfunction

function! s:createTabJumps()
	let b:jumplines    = []
	let b:jumplinesLen = tabpagenr("$")

	for t in range(1, b:jumplinesLen)
		let counter = ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceTabJumpCounter", 0)
		call add(b:jumplines, { "line": t, "counter": counter })
	endfor
endfunction

function! s:createBookmarkJumps()
	let b:jumplines    = []
	let b:jumplinesLen = b:size
	let bookmarks      = ctrlspace#bookmarks#Bookmarks()

	for l in range(1, b:jumplinesLen)
		let counter = bookmarks[b:indices[l - 1]].JumpCounter
		call add(b:jumplines, { "line": l, "counter": counter })
	endfor
endfunction

function! s:createBufferJumps()
	let b:jumplines    = []
	let b:jumplinesLen = b:size

	for l in range(1, b:jumplinesLen)
		let counter = ctrlspace#util#GetbufvarWithDefault(b:indices[l - 1], "CtrlSpaceJumpCounter", 0)
		call add(b:jumplines, { "line": l, "counter": counter })
	endfor
endfunction

function! ctrlspace#jumps#Jump(direction)
	if !exists("b:jumplines")
		let clv = ctrlspace#modes#CurrentListView()

		if clv.Name ==# "Tab"
			call s:createTabJumps()
		elseif clv.Name ==# "Bookmark"
			call s:createBookmarkJumps()
		else
			call s:createBufferJumps()
		endif

		call sort(b:jumplines, function("s:compareJumps"))
	endif

	if !exists("b:jumppos")
		let b:jumppos = 0
	endif

	if a:direction == "previous"
		let b:jumppos += 1

		if b:jumppos == b:jumplinesLen
			let b:jumppos = b:jumplinesLen - 1
		endif
	elseif a:direction == "next"
		let b:jumppos -= 1

		if b:jumppos < 0
			let b:jumppos = 0
		endif
	endif

	call ctrlspace#window#MoveSelectionBar(string(b:jumplines[b:jumppos]["line"]))
endfunction
