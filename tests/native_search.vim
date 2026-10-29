" Regression tests shared by Vim9 and Neovim. Run through tests/run.sh.
set nocompatible hidden encoding=utf-8 nomore noswapfile

let s:repo = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:temp = empty($CTRLSPACE_TEST_TMP) ? tempname() : $CTRLSPACE_TEST_TMP
let s:project = s:temp . '/project'
let s:original_cwd = getcwd()
let s:original_path = $PATH
let s:original_shell = &shell
let s:original_columns = &columns
let s:groups = []
call mkdir(s:project . '/.git', 'p')
call mkdir(s:temp . '/cache', 'p')
call mkdir(s:temp . '/empty-bin', 'p')
execute 'set runtimepath^=' . fnameescape(s:repo)

let g:CtrlSpaceCacheDir = s:temp . '/cache'
let g:CtrlSpaceEnableFilesCache = empty($CTRLSPACE_TEST_CACHE) ? 1 : str2nr($CTRLSPACE_TEST_CACHE)
let g:CtrlSpaceFileEngine = 'this-external-engine-must-never-run'
let g:CtrlSpaceSetDefaultMapping = 0
let g:CtrlSpaceUseTabline = 0
let g:CtrlSpaceMaxHeight = 4
let g:CtrlSpaceProjectRootMarkers = ['.git']
let g:CtrlSpaceGlobCommand = ''

" Exercise the native glob fallback, and make any accidental shell call fail.
" These changes affect only this disposable editor process.
let $PATH = s:temp . '/empty-bin'
let &shell = s:temp . '/nonexistent-shell'

function! s:Items(texts) abort
    return map(copy(a:texts), '{"index": v:key, "text": v:val, "indicators": ""}')
endfunction

function! s:Indices(items) abort
    return map(copy(a:items), 'v:val.index')
endfunction

function! s:SetQuery(query, enabled) abort
    call s:modes.Search.SetData('Letters', split(a:query, '\zs'))
    call s:modes.Search.SetData('NewSearchPerformed', 1)
    if a:enabled
        call s:modes.Search.Enable()
    else
        call s:modes.Search.Disable()
    endif
endfunction

