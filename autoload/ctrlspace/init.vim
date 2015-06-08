let s:config = g:ctrlspace#context#Configuration.Instance()

function! ctrlspace#init#Initialize()
  if s:config.UseTabline
    set tabline=%!ctrlspace#api#Tabline()

    if has("gui_running") && (&go =~# "e")
      set guitablabel=%{ctrlspace#api#Guitablabel()}

      " Fix MacVim issues:
      " http://stackoverflow.com/questions/11595301/controlling-tab-names-in-vim
      au BufEnter * set guitablabel=%{ctrlspace#api#Guitablabel()}
    endif
  endif

  command! -nargs=* -range CtrlSpace :call ctrlspace#window#StartAndFeedkeys(<q-args>)
  command! -nargs=0 -range CtrlSpaceGoUp :call ctrlspace#window#GoToBufferListPosition("up")
  command! -nargs=0 -range CtrlSpaceGoDown :call ctrlspace#window#GoToBufferListPosition("down")
  command! -nargs=0 -range CtrlSpaceTabLabel :call ctrlspace#tabs#NewTabLabel(0)
  command! -nargs=0 -range CtrlSpaceClearTabLabel :call ctrlspace#tabs#RemoveTabLabel(0)
  command! -nargs=* -range CtrlSpaceSaveWorkspace :call ctrlspace#workspaces#SaveWorkspace(<q-args>)
  command! -nargs=0 -range CtrlSpaceNewWorkspace :call ctrlspace#workspaces#NewWorkspace()
  command! -nargs=* -range -bang CtrlSpaceLoadWorkspace :call ctrlspace#workspaces#LoadWorkspace(<bang>0, <q-args>)
  command! -nargs=* -range -complete=dir CtrlSpaceAddProjectRoot :call ctrlspace#roots#AddProjectRoot(<q-args>)
  command! -nargs=* -range -complete=dir CtrlSpaceRemoveProjectRoot :call ctrlspace#roots#RemoveProjectRoot(<q-args>)

  hi def link CtrlSpaceNormal   Normal
  hi def link CtrlSpaceSelected Visual
  hi def link CtrlSpaceSearch   IncSearch
  hi def link CtrlSpaceStatus   StatusLine

  if s:config.SetDefaultMapping
    call ctrlspace#keys#SetDefaultMapping(s:config.DefaultMappingKey, ":CtrlSpace<CR>")
  endif

  call s:initProjectRootsAndBookmarks()
  call ctrlspace#keys#InitKeyNames()

  au BufEnter * call ctrlspace#buffers#AddBuffer()
  au VimEnter * call ctrlspace#buffers#Initialize()
  au TabEnter * let t:CtrlSpaceTablistJumpCounter = ctrlspace#jumps#IncrementJumpCounter()

  if s:config.SaveWorkspaceOnExit
    au VimLeavePre * if !empty(g:ctrlspace#modes#Workspace.Data.Active.Name) | call ctrlspace#workspaces#SaveWorkspace("") | endif
  endif

  if s:config.LoadLastWorkspaceOnStart
    au VimEnter * nested if (argc() == 0) && !empty(ctrlspace#roots#FindProjectRoot()) | call ctrlspace#workspaces#LoadWorkspace(0, "") | endif
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
        let parts = split(line[13:], g:ctrlspace#context#Separator)
        let bookmark = {
              \ "Name": ((len(parts) > 1) ? parts[1] : parts[0]),
              \ "Directory": parts[0],
              \ "JumpCounter": 0
              \ }
        call add(bookmarks, bookmark)
        let projectRoots[bookmark.Directory] = 1
      endif
    endfor
  endif

  let g:ctrlspace#roots#ProjectRoots  = projectRoots
  let g:ctrlspace#bookmarks#Bookmarks = bookmarks
endfunction

