let s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#init#Initialize()
  if s:config.UseTabline
    set tabline=%!ctrlspace#api#tabline()

    if has("gui_running") && (&go =~# "e")
      set guitablabel=%{ctrlspace#api#guitablabel()}

      " Fix MacVim issues:
      " http://stackoverflow.com/questions/11595301/controlling-tab-names-in-vim
      au BufEnter * set guitablabel=%{ctrlspace#api#guitablabel()}
    endif
  endif

  command! -nargs=* -range CtrlSpace :call ctrlspace#ui#StartAndFeedkeys(<q-args>)
  command! -nargs=0 -range CtrlSpaceGoUp :call ctrlspace#ui#GoOutsideList("up")
  command! -nargs=0 -range CtrlSpaceGoDown :call ctrlspace#ui#GoOutsideList("down")
  command! -nargs=0 -range CtrlSpaceTabLabel :call ctrlspace#ui#NewTabLabel(0)
  command! -nargs=0 -range CtrlSpaceClearTabLabel :call ctrlspace#ui#RemoveTabLabel(0)
  command! -nargs=* -range CtrlSpaceSaveWorkspace :call ctrlspace#ui#SaveWorkspace(<q-args>)
  command! -nargs=0 -range CtrlSpaceNewWorkspace :call ctrlspace#ui#NewWorkspace()
  command! -nargs=* -range -bang CtrlSpaceLoadWorkspace :call ctrlspace#ui#LoadWorkspace(<bang>0, <q-args>)
  command! -nargs=* -range -complete=dir CtrlSpaceAddProjectRoot :call ctrlspace#ui#AddProjectRoot(<q-args>)
  command! -nargs=* -range -complete=dir CtrlSpaceRemoveProjectRoot :call ctrlspace#ui#RemoveProjectRoot(<q-args>)

  hi def link CtrlSpaceNormal   Normal
  hi def link CtrlSpaceSelected Visual
  hi def link CtrlSpaceSearch   IncSearch
  hi def link CtrlSpaceStatus   StatusLine

  if s:config.SetDefaultMapping
    call ctrlspace#context#SetDefaultMapping(s:config.DefaultMappingKey, ":CtrlSpace<CR>")
  endif

  call s:initProjectRootsAndBookmarks()
  call s:initKeyNames()

  au BufEnter * call s:addTabBuffer()
  au BufEnter * call s:add_jump()
  au TabEnter * let t:CtrlSpaceTablistJumpCounter = ctrlspace#context#IncrementJumpCounter()

  if s:config.SaveWorkspaceOnExit
    au VimLeavePre * if !empty(ctrlspace#context#ActiveWorkspace().Name) | call ctrlspace#ui#SaveWorkspace("") | endif
  endif

  if context.LoadLastWorkspaceOnStart
    au VimEnter * nested if (argc() == 0) && !empty(ctrlspace#roots#FindProjectRoot()) | call ctrlspace#ui#LoadWorkspace(0, "") | endif
  endif
endfunction

function! s:initProjectRootsAndBookmarks()
  let cacheFile    = s:config.CacheDir . "/.cs_cache"
  let projectRoots = {}
  let bookmarks    = []

  if filereadable(cacheFile)
    for line in readfile(cacheFile)
      if line =~# "CS_PROJECT_ROOT: "
        let projectRoots[line[17:]] = 1
      endif

      if line =~# "CS_BOOKMARK: "
        let parts = split(line[13:], s:CS_SEP)
        let bookmark = { "Name": ((len(parts) > 1) ? parts[1] : parts[0]), "Directory": parts[0], "JumpCounter": 0 }
        call add(bookmarks, bookmark)
        let projectRoots[bookmark.Directory] = 1
      endif
    endfor
  endif

  call ctrlspace#context#SetProjectRoots(projectRoots)
  call ctrlspace#context#SetBookmarks(bookmarks)
endfunction

function! s:initKeyNames()
  let lowercase = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
  let uppercase = toupper(lowercase)

  let controlList = []

  for l in split(lowercase, " ")
    call add(controlList, "C-" . l)
  endfor

  let controls = join(controlList, " ")

  let numbers  = "1 2 3 4 5 6 7 8 9 0"
  let specials = "Space CR BS Tab S-Tab / ? ; : , . < > [ ] { } ( ) ' ` ~ + - _ = ! @ # $ % ^ & * C-f C-b C-u C-d C-h C-w " .
               \ "Bar BSlash MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse " .
               \ "Down Up Home End Left Right PageUp PageDown " .
               \ 'F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 "'

  if !s:config.UseMouseAndArrowsInTerm || has("gui_running")
    let specials .= " Esc"
  endif

  let specials .= (has("gui_running") || has("win32")) ? " C-Space" : " Nul"

  let keyNames = split(join([lowercase, uppercase, controls, numbers, specials], " "), " ")

  " won't work with leader mappings
  if ctrlspace#context#IsDefaultKey()
    for i in range(0, len(keyNames) - 1)
      let fullKeyName = (strlen(keyNames[i]) > 1) ? ("<" . keyNames[i] . ">") : keyNames[i]

      if fullKeyName ==# ctrlspace#context#DefaultKey()
        call remove(keyNames, i)
        break
      endif
    endfor
  endif

  call ctrlspace#context#SetKeyNames(keyNames)
endfunction

function! s:addTabBuffer()
  if ctrlspace#context#Modes().Zoom
    return
  endif

  if !exists('t:CtrlSpaceList')
    let t:CtrlSpaceList = {}
  endif

  let current = bufnr('%')

  if !exists("t:CtrlSpaceList[" . current . "]") &&
        \ getbufvar(current, '&modifiable') &&
        \ getbufvar(current, '&buflisted') &&
        \ getbufvar(current, '&ft') != "ctrlspace"
    let t:CtrlSpaceList[current] = len(t:CtrlSpaceList) + 1
  endif
endfunction

function! s:addJump()
  if ctrlspace#context#Modes().Zoom
    return
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') &&
        \ getbufvar(current, '&buflisted') &&
        \ getbufvar(current, '&ft') != "ctrlspace"
    let b:CtrlSpaceJumpCounter = ctrlspace#context#IncrementJumpCounter()
  endif
endfunction
