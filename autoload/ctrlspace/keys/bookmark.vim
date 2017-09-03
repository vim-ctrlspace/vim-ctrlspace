let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

" FUNCTION: ctrlspace#keys#bookmark#Init() {{{
function! ctrlspace#keys#bookmark#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#GoToBookmark" , "Bookmark" , ["Tab" , "CR"  , "Space"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#Add"          , "Bookmark" , ["a"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#Delete"       , "Bookmark" , ["d"])
endfunction
" }}}

" FUNCTION: ctrlspace#keys#bookmark#GoToBookmark(k) {{{
function! ctrlspace#keys#bookmark#GoToBookmark(k)
	let nr = ctrlspace#window#SelectedIndex()

	call ctrlspace#window#Kill(0, 1)
	call ctrlspace#bookmarks#GoToBookmark(nr)

	if a:k ==# "CR"
        " No need to open ctrlspace again when bookmark file was opened
		"call ctrlspace#window#Toggle(0)
	elseif a:k ==# "Space"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#Kill(0, 0)
		call s:modes.Bookmark.Enable()
		call ctrlspace#window#Toggle(1)
	endif

	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

function! ctrlspace#keys#bookmark#Add(k)
    let result = ctrlspace#bookmarks#AddNewBookmark()
	if result
		call ctrlspace#window#Kill(0, 1)
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#Kill(0, 0)
		call s:modes.Bookmark.Enable()
		call ctrlspace#window#Toggle(1)
		call ctrlspace#ui#DelayedMsg()
	endif
endfunction

function! ctrlspace#keys#bookmark#Delete(k)
	let nr = ctrlspace#window#SelectedIndex()
	call ctrlspace#bookmarks#RemoveBookmark(nr)
	call ctrlspace#window#Kill(0, 1)
	call ctrlspace#window#Toggle(0)
	call ctrlspace#window#Kill(0, 0)
	call s:modes.Bookmark.Enable()
	call ctrlspace#window#Toggle(1)
	call ctrlspace#ui#DelayedMsg()
endfunction
