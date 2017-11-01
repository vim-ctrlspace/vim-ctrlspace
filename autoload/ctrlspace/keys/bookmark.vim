let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

" FUNCTION: ctrlspace#keys#bookmark#Init() {{{
function! ctrlspace#keys#bookmark#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#GoToBookmark" , "Bookmark" , ["Tab" , "CR"  , "Space"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#Add"          , "Bookmark" , ["a"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#Delete"       , "Bookmark" , ["d"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#Append"       , "Bookmark" , ["t", "s", "v"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#bookmark#Sort"         , "Bookmark" , ["g"])
endfunction
" }}}

" FUNCTION: ctrlspace#keys#bookmark#GoToBookmark(k) {{{
function! ctrlspace#keys#bookmark#GoToBookmark(k)
	let nr = ctrlspace#window#SelectedIndex()

	call ctrlspace#window#Kill(0, 1)
	call ctrlspace#bookmarks#GoToBookmark(nr)

	if a:k ==# "Tab"
		call ctrlspace#window#Toggle(0)
    "elseif a:k ==# "CR"
        " No need to open ctrlspace again when bookmark file was opened
	elseif a:k ==# "Space"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#Kill(0, 0)
		call s:modes.Bookmark.Enable()
		call ctrlspace#window#Toggle(1)
	endif

	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#bookmark#Append(k) {{{
function! ctrlspace#keys#bookmark#Append(k)
    let l:bookmark = ctrlspace#bookmarks#Bookmarks()[ctrlspace#window#SelectedIndex()]

	call ctrlspace#window#Kill(0, 1)

    " Edit bookmarked file
    if a:k ==# "t"
        execute "tabe " . l:bookmark.Directory. "/" . l:bookmark.Name
    elseif a:k ==# "s"
        execute "split " . l:bookmark.Directory. "/" . l:bookmark.Name
    elseif a:k ==# "v"
        execute "vsplit " . l:bookmark.Directory. "/" . l:bookmark.Name
    endif

    " Change CWD to bookmakred directory
    call ctrlspace#ui#DelayedMsg("Directory: " . l:bookmark.Directory)
	call ctrlspace#ui#DelayedMsg()
endfunction
" }}}

" FUNCTION: ctrlspace#keys#bookmark#Add(k) {{{
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
" }}}

" FUNCTION: ctrlspace#keys#bookmark#Delete(k) {{{
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
" }}}

" FUNCTION: ctrlspace#keys#bookmark#Sort(k) {{{
function! ctrlspace#keys#bookmark#Sort(k)
	if s:modes.Bookmark.Data.SortMode ==# "path"
        call s:modes.Bookmark.SetData("SortMode", "name")
        call ctrlspace#ui#DelayedMsg("Bookmark was sorted by name")
    elseif s:modes.Bookmark.Data.SortMode ==# "name"
        call s:modes.Bookmark.SetData("SortMode", "path")
        call ctrlspace#ui#DelayedMsg("Bookmark was sorted by path")
    endif

    call ctrlspace#window#Toggle(0)
    call ctrlspace#window#Kill(0, 0)
    call s:modes.Bookmark.Enable()
    call ctrlspace#window#Toggle(1)
    call ctrlspace#ui#DelayedMsg()
endfunction
" }}}
