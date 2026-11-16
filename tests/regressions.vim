" Regression tests for buffer, file, bookmark, root and workspace operations.
" Shared by Vim9 and Neovim. Run through tests/run.sh.
set nocompatible hidden encoding=utf-8 nomore noswapfile
scriptencoding utf-8

let s:repo = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:temp = resolve(empty($CTRLSPACE_TEST_TMP) ? tempname() : $CTRLSPACE_TEST_TMP)
let s:project = s:temp . '/project'
let s:original_cwd = getcwd()
let s:original_path = $PATH
let s:original_shell = &shell
let s:original_home = $HOME
let s:groups = []
call mkdir(s:project . '/.git', 'p')
call mkdir(s:temp . '/cache', 'p')
call mkdir(s:temp . '/empty-bin', 'p')
execute 'set runtimepath^=' . fnameescape(s:repo)

let g:CtrlSpaceCacheDir = s:temp . '/cache'
let g:CtrlSpaceEnableFilesCache = empty($CTRLSPACE_TEST_CACHE) ? 1 : str2nr($CTRLSPACE_TEST_CACHE)
let g:CtrlSpaceSetDefaultMapping = 0
let g:CtrlSpaceUseTabline = 0
let g:CtrlSpaceProjectRootMarkers = ['.git']
let g:CtrlSpaceGlobCommand = ''

" Use the native globber, and make any accidental shell call fail.
let $PATH = s:temp . '/empty-bin'
let &shell = s:temp . '/nonexistent-shell'

runtime plugin/ctrlspace.vim
let s:modes = ctrlspace#modes#Modes()

" Replace prompts and messages with scripted answers and a message log.
runtime autoload/ctrlspace/ui.vim
let g:answers = []
let g:prompts = []
let g:messages = []

function! ctrlspace#ui#GetInput(msg, ...) abort
    call add(g:prompts, a:msg)
    call assert_false(empty(g:answers), 'unexpected prompt: ' . a:msg)
    return empty(g:answers) ? '' : remove(g:answers, 0)
endfunction

function! ctrlspace#ui#Msg(message) abort
    call add(g:messages, a:message)
endfunction

