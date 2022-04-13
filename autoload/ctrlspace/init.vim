let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#init#Init() abort
    augroup CtrlSpaceInit
        autocmd!
    augroup END

    if s:config.UseTabline
        set tabline=%!ctrlspace#api#Tabline()

        if has('gui_running') && (&guioptions =~# 'e')
            set guitablabel=%{ctrlspace#api#Guitablabel()}

            " Fix MacVim issues:
            " http://stackoverflow.com/questions/11595301/controlling-tab-names-in-vim
            if has('gui_macvim')
                autocmd CtrlSpaceInit BufWinEnter * set guitablabel=%{ctrlspace#api#Guitablabel()}
            endif
        endif
    endif

    command! -nargs=* -range CtrlSpace :call ctrlspace#window#Toggle(0) | :call feedkeys(<q-args>)
    command! -nargs=0 -range CtrlSpaceGoUp :call ctrlspace#window#GoToBufferListPosition("up")
    command! -nargs=0 -range CtrlSpaceGoDown :call ctrlspace#window#GoToBufferListPosition("down")
    command! -nargs=0 -range CtrlSpaceTabLabel :call ctrlspace#tabs#NewTabLabel(0)
    command! -nargs=0 -range CtrlSpaceClearTabLabel :call ctrlspace#tabs#RemoveTabLabel(0)
    command! -nargs=* -range CtrlSpaceSaveWorkspace :call ctrlspace#workspaces#SaveWorkspace(<q-args>)
    command! -nargs=0 -range CtrlSpaceNewWorkspace :call ctrlspace#workspaces#NewWorkspace()
    command! -nargs=* -range -bang CtrlSpaceLoadWorkspace :call ctrlspace#workspaces#LoadWorkspace(<bang>0, <q-args>)
    command! -nargs=* -range -complete=dir CtrlSpaceAddProjectRoot :call ctrlspace#roots#AddProjectRoot(<q-args>)
    command! -nargs=* -range -complete=dir CtrlSpaceRemoveProjectRoot :call ctrlspace#roots#RemoveProjectRoot(<q-args>)

    hi def link CtrlSpaceNormal   PMenu
    hi def link CtrlSpaceSelected PMenuSel
    hi def link CtrlSpaceSearch   Search
    hi def link CtrlSpaceStatus   StatusLine

    if s:config.SetDefaultMapping
        call ctrlspace#keys#SetDefaultMapping(s:config.DefaultMappingKey, ":CtrlSpace<CR>")
    endif

    call s:initProjectRootsAndBookmarks()
    call ctrlspace#keys#Init()

    if argc() > 1
        let curaltBuff=bufnr('#')
        let currBuff=bufnr('%')

        silent argdo call ctrlspace#buffers#AddBuffer()
        silent argdo silent echo ''
        
        if curaltBuff >= 0 
            execute 'buffer ' . curaltBuff
        endif
        execute 'buffer ' . currBuff
    endif

    autocmd CtrlSpaceInit BufEnter * call ctrlspace#buffers#AddBuffer()
    autocmd CtrlSpaceInit VimEnter * call ctrlspace#buffers#Init()
    autocmd CtrlSpaceInit TabEnter * let t:CtrlSpaceTabJumpCounter = ctrlspace#jumps#IncrementJumpCounter()

    if s:config.SaveWorkspaceOnExit
        autocmd CtrlSpaceInit VimLeavePre * if ctrlspace#workspaces#ActiveWorkspace().Status | call ctrlspace#workspaces#SaveWorkspace("") | endif
    endif

    if s:config.LoadLastWorkspaceOnStart
        autocmd CtrlSpaceInit VimEnter * nested if (argc() == 0) && !empty(ctrlspace#roots#FindProjectRoot()) | call ctrlspace#workspaces#LoadWorkspace(0, "") | endif
    endif
endfunction

function! s:initProjectRootsAndBookmarks() abort
    let cacheFile    = s:config.CacheDir . "/.cs_cache"
    let projectRoots = {}
    let bookmarks    = []

    if filereadable(cacheFile)
        for line in readfile(cacheFile)
            if line =~# "CS_PROJECT_ROOT: "
                let projectRoots[line[17:]] = 1
            endif

            if line =~# "CS_BOOKMARK: "
                let parts = split(line[13:], ctrlspace#context#Separator())
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

    call ctrlspace#roots#SetProjectRoots(projectRoots)
    call ctrlspace#bookmarks#SetBookmarks(bookmarks)
endfunction