function! s:TestMatcher() abort
    let items = [
                \ {'index': 17, 'text': 'same.vim', 'indicators': '*', 'kind': 'buffer'},
                \ {'index': 93, 'text': 'same.vim', 'indicators': '+', 'kind': 'file'}]
    let before = deepcopy(items)
    let found = ctrlspace#matcher#Search(items, 'SAME', 0)
    call assert_equal([17, 93], s:Indices(found), 'duplicate labels retain distinct identities and tie order')
    call assert_equal(['*', '+'], map(copy(found), 'v:val.indicators'))
    call assert_equal('buffer', found[0].kind)
    call assert_equal(v:t_number, type(found[0].score))
    let found[0].text = 'changed only in result'
    call assert_equal(before, items, 'matching and modifying a result must not mutate source items')

    let case_items = s:Items(['abc', 'AbC', 'ABC'])
    set noignorecase nosmartcase
    call assert_equal([0, 1, 2], sort(s:Indices(ctrlspace#matcher#Search(case_items, 'ABC', 0)), 'n'))
    set ignorecase smartcase
    call assert_equal([0, 1, 2], sort(s:Indices(ctrlspace#matcher#Search(case_items, 'ABC', 0)), 'n'))
    set noignorecase nosmartcase

    let words = s:Items(['one two', 'two one', 'onetwo', 'one   two'])
    call assert_equal([0, 3], sort(s:Indices(ctrlspace#matcher#Search(words, 'one two', 0)), 'n'), 'spaces are literal and word order is significant')

    for [text, query] in [['a[1].vim', '[1].'], ['a*b?c~d', '*?~'], ["a\"b'c\\d", "\"'\\"]]
        call assert_equal([0], s:Indices(ctrlspace#matcher#Search(s:Items([text, 'unrelated']), query, 0)), 'literal punctuation: ' . query)
    endfor

    let many = s:Items(map(range(520), 'printf("a_long_b_long_c_%04d.txt", v:val)'))
    call add(many, {'index': 9001, 'text': 'abc', 'indicators': ''})
    let before = deepcopy(many)
    let found = ctrlspace#matcher#Search(many, 'abc', 3)
    call assert_equal(3, len(found))
    call assert_equal(9001, found[0].index, 'a late best match must survive result limiting')
    call assert_equal(200, len(ctrlspace#matcher#Search(many, 'abc')))
    call assert_equal(521, len(ctrlspace#matcher#Search(many, 'abc', 0)))
    call assert_equal(521, len(ctrlspace#matcher#Search(many, 'abc', -1)))
    call assert_equal(before, many)

    let empty_query = ctrlspace#matcher#Search(items, '', 1)
    call assert_equal([17], s:Indices(empty_query))
    call assert_equal([], empty_query[0].positions)
    call assert_equal(0, empty_query[0].score)
    call assert_equal(2, len(ctrlspace#matcher#Search(items, '', 0)))
    call assert_equal([], ctrlspace#matcher#Search(items, 'no match', 0))
    call assert_equal([], ctrlspace#matcher#Search([], '', 0))
    call assert_equal([], ctrlspace#matcher#Search([], 'abc', 0))
    call add(s:groups, 'matcher')
endfunction

function! s:TestHighlights() abort
    let positions = [3, 0, 1, 1]
    call assert_equal([[2, 1, 5], [2, 7, 4]], ctrlspace#matcher#HighlightPositions('é界a😀x', positions, 2))
    call assert_equal([3, 0, 1, 1], positions, 'highlight conversion must not reorder source positions')
    call assert_equal([[3, 1, 3], [3, 7, 1], [3, 12, 1]], ctrlspace#matcher#HighlightPositions('é界a😀x', [0, 2, 4], 3))
    call assert_equal([], ctrlspace#matcher#HighlightPositions('anything', [], 1))

    for [text, expected] in [['é界a😀x', [[3, 6, 1], [3, 11, 1]]], ['é界a😀x', [[3, 7, 1], [3, 12, 1]]]]
        let found = ctrlspace#matcher#Search(s:Items([text]), 'AX', 0)
        call assert_equal(1, len(found))
        call assert_equal(expected, ctrlspace#matcher#HighlightPositions(text, found[0].positions, 3), 'native offsets must map to complete UTF-8 characters')
    endfor
    let spaced = ctrlspace#matcher#Search(s:Items(['one two']), 'one two', 0)
    call assert_equal([[1, 1, 7]], ctrlspace#matcher#HighlightPositions('one two', spaced[0].positions, 1))
    call add(s:groups, 'highlights')
endfunction

function! s:CreateProject() abort
    call mkdir(s:project . '/nested/empty-directory', 'p')
    let s:files = map(range(520), 'printf("a_n___e___e___d___l___e_%04d.txt", v:val)')
    call extend(s:files, ['needle', 'a[1].vim', "a\"b'c\\d", 'é界a😀x.txt', 'nested/readme.md'])
    for name in s:files
        call writefile(['fixture: ' . name], s:project . '/' . name)
    endfor
    call writefile(s:files, s:project . '/.git/cs_files')
    call writefile(['CS_WORKSPACE_BEGIN: Needle workspace', 'CS_WORKSPACE_END: Needle workspace',
                \ 'CS_WORKSPACE_BEGIN: Other workspace', 'CS_WORKSPACE_END: Other workspace'],
                \ s:project . '/.git/cs_workspaces')
    execute 'cd ' . fnameescape(s:project)
    call ctrlspace#roots#SetCurrentProjectRoot(s:project)
    call ctrlspace#roots#SetLastProjectRoot(s:project)
    call ctrlspace#workspaces#SetWorkspaceNames()
    call ctrlspace#bookmarks#SetBookmarks([
                \ {'Name': 'Needle project', 'Directory': s:project, 'JumpCounter': 0},
                \ {'Name': 'Other project', 'Directory': s:temp, 'JumpCounter': 0}])
endfunction

function! s:TestFileEngine() abort
    call assert_equal('', ctrlspace#context#Configuration().FileEngine, 'obsolete external engine settings cannot activate a binary')
    call s:modes.File.Enable()
    call ctrlspace#files#CollectFiles()
    let before = deepcopy(ctrlspace#files#Items())
    call assert_true(len(before) > 500)
    call assert_true(index(ctrlspace#files#Files(), 'nested/readme.md') >= 0, 'native globbing descends into directories')
    call assert_equal([], filter(copy(ctrlspace#files#Files()), 'isdirectory(v:val)'), 'file lists exclude directories')
    let exact_index = index(ctrlspace#files#Files(), 'needle')
    call assert_true(exact_index >= 500, 'the test exact match must occur beyond the unfiltered display cap')
    call s:SetQuery('NEEDLE', 0)
    let [highlights, indices, size, text] = ctrlspace#engine#Content()
    call assert_equal(200, size, 'matched list cap')
    call assert_equal(exact_index, indices[-1], 'best result is at the bottom of CtrlSpace')
    call assert_true(!empty(highlights))
    call assert_equal(before, ctrlspace#files#Items(), 'engine must not decorate cached source objects')

    call s:SetQuery('NEEDLE', 1)
    let [highlights, indices, size, text] = ctrlspace#engine#Content()
    call assert_equal(4, size, 'search view respects MaxHeight')
    call assert_equal(exact_index, indices[-1])
    call assert_equal(size, len(split(text, '\n')))

    call s:SetQuery('', 0)
    call assert_equal(500, ctrlspace#engine#Content()[2], 'unfiltered list cap')
    call s:SetQuery('never-matches-any-fixture', 1)
    call assert_equal([[], [], 0, ''], ctrlspace#engine#Content())

    call s:OpenSearch('File', 'NEEDLE')
    call writefile(['new fixture'], s:project . '/freshly-added.md')
    call delete(s:project . '/' . s:files[1])
    call ctrlspace#files#RefreshFiles()
    call ctrlspace#files#CollectFiles()
    let refreshed = ctrlspace#files#Files()
    call assert_true(index(refreshed, 'freshly-added.md') >= 0, 'refresh discovers added files')
    call assert_equal(-1, index(refreshed, s:files[1]), 'refresh removes deleted files')
    call assert_equal([], filter(copy(refreshed), 'isdirectory(v:val)'))
    call assert_equal(refreshed, map(copy(ctrlspace#files#Items()), 'v:val.text'), 'refreshed item text follows file order')
    call assert_equal(range(len(refreshed)), s:Indices(ctrlspace#files#Items()), 'refreshed indices still identify original files')
    call s:SetQuery('freshly-added.md', 1)
    let result = ctrlspace#engine#Content()
    call assert_equal('freshly-added.md', refreshed[result[1][-1]], 'search after refresh selects the new file identity')
    call ctrlspace#window#Kill(0, 1)
    call add(s:groups, 'file engine')
endfunction

function! s:TestCroppedHighlights() abort
    let saved_bookmarks = ctrlspace#bookmarks#Bookmarks()
    let saved_active = s:modes.Bookmark.Data.Active
    call s:modes.Bookmark.SetData('Active', {})
    let &columns = 24
    call ctrlspace#bookmarks#SetBookmarks([{'Name': repeat('界/', 30) . '終😀.txt', 'Directory': s:project}])
    call s:modes.Bookmark.Enable()
    call s:SetQuery('終😀', 1)
    let [highlights, indices, size, text] = ctrlspace#engine#Content()
    call assert_equal(1, size)
    let line = split(text, '\n')[0]
    call assert_equal(line, iconv(line, 'utf-8', 'utf-8'), 'cropping must preserve valid UTF-8')
    call assert_true(stridx(line, ctrlspace#context#Configuration().Symbols.Dots) >= 0)
    let highlighted = ''
    for position in highlights
        let highlighted .= strpart(line, position[1] - 1, position[2])
    endfor
    call assert_equal('終😀', highlighted, 'cropped highlights stay aligned with visible text')

    let config = ctrlspace#context#Configuration()
    let saved_dots = config.Symbols.Dots
    let config.Symbols.Dots = '..>'
    let long_name = 'prefix/' . repeat('界/', 30) . '終😀.txt'
    call ctrlspace#bookmarks#SetBookmarks([{'Name': long_name, 'Directory': s:project}])
    call s:SetQuery(long_name, 1)
    let [highlights, indices, size, text] = ctrlspace#engine#Content()
    let line = split(text, '\n')[0]
    call assert_equal(1, len(highlights), 'a matching run crossing the crop boundary stays contiguous')
    call assert_equal(3 + strlen(config.Symbols.Dots), highlights[0][1], 'custom ellipsis is excluded from highlighting')
    let visible_name = substitute(strpart(line, 2 + strlen(config.Symbols.Dots)), '\s\+$', '', '')
    call assert_equal(visible_name, strpart(line, highlights[0][1] - 1, highlights[0][2]))
    call assert_true(strdisplaywidth(line) <= &columns)
    call s:SetQuery('prefix', 1)
    call assert_equal([], ctrlspace#engine#Content()[0], 'matches removed by cropping do not highlight the ellipsis')
    let config.Symbols.Dots = saved_dots
    call ctrlspace#bookmarks#SetBookmarks(saved_bookmarks)
    call s:modes.Bookmark.SetData('Active', saved_active)
    let &columns = s:original_columns
    call add(s:groups, 'cropped Unicode')
endfunction

function! s:OpenSearch(mode, query) abort
    call ctrlspace#window#Toggle(0)
    if a:mode !=# 'Buffer'
        call call(function('ctrlspace#keys#common#Toggle' . a:mode . 'Mode'), [''])
    endif
    call ctrlspace#search#SwitchSearchMode(1)
    for letter in split(a:query, '\zs')
        call ctrlspace#search#AddSearchLetter(letter)
    endfor
    call ctrlspace#search#UpdateSearchResults()
endfunction

function! s:TestWindowsAndSelection() abort
    execute 'edit ' . fnameescape(s:project . '/needle')
    let needle_buffer = bufnr('%')
    call ctrlspace#tabs#SetTabLabel(1, 'Needle tab', 0)
    tabnew
    execute 'edit ' . fnameescape(s:project . '/' . s:files[0])
    call ctrlspace#tabs#SetTabLabel(2, 'Other tab', 0)
    tabfirst

    for mode in ['Buffer', 'File', 'Tab', 'Workspace', 'Bookmark']
        call s:OpenSearch(mode, 'NEEDLE')
        call assert_equal('ctrlspace', &filetype, mode . ' opens the CtrlSpace window')
        call assert_equal(mode, ctrlspace#modes#CurrentListView().Name)
        call assert_true(b:size > 0, mode . ' has a matching result')
        call assert_equal(b:size, line('.'), mode . ' selects the best result')
        call assert_true(!empty(filter(getmatches(), 'v:val.group ==# "CtrlSpaceSearch"')), mode . ' installs positional highlights')
        if mode ==# 'Buffer'
            call assert_equal(needle_buffer, ctrlspace#window#SelectedIndex())
        elseif mode ==# 'File'
            call assert_equal('needle', ctrlspace#files#SelectedFileName())
        elseif mode ==# 'Tab'
            call assert_equal(1, ctrlspace#window#SelectedIndex())
        elseif mode ==# 'Workspace'
            call assert_equal('Needle workspace', ctrlspace#workspaces#SelectedWorkspaceName())
        else
            call assert_equal(0, ctrlspace#window#SelectedIndex())
        endif
        call ctrlspace#window#Kill(0, 1)
    endfor

    " matchaddpos() accepts at most eight ranges per call. Exercise batching.
    call ctrlspace#bookmarks#SetBookmarks([{'Name': 'a-b-c-d-e-f-g-h-i-j-k-l', 'Directory': s:project, 'JumpCounter': 0}])
    call s:OpenSearch('Bookmark', 'abcdefghijkl')
    let matches = filter(getmatches(), 'v:val.group ==# "CtrlSpaceSearch"')
    call assert_equal(2, len(matches), 'twelve disjoint matches need two highlight groups')
    call ctrlspace#window#Kill(0, 1)

    call s:OpenSearch('File', 'NEEDLE')
    call ctrlspace#files#LoadFile()
    call assert_equal(s:project . '/needle', expand('%:p'), 'accepting the best match opens its original file')
    call assert_notequal('ctrlspace', &filetype)
    call add(s:groups, 'five list windows and file acceptance')
endfunction

try
    runtime plugin/ctrlspace.vim
    call assert_equal(2, exists(':CtrlSpace'), 'plugin initialized')
    let s:modes = ctrlspace#modes#Modes()
    call s:TestMatcher()
    call s:TestHighlights()
    call s:CreateProject()
    call s:TestFileEngine()
    call s:TestCroppedHighlights()
    call s:TestWindowsAndSelection()
catch
    call assert_report(v:exception . ' at ' . v:throwpoint)
finally
    let $PATH = s:original_path
    let &shell = s:original_shell
    let &columns = s:original_columns
    execute 'cd ' . fnameescape(s:original_cwd)
endtry

if !empty(v:errors)
    call writefile(v:errors, s:temp . '/result.txt')
    cquit
endif
call writefile(['PASS: ' . join(s:groups, ', ')], s:temp . '/result.txt')
qa!
