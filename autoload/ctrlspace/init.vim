" 
" Init ctrlspace called by plugin/ctrlspace.vim
"

let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

" FUNCTION: ctrlspace#init#Init() {{{
function! ctrlspace#init#Init()
    if s:config.UseTabline
        set tabline=%!ctrlspace#api#Tabline()

        if has("gui_running") && (&go =~# "e")
            set guitablabel=%{ctrlspace#api#Guitablabel()}

            " Fix MacVim issues:
            " http://stackoverflow.com/questions/11595301/controlling-tab-names-in-vim
            au BufEnter * set guitablabel=%{ctrlspace#api#Guitablabel()}
        endif
    endif

    command! -nargs=* -range CtrlSpace :call ctrlspace#window#Toggle(0) | :call feedkeys(<q-args>)
    command! -nargs=0 -range CtrlSpaceGoUp :call ctrlspace#window#GoToBufferListPosition("up")
    command! -nargs=0 -range CtrlSpaceGoDown :call ctrlspace#window#GoToBufferListPosition("down")
    command! -nargs=0 -range CtrlSpaceTabLabel :call ctrlspace#tabs#NewTabLabel(0)
    command! -nargs=0 -range CtrlSpaceClearTabLabel :call ctrlspace#tabs#RemoveTabLabel(0)
    command! -nargs=0 -range CtrlSpaceSaveWorkspace :call ctrlspace#workspaces#AddNewWorkspace()
    command! -nargs=0 -range CtrlSpaceNewWorkspace :call ctrlspace#workspaces#ClearWorkspace()
    command! -nargs=* -range -bang CtrlSpaceLoadWorkspace :call ctrlspace#workspaces#LoadWorkspaceFile(<bang>0, <q-args>)
    command! -nargs=* -range -complete=dir CtrlSpaceAddProjectRoot :call ctrlspace#roots#AddProjectRoot(<q-args>)
    command! -nargs=+ -complete=customlist,ctrlspace#roots#GetProjectRootCompletion CtrlSpaceRemoveProjectRoot :call ctrlspace#roots#RemoveProjectRoot(<f-args>)

    hi def link CtrlSpaceNormal   PMenu
    hi def link CtrlSpaceSelected PMenuSel
    hi def link CtrlSpaceSearch   Search
    hi def link CtrlSpaceStatus   StatusLine

    if s:config.SetDefaultMapping
        call ctrlspace#keys#SetDefaultMapping(s:config.DefaultMappingKey, ":CtrlSpace<CR>")
    endif

    call s:initProjectRootsAndBookmarks()
    call ctrlspace#keys#Init()

    au BufRead  * call ctrlspace#workspaces#FindExistedWorkspace()
    au BufEnter * call ctrlspace#buffers#AddBuffer()
    au VimEnter * call ctrlspace#buffers#Init()
    au TabEnter * let t:CtrlSpaceTabJumpCounter = ctrlspace#jumps#IncrementJumpCounter()

    if s:config.SaveWorkspaceOnExit
        au VimLeavePre * if ctrlspace#workspaces#ActiveWorkspace().Status | call ctrlspace#workspaces#SaveWorkspaceFile("") | endif
    endif

    if s:config.LoadLastWorkspaceOnStart
        au VimEnter * nested if (argc() == 0) && !empty(ctrlspace#roots#FindProjectRoot()) | call ctrlspace#workspaces#LoadWorkspaceFile(0, "") | endif
    endif
endfunction
" }}}

" FUNCTION: s:initProjectRootsAndBookmarks() {{{
function! s:initProjectRootsAndBookmarks()
    let cacheFile    = s:config.CacheDir . "/.cs_cache"
    let projectRoots = {}
    let cache_bookmarks    = []
    let cache_workspaces   = []

    " Parse .cs_data
    if filereadable(cacheFile)
        for line in readfile(cacheFile)
            " Find all project root dirctories
            if line =~# "CS_PROJECT_ROOT: "
                let projectRoots[line[17:]] = 1
            endif

            " Find all bookmark items.
            if line =~# "CS_BOOKMARK: "
                let parts = split(line[13:], ctrlspace#context#Separator())
                " Filename and directory of bookmark are both required.
                if len(parts) >  1
                    let bookmark = {
                                \ "Name"        : parts[1],
                                \ "Directory"   : parts[0],
                                \ "JumpCounter" : 0
                                \ }
                    call add(cache_bookmarks, bookmark)
                endif
            endif

            " Find all workspace items.
            if line =~# "CS_WORKSPACE: "
                let parts = split(line[14:], ctrlspace#context#Separator())
                " Workspace name and directory of workspace are both required.
                if len(parts) > 1
                    let workspace = {
                                \ "Name"      : parts[1],
                                \ "Directory" : parts[0],
                                \ }
                    call add(cache_workspaces, workspace)
                    let projectRoots[workspace.Directory] = 1
                endif
            endif
        endfor
    endif

    call ctrlspace#roots#SetProjectRoots(projectRoots)
    call ctrlspace#bookmarks#SetBookmarks(cache_bookmarks)
    call ctrlspace#workspaces#SetCacheWorkspaces(cache_workspaces)
endfunction
" }}}
