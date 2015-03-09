function! ctrlspace#bookmarks#AddToBookmarks(directory, name)
  let config    = ctrlspace#context#Configuration.Instance()
  let directory = ctrlspace#util#NormalizeDirectory(a:directory)
  let bookmarks = ctrlspace#context#Bookmarks()
  let roots     = ctrlspace#context#ProjectRoots()

  let jumpCounter = 0

  for i in range(0, len(bookmarks) - 1)
    if bookmarks[i].Directory == directory
      let jumpCounter = bookmarks[i].JumpCounter
      call remove(bookmarks, i)
      break
    endif
  endfor

  let bookmark = { "Name": a:name, "Directory": directory, "JumpCounter": jumpCounter }

  call add(bookmarks, bookmark)

  let lines     = []
  let bmRoots   = {}
  let cacheFile = config.CacheDir . "/.cs_cache"

  if filereadable(cacheFile)
    for oldLine in readfile(cacheFile)
      if (oldLine !~# "CS_BOOKMARK: ") && (oldLine !~# "CS_PROJECT_ROOT: ")
        call add(lines, oldLine)
      endif
    endfor
  endif

  for bm in bookmarks
    call add(lines, "CS_BOOKMARK: " . bm.Directory . ctrlspace#context#Separator() . bm.Name)
    let bmRoots[bm.Directory] = 1
  endfor

  for root in keys(roots)
    if !exists("bmRoots[root]")
      call add(lines, "CS_PROJECT_ROOT: " . root)
    endif
  endfor

  call writefile(lines, cacheFile)

  let roots[bookmark.Directory] = 1

  call ctrlspace#context#SetBookmarks(bookmarks)
  call ctrlspace#context#SetProjectRoots(roots)

  return bookmark
endfunction

function! <SID>init_key_names()
  let lowercase_letters = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
  let uppercase_letters = toupper(lowercase_letters)

  let control_letters_list = []

  for l in split(lowercase_letters, " ")
    call add(control_letters_list, "C-" . l)
  endfor

  let control_letters = join(control_letters_list, " ")

  let numbers       = "1 2 3 4 5 6 7 8 9 0"
  let special_chars = "Space CR BS Tab S-Tab / ? ; : , . < > [ ] { } ( ) ' ` ~ + - _ = ! @ # $ % ^ & * C-f C-b C-u C-d C-h C-w " .
                    \ "Bar BSlash MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse " .
                    \ "Down Up Home End Left Right PageUp PageDown " .
                    \ 'F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 "'

  if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
    let special_chars .= " Esc"
  endif

  let special_chars .= (has("gui_running") || has("win32")) ? " C-Space" : " Nul"

  let s:key_names = split(join([lowercase_letters, uppercase_letters, control_letters, numbers, special_chars], " "), " ")

  " won't work with leader mappings
  if exists("s:default_key")
    for i in range(0, len(s:key_names) - 1)
      let full_key_name = (strlen(s:key_names[i]) > 1) ? ("<" . s:key_names[i] . ">") : s:key_names[i]

      if full_key_name ==# s:default_key
        call remove(s:key_names, i)
        break
      endif
    endfor
  endif
endfunction

call <SID>init_key_names()

au BufEnter * call <SID>add_tab_buffer()

let s:jump_counter = 0

au BufEnter * call <SID>add_jump()
au TabEnter * let s:jump_counter += 1 | let t:ctrlspace_tablist_jump_counter = s:jump_counter

if g:ctrlspace_save_workspace_on_exit
  au VimLeavePre * if !empty(s:active_workspace_name) | call <SID>save_workspace_externally("") | endif
endif

if g:ctrlspace_load_last_workspace_on_start
  au VimEnter * nested if (argc() == 0) && !empty(<SID>find_project_root()) | call <SID>load_workspace_externally(0, "") | endif
endif
