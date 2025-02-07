function! ctrlspace#util#system(cmd, ...) abort
    if has('win32') && &shell !~? 'cmd'
        let saved_shell = [
            \ &shell,
            \ &shellcmdflag,
            \ &shellxquote,
            \ &shellxescape,
            \ &shellquote,
            \ &shellpipe,
            \ &shellredir,
            \ &shellslash
            \]
        set shell& shellcmdflag& shellxquote& shellxescape&
        set shellquote& shellpipe& shellredir& shellslash&
    endif

    let output = a:0 > 0 ? system(a:cmd, a:1) : system(a:cmd)

    if exists('saved_shell')
        let [ &shell,
            \ &shellcmdflag,
            \ &shellxquote,
            \ &shellxescape,
            \ &shellquote,
            \ &shellpipe,
            \ &shellredir,
            \ &shellslash ] = saved_shell
    endif

    return has('win32') ? substitute(output, "\r", '', 'g') : output
endfunction

function! ctrlspace#util#NormalizeDirectory(directory) abort
    let directory = resolve(expand(a:directory))

    while directory[strlen(directory) - 1] ==# "/" || directory[strlen(directory) - 1] ==# "\\"
        let directory = directory[0:-2]
    endwhile

    return directory
endfunction

function! ctrlspace#util#HandleVimSettings(switch) abort
    call s:handleSwitchbuf(a:switch)
    call s:handleAutochdir(a:switch)
endfunction

function! s:handleSwitchbuf(switch) abort
    if (a:switch ==# "start") && !empty(&swb)
        let s:swbSave = &swb
        set swb=
    elseif (a:switch ==# "stop") && exists("s:swbSave")
        let &swb = s:swbSave
        unlet s:swbSave
    endif
endfunction

function! s:handleAutochdir(switch) abort
    if (a:switch ==# "start") && &acd
        let s:acdWasOn = 1
        set noacd
    elseif (a:switch ==# "stop") && exists("s:acdWasOn")
        set acd
        unlet s:acdWasOn
    endif
endfunction

function! ctrlspace#util#WorkspaceFile() abort
    let config = ctrlspace#context#Configuration()
    return filereadable(config.WorkspaceFile) ? config.WorkspaceFile : s:internalFilePath("cs_workspaces")
endfunction

function! ctrlspace#util#FilesCache() abort
    return s:internalFilePath("cs_files")
endfunction

function! ctrlspace#util#ChDir(dir) abort
    let dir    = fnameescape(a:dir)
    let curtab = tabpagenr()
    let curwin = winnr()

    silent! exe "cd " . dir

    for t in range(1, tabpagenr("$"))
        silent! exe "noautocmd tabnext " . t

        for w in range(1, winnr("$"))
            silent! exe "noautocmd " . w . "wincmd w"

            if haslocaldir()
                silent! exe "lcd " . dir
            endif
        endfor
    endfor

    silent! exe "noautocmd tabnext " . curtab
    silent! exe "noautocmd " . curwin . "wincmd w"
endfunction

function! s:internalFilePath(name) abort
    let config = ctrlspace#context#Configuration()
    let root = ctrlspace#roots#CurrentProjectRoot()
    let fullPart = empty(root) ? "" : (root . "/")

    if !empty(config.ProjectRootMarkers)
        for candidate in config.ProjectRootMarkers
            let candidatePath = fullPart . candidate

            if isdirectory(candidatePath)
                return candidatePath . "/" . a:name
            endif
        endfor
    endif

    return fullPart . "." . a:name
endfunction

" Workaround for a Vim bug after :only and e.g. help window:
" for the first time after :only gettabvar cannot properly ready any tab variable
" More info: https://github.com/vim/vim/issues/394
" TODO Remove when decided to drop support for Vim 7.3
function! ctrlspace#util#Gettabvar(nr, name) abort
    let value = gettabvar(a:nr, a:name)

    if type(value) == 1 && empty(value)
        unlet value
        let value = gettabvar(a:nr, a:name)
    endif

    return value
endfunction

function! ctrlspace#util#GettabvarWithDefault(nr, name, default) abort
    let value = ctrlspace#util#Gettabvar(a:nr, a:name)
    return type(value) == 1 && empty(value) ? a:default : value
endfunction

function! ctrlspace#util#GetbufvarWithDefault(nr, name, default) abort
    let value = getbufvar(a:nr, a:name)
    return type(value) == 1 && empty(value) ? a:default : value
endfunction

function! ctrlspace#util#SetStatusline() abort
    if has("statusline")
        let config = ctrlspace#context#Configuration()
        silent! exe "let &l:statusline = " . config.StatuslineFunction
    endif
endfunction