function! s:Reset() abort
    if bufexists(ctrlspace#context#PluginBuffer())
        call ctrlspace#window#Kill(ctrlspace#context#PluginBuffer(), 1)
    endif
    silent! tabonly!
    silent! only!
    silent! %bwipeout!
    let g:answers = []
    let g:prompts = []
    let g:messages = []
    call s:modes.Zoom.Disable()
    call s:modes.Search.SetData('Letters', [])
    execute 'cd ' . fnameescape(s:project)
    call ctrlspace#roots#SetCurrentProjectRoot(s:project)
    call ctrlspace#roots#SetLastProjectRoot(s:project)
endfunction

function! s:Write(name, ...) abort
    call writefile(a:0 ? a:1 : ['fixture: ' . a:name], s:project . '/' . a:name)
    return s:project . '/' . a:name
endfunction

" Open the list in a:mode and put the selection bar on the item a:index.
function! s:OpenAndSelect(mode, index) abort
    call ctrlspace#window#Toggle(0)
    if a:mode !=# 'Buffer'
        call call(function('ctrlspace#keys#common#Toggle' . a:mode . 'Mode'), [''])
    endif
    let line = index(b:indices, a:index) + 1
    call assert_true(line > 0, a:mode . ' list contains item ' . a:index)
    call ctrlspace#window#MoveSelectionBar(line)
    call assert_equal(a:index, ctrlspace#window#SelectedIndex())
endfunction

function! s:Close() abort
    if bufexists(ctrlspace#context#PluginBuffer())
        call ctrlspace#window#Kill(ctrlspace#context#PluginBuffer(), 1)
    endif
endfunction

function! s:Run(name) abort
    let errors = len(v:errors)
    try
        call s:Reset()
        call call('s:Test' . substitute(a:name, ' ', '', 'g'), [])
    catch
        call assert_report(a:name . ': ' . v:exception . ' at ' . v:throwpoint)
    finally
        call s:Close()
    endtry
    if len(v:errors) == errors
        call add(s:groups, a:name)
    endif
endfunction

" Buffers listed before startup are registered even after an unlisted one.
function! s:TestBufferInit() abort
    badd first-listed.txt
    badd unlisted.txt
    call setbufvar(bufnr('unlisted.txt'), '&buflisted', 0)
    badd last-listed.txt
    call ctrlspace#buffers#Init()
    let all = ctrlspace#buffers#Buffers(0)
    call assert_true(has_key(all, bufnr('first-listed.txt')))
    call assert_true(has_key(all, bufnr('last-listed.txt')), 'an unlisted buffer must not stop registration')
    call assert_false(has_key(all, bufnr('unlisted.txt')))
endfunction

" Deleting a buffer shown twice in another tab, and forgetting it everywhere.
function! s:TestDeleteBuffer() abort
    execute 'edit ' . fnameescape(s:Write('keep.txt'))
    let keep = bufnr('%')
    execute 'edit ' . fnameescape(s:Write('doomed.txt'))
    let doomed = bufnr('%')
    execute 'buffer ' . keep
    tabnew
    execute 'buffer ' . doomed
    split
    tabnew
    execute 'buffer ' . doomed
    execute 'edit ' . fnameescape(s:Write('other.txt'))
    tabfirst

    call s:OpenAndSelect('Buffer', doomed)
    call ctrlspace#buffers#DeleteBuffer()
    call s:Close()

    call assert_false(buflisted(doomed))
    call assert_equal(-1, index(tabpagebuflist(2), doomed), 'no window of tab 2 shows the deleted buffer')
    for t in range(1, tabpagenr('$'))
        call assert_false(has_key(gettabvar(t, 'CtrlSpaceList', {}), doomed), 'tab ' . t . ' forgets the deleted buffer')
    endfor
    execute 'buffer ' . doomed
    call assert_false(has_key(ctrlspace#buffers#Buffers(3), doomed), 'a relisted buffer does not reappear in other tabs')
endfunction

" Copy a buffer that has no file yet.
function! s:TestCopyBuffer() abort
    edit draft-only-buffer.txt
    call setline(1, ['draft line'])
    let draft = bufnr('%')
    call s:OpenAndSelect('Buffer', draft)
    let g:answers = ['copy-of-draft.txt']
    call ctrlspace#files#CopyFileOrBuffer()
    call s:Close()
    call assert_equal(1, bufexists('copy-of-draft.txt'))
    call assert_equal(['draft line'], getbufline(bufnr('copy-of-draft.txt'), 1, '$'))
endfunction

function! s:ProjectFiles() abort
    call delete(s:project . '/.git/cs_files')
    call ctrlspace#files#ClearAll()
    for i in range(160)
        call s:Write(printf('file-%03d.txt', i))
    endfor
endfunction

" Removing a file keeps every remaining list entry pointing at its own file,
" and in the File list never touches the buffer numbered like the file index.
function! s:TestRemoveFileInFileList() abort
    call s:ProjectFiles()
    execute 'edit ' . fnameescape(s:temp . '/unrelated-buffer.txt')
    let unrelated = bufnr('%')
    call ctrlspace#files#CollectFiles()
    call assert_true(unrelated < len(ctrlspace#files#Files()))
    let victim = ctrlspace#files#Files()[unrelated]
    call s:OpenAndSelect('File', unrelated)
    let g:answers = ['y']
    call ctrlspace#files#RemoveFile()
    call s:Close()
    call assert_false(filereadable(s:project . '/' . victim))
    call assert_true(buflisted(unrelated), 'removing a file must not delete the buffer numbered like its index')
    call assert_equal(-1, index(ctrlspace#files#Files(), victim))
    let files = ctrlspace#files#Files()
    let mismatched = filter(copy(ctrlspace#files#Items()), 'get(files, v:val.index, "") !=# v:val.text')
    call assert_equal([], mismatched, 'list entries keep identifying their own files')
endfunction

" Removing the file of a modified buffer is aborted when the buffer is kept.
function! s:TestRemoveFileDeclined() abort
    let path = s:Write('precious.txt')
    execute 'edit ' . fnameescape(path)
    call setline(1, 'unsaved change')
    let precious = bufnr('%')
    enew
    call s:OpenAndSelect('Buffer', precious)
    let g:answers = ['y', 'n']
    call ctrlspace#files#RemoveFile()
    call s:Close()
    call assert_equal(2, len(g:prompts))
    call assert_true(filereadable(path), 'declining to drop unsaved changes keeps the file')
    call assert_true(buflisted(precious))
endfunction

" A failed workspace load restores 'switchbuf' and 'autochdir'.
function! s:TestLoadWorkspaceRestoresSettings() abort
    call delete(s:project . '/.git/cs_workspaces')
    set switchbuf=useopen
    set autochdir
    try
        call assert_equal(0, ctrlspace#workspaces#LoadWorkspace(0, 'missing'))
        call assert_equal('useopen', &switchbuf, 'without a workspace file')
        call assert_equal(1, &autochdir, 'without a workspace file')
        call writefile(['CS_WORKSPACE_BEGIN: present', 'CS_WORKSPACE_END: present'], s:project . '/.git/cs_workspaces')
        call assert_equal(0, ctrlspace#workspaces#LoadWorkspace(0, 'missing'))
        call assert_equal('useopen', &switchbuf, 'with an unknown workspace name')
        call assert_equal(1, &autochdir, 'with an unknown workspace name')
    finally
        set switchbuf& noautochdir
        execute 'cd ' . fnameescape(s:project)
        call delete(s:project . '/.git/cs_workspaces')
    endtry
endfunction

" Bookmarked directories are not persisted as permanent project roots.
function! s:TestProjectRootsAndBookmarks() abort
    let cache = g:CtrlSpaceCacheDir . '/.cs_cache'
    let bookmarked = s:temp . '/bookmarked'
    let rooted = s:temp . '/rooted'
    call mkdir(bookmarked, 'p')
    call mkdir(rooted, 'p')
    let saved_roots = ctrlspace#roots#ProjectRoots()
    let saved_bookmarks = ctrlspace#bookmarks#Bookmarks()
    try
        call writefile(['CS_BOOKMARK: ' . bookmarked . ctrlspace#context#Separator() . 'BM',
                    \ 'CS_PROJECT_ROOT: ' . rooted, 'UNRELATED LINE'], cache)
        call ctrlspace#roots#SetProjectRoots({bookmarked : 1, rooted : 1})
        call ctrlspace#bookmarks#SetBookmarks([{'Name': 'BM', 'Directory': bookmarked, 'JumpCounter': 0}])

        call ctrlspace#roots#RemoveProjectRoot(rooted)
        let lines = readfile(cache)
        call assert_equal(-1, index(lines, 'CS_PROJECT_ROOT: ' . bookmarked), 'removing a root persists no bookmark as a root')
        call assert_equal(-1, index(lines, 'CS_PROJECT_ROOT: ' . rooted))
        call assert_true(index(lines, 'UNRELATED LINE') >= 0)
        call assert_true(index(lines, 'CS_BOOKMARK: ' . bookmarked . ctrlspace#context#Separator() . 'BM') >= 0)

        let g:answers = ['y']
        call ctrlspace#bookmarks#RemoveBookmark(0)
        call assert_false(has_key(ctrlspace#roots#ProjectRoots(), bookmarked), 'a deleted bookmark is no longer a project root')
        call ctrlspace#roots#AddProjectRoot(rooted)
        call assert_equal(['UNRELATED LINE', 'CS_PROJECT_ROOT: ' . rooted], readfile(cache))
    finally
        call ctrlspace#roots#SetProjectRoots(saved_roots)
        call ctrlspace#bookmarks#SetBookmarks(saved_bookmarks)
        call delete(cache)
    endtry
endfunction

" Labels and buffers of every tab survive a save and load, also when the
" first tab shows an unnamed buffer.
function! s:TestWorkspaceTabs() abort
    call delete(s:project . '/.git/cs_workspaces')
    let first = s:Write('ws-first.txt')
    let second = s:Write('ws second.txt')
    enew
    tabnew
    execute 'edit ' . fnameescape(first)
    call ctrlspace#tabs#SetTabLabel(2, 'Second', 0)
    tabnew
    execute 'edit ' . fnameescape(second)
    call ctrlspace#tabs#SetTabLabel(3, "Third's", 1)
    call assert_equal(1, ctrlspace#workspaces#SaveWorkspace('tabs'))

    call assert_equal(1, ctrlspace#workspaces#LoadWorkspace(0, 'tabs'))
    call assert_equal(3, tabpagenr('$'))
    call assert_equal('Second', gettabvar(2, 'CtrlSpaceLabel'))
    call assert_equal("Third's", gettabvar(3, 'CtrlSpaceLabel'))
    call assert_equal(1, gettabvar(3, 'CtrlSpaceAutotab', 0))
    call assert_equal(['ws-first.txt'], map(values(ctrlspace#api#Buffers(2)), 'fnamemodify(v:val, ":t")'))
    call assert_equal(['ws second.txt'], map(values(ctrlspace#api#Buffers(3)), 'fnamemodify(v:val, ":t")'))
    call assert_equal(second, fnamemodify(bufname(tabpagebuflist(3)[0]), ':p'))
    call delete(s:project . '/.git/cs_workspaces')
endfunction

" A custom workspace file outside the project still saves and loads.
function! s:TestCustomWorkspaceFile() abort
    let config = ctrlspace#context#Configuration()
    let saved_file = config.WorkspaceFile
    let config.WorkspaceFile = s:temp . '/custom-workspaces'
    call writefile([], config.WorkspaceFile)
    try
        let path = s:Write('custom.txt')
        execute 'edit ' . fnameescape(path)
        call ctrlspace#tabs#SetTabLabel(1, 'Custom', 0)
        call assert_equal(1, ctrlspace#workspaces#SaveWorkspace('custom'))
        execute 'cd ' . fnameescape(s:temp)
        enew
        call assert_equal(1, ctrlspace#workspaces#LoadWorkspace(0, 'custom'))
        call assert_equal('Custom', gettabvar(1, 'CtrlSpaceLabel'))
        call assert_equal(path, expand('%:p'))
    finally
        let config.WorkspaceFile = saved_file
    endtry
endfunction

" Workspaces saved with 'let t:' tab variables still load in Vim9 sessions.
function! s:TestLegacyTabVariables() abort
    let path = s:Write('legacy.txt')
    call writefile(['CS_WORKSPACE_BEGIN: legacy', 'vim9script',
                \ 'edit ' . fnameescape(path),
                \ "let t:CtrlSpaceLabel = 'It''s legacy'",
                \ 'let t:ctrlspace_autotab = 1',
                \ 'CS_WORKSPACE_END: legacy'], s:project . '/.git/cs_workspaces')
    if has('nvim')
        " Neovim cannot source Vim9 script; legacy sessions must keep working.
        call writefile(filter(readfile(s:project . '/.git/cs_workspaces'), 'v:val !=# "vim9script"'),
                    \ s:project . '/.git/cs_workspaces')
    endif
    call assert_equal(1, ctrlspace#workspaces#LoadWorkspace(0, 'legacy'))
    call assert_equal("It's legacy", gettabvar(1, 'CtrlSpaceLabel'))
    call assert_equal(1, gettabvar(1, 'CtrlSpaceAutotab', 0))
    call delete(s:project . '/.git/cs_workspaces')
endfunction

" A project root entered at the prompt is expanded and normalized.
function! s:TestPromptedProjectRoot() abort
    let $HOME = s:temp . '/home'
    let saved_roots = copy(ctrlspace#roots#ProjectRoots())
    let config = ctrlspace#context#Configuration()
    let saved_markers = config.ProjectRootMarkers
    " No root may be found above the temporary directory, wherever it is.
    let config.ProjectRootMarkers = ['.no-such-ctrlspace-marker']
    call ctrlspace#roots#SetProjectRoots({})
    call mkdir($HOME . '/elsewhere', 'p')
    try
        execute 'cd ' . fnameescape($HOME . '/elsewhere')
        call ctrlspace#roots#SetCurrentProjectRoot('')
        let g:answers = ['~/elsewhere/']
        call assert_equal(1, ctrlspace#roots#ProjectRootFound())
        call assert_equal($HOME . '/elsewhere', ctrlspace#roots#CurrentProjectRoot())
    finally
        let $HOME = s:original_home
        let config.ProjectRootMarkers = saved_markers
        call ctrlspace#roots#SetProjectRoots(saved_roots)
        call delete(g:CtrlSpaceCacheDir . '/.cs_cache')
    endtry
endfunction

" The duplicate-directory message names the bookmark that owns it.
function! s:TestBookmarkDirectoryConflict() abort
    let saved_bookmarks = ctrlspace#bookmarks#Bookmarks()
    try
        call ctrlspace#bookmarks#SetBookmarks([
                    \ {'Name': 'Alpha', 'Directory': s:project, 'JumpCounter': 0},
                    \ {'Name': 'Beta', 'Directory': s:temp, 'JumpCounter': 0}])
        let g:answers = [s:temp]
        call assert_equal(0, ctrlspace#bookmarks#ChangeBookmarkDirectory(0))
        call assert_match("under name 'Beta'", g:messages[-1])
    finally
        call ctrlspace#bookmarks#SetBookmarks(saved_bookmarks)
    endtry
endfunction

try
    call assert_equal(2, exists(':CtrlSpace'), 'plugin initialized')
    for s:name in ['Buffer Init', 'Delete Buffer', 'Copy Buffer',
                \ 'Remove File In File List', 'Remove File Declined',
                \ 'Load Workspace Restores Settings', 'Project Roots And Bookmarks',
                \ 'Workspace Tabs', 'Custom Workspace File', 'Legacy Tab Variables', 'Prompted Project Root',
                \ 'Bookmark Directory Conflict']
        call s:Run(s:name)
    endfor
finally
    let $PATH = s:original_path
    let &shell = s:original_shell
    let $HOME = s:original_home
    execute 'cd ' . fnameescape(s:original_cwd)
endtry

if !empty(v:errors)
    call writefile(v:errors, s:temp . '/result.txt')
    cquit
endif
call writefile(['PASS: ' . join(s:groups, ', ')], s:temp . '/result.txt')
qa!
