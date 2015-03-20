" Vim-CtrlSpace - Vim Workspace Controller
" Maintainer:   Szymon Wrozynski
" Version:      4.2.14
"
" The MIT License (MIT)

" Copyright (c) 2013-2015 Szymon Wrozynski <szymon@wrozynski.com> and Contributors
" Original BufferList plugin code - copyright (c) 2005 Robert Lillack <rob@lillack.de>

" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:

" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.

" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
"
" Usage:
" https://github.com/szw/vim-ctrlspace/blob/master/README.md

scriptencoding utf-8

if exists('g:ctrlspace_loaded')
  finish
endif

let g:ctrlspace_loaded = 1

function! <SID>define_config_variable(name, default_value)
  if !exists("g:ctrlspace_" . a:name)
    let g:{"ctrlspace_" . a:name} = a:default_value
  endif
endfunction

function! <SID>define_symbols()
  if g:ctrlspace_unicode_font
    let symbols = {
          \ "cs":      "⌗",
          \ "tab":     "∙",
          \ "all":     "፨",
          \ "vis":     "★",
          \ "file":    "⊚",
          \ "tabs":    "○",
          \ "c_tab":   "●",
          \ "ntm":     "⁺",
          \ "load":    "|∷|",
          \ "save":    "[∷]",
          \ "zoom":    "⌕",
          \ "s_left":  "›",
          \ "s_right": "‹",
          \ "bm":      "♥",
          \ "help":    "?",
          \ "iv":      "☆",
          \ "ia":      "★",
          \ "im":      "+",
          \ "dots":    "…"
          \ }
  else
    let symbols = {
          \ "cs":      "#",
          \ "tab":     "TAB",
          \ "all":     "ALL",
          \ "vis":     "VIS",
          \ "file":    "FILE",
          \ "tabs":    "-",
          \ "c_tab":   "+",
          \ "ntm":     "+",
          \ "load":    "|::|",
          \ "save":    "[::]",
          \ "zoom":    "*",
          \ "s_left":  "[",
          \ "s_right": "]",
          \ "bm":      "BM",
          \ "help":    "?",
          \ "iv":      "-",
          \ "ia":      "*",
          \ "im":      "+",
          \ "dots":    "..."
          \ }
  endif

  return symbols
endfunction

call <SID>define_config_variable("height", 1)
call <SID>define_config_variable("max_height", 0)
call <SID>define_config_variable("set_default_mapping", 1)
call <SID>define_config_variable("default_mapping_key", "<C-Space>")
call <SID>define_config_variable("use_ruby_bindings", 1)
call <SID>define_config_variable("glob_command", "")
call <SID>define_config_variable("use_tabline", 1)
call <SID>define_config_variable("use_mouse_and_arrows_in_term", 0)
call <SID>define_config_variable("statusline_function", "ctrlspace#statusline()")
call <SID>define_config_variable("cache_files", 1)
call <SID>define_config_variable("save_workspace_on_exit", 0)
call <SID>define_config_variable("save_workspace_on_switch", 0)
call <SID>define_config_variable("load_last_workspace_on_start", 0)
call <SID>define_config_variable("cache_dir", expand($HOME))

" make empty to disable
call <SID>define_config_variable("project_root_markers", [".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"])

call <SID>define_config_variable("unicode_font", 1)
call <SID>define_config_variable("symbols", <SID>define_symbols())
call <SID>define_config_variable("ignored_files", '\v(tmp|temp)[\/]') " in addition to 'wildignore' option
call <SID>define_config_variable("max_files", 500)
call <SID>define_config_variable("max_search_results", 200)
call <SID>define_config_variable("search_timing", [50, 500])
call <SID>define_config_variable("search_resonators", ['.', '/', '\', '_', '-'])

command! -nargs=* -range CtrlSpace :call <SID>start_ctrlspace_and_feedkeys(<q-args>)
command! -nargs=0 -range CtrlSpaceGoUp :call <SID>go_outside_list("up")
command! -nargs=0 -range CtrlSpaceGoDown :call <SID>go_outside_list("down")
command! -nargs=0 -range CtrlSpaceTabLabel :call <SID>new_tab_label(0)
command! -nargs=0 -range CtrlSpaceClearTabLabel :call <SID>remove_tab_label(0)
command! -nargs=* -range CtrlSpaceSaveWorkspace :call <SID>save_workspace_externally(<q-args>)
command! -nargs=0 -range CtrlSpaceNewWorkspace :call <SID>new_workspace_externally()
command! -nargs=* -range -bang CtrlSpaceLoadWorkspace :call <SID>load_workspace_externally(<bang>0, <q-args>)
command! -nargs=* -range -complete=dir CtrlSpaceAddProjectRoot :call <SID>add_project_root_ui(<q-args>)
command! -nargs=* -range -complete=dir CtrlSpaceRemoveProjectRoot :call <SID>remove_project_root_ui(<q-args>)

hi def link CtrlSpaceNormal   Normal
hi def link CtrlSpaceSelected Visual
hi def link CtrlSpaceSearch   IncSearch
hi def link CtrlSpaceStatus   StatusLine

function! <SID>set_default_mapping(key, action)
  let s:default_key = a:key
  if !empty(s:default_key)
    if s:default_key ==? "<C-Space>" && !has("gui_running") && !has("win32")
      let s:default_key = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . s:default_key . ' ' . a:action
  endif
endfunction

if g:ctrlspace_set_default_mapping
  call <SID>set_default_mapping(g:ctrlspace_default_mapping_key, ":CtrlSpace<CR>")
endif

let s:files                   = []
let s:zoom_mode               = 0
let s:key_esc_sequence        = 0
let s:active_workspace_name   = ""
let s:active_workspace_digest = ""
let s:workspace_names         = []
let s:last_active_workspace   = ""
let s:update_search_results   = 0
let s:last_project_root       = ""
let s:project_root            = ""
let s:symbol_sizes            = {}
let s:CS_SEP                  = "|CS_###_CS|"
let s:plugin_buffer           = -1

function! <SID>init_project_roots_and_bookmarks()
  let cache_file      = g:ctrlspace_cache_dir . "/.cs_cache"
  let s:project_roots = {}
  let s:bookmarks     = []

  if filereadable(cache_file)
    for line in readfile(cache_file)
      if line =~# "CS_PROJECT_ROOT: "
        let s:project_roots[line[17:]] = 1
      endif

      if line =~# "CS_BOOKMARK: "
        let parts = split(line[13:], s:CS_SEP)
        let bookmark = { "name": ((len(parts) > 1) ? parts[1] : parts[0]), "directory": parts[0], "jump_counter": 0 }
        call add(s:bookmarks, bookmark)
        let s:project_roots[bookmark.directory] = 1
      endif
    endfor
  endif
endfunction

call <SID>init_project_roots_and_bookmarks()

function! <SID>add_project_root_ui(directory)
  let directory = <SID>normalize_directory(empty(a:directory) ? getcwd() : a:directory)

  if !isdirectory(directory)
    call <SID>msg("Invalid directory: '" . directory . "'")
    return
  endif

  let roots = copy(s:project_roots)

  for bookmark in s:bookmarks
    let roots[bookmark.directory] = 1
  endfor

  if exists("roots[directory]")
    call <SID>msg("Directory is already a permanent project root!")
    return
  endif

  call <SID>add_project_root(directory)
  call <SID>msg("Directory '" . directory . "' has been added as a permanent project root.")
endfunction

function! <SID>remove_project_root_ui(directory)
  let directory = <SID>normalize_directory(empty(a:directory) ? getcwd() : a:directory)

  if !exists("s:project_roots[directory]")
    call <SID>msg("Directory '" . directory . "' is not a permanent project root!" )
    return
  endif

  call <SID>remove_project_root(directory)
  call <SID>msg("The project root '" . directory . "' has been removed.")
endfunction

function! <SID>remove_project_root(directory)
  let directory = <SID>normalize_directory(a:directory)

  if exists("s:project_roots[directory]")
    unlet s:project_roots[directory]
  endif

  let lines      = []
  let cache_file = g:ctrlspace_cache_dir . "/.cs_cache"

  if filereadable(cache_file)
    for old_line in readfile(cache_file)
      if old_line !~# "CS_PROJECT_ROOT: "
        call add(lines, old_line)
      endif
    endfor
  endif

  for root in keys(s:project_roots)
    call add(lines, "CS_PROJECT_ROOT: " . root)
  endfor

  call writefile(lines, cache_file)
endfunction

function! <SID>add_project_root(directory)
  let directory = <SID>normalize_directory(a:directory)
  let s:project_roots[directory] = 1

  let lines      = []
  let bm_roots   = {}
  let cache_file = g:ctrlspace_cache_dir . "/.cs_cache"

  for bookmark in s:bookmarks
    let bm_roots[bookmark.directory] = 1
  endfor

  if filereadable(cache_file)
    for old_line in readfile(cache_file)
      if old_line !~# "CS_PROJECT_ROOT: "
        call add(lines, old_line)
      endif
    endfor
  endif

  for root in keys(s:project_roots)
    if !exists("bm_roots[root]")
      call add(lines, "CS_PROJECT_ROOT: " . root)
    endif
  endfor

  call writefile(lines, cache_file)
endfunction

function! <SID>add_to_bookmarks(directory, name)
  let directory = <SID>normalize_directory(a:directory)

  let jump_counter = 0

  for i in range(0, len(s:bookmarks) - 1)
    if s:bookmarks[i].directory == directory
      let jump_counter = s:bookmarks[i].jump_counter
      call remove(s:bookmarks, i)
      break
    endif
  endfor

  let bookmark = { "name": a:name, "directory": directory, "jump_counter": jump_counter }

  call add(s:bookmarks, bookmark)

  let lines      = []
  let bm_roots   = {}
  let cache_file = g:ctrlspace_cache_dir . "/.cs_cache"

  if filereadable(cache_file)
    for old_line in readfile(cache_file)
      if (old_line !~# "CS_BOOKMARK: ") && (old_line !~# "CS_PROJECT_ROOT: ")
        call add(lines, old_line)
      endif
    endfor
  endif

  for bm in s:bookmarks
    call add(lines, "CS_BOOKMARK: " . bm.directory . s:CS_SEP . bm.name)
    let bm_roots[bm.directory] = 1
  endfor

  for root in keys(s:project_roots)
    if !exists("bm_roots[root]")
      call add(lines, "CS_PROJECT_ROOT: " . root)
    endif
  endfor

  call writefile(lines, cache_file)

  let s:project_roots[bookmark.directory] = 1

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

function! ctrlspace#statusline()
  hi def link User1 CtrlSpaceStatus

  let statusline = "%1*" . g:ctrlspace_symbols.cs . "    " . ctrlspace#statusline_mode_segment("    ")

  if !&showtabline
    let statusline .= " %=%1* %<" . ctrlspace#statusline_tab_segment()
  endif

  return statusline
endfunction

function! <SID>go_outside_list(direction)
  let buffer_list     = ctrlspace#bufferlist(tabpagenr())
  let current_buffer  = bufnr("%")
  let current_index   = -1
  let buffer_list_len = len(buffer_list)

  for index in range(0, buffer_list_len - 1)
    if buffer_list[index]["number"] == current_buffer
      let current_index = index
      break
    endif
  endfor

  if current_index == -1
    return
  endif

  if a:direction == "down"
    let target_index = current_index + 1

    if target_index == buffer_list_len
      let target_index = 0
    endif
  else
    let target_index = current_index - 1

    if target_index < 0
      let target_index = buffer_list_len - 1
    endif
  endif

  silent! exe ":b " . buffer_list[target_index]["number"]
endfunction

function! ctrlspace#bufferlist(tabnr)
  let buffer_list     = []
  let tabnr           = tabpagenr()
  let single_list     = gettabvar(tabnr, "ctrlspace_list")
  let visible_buffers = tabpagebuflist(tabnr)

  if type(single_list) != 4
    return
  endif

  for i in keys(single_list)
    let i = str2nr(i)

    let bufname = bufname(i)

    if !strlen(bufname) && (getbufvar(i, '&modified') || (index(visible_buffers, i) != -1))
      let bufname = '[' . i . '*No Name]'
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      call add(buffer_list, { "number": i, "raw": bufname })
    endif
  endfor

  call sort(buffer_list, function("s:compare_raw_names"))

  return buffer_list
endfunction

function! ctrlspace#buffers(tabnr)
  let buffer_list     = {}
  let ctrlspace_list  = gettabvar(a:tabnr, "ctrlspace_list")
  let visible_buffers = tabpagebuflist(a:tabnr)

  if type(ctrlspace_list) != 4
    return buffer_list
  endif

  for i in keys(ctrlspace_list)
    let i = str2nr(i)

    let bufname = bufname(i)

    if !strlen(bufname) && (getbufvar(i, '&modified') || (index(visible_buffers, i) != -1))
      let bufname = '[' . i . '*No Name]'
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      let buffer_list[i] = bufname
    endif
  endfor

  return buffer_list
endfunction

function! ctrlspace#statusline_tab_segment()
  let current_tab = tabpagenr()
  let winnr       = tabpagewinnr(current_tab)
  let buflist     = tabpagebuflist(current_tab)
  let bufnr       = buflist[winnr - 1]
  let bufname     = bufname(bufnr)
  let bufs_number = ctrlspace#tab_buffers_number(current_tab)
  let title       = ctrlspace#tab_title(current_tab, bufnr, bufname)

  if !g:ctrlspace_unicode_font && !empty(bufs_number)
    let bufs_number = ":" . bufs_number
  end

  let tabinfo = string(current_tab) . bufs_number . " "

  if ctrlspace#tab_modified(current_tab)
    let tabinfo .= "+ "
  endif

  let tabinfo .= title

  return tabinfo
endfunction

function! <SID>create_status_tabline()
  let current = tabpagenr()
  let line    = ""

  for i in range(1, tabpagenr("$"))
    let line .= (current == i ? g:ctrlspace_symbols.c_tab : g:ctrlspace_symbols.tabs)
  endfor

  return line
endfunction

function! ctrlspace#statusline_mode_segment(...)
  let statusline_elements = []

  if s:workspace_mode == 1
    call add(statusline_elements, g:ctrlspace_symbols.load)
  elseif s:workspace_mode == 2
    call add(statusline_elements, g:ctrlspace_symbols.save)
  elseif s:tablist_mode
    call add(statusline_elements, <SID>create_status_tabline())
  elseif s:bookmark_mode
    call add(statusline_elements, g:ctrlspace_symbols.bm)
  else
    if s:file_mode
      let symbol = g:ctrlspace_symbols.file
    elseif s:single_mode == 2
      let symbol = g:ctrlspace_symbols.vis
    elseif s:single_mode == 1
      let symbol = g:ctrlspace_symbols.tab
    else
      let symbol = g:ctrlspace_symbols.all
    endif

    if s:next_tab_mode
      let symbol .= g:ctrlspace_symbols.ntm . ctrlspace#tab_buffers_number(tabpagenr() + 1)
    endif

    call add(statusline_elements, symbol)
  endif

  if !empty(s:search_letters) || s:search_mode
    let search_element = g:ctrlspace_symbols.s_left . join(s:search_letters, "")

    if s:search_mode
      let search_element .= "_"
    endif

    let search_element .= g:ctrlspace_symbols.s_right

    call add(statusline_elements, search_element)
  endif

  if s:zoom_mode
    call add(statusline_elements, g:ctrlspace_symbols.zoom)
  endif

  if s:help_mode
    call add(statusline_elements, g:ctrlspace_symbols.help)
  endif

  let separator = (a:0 > 0) ? a:1 : "  "
  return join(statusline_elements, separator)
endfunction

function! ctrlspace#tab_buffers_number(tabnr)
  let buffers_number = len(ctrlspace#buffers(a:tabnr))
  let number_to_show = ""

  if buffers_number > 1
    if g:ctrlspace_unicode_font
      let small_numbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
      let number_str    = string(buffers_number)

      for i in range(0, len(number_str) - 1)
        let number_to_show .= small_numbers[str2nr(number_str[i])]
      endfor
    else
      let number_to_show = string(buffers_number)
    endif
  endif

  return number_to_show
endfunction

function! ctrlspace#tab_title(tabnr, bufnr, bufname)
  let bufname = a:bufname
  let bufnr   = a:bufnr
  let title   = gettabvar(a:tabnr, "ctrlspace_label")

  if empty(title)
    if getbufvar(bufnr, "&ft") == "ctrlspace"
      if s:zoom_mode && exists("s:zoom_mode_original_buffer")
        let bufnr = s:zoom_mode_original_buffer
      else
        let bufnr = winbufnr(t:ctrlspace_start_window)
      endif

      let bufname = bufname(bufnr)
    endif

    if empty(bufname)
      let title = "[" . bufnr . "*No Name]"
    else
      let title = "[" . fnamemodify(bufname, ':t') . "]"
    endif
  endif

  return title
endfunction

function! ctrlspace#guitablabel()
  let winnr       = tabpagewinnr(v:lnum)
  let buflist     = tabpagebuflist(v:lnum)
  let bufnr       = buflist[winnr - 1]
  let bufname     = bufname(bufnr)
  let title       = ctrlspace#tab_title(v:lnum, bufnr, bufname)
  let bufs_number = ctrlspace#tab_buffers_number(v:lnum)

  if !g:ctrlspace_unicode_font && !empty(bufs_number)
    let bufs_number = ":" . bufs_number
  end

  let label = '' . v:lnum . bufs_number . ' '

  if ctrlspace#tab_modified(v:lnum)
    let label .= '+ '
  endif

  let label .= title . ' '

  return label
endfunction

function! ctrlspace#tabline()
  let last_tab    = tabpagenr("$")
  let current_tab = tabpagenr()
  let tabline     = ''

  for t in range(1, last_tab)
    let winnr       = tabpagewinnr(t)
    let buflist     = tabpagebuflist(t)
    let bufnr       = buflist[winnr - 1]
    let bufname     = bufname(bufnr)
    let bufs_number = ctrlspace#tab_buffers_number(t)
    let title       = ctrlspace#tab_title(t, bufnr, bufname)

    if !g:ctrlspace_unicode_font && !empty(bufs_number)
      let bufs_number = ":" . bufs_number
    end

    let tabline .= '%' . t . 'T'
    let tabline .= (t == current_tab ? '%#TabLineSel#' : '%#TabLine#')
    let tabline .= ' ' . t . bufs_number . ' '

    if ctrlspace#tab_modified(t)
      let tabline .= '+ '
    endif

    let tabline .= title . ' '
  endfor

  let tabline .= '%#TabLineFill#%T'

  if last_tab > 1
    let tabline .= '%='
    let tabline .= '%#TabLine#%999XX'
  endif

  return tabline
endfunction

function! ctrlspace#bufnr()
  return bufexists(s:plugin_buffer) ? s:plugin_buffer : -1
endfunction

function! <SID>new_tab_label(tabnr)
  let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
  let label = <SID>get_input("Label for tab " . tabnr . ": ", gettabvar(tabnr, "ctrlspace_label"))
  if !empty(label)
    call <SID>set_tab_label(tabnr, label, 0)
  endif
endfunction

function! <SID>remove_tab_label(tabnr)
  let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
  call <SID>set_tab_label(tabnr, "", 0)
endfunction

function! ctrlspace#tab_modified(tabnr)
  for b in map(keys(ctrlspace#buffers(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction

function! <SID>msg(message)
  echo g:ctrlspace_symbols.cs . "  " . a:message
endfunction

function! <SID>delayed_msg(...)
  if !empty(a:000)
    let s:delayed_message = a:1
  elseif exists("s:delayed_message") && !empty(s:delayed_message)
    redraw
    call <SID>msg(s:delayed_message)
    unlet s:delayed_message
  endif
endfunction

function! <SID>max_height()
  if g:ctrlspace_max_height
    return g:ctrlspace_max_height
  else
    return &lines / 3
  endif
endfunction

function! <SID>internal_file_path(name)
  let full_part = empty(s:project_root) ? "" : (s:project_root . "/")

  if !empty(g:ctrlspace_project_root_markers)
    for candidate in g:ctrlspace_project_root_markers
      let candidate_path = full_part . candidate

      if isdirectory(candidate_path)
        return candidate_path . "/" . a:name
      endif
    endfor
  endif

  return full_part . "." . a:name
endfunction

function! <SID>workspace_file()
  return <SID>internal_file_path("cs_workspaces")
endfunction

function! <SID>files_cache()
  return empty(g:ctrlspace_cache_files) ? "" : <SID>internal_file_path("cs_files")
endfunction

function! <SID>save_first_workspace()
  let labels = []

  for t in range(1, tabpagenr("$"))
    let label = gettabvar(t, "ctrlspace_label")
    if !empty(label)
      call add(labels, gettabvar(t, "ctrlspace_label"))
    endif
  endfor

  call <SID>save_workspace(join(labels, " "))
endfunction

function! <SID>create_workspace_digest()
  let use_nossl = exists("b:nossl_save") && b:nossl_save

  if use_nossl
    set nossl
  endif

  let lines = []

  for t in range(1, tabpagenr("$"))
    let line     = [t, gettabvar(t, "ctrlspace_label")]
    let bufs     = []
    let visibles = []

    let tab_buffers = ctrlspace#buffers(t)

    for bname in values(tab_buffers)
      let bufname = fnamemodify(bname, ":p")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor

    for visible_buf in tabpagebuflist(t)
      if exists("tab_buffers[visible_buf]")
        let bufname = fnamemodify(tab_buffers[visible_buf], ":p")

        if !filereadable(bufname)
          continue
        endif

        call add(visibles, bufname)
      endif
    endfor

    call add(line, join(bufs, "|"))
    call add(line, join(visibles, "|"))
    call add(lines, join(line, ","))
  endfor

  if use_nossl
    set ssl
  endif

  return join(lines, "&&&")
endfunction

function! <SID>save_workspace(name)
  let name = <SID>get_input("Save current workspace as: ", a:name)

  if empty(name)
    return 0
  endif

  call <SID>kill(0, 1)
  call <SID>save_workspace_externally(name)
  return 1
endfunction

function <SID>save_workspace_externally(name)
  if !<SID>project_root_found()
    return
  endif

  call <SID>handle_vim_settings("start")

  let cwd_save = fnamemodify(".", ":p:h")
  silent! exe "cd " . s:project_root

  if empty(a:name)
    if !empty(s:active_workspace_name)
      let name = s:active_workspace_name
    else
      silent! exe "cd " . cwd_save
      call <SID>handle_vim_settings("stop")
      return
    endif
  else
    let name = a:name
  endif

  let filename = <SID>workspace_file()
  let last_tab = tabpagenr("$")

  let lines        = []
  let in_workspace = 0

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . name

  if filereadable(filename)
    for old_line in readfile(filename)
      if old_line ==# workspace_start_marker
        let in_workspace = 1
      endif

      if !in_workspace
        call add(lines, old_line)
      endif

      if old_line ==# workspace_end_marker
        let in_workspace = 0
      endif
    endfor
  endif

  call add(lines, workspace_start_marker)

  let ssop_save = &ssop
  set ssop=winsize,tabpages,buffers,sesdir

  let tab_data = []

  for t in range(1, last_tab)
    let data = {
          \ "label": gettabvar(t, "ctrlspace_label"),
          \ "autotab": <SID>gettabvar_with_default(t, "ctrlspace_autotab", 0)
          \ }

    let ctrlspace_list = ctrlspace#buffers(t)

    let bufs = []

    for [nr, bname] in items(ctrlspace_list)
      let bufname = fnamemodify(bname, ":.")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor

    let data.bufs = bufs
    call add(tab_data, data)
  endfor

  silent! exe "mksession! CS_SESSION"

  if !filereadable("CS_SESSION")
    silent! exe "cd " . cwd_save
    silent! exe "set ssop=" . ssop_save

    call <SID>handle_vim_settings("stop")
    call <SID>msg("The workspace '" . name . "' cannot be saved at this moment.")
    return
  endif

  let tab_index = 0

  for cmd in readfile("CS_SESSION")
    if ((cmd =~# "^edit") && (tab_index == 0)) || (cmd =~# "^tabnew") || (cmd =~# "^tabedit")
      let data = tab_data[tab_index]

      if tab_index > 0
        call add(lines, cmd)
      endif

      for b in data.bufs
        call add(lines, "edit " . b)
      endfor

      if !empty(data.label)
        call add(lines, "let t:ctrlspace_label = '" . substitute(data.label, "'", "''","g") . "'")
      endif

      if !empty(data.autotab)
        call add(lines, "let t:ctrlspace_autotab = " . data.autotab)
      endif

      if tab_index == 0
        call add(lines, cmd)
      elseif cmd =~# "^tabedit"
        call add(lines, cmd[3:]) "make edit from tabedit
      endif

      let tab_index += 1
    else
      let badd_list = matchlist(cmd, "\\m^badd \+\\d* \\(.*\\)$")

      if !(exists("badd_list[1]") && !empty(badd_list[1]) && !filereadable(badd_list[1]))
        call add(lines, cmd)
      endif
    endif
  endfor

  call add(lines, workspace_end_marker)

  call writefile(lines, filename)
  call delete("CS_SESSION")

  call <SID>set_active_workspace_name(name)

  let s:active_workspace_digest = <SID>create_workspace_digest()

  call <SID>set_workspace_names()

  silent! exe "cd " . cwd_save
  silent! exe "set ssop=" . ssop_save

  call <SID>handle_vim_settings("stop")
  call <SID>msg("The workspace '" . name . "' has been saved.")
endfunction

function! <SID>delete_workspace(name)
  if !<SID>confirmed("Delete workspace '" . a:name . "'?")
    return
  endif

  let filename     = <SID>workspace_file()
  let lines        = []
  let in_workspace = 0

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . a:name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . a:name

  if filereadable(filename)
    for old_line in readfile(filename)
      if old_line ==# workspace_start_marker
        let in_workspace = 1
      endif

      if !in_workspace
        call add(lines, old_line)
      endif

      if old_line ==# workspace_end_marker
        let in_workspace = 0
      endif
    endfor
  endif

  call writefile(lines, filename)

  if s:active_workspace_name ==# a:name
    call <SID>set_active_workspace_name("")
    let s:active_workspace_digest = ""
  endif

  call <SID>msg("The workspace '" . a:name . "' has been deleted.")

  call <SID>set_workspace_names()

  if empty(s:workspace_names)
    call <SID>kill(0, 1)
  else
    call <SID>kill(0, 0)
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>set_workspace_names()
  let filename                = <SID>workspace_file()
  let s:last_active_workspace = ""
  let s:workspace_names       = []

  if filereadable(filename)
    for line in readfile(filename)
      if line =~? "CS_WORKSPACE_BEGIN: "
        call add(s:workspace_names, line[20:])
      elseif line =~? "CS_LAST_WORKSPACE: "
        let s:last_active_workspace = line[19:]
      endif
    endfor
  endif
endfunction

function! <SID>set_active_workspace_name(name)
  let s:active_workspace_name = a:name
  let s:last_active_workspace = a:name

  let filename = <SID>workspace_file()
  let lines    = []

  if filereadable(filename)
    for line in readfile(filename)
      if !(line =~? "CS_LAST_WORKSPACE: ")
        call add(lines, line)
      endif
    endfor
  endif

  if !empty(s:active_workspace_name)
    call insert(lines, "CS_LAST_WORKSPACE: " . s:active_workspace_name)
  endif

  call writefile(lines, filename)
endfunction

function! <SID>get_selected_workspace_name()
  return s:workspace_names[<SID>get_selected_buffer() - 1]
endfunction

function! <SID>get_input(msg, ...)
  let msg = g:ctrlspace_symbols.cs . "  " . a:msg

  call inputsave()

  if a:0 >= 2
    let answer = input(msg, a:1, a:2)
  elseif a:0 == 1
    let answer = input(msg, a:1)
  else
    let answer = input(msg)
  endif

  call inputrestore()
  redraw!

  return answer
endfunction

function! <SID>confirmed(msg)
  return <SID>get_input(a:msg . " (yN): ") =~? "y"
endfunction

function! <SID>load_last_active_workspace()
  if !empty(s:last_active_workspace)
    call <SID>load_workspace(0, s:last_active_workspace)
  endif
endfunction

function <SID>proceed_if_modified()
  for i in range(1, bufnr("$"))
    if getbufvar(i, "&modified")
      return <SID>confirmed("Some buffers not saved. Proceed anyway?")
    endif
  endfor

  return 1
endfunction

function! <SID>new_workspace()
  let save_workspace_before = 0

  if !empty(s:active_workspace_name) && (s:active_workspace_digest !=# <SID>create_workspace_digest())
    if g:ctrlspace_save_workspace_on_switch
      let save_workspace_before = 1
    elseif !<SID>confirmed("Current workspace ('" . s:active_workspace_name . "') not saved. Proceed anyway?")
      return
    endif
  endif

  if !<SID>proceed_if_modified()
    return
  endif

  call <SID>kill(0, 1)

  if save_workspace_before
    call <SID>save_workspace_externally("")
  endif

  call <SID>new_workspace_externally()
endfunction

function! <SID>new_workspace_externally()
  tabe
  tabo!
  call <SID>delete_hidden_noname_buffers(1)
  call <SID>delete_foreign_buffers(1)
  let s:active_workspace_name   = ""
  let s:active_workspace_digest = ""
endfunction

function! <SID>rename_workspace(name)
  let new_name = <SID>get_input("Rename workspace '" . a:name . "' to: ", a:name)

  if empty(new_name)
    return
  endif

  for existing_name in s:workspace_names
    if new_name ==# existing_name
      call <SID>msg("The workspace '" . new_name . "' already exists.")
      return
    endif
  endfor

  let filename     = <SID>workspace_file()
  let lines        = []
  let in_workspace = 0

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . a:name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . a:name
  let last_workspace_marker  = "CS_LAST_WORKSPACE: " . a:name

  if filereadable(filename)
    for line in readfile(filename)
      if line ==# workspace_start_marker
        let line = "CS_WORKSPACE_BEGIN: " . new_name
      elseif line ==# workspace_end_marker
        let line = "CS_WORKSPACE_END: " . new_name
      elseif line ==# last_workspace_marker
        let line = "CS_LAST_WORKSPACE: " . new_name
      endif

      call add(lines, line)
    endfor
  endif

  call writefile(lines, filename)

  if s:active_workspace_name ==# a:name
    call <SID>set_active_workspace_name(new_name)
  endif

  call <SID>msg("The workspace '" . a:name . "' has been renamed to '" . new_name . "'.")

  call <SID>set_workspace_names()

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>load_workspace(bang, name)
  let save_workspace_before = 0

  if !empty(s:active_workspace_name) && !a:bang
    let msg = ""

    if a:name == s:active_workspace_name
      let msg = "Reload current workspace: '" . a:name . "'?"
    elseif !empty(s:active_workspace_name)
      if s:active_workspace_digest !=# <SID>create_workspace_digest()
        if g:ctrlspace_save_workspace_on_switch
          let save_workspace_before = 1
        else
          let msg = "Current workspace ('" . s:active_workspace_name . "') not saved. Proceed anyway?"
        end
      endif
    endif

    if !empty(msg) && !<SID>confirmed(msg)
      return
    endif
  endif

  if !a:bang && !<SID>proceed_if_modified()
    return
  endif

  call <SID>kill(0, 1)

  if save_workspace_before
    call <SID>save_workspace_externally("")
  endif

  call <SID>load_workspace_externally(a:bang, a:name)

  if a:bang
    call <SID>ctrlspace_toggle(0)
    let s:workspace_mode = 1
    call <SID>kill(0, 0)
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>execute_workspace_commands_from_lines_v2(bang, name, lines)
  let commands = []

  if !a:bang
    call <SID>msg("Loading workspace '" . a:name . "'...")
    call add(commands, "tabe")
    call add(commands, "tabo!")
    call add(commands, "call <SID>delete_hidden_noname_buffers(1)")
    call add(commands, "call <SID>delete_foreign_buffers(1)")

    call <SID>set_active_workspace_name(a:name)
  else
    call <SID>msg("Appending workspace '" . a:name . "'...")
    call add(commands, "tabe")
  endif

  call writefile(a:lines, "CS_SESSION")

  call add(commands, "source CS_SESSION")
  call add(commands, "redraw!")

  for c in commands
    silent exe c
  endfor

  call delete("CS_SESSION")
endfunction

function! <SID>execute_workspace_commands_from_lines_v1(bang, name, lines)
  let window_split_command = "vs "

  let commands = []

  if !a:bang
    call <SID>msg("Loading workspace '" . a:name . "'...")
    call add(commands, "tabe")
    call add(commands, "tabo!")
    call add(commands, "call <SID>delete_hidden_noname_buffers(1)")
    call add(commands, "call <SID>delete_foreign_buffers(1)")

    let create_first_tab = 0
    call <SID>set_active_workspace_name(a:name)
  else
    call <SID>msg("Appending workspace '" . a:name . "'...")
    let create_first_tab = 1
  endif

  for line in a:lines
    let tab_data   = split(line, ",")
    let tabnr      = tab_data[0]
    let tab_label  = tab_data[1]
    let is_current = str2nr(tab_data[2])
    let files      = split(tab_data[3], "|")
    let visibles   = (len(tab_data) > 4) ? split(tab_data[4], "|") : []

    let readable_files = []
    let visible_files  = []

    let index = 0

    for fname in files
      if filereadable(fname)
        call add(readable_files, fname)

        if index(visibles, string(index)) > -1
          call add(visible_files, fname)
        endif
      endif

      let index += 1
    endfor

    if empty(readable_files)
      continue
    endif

    if create_first_tab
      call add(commands, "tabe")
    else
      let create_first_tab = 1 " we want omit only first tab creation if a:bang == 0 (append mode)
    endif

    for fname in readable_files
      call add(commands, "e " . fnameescape(fname))
      call add(commands, "if line(\"'\\\"\") > 0 | " .
            \ "if line(\"'\\\"\") <= line('$') | " .
            \ "exe(\"norm '\\\"\") | else | exe 'norm $' | " .
            \ "endif | endif")
    endfor

    if !empty(visible_files)
      call add(commands, "e " . fnameescape(visible_files[0]))
      call add(commands, "normal! zbze")

      for visible_fname in visible_files[1:-1]
        call add(commands, window_split_command . visible_fname)
        call add(commands, "normal! zbze")
        call add(commands, "wincmd p")
        call add(commands, "normal! zbze")
        call add(commands, "wincmd p")
      endfor
    endif

    if is_current
      call add(commands, "let ctrlspace_workspace_current_tab = tabpagenr()")
    endif

    if !empty(tab_label)
      call add(commands, "let t:ctrlspace_label = \"" . escape(tab_label, '"') . "\"")
    endif
  endfor

  call add(commands, "silent! exe 'normal! ' . ctrlspace_workspace_current_tab . 'gt'")
  call add(commands, "redraw!")

  for c in commands
    silent exe c
  endfor
endfunction

" bang == 0) load
" bang == 1) append
function! <SID>load_workspace_externally(bang, name)
  if !<SID>project_root_found()
    return
  endif

  call <SID>handle_vim_settings("start")

  let cwd_save = fnamemodify(".", ":p:h")
  silent! exe "cd " . s:project_root

  let filename = <SID>workspace_file()

  if !filereadable(filename)
    silent! exe "cd " . cwd_save
    return
  endif

  let old_lines = readfile(filename)

  if empty(a:name)
    let name = ""

    for line in old_lines
      if line =~? "CS_LAST_WORKSPACE: "
        let name = line[19:]
        break
      endif
    endfor

    if empty(name)
      silent! exe "cd " . cwd_save
      return
    endif
  else
    let name = a:name
  endif

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . name

  let lines        = []
  let in_workspace = 0

  for old_line in old_lines
    if old_line ==# workspace_start_marker
      let in_workspace = 1
    elseif old_line ==# workspace_end_marker
      let in_workspace = 0
    elseif in_workspace
      call add(lines, old_line)
    endif
  endfor

  if empty(lines)
    call <SID>msg("Workspace '" . name . "' not found in file '" . filename . "'.")
    call <SID>set_workspace_names()
    silent! exe "cd " . cwd_save
    return
  endif

  if lines[0] == "let SessionLoad = 1"
    call <SID>execute_workspace_commands_from_lines_v2(a:bang, name, lines)
  else
    call <SID>execute_workspace_commands_from_lines_v1(a:bang, name, lines)
  endif

  if !a:bang
    call <SID>msg("The workspace '" . name . "' has been loaded.")
    let s:active_workspace_digest = <SID>create_workspace_digest()
  else
    let s:active_workspace_digest = ""
    call <SID>msg("The workspace '" . name . "' has been appended.")
  endif

  silent! exe "cd " . cwd_save

  call <SID>handle_vim_settings("stop")
endfunction

function! <SID>quit_vim()
  if !g:ctrlspace_save_workspace_on_exit && !empty(s:active_workspace_name)
        \ && (s:active_workspace_digest !=# <SID>create_workspace_digest())
        \ && !<SID>confirmed("Current workspace ('" . s:active_workspace_name . "') not saved. Proceed anyway?")
    return
  endif

  if !<SID>proceed_if_modified()
    return
  endif

  call <SID>kill(0, 1)
  qa!
endfunction

function! <SID>find_subsequence(bufname, offset)
  let positions      = []
  let noise          = 0
  let current_offset = a:offset

  for letter in s:search_letters
    let matched_position = match(a:bufname, "\\m\\c" . letter, current_offset)

    if matched_position == -1
      return [-1, []]
    else
      if !empty(positions)
        let noise += abs(matched_position - positions[-1]) - 1
      endif
      call add(positions, matched_position)
      let current_offset = matched_position + 1
    endif
  endfor

  return [noise, positions]
endfunction

function! <SID>find_lowest_search_noise(bufname)
  if has("ruby") && g:ctrlspace_use_ruby_bindings
    ruby VIM.command("return #{CtrlSpace.find_lowest_search_noise(VIM.evaluate('a:bufname'))}")
  else
    let search_letters_count = len(s:search_letters)
    let noise                = -1
    let matched_string       = ""

    if search_letters_count == 1
      let noise          = match(a:bufname, "\\m\\c" . s:search_letters[0])
      let matched_string = s:search_letters[0]
    else
      let offset      = 0
      let bufname_len = strlen(a:bufname)

      while offset < bufname_len
        let subseq = <SID>find_subsequence(a:bufname, offset)

        if subseq[0] == -1
          break
        elseif (noise == -1) || (subseq[0] < noise)
          let noise          = subseq[0]
          let offset         = subseq[1][0] + 1
          let matched_string = a:bufname[subseq[1][0]:subseq[1][-1]]

          if !empty(g:ctrlspace_search_resonators)
            if subseq[1][0] != 0
              let noise += 1

              if index(g:ctrlspace_search_resonators, a:bufname[subseq[1][0] - 1]) == -1
                let noise += 1
              endif
            endif

            if subseq[1][-1] != bufname_len - 1
              let noise += 1

              if index(g:ctrlspace_search_resonators, a:bufname[subseq[1][-1] + 1]) == -1
                let noise += 1
              endif
            endif
          endif
        else
          let offset += 1
        endif
      endwhile
    endif

    if (noise > -1) && !empty(matched_string)
      let b:last_search_pattern = matched_string
    endif

    return noise
  endif
endfunction

function! <SID>display_search_patterns(patterns)
  let set_patterns = {}

  for pattern in a:patterns
    if !get(set_patterns, pattern)
      " escape ~ sign because of E874: (NFA) Could not pop the stack !
      call matchadd("CtrlSpaceSearch", "\\c" .substitute(pattern, '\~', '\\~', "g"))
      let set_patterns[pattern] = 1
    endif
  endfor
endfunction

function! <SID>get_search_history_index()
  if s:file_mode || s:tablist_mode || s:bookmark_mode || s:workspace_mode
    if !exists("s:search_history_index")
      let s:search_history_index = -1
    endif

    return s:search_history_index
  else
    if !exists("t:ctrlspace_search_history_index")
      let t:ctrlspace_search_history_index = -1
    endif

    return t:ctrlspace_search_history_index
  endif
endfunction

function! <SID>set_search_history_index(value)
  if s:file_mode || s:tablist_mode || s:bookmark_mode || s:workspace_mode
    let s:search_history_index = a:value
  else
    let t:ctrlspace_search_history_index = a:value
  endif
endfunction

function! <SID>append_to_search_history()
  if empty(s:search_letters)
    return
  endif

  if s:file_mode || s:tablist_mode || s:bookmark_mode || s:workspace_mode
    if !exists("s:search_history")
      let s:search_history = {}
    endif

    let history_store = s:search_history
  else
    if !exists("t:ctrlspace_search_history")
      let t:ctrlspace_search_history = {}
    endif

    let history_store = t:ctrlspace_search_history
  endif

  let s:jump_counter += 1
  let history_store[join(s:search_letters)] = s:jump_counter
endfunction

function! <SID>restore_search_letters(direction)
  let history_stores = []

  if exists("s:search_history") && !empty(s:search_history)
    call add(history_stores, s:search_history)
  endif

  if !s:file_mode && !s:workspace_mode && !s:tablist_mode && !s:bookmark_mode
    let tab_range = s:single_mode ? range(tabpagenr(), tabpagenr()) : range(1, tabpagenr("$"))

    for t in tab_range
      let tab_store = <SID>gettabvar_with_default(t, "ctrlspace_search_history", {})
      if !empty(tab_store)
        call add(history_stores, tab_store)
      endif
    endfor
  endif

  let history_store = {}

  for store in history_stores
    for [letters, counter] in items(store)
      if exists("history_store." . letters) && history_store[letters] >= counter
        continue
      endif

      let history_store[letters] = counter
    endfor
  endfor

  if empty(history_store)
    return
  endif

  let history_entries = []

  for [letters, counter] in items(history_store)
    call add(history_entries, { "letters": letters, "counter": counter })
	endfor

  call sort(history_entries, function("s:compare_jumps"))

  let history_index = <SID>get_search_history_index()

  if a:direction == "previous"
    let history_index += 1

    if history_index == len(history_entries)
      let history_index = len(history_entries) - 1
    endif
  elseif a:direction == "next"
    let history_index -= 1

    if history_index < -1
      let history_index = -1
    endif
  endif

  if history_index < 0
    let s:search_letters = []
  else
    let s:search_letters = split(history_entries[history_index]["letters"])
    let s:restored_search_mode = 1
  endif

  call <SID>set_search_history_index(history_index)

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>prepare_buftext_to_display(buflist)
  if has("ruby") && g:ctrlspace_use_ruby_bindings
    ruby VIM.command(%Q(return "#{CtrlSpace.prepare_buftext_to_display(VIM.evaluate('a:buflist'))}"))
  else
    if s:file_mode
      let bufname_space = 5
    elseif s:bookmark_mode
      let bufname_space = 5 + s:symbol_sizes.iav
    else
      let bufname_space = 5 + s:symbol_sizes.iav + s:symbol_sizes.im
    endif

    let buftext = ""

    for entry in a:buflist
      let bufname = entry.raw

      if strwidth(bufname) + bufname_space > &columns
        let bufname = g:ctrlspace_symbols.dots . strpart(bufname, strwidth(bufname) - &columns + bufname_space + s:symbol_sizes.dots)
      endif

      if !s:file_mode && !s:workspace_mode && !s:tablist_mode && !s:bookmark_mode
        let bufname = <SID>decorate_with_indicators(bufname, entry.number)
      elseif s:workspace_mode
        if entry.raw ==# s:active_workspace_name
          let bufname .= " "

          if s:active_workspace_digest !=# <SID>create_workspace_digest()
            let bufname .= g:ctrlspace_symbols.im
          endif

          let bufname .= g:ctrlspace_symbols.ia
        elseif entry.raw ==# s:last_active_workspace
          let bufname .= " " . g:ctrlspace_symbols.iv
        endif
      elseif s:tablist_mode
        let indicators = ""

        if ctrlspace#tab_modified(entry.number)
          let indicators .= g:ctrlspace_symbols.im
        endif

        if entry.number == tabpagenr()
          let indicators .= g:ctrlspace_symbols.ia
        endif

        if !empty(indicators)
          let bufname .= " " . indicators
        endif
      elseif s:bookmark_mode
        let indicators = ""

        if !empty(s:active_bookmark) && (s:bookmarks[entry.number - 1].directory == s:active_bookmark.directory)
          let indicators .= g:ctrlspace_symbols.ia
        endif

        if !empty(indicators)
          let bufname .= " " . indicators
        endif
      endif

      while strwidth(bufname) < &columns
        let bufname .= " "
      endwhile

      let buftext .= "  " . bufname . "\n"
    endfor

    return buftext
  endif
endfunction

function! <SID>add_first_bookmark()
  if <SID>add_new_bookmark(0)
    call <SID>kill(0, 1)
    call <SID>ctrlspace_toggle(0)
    call <SID>kill(0, 0)
    let s:bookmark_mode = 1
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>normalize_directory(directory)
  let directory = resolve(expand(a:directory))

  while directory[strlen(directory) - 1] == "/" || directory[strlen(directory) - 1] == "\\"
    let directory = directory[0:-2]
  endwhile

  return directory
endfunction

function! <SID>add_new_bookmark(bm_nr)
  if a:bm_nr
    let current = s:bookmarks[a:bm_nr - 1].directory
  else
    let current = empty(s:project_root) ? fnamemodify(".", ":p:h") : s:project_root
  endif

  let directory = <SID>get_input("Add directory to bookmarks: ", current, "dir")

  if empty(directory)
    return 0
  endif

  let directory = <SID>normalize_directory(directory)

  if !isdirectory(directory)
    call <SID>msg("Directory incorrect.")
    return 0
  endif

  for bookmark in s:bookmarks
    if bookmark.directory == directory
      call <SID>msg("This directory has been already bookmarked under name '" . bookmark.name . "'.")
      return 0
    endif
  endfor

  let name = <SID>get_input("New bookmark name: ", fnamemodify(directory, ":t"))

  if empty(name)
    return 0
  endif

  call <SID>add_to_bookmarks(directory, name)
  call <SID>delayed_msg("Directory '" . directory . "' has been bookmarked under name '" . name . "'.")
  return 1
endfunction

function! <SID>goto_bookmark(bm_nr)
  let new_bookmark = s:bookmarks[a:bm_nr - 1]

  if !empty(s:active_bookmark) && s:active_bookmark.directory == new_bookmark.directory
    return
  endif

  silent! exe "cd " . new_bookmark.directory
  call <SID>delayed_msg("CWD is now: " . new_bookmark.directory)
endfunction

function! <SID>change_bookmark_name(bm_nr)
  let bookmark  = s:bookmarks[a:bm_nr - 1]
  let new_name = <SID>get_input("New bookmark name: ", bookmark.name)

  if !empty(new_name)
    call <SID>add_to_bookmarks(bookmark.directory, new_name)
  endif
endfunction

function! <SID>change_bookmark_directory(bm_nr)
  let bookmark  = s:bookmarks[a:bm_nr - 1]
  let current   = bookmark.directory
  let name      = bookmark.name
  let directory = <SID>get_input("Edit directory for bookmark '" . name . "': ", current, "dir")

  if empty(directory)
    return 0
  endif

  let directory = <SID>normalize_directory(directory)

  if !isdirectory(directory)
    call <SID>msg("Directory incorrect.")
    return 0
  endif

  for bookmark in s:bookmarks
    if bookmark.directory == directory
      call <SID>msg("This directory has been already bookmarked under name '" . name . "'.")
      return 0
    endif
  endfor

  call remove(s:bookmarks, a:bm_nr - 1)

  call <SID>add_to_bookmarks(directory, name)
  call <SID>delayed_msg("Directory '" . directory . "' has been bookmarked under name '" . name . "'.")

  return 1
endfunction

function! <SID>remove_bookmark(bm_nr)
  let name = s:bookmarks[a:bm_nr - 1].name

  if !<SID>confirmed("Delete bookmark '" . name . "'?")
    return
  endif

  call remove(s:bookmarks, a:bm_nr - 1)

  let lines      = []
  let cache_file = g:ctrlspace_cache_dir . "/.cs_cache"

  if filereadable(cache_file)
    for old_line in readfile(cache_file)
      if old_line !~# "CS_BOOKMARK: "
        call add(lines, old_line)
      endif
    endfor
  endif

  for bm in s:bookmarks
    call add(lines, "CS_BOOKMARK: " . bm.directory . s:CS_SEP . bm.name)
  endfor

  call writefile(lines, cache_file)

  call <SID>delayed_msg("Bookmark '" . name . "' has been deleted.")
endfunction

function! <SID>project_root_found()
  if empty(s:project_root)
    let s:project_root = <SID>find_project_root()
    if empty(s:project_root)
      let project_root = <SID>get_input("No project root found. Set the project root: ", fnamemodify(".", ":p:h"), "dir")
      if !empty(project_root) && isdirectory(project_root)
        let s:files = [] " clear current files - force reload
        call <SID>add_project_root(project_root)
      else
        call <SID>msg("Cannot continue with the project root not set.")
        return 0
      endif
    endif
  endif
  return 1
endfunction

function! <SID>save_files_in_cache()
  let filename = <SID>files_cache()

  if empty(filename)
    return
  endif

  call writefile(s:files, filename)
endfunction

function! <SID>load_files_from_cache()
  let filename = <SID>files_cache()

  if empty(filename) || !filereadable(filename)
    return
  endif

  let s:files = readfile(filename)
endfunction

function! <SID>start_ctrlspace_and_feedkeys(keys)
  call <SID>ctrlspace_toggle(0)

  if !empty(a:keys)
    call feedkeys(a:keys)
  endif
endfunction

function! <SID>puts(str)
  let str = "  " . a:str

  if &columns < (strwidth(str) + 2)
    let str = strpart(str, 0, &columns - 2 - s:symbol_sizes.dots) . g:ctrlspace_symbols.dots
  endif

  while strwidth(str) < &columns
    let str .= " "
  endwhile

  if !exists("s:text_buffer")
    let s:text_buffer = []
  endif

  call add(s:text_buffer, str)
endfunction

function! <SID>flush_text_buffer()
  let text = join(s:text_buffer, "\n")
  unlet s:text_buffer
  return text
endfunction

function! <SID>text_buffer_size()
  return exists("s:text_buffer") ? len(s:text_buffer) : 0
endfunction

function! <SID>key_help(key, description)
  if !exists("b:help_key_descriptions")
    let b:help_key_descriptions = []
    let b:help_key_width = 0
  endif

  call add(b:help_key_descriptions, { "key": a:key, "description": a:description })

  if strwidth(a:key) > b:help_key_width
    let b:help_key_width = strwidth(a:key)
  else
    for key_info in b:help_key_descriptions
      while strwidth(key_info.key) < b:help_key_width
        let key_info.key .= " "
      endwhile
    endfor
  endif
endfunction

function! <SID>display_help()
  call <SID>key_help("?", "Toggle the help view")

  let current_list = ""
  let current_mode = ""

  if s:nop_mode
    let b:help_tag = "ctrlspace-nop-mode"
    let current_mode .= "NOP MODE"

    if s:search_mode
      let current_mode .= " - Search entering phase"

      if empty(s:search_letters)
        call <SID>key_help("BS", "Clear search")
      else
        let current_mode .= " ('" . join(s:search_letters, "") .  "')"
        call <SID>key_help("BS", "Remove the previously entered character")
        call <SID>key_help("C-h", "Remove the previously entered character")
        call <SID>key_help("C-u", "Clear the search phrase")
        call <SID>key_help("C-w", "Clear the search phrase")
      endif
    else
      call <SID>key_help("a", "Toggle between Single and All modes")
      call <SID>key_help("A", "Enter All mode and switch to Search Mode")
      call <SID>key_help("o", "Toggle the File List (Open List)")
      call <SID>key_help("O", "Enter the File List (Open List) in Search Mode")
      call <SID>key_help("w", "Toggle the Workspace List view")
      call <SID>key_help("W", "Enter the Workspace List view in Search Mode")
      call <SID>key_help("l", "Toggle the Tab List view")
      call <SID>key_help("L", "Enter the Tab List in Search Mode")
      call <SID>key_help("b", "Toggle the Bookmark List view")
      call <SID>key_help("B", "Enter the Bookmark List view in Search Mode")
      call <SID>key_help("C-p", "Bring back the previous searched text")
      call <SID>key_help("C-n", "Bring the next searched text")
      call <SID>key_help("BS", "Delete the search query")
      call <SID>key_help("Q", "Quit Vim with a prompt if unsaved changes found")
      call <SID>key_help("q", "Close the list")
    endif

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
  elseif s:search_mode
    let b:help_tag = "ctrlspace-search-mode"
    let current_mode .= "SEARCH MODE"

    if empty(s:search_letters)
      call <SID>key_help("BS", "Clear search")
    else
      let current_mode .= " ('" . join(s:search_letters, "") .  "')"
      call <SID>key_help("BS", "Remove the previously entered character")
      call <SID>key_help("C-h", "Remove the previously entered character")
      call <SID>key_help("C-u", "Clear the search phrase")
      call <SID>key_help("C-w", "Clear the search phrase")
    endif

    call <SID>key_help("CR", "Close the entering phase and accept the entered content")
    call <SID>key_help("/", "Toggle the entering phase")
    call <SID>key_help("a..z", "Add the character to the search phrase")
    call <SID>key_help("A..Z", "Add the character to the search phrase")
    call <SID>key_help("0..9", "Add the character to the search phrase")

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
  elseif s:workspace_mode
    let b:help_tag = "ctrlspace-workspace-list"
    let current_list .= "WORKSPACE LIST"

    if s:workspace_mode == 1
      let current_mode .= "LOAD MODE"
      call <SID>key_help("Tab", "Load selected workspace and close the plugin window")
      call <SID>key_help("CR", "Load selected workspace and enter the Buffer List")
      call <SID>key_help("Space", "Load selected workspace but stay in the Workspace List")
    elseif s:workspace_mode == 2
      let current_mode .= "SAVE MODE"
      call <SID>key_help("Tab", "Save selected workspace and close the plugin window")
      call <SID>key_help("CR", "Save selected workspace and enter the Buffer List")
      call <SID>key_help("Space", "Save selected workspace but stay in the Workspace List")
    endif

    call <SID>key_help("q", "Close the list")

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
    call <SID>key_help("Q", "Quit Vim with a prompt if unsaved changes found")
    call <SID>key_help("a", "Append a selected workspace to the current one")
    call <SID>key_help("n", "Make a new workspace (closes all buffers)")
    call <SID>key_help("N", "Make a new workspace but stay in the list")

    if s:workspace_mode == 1
      call <SID>key_help("s", "Toggle the mode from Load to Save")
    elseif s:workspace_mode == 2
      call <SID>key_help("s", "Toggle the mode from Save to Load")
    endif

    call <SID>key_help("C-s", "Save the workspace immediately")

    if !empty(s:last_active_workspace)
      call <SID>key_help("C-l", "Load the last active workspace")
    endif

    call <SID>key_help("w", "Go to the Buffer List")
    call <SID>key_help("W", "Enter the Search Mode")
    call <SID>key_help("/", "Enter the Search Mode")

    if empty(s:search_letters)
      call <SID>key_help("BS", "Go back to the Buffer List")
    else
      call <SID>key_help("BS", "Clear search")
    endif

    call <SID>key_help("d", "Delete selected workspace")
    call <SID>key_help("=", "Rename selected workspace")
    call <SID>key_help("j", "Move the selection bar down")
    call <SID>key_help("k", "Move the selection bar up")
    call <SID>key_help("J", "Move the selection bar to the bottom of the list")
    call <SID>key_help("K", "Move the selection bar to the top of the list")
    call <SID>key_help("C-f", "Move the selection bar one screen down")
    call <SID>key_help("C-b", "Move the selection bar one screen up")
    call <SID>key_help("C-d", "Move the selection bar a half screen down")
    call <SID>key_help("C-u", "Move the selection bar a half screen up")
    call <SID>key_help("l", "Go to the Tab List")
    call <SID>key_help("L", "Enter the Tab List in Search Mode")
    call <SID>key_help("b", "Go to the Bookmark List")
    call <SID>key_help("B", "Enter the Bookmark List view in Search Mode")
    call <SID>key_help("o", "Go to the File List")
    call <SID>key_help("O", "Go to the File List in the Search Mode")
  elseif s:tablist_mode
    let b:help_tag = "ctrlspace-tab-list"
    let current_list .= "TAB LIST"

    call <SID>key_help("Tab", "Open a selected tab and close the plugin window")
    call <SID>key_help("CR", "Open a selected tab and enter the Buffer List view")
    call <SID>key_help("Space", "Open a selected tab but stay in the Tab List view")
    call <SID>key_help("0..9", "Jump to the n-th tab (0 is for the 10th one)")
    call <SID>key_help("p", "Move the selection bar to the previously opened tab")
    call <SID>key_help("P", "Move the selection bar to the previously opened tab and open it")
    call <SID>key_help("n", "Move the selection bar to the next opened tab")
    call <SID>key_help("c", "Close the selected tab, then forgotten buffers and nonames")
    call <SID>key_help("t", "Create a new tab")
    call <SID>key_help("a", "Create a new tab")
    call <SID>key_help("y", "Make a copy of the current tab")
    call <SID>key_help("u", "Create a new tab with all unsaved buffers")
    call <SID>key_help("[", "Go to the previous tab")
    call <SID>key_help("]", "Go to the next tab")
    call <SID>key_help("=", "Change the selected tab name")
    call <SID>key_help("_", "Remove the selected tab name")
    call <SID>key_help("+", "Move the selected tab forward (increase its number)")
    call <SID>key_help("-", "Move the current tab backward (decrease its number)")
    call <SID>key_help("}", "Same as +")
    call <SID>key_help("{", "Same as -")
    call <SID>key_help("l", "Go back to the Buffer List")
    call <SID>key_help("L", "Enter the Search Mode")
    call <SID>key_help("/", "Toggle the Search Mode")
    if empty(s:search_letters)
      call <SID>key_help("BS", "Go back to the Buffer List")
    else
      call <SID>key_help("BS", "Clear search")
    endif
    call <SID>key_help("q", "Close the list")

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
    call <SID>key_help("Q", "Quit Vim with a prompt if unsaved changes found")
    call <SID>key_help("j", "Move the selection bar down")
    call <SID>key_help("k", "Move the selection bar up")
    call <SID>key_help("J", "Move the selection bar to the bottom of the list")
    call <SID>key_help("K", "Move the selection bar to the top of the list")
    call <SID>key_help("C-f", "Move the selection bar one screen down")
    call <SID>key_help("C-b", "Move the selection bar one screen up")
    call <SID>key_help("C-d", "Move the selection bar a half screen down")
    call <SID>key_help("C-u", "Move the selection bar a half screen up")
    call <SID>key_help("w", "Go to the Workspace List view")
    call <SID>key_help("W", "Enter the Workspace List view in Search Mode")
    call <SID>key_help("b", "Toggle the Bookmark List view")
    call <SID>key_help("B", "Enter the Bookmark List view in Search Mode")
    call <SID>key_help("o", "Go to the File List view")
    call <SID>key_help("O", "Go to the File List view in the Search Mode")
  elseif s:bookmark_mode
    let b:help_tag = "ctrlspace-bookmark-list"
    let current_list .= "BOOKMARK LIST"

    call <SID>key_help("Tab", "Jump to selected bookmark and close the plugin window")
    call <SID>key_help("CR", "Jump to selected bookmark and enter the Buffer List")
    call <SID>key_help("Space", "Jump to selected bookmark but stay in the Bookmark List")
    call <SID>key_help("=", "Change selected bookmark name")
    call <SID>key_help("e", "Edit selected bookmark directory")
    call <SID>key_help("a", "Add a new bookmark")
    call <SID>key_help("A", "Add a new bookmark for the current directory")
    call <SID>key_help("d", "Delete selected bookmark")
    call <SID>key_help("p", "Move selection bar to the previously opened bookmark")
    call <SID>key_help("P", "Move selection bar to the previously opened tab and open it")
    call <SID>key_help("n", "Move selection bar to the next opened bookmark")
    call <SID>key_help("b", "Go to the Buffer List")
    call <SID>key_help("B", "Enter the Search Mode")
    call <SID>key_help("/", "Enter the Search Mode")
    if empty(s:search_letters)
      call <SID>key_help("BS", "Go back to the Buffer List")
    else
      call <SID>key_help("BS", "Clear search")
    endif

    call <SID>key_help("q", "Close the list")

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
    call <SID>key_help("Q", "Quit Vim with a prompt if unsaved changes found")
    call <SID>key_help("j", "Move the selection bar down")
    call <SID>key_help("k", "Move the selection bar up")
    call <SID>key_help("J", "Move the selection bar to the bottom of the list")
    call <SID>key_help("K", "Move the selection bar to the top of the list")
    call <SID>key_help("C-f", "Move the selection bar one screen down")
    call <SID>key_help("C-b", "Move the selection bar one screen up")
    call <SID>key_help("C-d", "Move the selection bar a half screen down")
    call <SID>key_help("C-u", "Move the selection bar a half screen up")
    call <SID>key_help("w", "Go to the Workspace List view")
    call <SID>key_help("W", "Enter the Workspace List view in Search Mode")
    call <SID>key_help("o", "Go to the File List view")
    call <SID>key_help("O", "Go to the File List view in the Search Mode")
    call <SID>key_help("l", "Go to the Tab List view")
    call <SID>key_help("L", "Enter the Tab List view in Search Mode")
  elseif s:file_mode
    let b:help_tag = "ctrlspace-file-list"
    let current_list .= "FILE LIST"

    if !empty(s:search_letters)
      let current_list .= " - scoped to '" . join(s:search_letters, "") . "'"
    endif

    call <SID>key_help("CR", "Open selected file")
    call <SID>key_help("Space", "Open selected file but stays in the plugin window")

    if empty(s:search_letters)
      call <SID>key_help("BS", "Go back to the Buffer List")
    else
      call <SID>key_help("BS", "Clear search")
    endif

    call <SID>key_help("/", "Enter the Search Mode")
    call <SID>key_help('\', "Cyclic search through parent directories")
    call <SID>key_help('|', "The same as \\")
    call <SID>key_help("O", "Enter the Search Mode")

    call <SID>key_help("v", "Open selected file in a new vertical split")
    call <SID>key_help("V", "Open selected file in a new vertical split but stay in the plugin window")
    call <SID>key_help("s", "Open selected file in a new horizontal split")
    call <SID>key_help("S", "Open selected file in a new horizontal split but stay in the plugin window")
    call <SID>key_help("t", "Open selected file in a new tab")

    if s:next_tab_mode
      call <SID>key_help("T", "Open selected file in the next tab but stay in the plugin window")
    else
      call <SID>key_help("T", "Open selected file in a new tab but stay in the plugin window")
    endif

    call <SID>key_help("C-t", "Create a new tab and stay in the plugin window")
    call <SID>key_help("Y", "Copy (yank) the current tab into a new one")
    call <SID>key_help("U", "Create a new tab with all unsaved buffers")
    call <SID>key_help("=", "Change the tab name")
    call <SID>key_help("0..9", "Jump to the n-th tab (0 is for 10th one)")
    call <SID>key_help("+", "Move the current tab to the right (increase its number)")
    call <SID>key_help("-", "Move the current tab to the left (decrease its number)")
    call <SID>key_help("_", "Remove a custom tab name")
    call <SID>key_help("[", "Go to the previous (left) tab")
    call <SID>key_help("]", "Go to the next (right) tab")
    call <SID>key_help("r", "Refresh the file list (force reloading)")
    call <SID>key_help("q", "Close the list")

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
    call <SID>key_help("Q", "Quit Vim with a prompt if unsaved changes found")
    call <SID>key_help("j", "Move the selection bar down")
    call <SID>key_help("k", "Move the selection bar up")
    call <SID>key_help("J", "Move the selection bar to the bottom of the list")
    call <SID>key_help("K", "Move the selection bar to the top of the list")
    call <SID>key_help("C-f", "Move the selection bar one screen down")
    call <SID>key_help("C-b", "Move the selection bar one screen up")
    call <SID>key_help("C-d", "Move the selection bar a half screen down")
    call <SID>key_help("C-u", "Move the selection bar a half screen up")

    call <SID>key_help("o", "Go back to Buffer List")
    call <SID>key_help("C-p", "Bring back the previous searched text")
    call <SID>key_help("C-n", "Bring the next searched text")
    call <SID>key_help("C", "Close the current tab (with forgotten buffers and nonames)")
    call <SID>key_help("i", "Go into a directory having the selected file (changes its CWD)")
    call <SID>key_help("I", "Go back to the previous directory (reverse to 'i')")
    call <SID>key_help("e", "Edit a new file or a sibling of selected file")
    call <SID>key_help("E", "Explore a directory of selected file")
    call <SID>key_help("R", "Remove the selected file entirely")
    call <SID>key_help("m", "Move or rename the selected file")
    call <SID>key_help("y", "Copy the selected file")
    call <SID>key_help("w", "Toggle the Workspace List view")
    call <SID>key_help("W", "Enter the Workspace List view in Search Mode")
    call <SID>key_help("l", "Toggle the Tab List view")
    call <SID>key_help("L", "Enter the Tab List view in Search Mode")
    call <SID>key_help("b", "Toggle the Bookmark List view")
    call <SID>key_help("B", "Enter the Bookmark List view in Search Mode")
    call <SID>key_help("g", "Jump to a next tab containing the selected file")
    call <SID>key_help("G", "Jump to a previous tab containing the selected file")
  else
    let b:help_tag = "ctrlspace-buffer-list"
    let current_list .= "BUFFER LIST"

    if !empty(s:search_letters)
      let current_list .= " - scoped to '" . join(s:search_letters, "") . "'"
    endif

    if s:single_mode == 2
      let current_mode = "VISIBLE MODE"
    elseif s:single_mode == 1
      let current_mode = "SINGLE MODE"
    else
      let current_mode = "ALL MODE"
    endif

    call <SID>key_help("CR", "Open selected buffer")

    if s:zoom_mode
      let current_mode .= " - ZOOM MODE"
      call <SID>key_help("Space", "Zoom (preview) selected buffer")
    else
      call <SID>key_help("Space", "Open selected buffer and stay in the plugin window")
    endif

    call <SID>key_help("Tab", "Jump to the window containing selected buffer")
    call <SID>key_help("S-Tab", "Change the target window to one containing selected buffer")

    if !empty(s:search_letters)
      call <SID>key_help("BS", "Clear search")
    elseif !s:single_mode
      call <SID>key_help("BS", "Go back to the Single Mode")
    else
      call <SID>key_help("BS", "Close the list")
    endif

    call <SID>key_help("*", "Toggle Visible Mode")
    call <SID>key_help("/", "Toggle Search Mode")
    call <SID>key_help('\', "Cyclic search through parent directories")
    call <SID>key_help('|', "Cyclic search through parent directories in File Mode")
    call <SID>key_help("z", "Toggle Zoom Mode")
    call <SID>key_help("v", "Open selected buffer in a new vertical split")
    call <SID>key_help("V", "Open selected buffer in a new vertical split but stay in the plugin window")
    call <SID>key_help("s", "Open selected buffer in a new horizontal split")
    call <SID>key_help("S", "Open selected buffer in a new horizontal split but stay in the plugin window")
    call <SID>key_help("x", "Close the split window containing selected buffer")
    call <SID>key_help("X", "Leave the window containing selected buffer - close all others")
    call <SID>key_help("t", "Open selected buffer in a new tab")

    if s:next_tab_mode
      call <SID>key_help("T", "Open selected buffer in the next tab but stay in the plugin window")
    else
      call <SID>key_help("T", "Open selected buffer in a new tab but stay in the plugin window")
    endif

    call <SID>key_help("C-t", "Create a new tab and stay in the plugin window")
    call <SID>key_help("Y", "Copy (yank) the current tab into a new one")
    call <SID>key_help("U", "Create a new tab with all unsaved buffers")
    call <SID>key_help("=", "Change the tab name")
    call <SID>key_help("0..9", "Jump to the n-th tab (0 is for the 10th one)")
    call <SID>key_help("+", "Move the current tab to the right (increase its number)")
    call <SID>key_help("-", "Move the current tab to the left (decrease its number)")
    call <SID>key_help("_", "Remove a custom tab name")
    call <SID>key_help("[", "Go to the previous (left) tab")
    call <SID>key_help("]", "Go to the next (right) tab")

    if s:single_mode
      call <SID>key_help("{", "Move the selected buffer to to the previous (left) tab")
      call <SID>key_help("}", "Move the selected buffer to the next (right) tab")
      call <SID>key_help("<", "Copy the selected buffer to to the previous (left) tab")
      call <SID>key_help(">", "Copy the selected buffer to the next (right) tab")
    endif

    call <SID>key_help("q", "Close the list")

    if !g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running")
      call <SID>key_help("Esc", "Close the list")
    endif

    call <SID>key_help("C-c", "Close the list")
    call <SID>key_help("Q", "Quit Vim with a prompt if unsaved changes found")
    call <SID>key_help("j", "Move the selection bar down")
    call <SID>key_help("k", "Move the selection bar up")
    call <SID>key_help("J", "Move the selection bar to the bottom of the list")
    call <SID>key_help("K", "Move the selection bar to the top of the list")
    call <SID>key_help("C-f", "Move the selection bar one screen down")
    call <SID>key_help("C-b", "Move the selection bar one screen up")
    call <SID>key_help("C-d", "Move the selection bar a half screen down")
    call <SID>key_help("C-u", "Move the selection bar a half screen up")

    call <SID>key_help("p", "Move the selection bar to the previous buffer")
    call <SID>key_help("P", "Move the selection bar to the previous buffer and open it")
    call <SID>key_help("n", "Move the selection bar to the next opened buffer")
    call <SID>key_help("d", "Delete the selected buffer (close it)")
    call <SID>key_help("D", "Close all empty noname buffers")

    if s:single_mode
      call <SID>key_help("a", "Enter the All Mode")
      call <SID>key_help("A", "Enter the Search Mode combined with the All mode")
      call <SID>key_help("f", "Forget the current buffer (make it a unrelated to the current tab)")
      call <SID>key_help("c",  "Try to close selected buffer (delete if possible, forget otherwise)")
    else
      call <SID>key_help("a", "Enter the Single Mode")
      call <SID>key_help("A", "Enter the Search Mode")
    endif

    call <SID>key_help("F", "Delete (close) all forgotten buffers (unrelated to any tab)")
    call <SID>key_help("C", "Close the current tab, then perform F, and then D")
    call <SID>key_help("i", "Go into a directory having the selected buffer (changes its CWD)")
    call <SID>key_help("I", "Go back to the previous directory (reverse to 'i')")
    call <SID>key_help("e", "Edit a new file or a sibling of selected buffer")
    call <SID>key_help("E", "Explore a directory of selected buffer")
    call <SID>key_help("R", "Remove the selected buffer (file) entirely (from the disk too)")
    call <SID>key_help("m", "Move or rename the selected buffer (together with its file)")
    call <SID>key_help("y", "Copy selected file")
    call <SID>key_help("C-p", "Bring back the previous searched text")
    call <SID>key_help("C-n", "Bring the next searched text")
    call <SID>key_help("g", "Jump to a next tab containing the selected buffer")
    call <SID>key_help("G", "Jump to a previous tab containing the selected buffer")
    call <SID>key_help("w", "Toggle the Workspace List view")
    call <SID>key_help("W", "Enter the Workspace List view in Search Mode")
    call <SID>key_help("l", "Toggle the Tab List view")
    call <SID>key_help("L", "Enter the Tab List view in Search Mode")
    call <SID>key_help("b", "Toggle the Bookmark List view")
    call <SID>key_help("B", "Enter the Bookmark List view in Search Mode")
    call <SID>key_help("o", "Toggle the File List (Open List)")
    call <SID>key_help("O", "Enter the Search Mode in the File List")
    call <SID>key_help("C-l", "Load the last active workspace (if present)")
    call <SID>key_help("C-s", "Save the current workspace")
    call <SID>key_help("N", "Make a new workspace (closes all buffers)")
  endif

  let title_line = []

  if !empty(current_list)
    call add(title_line, current_list)
  endif

  if !empty(current_mode)
    call add(title_line, current_mode)
  endif

  call <SID>puts("Context help for " . join(title_line, " - "))
  call <SID>puts("You have following keys available (press 'h' for more detailed help):")
  call <SID>puts("")

  for key_info in b:help_key_descriptions
    call<SID>puts(key_info.key . " | " . key_info.description)
  endfor

  call <SID>puts("")
  call <SID>puts(g:ctrlspace_symbols.cs . " CtrlSpace 4.2.14 (c) 2013-2015 Szymon Wrozynski and Contributors")

  setlocal modifiable

  let b:bufcount = <SID>text_buffer_size()

  " set up window height
  if b:bufcount > g:ctrlspace_height
    if b:bufcount < <SID>max_height()
      silent! exe "resize " . b:bufcount
    else
      silent! exe "resize " . <SID>max_height()
    endif
  endif

  silent! put! =<SID>flush_text_buffer()
  normal! GkJ

  let fill = <SID>make_filler()

  while winheight(0) > line(".")
    silent! put =fill
  endwhile

  normal! 0
  normal! gg

  setlocal nomodifiable
endfunction

" toggled the buffer list on/off
function! <SID>ctrlspace_toggle(internal)
  if !a:internal
    let s:help_mode                      = 0
    let s:single_mode                    = 1
    let s:nop_mode                       = 0
    let s:new_search_performed           = 0
    let s:search_mode                    = 0
    let s:file_mode                      = 0
    let s:workspace_mode                 = 0
    let s:tablist_mode                   = 0
    let s:bookmark_mode                  = 0
    let s:last_browsed_workspace         = 0
    let s:restored_search_mode           = 0
    let s:next_tab_mode                  = 0
    let s:search_letters                 = []
    let t:ctrlspace_search_history_index = -1
    let s:search_history_index           = -1
    let s:project_root                   = <SID>find_project_root()
    let s:active_bookmark                = <SID>find_active_bookmark()

    unlet! s:last_searched_directory

    if s:last_project_root != s:project_root
      let s:files             = []
      let s:last_project_root = s:project_root

      call <SID>set_workspace_names()
    endif

    if empty(s:symbol_sizes)
      let s:symbol_sizes.iav  = max([strwidth(g:ctrlspace_symbols.iv), strwidth(g:ctrlspace_symbols.ia)])
      let s:symbol_sizes.im   = strwidth(g:ctrlspace_symbols.im)
      let s:symbol_sizes.dots = strwidth(g:ctrlspace_symbols.dots)
    endif

    call <SID>handle_vim_settings("start")
  endif

  " if we get called and the list is open --> close it
  if bufexists(s:plugin_buffer)
    if bufwinnr(s:plugin_buffer) != -1
      call <SID>kill(s:plugin_buffer, 1)
      return
    else
      call <SID>kill(s:plugin_buffer, 0)
      if !a:internal
        let t:ctrlspace_start_window = winnr()
        let t:ctrlspace_winrestcmd = winrestcmd()
        let t:ctrlspace_activebuf = bufnr("")
      endif
    endif
  elseif !a:internal
    " make sure zoom window is closed
    silent! exe "pclose"
    let t:ctrlspace_start_window = winnr()
    let t:ctrlspace_winrestcmd = winrestcmd()
    let t:ctrlspace_activebuf = bufnr("")
  endif

  if s:zoom_mode
    let t:ctrlspace_activebuf = bufnr("")
  endif

  let bufcount      = bufnr("$")
  let displayedbufs = 0
  let buflist       = []

  let max_results   = g:ctrlspace_max_search_results

  if max_results == -1
    let max_results = <SID>max_height()
  endif

  " create the buffer first & set it up
  silent! exe "noautocmd botright pedit CtrlSpace"
  silent! exe "noautocmd wincmd P"
  silent! exe "resize" g:ctrlspace_height

  " zoom start window in Zoom Mode
  if s:zoom_mode
    silent! exe t:ctrlspace_start_window . "wincmd w"
    vert resize | resize
    silent! exe "noautocmd wincmd P"
  endif

  call <SID>set_up_buffer()

  if s:help_mode
    call <SID>display_help()
    call <SID>set_statusline()
    return
  endif

  let noises   = []
  let patterns = []

  if s:file_mode
    if empty(s:files)

      let s:all_files_cached = []

      " try to pick up files from cache
      call <SID>load_files_from_cache()

      if empty(s:files)
        let action = "Collecting files..."
        call <SID>msg(action)

        let unique_files = {}

        for fname in empty(g:ctrlspace_glob_command) ? split(globpath('.', '**'), '\n') : split(system(g:ctrlspace_glob_command), '\n')
          let fname_modified = fnamemodify(has("win32") ? substitute(fname, "\r$", "", "") : fname, ":.")

          if isdirectory(fname_modified) || (fname_modified =~# g:ctrlspace_ignored_files)
            continue
          endif

          let unique_files[fname_modified] = 1
        endfor

        let s:files = keys(unique_files)
        call <SID>save_files_in_cache()
      else
        let action = "Loading files..."
        call <SID>msg(action)
      endif

      let s:all_files_cached = map(s:files[0:g:ctrlspace_max_files - 1],
            \ '{ "number": v:key + 1, "raw": v:val, "search_noise": 0 }')

      call sort(s:all_files_cached, function("s:compare_raw_names"))
      let s:all_files_buftext = <SID>prepare_buftext_to_display(s:all_files_cached)

      redraw!
      call <SID>msg(action . " Done (" . len(s:all_files_cached). "/" . len(s:files) . ").")
    endif

    let bufcount = len(s:files)
  elseif s:workspace_mode
    let bufcount = len(s:workspace_names)
  elseif s:tablist_mode
    let bufcount = tabpagenr("$")
  elseif s:bookmark_mode
    let bufcount = len(s:bookmarks)
  endif

  if (s:file_mode && empty(s:search_letters)) || (s:file_mode && g:ctrlspace_use_ruby_bindings && has("ruby"))
    if empty(s:search_letters)
      let buflist = s:all_files_cached
    else
      ruby CtrlSpace.get_file_search_results(VIM.evaluate("max_results"))

      let buflist = b:file_search_results
      let patterns = b:file_search_patterns
    endif

    let displayedbufs = len(buflist)
  else
    for i in range(1, bufcount)
      if s:file_mode
        let bufname = s:files[i - 1]
      elseif s:workspace_mode
        let bufname = s:workspace_names[i - 1]
      elseif s:tablist_mode
        let tab_winnr       = tabpagewinnr(i)
        let tab_buflist     = tabpagebuflist(i)
        let tab_bufnr       = tab_buflist[tab_winnr - 1]
        let tab_bufname     = bufname(tab_bufnr)
        let tab_bufs_number = ctrlspace#tab_buffers_number(i)
        let tab_title       = ctrlspace#tab_title(i, tab_bufnr, tab_bufname)

        if !g:ctrlspace_unicode_font && !empty(tab_bufs_number)
          let tab_bufs_number = ":" . tab_bufs_number
        end

        let bufname         = string(i) . tab_bufs_number . " " . tab_title
      elseif s:bookmark_mode
        let bufname = s:bookmarks[i - 1].name
      else
        if !bufexists(i)
          continue
        endif

        if ((s:single_mode == 1) && !exists('t:ctrlspace_list[' . i . ']')) ||
              \ ((s:single_mode == 2) && (bufwinnr(i) == -1))
          continue
        endif

        let bufname = fnamemodify(bufname(i), ":.")

        if !strlen(bufname) && (getbufvar(i, '&modified') || (bufwinnr(i) != -1))
          let bufname = '[' . i . '*No Name]'
        endif
      endif

      if strlen(bufname) && (s:file_mode || s:workspace_mode || s:tablist_mode || s:bookmark_mode ||
            \ (getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')))
        let search_noise = empty(s:search_letters) ? 0 : <SID>find_lowest_search_noise(bufname)

        if search_noise == -1
          continue
        elseif !empty(s:search_letters)
          if !max_results
            let displayedbufs += 1
            call add(buflist, { "number": i, "raw": bufname, "search_noise": search_noise })
            call add(patterns, b:last_search_pattern)
          elseif displayedbufs < max_results
            let displayedbufs += 1
            call add(buflist, { "number": i, "raw": bufname, "search_noise": search_noise })
            call add(noises, search_noise)
            call add(patterns, b:last_search_pattern)
          else
            let max_index = index(noises, max(noises))
            if noises[max_index] > search_noise
              call remove(noises, max_index)
              call insert(noises, search_noise, max_index)
              call remove(patterns, max_index)
              call insert(patterns, b:last_search_pattern, max_index)
              call remove(buflist, max_index)
              call insert(buflist, { "number": i, "raw": bufname, "search_noise": search_noise }, max_index)
            endif
          endif
        else
          let displayedbufs += 1
          call add(buflist, { "number": i, "raw": bufname, "search_noise": search_noise })
        endif
      endif
    endfor
  endif

  " set up window height
  if displayedbufs > g:ctrlspace_height
    if displayedbufs < <SID>max_height()
      silent! exe "resize " . displayedbufs
    else
      silent! exe "resize " . <SID>max_height()
    endif
  endif

  " adjust search timing
  let search_timing_reference = s:file_mode ? len(s:files) : len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))

  if search_timing_reference < g:ctrlspace_search_timing[0]
    let search_timing = g:ctrlspace_search_timing[0]
  elseif search_timing_reference > g:ctrlspace_search_timing[1]
    let search_timing = g:ctrlspace_search_timing[1]
  else
    let search_timing = search_timing_reference
  endif

  silent! exe "set updatetime=" . search_timing

  call <SID>display_list(displayedbufs, buflist)
  call <SID>set_statusline()

  if !empty(s:search_letters)
    call <SID>display_search_patterns(patterns)
  endif

  if s:workspace_mode
    if s:last_browsed_workspace
      let activebufline = s:last_browsed_workspace
    else
      let activebufline = 1

      if !empty(s:active_workspace_name)
        let current_workspace = s:active_workspace_name
      elseif !empty(s:last_active_workspace)
        let current_workspace = s:last_active_workspace
      else
        let current_workspace = ""
      endif

      if !empty(current_workspace)
        let active_workspace_line = 0

        for workspace_name in buflist
          let active_workspace_line += 1

          if current_workspace ==# workspace_name.raw
            let activebufline = active_workspace_line
            break
          endif
        endfor
      endif
    endif
  elseif s:tablist_mode
    let activebufline = tabpagenr()
  elseif s:bookmark_mode
    let activebufline = 1

    if !empty(s:active_bookmark)
      let active_bookmark_line = 0

      for bm_name in buflist
        let active_bookmark_line += 1

        if s:active_bookmark.name ==# bm_name.raw
          let activebufline = active_bookmark_line
          break
        endif
      endfor
    endif
  else
    let activebufline = s:file_mode ? line("$") : <SID>find_activebufline(t:ctrlspace_activebuf, buflist)
  endif

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:buflist = buflist
  let b:bufcount = displayedbufs

  " go to the correct line
  if !empty(s:search_letters) && s:new_search_performed
    call<SID>move_selection_bar(line("$"))
    if !s:search_mode
      let s:new_search_performed = 0
    endif
  else
    call <SID>move_selection_bar(activebufline)
  endif
  normal! zb
endfunction

function! <SID>clear_search_mode()
  let s:search_letters                 = []
  let s:search_mode                    = 0
  let t:ctrlspace_search_history_index = -1
  let s:search_history_index           = -1
  unlet! s:last_searched_directory
  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>update_search_results()
  if s:update_search_results
    let s:update_search_results = 0
    call <SID>kill(0, 0)
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>add_search_letter(letter)
  call add(s:search_letters, a:letter)
  let s:new_search_performed = 1
  let s:update_search_results = 1
  unlet! s:last_searched_directory
  call <SID>set_statusline()
  redraws
endfunction

function! <SID>remove_search_letter()
  call remove(s:search_letters, -1)
  let s:new_search_performed = 1
  let s:update_search_results = 1
  unlet! s:last_searched_directory
  call <SID>set_statusline()
  redraws
endfunction

function! <SID>clear_search_letters()
  if !empty(s:search_letters)
    let s:search_letters = []
    let s:new_search_performed = 1
    let s:update_search_results = 1
    unlet! s:last_searched_directory
    call <SID>set_statusline()
    redraws
  endif
endfunction

function! <SID>switch_search_mode(switch)
  if (a:switch == 0) && !empty(s:search_letters)
    call <SID>append_to_search_history()
  endif

  let s:search_mode = a:switch
  let s:update_search_results = 1

  call <SID>update_search_results()
endfunction

function! <SID>insert_search_text(text)
  let letters = []

  for i in range(0, strlen(a:text) - 1)
    if a:text[i] =~? "^[A-Z0-9]$"
      call add(letters, a:text[i])
    endif
  endfor

  if !empty(letters)
    let s:search_letters = letters
    call <SID>append_to_search_history()
    let t:ctrlspace_search_history_index = 0
    let s:search_history_index           = 0
    let s:update_search_results          = 1
    call <SID>update_search_results()
    return 1
  endif

  return 0
endfunction

function! <SID>get_selected_directory()
  let bufentry = b:buflist[line(".") - 1]
  return fnamemodify(bufentry.raw, ":h")
endfunction

function! <SID>search_parent_directory_cycle()
  let candidate = <SID>get_selected_directory()

  if !exists("s:last_searched_directory") || s:last_searched_directory != candidate
    let s:last_searched_directory = candidate
  else
    let s:last_searched_directory = fnamemodify(s:last_searched_directory, ":h")
  endif

  call <SID>insert_search_text(s:last_searched_directory)
endfunction

function! <SID>decorate_with_indicators(name, bufnum)
  let indicators = ""

  if getbufvar(a:bufnum, "&modified")
    let indicators .= g:ctrlspace_symbols.im
  endif

  let win = bufwinnr(a:bufnum)

  if win == t:ctrlspace_start_window
    let indicators .= g:ctrlspace_symbols.ia
  elseif win != -1
    let indicators .= g:ctrlspace_symbols.iv
  endif

  if !empty(indicators)
    return a:name . " " . indicators
  else
    return a:name
  endif
endfunction

function! <SID>getbufvar_with_default(nr, name, default)
  let value = getbufvar(a:nr, a:name)
  return type(value) == type("") && empty(value) ? a:default : value
endfunction

function! <SID>gettabvar_with_default(nr, name, default)
  let value = gettabvar(a:nr, a:name)
  return type(value) == type("") && empty(value) ? a:default : value
endfunction

function! <SID>find_activebufline(activebuf, buflist)
  let activebufline = 0

  let max_counter = 0
  let last_line   = 0

  for bufentry in a:buflist
    let activebufline += 1
    if a:activebuf == bufentry.number
      return activebufline
    endif

    let current_jump_counter = <SID>getbufvar_with_default(bufentry.number, "ctrlspace_jump_counter", 0)

    if current_jump_counter > max_counter
      let max_counter = current_jump_counter
      let last_line = activebufline
    endif
  endfor

  return (last_line > 0) ? last_line : activebufline
endfunction

function! <SID>goto_start_window()
  silent! exe t:ctrlspace_start_window . "wincmd w"

  if winrestcmd() != t:ctrlspace_winrestcmd
    silent! exe t:ctrlspace_winrestcmd

    if winrestcmd() != t:ctrlspace_winrestcmd
      wincmd =
    endif
  endif
endfunction

function! <SID>kill(plugin_buffer, final)
  " added workaround for strange Vim behavior when, when kill starts with some delay
  " (in a wrong buffer). This happens in some Nop modes (in a File List view).
  if (exists("s:killing_now") && s:killing_now) || (!a:plugin_buffer && &ft != "ctrlspace")
    return
  endif

  let s:killing_now = 1

  if exists("b:updatetime_save")
    silent! exe "set updatetime=" . b:updatetime_save
  endif

  if exists("b:timeoutlen_save")
    silent! exe "set timeoutlen=" . b:timeoutlen_save
  endif

  if exists("b:mouse_save")
    silent! exe "set mouse=" . b:mouse_save
  endif

  " shellslash support for win32
  if exists("b:nossl_save") && b:nossl_save
    set nossl
  endif

  if a:plugin_buffer
    silent! exe ':' . a:plugin_buffer . 'bwipeout'
  else
    bwipeout
  endif

  if a:final
    call <SID>handle_vim_settings("stop")

    if s:restored_search_mode
      call <SID>append_to_search_history()
    endif

    call <SID>goto_start_window()

    if s:zoom_mode
      exec ":b " . s:zoom_mode_original_buffer
      unlet s:zoom_mode_original_buffer
      let s:zoom_mode = 0
    endif
  endif

  unlet s:killing_now
endfunction

function! <SID>tab_command(key)
  call <SID>kill(0, 1)

  if a:key ==# "T"
    silent! exe "tabnew"
  elseif a:key ==# "Y"
    let source_tab_nr = tabpagenr()
    let source_label = exists("t:ctrlspace_label") ? t:ctrlspace_label : ""
    let source_list = copy(t:ctrlspace_list)

    if exists("t:ctrlspace_search_history")
      let source_search_history = copy(t:ctrlspace_search_history)
    endif

    if exists("t:ctrlspace_search_history_index")
      let source_search_history_index = copy(t:ctrlspace_search_history_index)
    endif

    silent! exe "tabnew"

    let label = empty(source_label) ? ("Copy of tab " . source_tab_nr) : (source_label . " (copy)")
    call <SID>set_tab_label(tabpagenr(), label, 1)

    let t:ctrlspace_list = source_list

    if exists("source_search_history")
      let t:ctrlspace_search_history = source_search_history
    endif

    if exists("source_search_history_index")
      let t:ctrlspace_search_history_index = source_search_history_index
    endif

    call <SID>ctrlspace_toggle(0)
    call <SID>kill(0, 1)
    call <SID>ctrlspace_toggle(0)
    call <SID>close_buffer()
    call <SID>jump("previous")
    call <SID>load_buffer()
  elseif a:key ==# "["
    silent! exe "normal! gT"
  elseif a:key ==# "]"
    silent! exe "normal! gt"
  else
    let tab_nr   = str2nr((a:key == "0") ? "10" : a:key)
    let last_tab = tabpagenr("$")

    if tab_nr > last_tab
      let tab_nr = last_tab
    endif

    silent! exe "normal! " . tab_nr . "gt"
  endif

  call <SID>ctrlspace_toggle(0)
endfunction

function! <SID>goto_window()
  let nr = str2nr(<SID>get_selected_buffer())

  if bufwinnr(nr) != -1
    call <SID>kill(0, 1)
    silent! exe bufwinnr(nr) . "wincmd w"
    return 1
  endif

  return 0
endfunction

function! <SID>keypressed(key)
  let term_s_tab         = s:key_esc_sequence && (a:key ==# "Z")
  let s:key_esc_sequence = 0

  if a:key ==# "?"
    call <SID>kill(0, 0)
    let s:help_mode = !s:help_mode
    call <SID>ctrlspace_toggle(1)
    return
  endif

  if s:help_mode
    if a:key ==# "h" && exists("b:help_tag")
      let help_tag = b:help_tag
      call <SID>kill(0, 1)
      silent! exe "help " . help_tag
    elseif a:key ==# "BS"
      call <SID>kill(0, 0)
      let s:help_mode = !s:help_mode
      call <SID>ctrlspace_toggle(1)
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move_cursor("down")
    elseif a:key ==# "k"
      call <SID>move_cursor("up")
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_cursor("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_cursor("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_cursor("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_cursor("mouse")
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_cursor(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_cursor(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_cursor("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_cursor("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_cursor("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_cursor("half_pgup")
    endif
    return
  endif

  if s:nop_mode
    if s:search_mode
      if (a:key ==# "C-u") || (a:key ==# "C-w")
        call <SID>clear_search_letters()
      endif
    else
      if a:key ==# "a"
        let s:tablist_mode   = 0
        let s:bookmark_mode  = 0
        let s:workspace_mode = 0
        let s:file_mode      = 0
        call <SID>toggle_single_mode()
      elseif a:key ==# "A"
        let s:tablist_mode   = 0
        let s:bookmark_mode  = 0
        let s:workspace_mode = 0
        let s:file_mode      = 0
        call <SID>toggle_single_mode()
        call <SID>switch_search_mode(1)
      elseif a:key ==# "o"
        let s:tablist_mode   = 0
        let s:bookmark_mode  = 0
        let s:workspace_mode = 0
        call <SID>toggle_file_mode()
      elseif a:key ==# "O"
        if !s:file_mode
          let s:tablist_mode   = 0
          let s:bookmark_mode  = 0
          let s:workspace_mode = 0
          call <SID>toggle_file_mode()
        endif
        call <SID>switch_search_mode(1)
      elseif a:key ==# "w"
        if s:workspace_mode
          call <SID>kill(0, 0)
          let s:workspace_mode = 0
          call <SID>ctrlspace_toggle(1)
        elseif empty(s:workspace_names)
          call <SID>save_first_workspace()
        else
          call <SID>kill(0, 0)
          let s:file_mode      = 0
          let s:tablist_mode   = 0
          let s:bookmark_mode  = 0
          let s:workspace_mode = 1
          call <SID>ctrlspace_toggle(1)
        endif
      elseif a:key ==# "W"
        if !s:workspace_mode
          if empty(s:workspace_names)
            call <SID>save_first_workspace()
          else
            call <SID>kill(0, 0)
            let s:file_mode      = 0
            let s:tablist_mode   = 0
            let s:bookmark_mode  = 0
            let s:workspace_mode = 1
            call <SID>ctrlspace_toggle(1)
            call <SID>switch_search_mode(1)
          endif
        else
          call <SID>switch_search_mode(1)
        endif
      elseif a:key ==# "l"
        if s:tablist_mode
          call <SID>kill(0, 0)
          let s:tablist_mode = 0
          call <SID>ctrlspace_toggle(1)
        else
          call <SID>kill(0, 0)
          let s:file_mode      = 0
          let s:tablist_mode   = 1
          let s:bookmark_mode  = 0
          let s:workspace_mode = 0
          call <SID>ctrlspace_toggle(1)
        endif
      elseif a:key ==# "L"
        if !s:tablist_mode
          call <SID>kill(0, 0)
          let s:file_mode      = 0
          let s:tablist_mode   = 1
          let s:bookmark_mode  = 0
          let s:workspace_mode = 0
          call <SID>ctrlspace_toggle(1)
          call <SID>switch_search_mode(1)
        else
          call <SID>switch_search_mode(1)
        endif
      elseif a:key ==# "b"
        if s:bookmark_mode
          call <SID>kill(0, 0)
          let s:bookmark_mode = 0
          call <SID>ctrlspace_toggle(1)
        else
          if empty(s:bookmarks)
            call <SID>add_first_bookmark()
          else
            call <SID>kill(0, 0)
            let s:file_mode      = 0
            let s:tablist_mode   = 0
            let s:bookmark_mode  = 1
            let s:workspace_mode = 0
            call <SID>ctrlspace_toggle(1)
          endif
        endif
      elseif a:key ==# "B"
        if !s:bookmark_mode
          if empty(s:bookmarks)
            call <SID>add_first_bookmark()
          else
            call <SID>kill(0, 0)
            let s:file_mode      = 0
            let s:tablist_mode   = 0
            let s:bookmark_mode  = 1
            let s:workspace_mode = 0
            call <SID>ctrlspace_toggle(1)
            call <SID>switch_search_mode(1)
          endif
        else
          call <SID>switch_search_mode(1)
        endif
      elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
        call <SID>kill(0, 1)
      elseif a:key ==# "Q"
        call <SID>quit_vim()
      elseif a:key ==# "C-p"
        call <SID>restore_search_letters("previous")
      elseif a:key ==# "C-n"
        call <SID>restore_search_letters("next")
      endif
    endif

    if (a:key ==# "BS") || (a:key ==# "C-h")
      if s:search_mode
        if empty(s:search_letters)
          call <SID>clear_search_mode()
        else
          call <SID>remove_search_letter()
        endif
      elseif !empty(s:search_letters)
        call <SID>clear_search_mode()
      endif
    elseif (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    endif

    return
  endif

  if s:search_mode
    if (a:key ==# "BS") || (a:key ==# "C-h")
      if empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        call <SID>remove_search_letter()
      endif
    elseif (a:key ==# "/") || (a:key ==# "CR")
      call <SID>switch_search_mode(0)
    elseif (a:key ==# "C-u") || (a:key ==# "C-w")
      call <SID>clear_search_letters()
    elseif a:key =~? "^[A-Z0-9]$"
      call <SID>add_search_letter(a:key)
    elseif (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    endif
  elseif s:workspace_mode == 1
    if a:key ==# "Tab"
      call <SID>load_workspace(0, <SID>get_selected_workspace_name())
    elseif a:key ==# "CR"
      call <SID>load_workspace(0, <SID>get_selected_workspace_name())
      call <SID>ctrlspace_toggle(0)
    elseif a:key ==# "Space"
      call <SID>load_workspace(0, <SID>get_selected_workspace_name())
      call <SID>start_ctrlspace_and_feedkeys("w")
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "a"
      call <SID>load_workspace(1, <SID>get_selected_workspace_name())
    elseif a:key ==# "n"
      call <SID>new_workspace()
    elseif a:key ==# "N"
      call <SID>new_workspace()
      call <SID>start_ctrlspace_and_feedkeys("w")
    elseif a:key ==# "s"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 2
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "C-s"
      if empty(s:active_workspace_name)
        call <SID>save_first_workspace()
      else
        call <SID>save_workspace(s:active_workspace_name)
      endif
    elseif a:key ==# "C-l"
      call <SID>load_last_active_workspace()
    elseif a:key ==# "w"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        let s:last_browsed_workspace = line(".")
        call <SID>kill(0, 0)
        let s:workspace_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif (a:key ==# "/") || (a:key ==# "W")
      call <SID>switch_search_mode(1)
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif a:key ==# "d"
      call <SID>delete_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "="
      call <SID>rename_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "j"
      call <SID>move_selection_bar("down")
    elseif a:key ==# "k"
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      call <SID>load_workspace(0, <SID>get_selected_workspace_name())
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
    elseif a:key ==# "l"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "L"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    elseif a:key ==# "b"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        let s:last_browsed_workspace = line(".")
        call <SID>kill(0, 0)
        let s:workspace_mode = 0
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "B"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        let s:last_browsed_workspace = line(".")
        call <SID>kill(0, 0)
        let s:workspace_mode = 0
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "o"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "O"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    endif
  elseif s:workspace_mode == 2
    if a:key ==# "Tab"
      call <SID>save_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "CR"
      if <SID>save_workspace(<SID>get_selected_workspace_name())
        call <SID>ctrlspace_toggle(0)
      endif
    elseif a:key ==# "Space"
      if <SID>save_workspace(<SID>get_selected_workspace_name())
        call <SID>start_ctrlspace_and_feedkeys("w")
      endif
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "n"
      call <SID>new_workspace()
    elseif a:key ==# "N"
      call <SID>new_workspace()
      call <SID>start_ctrlspace_and_feedkeys("w")
    elseif a:key ==# "s"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "C-s"
      if empty(s:active_workspace_name)
        call <SID>save_first_workspace()
      else
        call <SID>save_workspace(s:active_workspace_name)
      endif
    elseif a:key ==# "C-l"
      call <SID>load_last_active_workspace()
    elseif a:key ==# "w"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        let s:last_browsed_workspace = line(".")
        call <SID>kill(0, 0)
        let s:workspace_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif (a:key ==# "/") || (a:key ==# "W")
      call <SID>switch_search_mode(1)
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif a:key ==# "d"
      call <SID>delete_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "="
      call <SID>rename_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "j"
      call <SID>move_selection_bar("down")
    elseif a:key ==# "k"
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      call <SID>save_workspace(<SID>get_selected_workspace_name())
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
    elseif a:key ==# "l"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "L"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    elseif a:key ==# "b"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        let s:last_browsed_workspace = line(".")
        call <SID>kill(0, 0)
        let s:workspace_mode = 0
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "B"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        let s:last_browsed_workspace = line(".")
        call <SID>kill(0, 0)
        let s:workspace_mode = 0
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "o"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "O"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    endif
  elseif s:tablist_mode
    if a:key ==# "Tab"
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
    elseif a:key ==# "CR"
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
    elseif a:key ==# "Space"
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key =~? "^[0-9]$"
      let tab_nr   = str2nr((a:key == "0") ? "10" : a:key)
      let last_tab = tabpagenr("$")

      if tab_nr > last_tab
        let tab_nr = last_tab
      endif

      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "p"
      call <SID>jump("previous")
    elseif a:key ==# "P"
      call <SID>jump("previous")
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
    elseif a:key ==# "n"
      call <SID>jump("next")
    elseif a:key ==# "c"
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
      call <SID>close_tab()
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif (a:key ==# "t") || (a:key ==# "a")
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
      call <SID>tab_command("T")
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "y"
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
      call <SID>tab_command("Y")
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "["
      call <SID>move_selection_bar(tabpagenr())
      call feedkeys("k\<Space>")
    elseif a:key ==# "]"
      call <SID>move_selection_bar(tabpagenr())
      call feedkeys("j\<Space>")
    elseif a:key ==# "="
      let tab_nr = <SID>get_selected_buffer()
      call <SID>new_tab_label(tab_nr)
      call <SID>kill(0, 0)
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "_"
      let tab_nr = <SID>get_selected_buffer()
      call <SID>remove_tab_label(tab_nr)
      call <SID>kill(0, 0)
      call <SID>ctrlspace_toggle(1)
      redraw!
    elseif (a:key ==# "+") || (a:key ==# "}")
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      silent! exe "tabm" . tabpagenr()
      call <SID>ctrlspace_toggle(0)
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif (a:key ==# "-") || (a:key ==# "{")
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      silent! exe "tabm" . (tabpagenr() - 2)
      call <SID>ctrlspace_toggle(0)
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "l"
      call <SID>kill(0, 0)
      let s:tablist_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "L"
      call <SID>switch_search_mode(1)
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        call <SID>kill(0, 0)
        let s:tablist_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "/"
      call <SID>switch_search_mode(1)
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move_selection_bar("down")
    elseif a:key ==# "k"
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      let tab_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      silent! exe "normal! " . tab_nr . "gt"
      call <SID>ctrlspace_toggle(0)
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
    elseif a:key ==# "w"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:tablist_mode = 0
        let s:workspace_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "W"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:tablist_mode = 0
        let s:workspace_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "b"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        call <SID>kill(0, 0)
        let s:tablist_mode = 0
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "B"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        call <SID>kill(0, 0)
        let s:tablist_mode = 0
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "o"
      if !<SID>project_root_found()
        return
      endif
      call <SID>kill(0, 0)
      let s:tablist_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "O"
      if !<SID>project_root_found()
        return
      endif
      call <SID>kill(0, 0)
      let s:tablist_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    elseif a:key ==# "u"
      if <SID>collect_unsaved_buffers()
        call feedkeys("l")
      endif
    endif
  elseif s:bookmark_mode
    if a:key ==# "Tab"
      let bm_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      call <SID>goto_bookmark(bm_nr)
      call <SID>delayed_msg()
    elseif a:key ==# "CR"
      let bm_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      call <SID>goto_bookmark(bm_nr)
      call <SID>ctrlspace_toggle(0)
      call <SID>delayed_msg()
    elseif a:key ==# "Space"
      let bm_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      call <SID>goto_bookmark(bm_nr)
      call <SID>ctrlspace_toggle(0)
      call <SID>kill(0, 0)
      let s:bookmark_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>delayed_msg()
    elseif a:key ==# "="
      let current_line = line(".")
      let bm_nr = <SID>get_selected_buffer()
      call <SID>change_bookmark_name(bm_nr)
      call <SID>kill(0, 0)
      call <SID>ctrlspace_toggle(1)
      call <SID>move_selection_bar(current_line)
    elseif a:key ==# "e"
      let bm_nr = <SID>get_selected_buffer()
      let current_line = line(".")
      if <SID>change_bookmark_directory(bm_nr)
        call <SID>kill(0, 1)
        call <SID>ctrlspace_toggle(0)
        call <SID>kill(0, 0)
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>move_selection_bar(current_line)
        call <SID>delayed_msg()
      endif
    elseif a:key ==# "a"
      let bm_nr = <SID>get_selected_buffer()
      if <SID>add_new_bookmark(bm_nr)
        call <SID>kill(0, 1)
        call <SID>ctrlspace_toggle(0)
        call <SID>kill(0, 0)
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>delayed_msg()
      endif
    elseif a:key ==# "A"
      if <SID>add_new_bookmark(0)
        call <SID>kill(0, 1)
        call <SID>ctrlspace_toggle(0)
        call <SID>kill(0, 0)
        let s:bookmark_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>delayed_msg()
      endif
    elseif a:key ==# "d"
      let bm_nr = <SID>get_selected_buffer()
      call <SID>remove_bookmark(bm_nr)
      call <SID>kill(0, 1)
      call <SID>ctrlspace_toggle(0)
      call <SID>kill(0, 0)
      let s:bookmark_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>delayed_msg()
    elseif a:key ==# "p"
      call <SID>jump("previous")
    elseif a:key ==# "P"
      call <SID>jump("previous")
      let bm_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      call <SID>goto_bookmark(bm_nr)
      call <SID>ctrlspace_toggle(0)
    elseif a:key ==# "n"
      call <SID>jump("next")
    elseif a:key ==# "b"
      call <SID>kill(0, 0)
      let s:bookmark_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        call <SID>kill(0, 0)
        let s:bookmark_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif (a:key ==# "/") || (a:key ==# "B")
      call <SID>switch_search_mode(1)
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move_selection_bar("down")
    elseif a:key ==# "k"
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      let bm_nr = <SID>get_selected_buffer()
      call <SID>kill(0, 1)
      call <SID>goto_bookmark(bm_nr)
      call <SID>ctrlspace_toggle(0)
      call <SID>delayed_msg()
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
    elseif a:key ==# "w"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:bookmark_mode = 0
        let s:workspace_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "W"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:bookmark_mode = 0
        let s:workspace_mode = 1
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "l"
      call <SID>kill(0, 0)
      let s:bookmark_mode = 0
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "L"
      call <SID>kill(0, 0)
      let s:bookmark_mode = 0
      let s:tablist_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    elseif a:key ==# "o"
      if !<SID>project_root_found()
        return
      endif
      call <SID>kill(0, 0)
      let s:bookmark_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "O"
      if !<SID>project_root_found()
        return
      endif
      call <SID>kill(0, 0)
      let s:bookmark_mode = 0
      let s:file_mode = 1
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    endif
  elseif s:file_mode
    if a:key ==# "CR"
      call <SID>load_file()
    elseif a:key ==# "Space"
      call <SID>load_many_files()
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        call <SID>toggle_file_mode()
      endif
    elseif (a:key ==# "/") || (a:key ==# "O")
      call <SID>switch_search_mode(1)
    elseif (a:key ==# "BSlash") || (a:key ==# "Bar")
      call <SID>search_parent_directory_cycle()
    elseif a:key ==# "v"
      call <SID>load_file("vs")
    elseif a:key ==# "V"
      call <SID>load_many_files("vs")
    elseif a:key ==# "s"
      call <SID>load_file("sp")
    elseif a:key ==# "S"
      call <SID>load_many_files("sp")
    elseif a:key ==# "t"
      call <SID>load_file("tabnew")
    elseif a:key ==# "T"
      if s:next_tab_mode
        call <SID>load_many_files("tabnext", "tabprevious")
      else
        let s:next_tab_mode = 1
        call <SID>load_many_files("tabnew", "tabprevious")
      endif
    elseif a:key ==# "C-t"
      call <SID>tab_command("T")
    elseif a:key ==# "Y"
      call <SID>tab_command(a:key)
    elseif a:key ==# "="
      call <SID>new_tab_label(0)
      call <SID>set_statusline()
      redraws
    elseif a:key =~? "^[0-9]$"
      call <SID>tab_command(a:key)
    elseif a:key ==# "+"
      silent! exe "tabm" . tabpagenr()
      call <SID>set_statusline()
      redraws
    elseif a:key ==# "-"
      silent! exe "tabm" . (tabpagenr() - 2)
      call <SID>set_statusline()
      redraws
    elseif a:key ==# "_"
      call <SID>remove_tab_label(0)
      call <SID>set_statusline()
      redraw!
    elseif a:key ==# "["
      call <SID>tab_command(a:key)
    elseif a:key ==# "]"
      call <SID>tab_command(a:key)
    elseif a:key ==# "r"
      call <SID>refresh_files()
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move_selection_bar("down")
    elseif a:key ==# "k"
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      call <SID>load_file()
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
    elseif a:key ==# "o"
      call <SID>toggle_file_mode()
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif a:key ==# "C"
      call <SID>close_tab()
    elseif a:key ==# "e"
      call <SID>edit_file()
    elseif a:key ==# "i"
      call <SID>goto_directory(0)
    elseif a:key ==# "I"
      call <SID>goto_directory(1)
    elseif a:key ==# "E"
      call <SID>explore_directory()
    elseif a:key ==# "R"
      call <SID>remove_file()
    elseif a:key ==# "m"
      call <SID>rename_file_or_buffer()
    elseif a:key ==# "y"
      call <SID>copy_file_or_buffer()
    elseif a:key ==# "w"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:file_mode = !s:file_mode
        let s:workspace_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "W"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:file_mode = !s:file_mode
        let s:workspace_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "l"
      call <SID>kill(0, 0)
      let s:file_mode = !s:file_mode
      let s:tablist_mode = 1
      let s:next_tab_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "L"
      call <SID>kill(0, 0)
      let s:file_mode = !s:file_mode
      let s:tablist_mode = 1
      let s:next_tab_mode = 0
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    elseif a:key ==# "b"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        call <SID>kill(0, 0)
        let s:file_mode = !s:file_mode
        let s:bookmark_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "B"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        call <SID>kill(0, 0)
        let s:file_mode = !s:file_mode
        let s:bookmark_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "g"
      call <SID>goto_buffer_or_file("next")
    elseif a:key ==# "G"
      call <SID>goto_buffer_or_file("previous")
    elseif a:key ==# "U"
      call <SID>collect_unsaved_buffers()
    endif
  else
    if a:key ==# "CR"
      call <SID>load_buffer()
    elseif a:key ==# "Space"
      call <SID>load_many_buffers()
    elseif a:key ==# "Tab"
      call <SID>goto_window()
    elseif (a:key ==# "S-Tab") || term_s_tab
      let single_mode_save = s:single_mode

      if <SID>goto_window()
        call <SID>ctrlspace_toggle(0)

        if single_mode_save != 1
          call <SID>kill(0, 0)
          let s:single_mode = single_mode_save
          call <SID>ctrlspace_toggle(1)
        endif
      endif
    elseif a:key == "*"
      if s:single_mode == 2
        let s:single_mode = 1
      else
        let s:single_mode = 2
      endif

      call <SID>kill(0, 0)
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "z"
      if !s:zoom_mode
        call <SID>zoom_buffer(0)
      else
        call <SID>kill(0, 1)
        call <SID>ctrlspace_toggle(0)
      endif
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      elseif !s:single_mode
        call <SID>toggle_single_mode()
      else
        call <SID>kill(0, 1)
      endif
    elseif a:key ==# "/"
      call <SID>switch_search_mode(1)
    elseif a:key ==# "BSlash"
      call <SID>search_parent_directory_cycle()
    elseif a:key ==# "Bar"
      call <SID>search_parent_directory_cycle()
      call <SID>toggle_file_mode()
    elseif a:key ==# "v"
      call <SID>load_buffer("vs")
    elseif a:key ==# "V"
      call <SID>load_many_buffers("vs")
    elseif a:key ==# "s"
      call <SID>load_buffer("sp")
    elseif a:key ==# "S"
      call <SID>load_many_buffers("sp")
    elseif a:key ==# "x"
      let current_line = line(".")
      if (winnr("$") > 2) && <SID>goto_window()
        silent! exe "wincmd c"
        call <SID>ctrlspace_toggle(0)
        call <SID>move_selection_bar(current_line)
      endif
    elseif a:key ==# "X"
      let current_line = line(".")
      if (winnr("$") > 2) && <SID>goto_window()
        silent! exe "wincmd o"
        call <SID>ctrlspace_toggle(0)
        call <SID>move_selection_bar(current_line)
      endif
    elseif a:key ==# "t"
      call <SID>load_buffer("tabnew")
    elseif a:key ==# "T"
      if s:next_tab_mode
        call <SID>load_many_buffers("tabnext", "tabprevious")
      else
        let s:next_tab_mode = 1
        call <SID>load_many_buffers("tabnew", "tabprevious")
      endif
    elseif a:key ==# "C-t"
      call <SID>tab_command("T")
    elseif a:key ==# "Y"
      call <SID>tab_command(a:key)
    elseif a:key ==# "="
      call <SID>new_tab_label(0)
      call <SID>set_statusline()
      redraws
    elseif a:key =~? "^[0-9]$"
      call <SID>tab_command(a:key)
    elseif a:key ==# "+"
      silent! exe "tabm" . tabpagenr()
      call <SID>set_statusline()
      redraws
    elseif a:key ==# "-"
      silent! exe "tabm" . (tabpagenr() - 2)
      call <SID>set_statusline()
      redraws
    elseif a:key ==# "_"
      call <SID>remove_tab_label(0)
      call <SID>set_statusline()
      redraw!
    elseif a:key ==# "["
      call <SID>tab_command(a:key)
    elseif a:key ==# "]"
      call <SID>tab_command(a:key)
    elseif (a:key ==# "{" || a:key ==# "<") && s:single_mode
      let current_tab = tabpagenr()

      if current_tab > 1
        call <SID>copy_or_move_selected_buffer_into_tab(current_tab - 1, a:key ==# "{")
      endif
    elseif (a:key ==# "}" || a:key ==# ">") && s:single_mode
      let current_tab = tabpagenr()

      if current_tab < tabpagenr("$")
        call <SID>copy_or_move_selected_buffer_into_tab(current_tab + 1, a:key ==# "}")
      endif
    elseif (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move_selection_bar("down")
    elseif a:key ==# "k"
      call <SID>move_selection_bar("up")
    elseif a:key ==# "p"
      call <SID>jump("previous")
    elseif a:key ==# "P"
      call <SID>jump("previous")
      call <SID>load_buffer()
    elseif a:key ==# "n"
      call <SID>jump("next")
    elseif a:key ==# "d"
      call <SID>delete_buffer()
    elseif a:key ==# "D"
      call <SID>delete_hidden_noname_buffers(0)
    elseif (a:key ==# "MouseDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("up")
    elseif (a:key ==# "MouseUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("down")
    elseif (a:key ==# "LeftRelease") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
    elseif (a:key ==# "2-LeftMouse") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call <SID>move_selection_bar("mouse")
      call <SID>load_buffer()
    elseif (a:key ==# "Down") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("j")
    elseif (a:key ==# "Up") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))
      call feedkeys("k")
    elseif ((a:key ==# "Home") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "K")
      call <SID>move_selection_bar(1)
    elseif ((a:key ==# "End") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "J")
      call <SID>move_selection_bar(line("$"))
    elseif ((a:key ==# "PageDown") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-f")
      call <SID>move_selection_bar("pgdown")
    elseif ((a:key ==# "PageUp") && (g:ctrlspace_use_mouse_and_arrows_in_term || has("gui_running"))) || (a:key ==# "C-b")
      call <SID>move_selection_bar("pgup")
    elseif a:key ==# "C-d"
      call <SID>move_selection_bar("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move_selection_bar("half_pgup")
    elseif a:key ==# "a"
      call <SID>toggle_single_mode()
    elseif a:key ==# "A"
      if s:single_mode
        call <SID>toggle_single_mode()
      endif
      call <SID>switch_search_mode(1)
    elseif a:key ==# "f" && s:single_mode
      call <SID>detach_buffer()
    elseif a:key ==# "F"
      call <SID>delete_foreign_buffers(0)
    elseif a:key ==# "c" && s:single_mode
      call <SID>close_buffer()
    elseif a:key ==# "C"
      call <SID>close_tab()
    elseif a:key ==# "e"
      call <SID>edit_file()
    elseif a:key ==# "i"
      call <SID>goto_directory(0)
    elseif a:key ==# "I"
      call <SID>goto_directory(1)
    elseif a:key ==# "E"
      call <SID>explore_directory()
    elseif a:key ==# "R"
      call <SID>remove_file()
    elseif a:key ==# "m"
      call <SID>rename_file_or_buffer()
    elseif a:key ==# "y"
      call <SID>copy_file_or_buffer()
    elseif a:key ==# "C-l"
      call <SID>load_last_active_workspace()
    elseif a:key ==# "N"
      call <SID>new_workspace()
    elseif a:key ==# "C-s"
      if empty(s:active_workspace_name)
        call <SID>save_first_workspace()
      else
        call <SID>save_workspace(s:active_workspace_name)
      endif
    elseif a:key ==# "w"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:workspace_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "W"
      if empty(s:workspace_names)
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:workspace_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "l"
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      let s:next_tab_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "L"
      call <SID>kill(0, 0)
      let s:tablist_mode = 1
      let s:next_tab_mode = 0
      call <SID>ctrlspace_toggle(1)
      call <SID>switch_search_mode(1)
    elseif a:key ==# "b"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        call <SID>kill(0, 0)
        let s:bookmark_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "B"
      if empty(s:bookmarks)
        call <SID>add_first_bookmark()
      else
        call <SID>kill(0, 0)
        let s:bookmark_mode = 1
        let s:next_tab_mode = 0
        call <SID>ctrlspace_toggle(1)
        call <SID>switch_search_mode(1)
      endif
    elseif a:key ==# "o"
      call <SID>toggle_file_mode()
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif a:key ==# "O"
      call <SID>toggle_file_mode()
      call <SID>switch_search_mode(1)
    elseif a:key ==# "g"
      call <SID>goto_buffer_or_file("next")
    elseif a:key ==# "G"
      call <SID>goto_buffer_or_file("previous")
    elseif a:key ==# "U"
      call <SID>collect_unsaved_buffers()
    endif
  endif
endfunction

function! <SID>copy_or_move_selected_buffer_into_tab(tab, move)
  let nr = <SID>get_selected_buffer()

  if !getbufvar(str2nr(nr), '&modifiable') || !getbufvar(str2nr(nr), '&buflisted') || empty(bufname(str2nr(nr)))
    return
  endif

  let map = gettabvar(a:tab, "ctrlspace_list")

  if a:move
    call <SID>detach_buffer()
  endif

  if empty(map)
    let new_map = {}
    let new_map[nr] = 1
    call settabvar(a:tab, "ctrlspace_list", new_map)
  elseif !exists("map[nr]")
    let map[nr] = len(map) + 1
  endif

  call <SID>kill(0, 1)

  silent! exe "normal! " . a:tab . "gt"

  call <SID>ctrlspace_toggle(0)

  for i in range(0, len(b:buflist))
    if b:buflist[i].raw == bufname(str2nr(nr))
      call <SID>move_selection_bar(i + 1)
      call <SID>load_many_buffers()
      break
    endif
  endfor
endfunction

function! <SID>find_active_bookmark()
  let project_root = <SID>normalize_directory(empty(s:project_root) ? fnamemodify(".", ":p:h") : s:project_root)

  for bookmark in s:bookmarks
    if <SID>normalize_directory(bookmark.directory) == project_root
      let s:jump_counter += 1
      let bookmark.jump_counter = s:jump_counter
      return bookmark
    endif
  endfor

  return {}
endfunction

function! <SID>find_project_root()
  let project_root = fnamemodify(".", ":p:h")

  if !empty(g:ctrlspace_project_root_markers)
    let root_found = 0

    let candidate = fnamemodify(project_root, ":p:h")
    let last_candidate = ""

    while candidate != last_candidate
      for marker in g:ctrlspace_project_root_markers
        let marker_path = candidate . "/" . marker
        if filereadable(marker_path) || isdirectory(marker_path)
          let root_found = 1
          break
        endif
      endfor

      if !root_found
        let root_found = exists("s:project_roots[candidate]")
      endif

      if root_found
        let project_root = candidate
        break
      endif

      let last_candidate = candidate
      let candidate = fnamemodify(candidate, ":p:h:h")
    endwhile

    return root_found ? project_root : ""
  endif

  return project_root
endfunction

function! <SID>handle_switchbuf(switch)
  if (a:switch == "start") && !empty(&swb)
    let s:swb_save = &swb
    set swb=
  elseif (a:switch == "stop") && exists("s:swb_save")
    let &swb = s:swb_save
    unlet s:swb_save
  endif
endfunction

function! <SID>handle_autochdir(switch)
  if (a:switch == "start") && &acd
    let s:acd_was_on = 1
    set noacd
  elseif (a:switch == "stop") && exists("s:acd_was_on")
    set acd
    unlet s:acd_was_on
  endif
endfunction

function! <SID>handle_vim_settings(switch)
  call <SID>handle_switchbuf(a:switch)
  call <SID>handle_autochdir(a:switch)
endfunction

function! <SID>toggle_file_mode()
  if !<SID>project_root_found()
    return
  endif

  let s:file_mode = !s:file_mode

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function <SID>set_statusline()
  if has("statusline")
    silent! exe "let &l:statusline = " . g:ctrlspace_statusline_function
  endif
endfunction

function! <SID>set_up_buffer()
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nomodifiable
  setlocal nowrap
  setlocal nonumber
  if exists('+relativenumber')
    setlocal norelativenumber
  endif
  setlocal nocursorcolumn
  setlocal nocursorline
  setlocal nolist
  setlocal cc=
  setlocal filetype=ctrlspace

  let s:plugin_buffer = bufnr("%")

  if !empty(s:project_root)
    silent! exe "lcd " . s:project_root
  endif

  let b:search_patterns = {}

  if &timeout
    let b:timeoutlen_save = &timeoutlen
    set timeoutlen=10
  endif

  let b:updatetime_save = &updatetime

  " shellslash support for win32
  if has("win32") && !&ssl
    let b:nossl_save = 1
    set ssl
  endif

  augroup CtrlSpaceUpdateSearch
    au!
    au CursorHold <buffer> call <SID>update_search_results()
  augroup END

  augroup CtrlSpaceLeave
    au!
    au BufLeave <buffer> call <SID>kill(0, 1)
  augroup END

  " set up syntax highlighting
  if has("syntax")
    syn clear
    syn match CtrlSpaceNormal /  .*/
    syn match CtrlSpaceSelected /> .*/hs=s+1
  endif

  call clearmatches()

  if !g:ctrlspace_use_mouse_and_arrows_in_term && !has("gui_running")
    " Block unnecessary escape sequences!
    noremap <silent><buffer><esc>[ :call <SID>mark_key_esc_sequence()<CR>
    let b:mouse_save = &mouse
    set mouse=
  endif

  for key_name in s:key_names
    let key = strlen(key_name) > 1 ? ("<" . key_name . ">") : key_name

    if key_name == '"'
      let key_name = '\' . key_name
    endif

    silent! exe "noremap <silent><buffer> " . key . " :call <SID>keypressed(\"" . key_name . "\")<CR>"
  endfor
endfunction

function! <SID>mark_key_esc_sequence()
  let s:key_esc_sequence = 1
endfunction

function! <SID>make_filler()
  " generate a variable to fill the buffer afterwards
  " (we need this for "full window" color :)
  let fill = "\n"
  let i = 0 | while i < &columns | let i += 1
    let fill = ' ' . fill
  endwhile

  return fill
endfunction

function! <SID>compare_raw_names(a, b)
  if a:a.raw < a:b.raw
    return -1
  elseif a:a.raw > a:b.raw
    return 1
  else
    return 0
  endif
endfunction

function! <SID>compare_tab_names(a, b)
  if a:a.number < a:b.number
    return -1
  elseif a:a.number > a:b.number
    return 1
  else
    return 0
  endif
endfunction

function! <SID>compare_raw_names_with_search_noise(a, b)
  if a:a.search_noise < a:b.search_noise
    return 1
  elseif a:a.search_noise > a:b.search_noise
    return -1
  elseif strlen(a:a.raw) < strlen(a:b.raw)
    return 1
  elseif strlen(a:a.raw) > strlen(a:b.raw)
    return -1
  elseif a:a.raw < a:b.raw
    return -1
  elseif a:a.raw > a:b.raw
    return 1
  else
    return 0
  endif
endfunction

function! <SID>display_list(displayedbufs, buflist)
  setlocal modifiable
  if a:displayedbufs > 0
    if s:file_mode && empty(s:search_letters)
      let buftext = s:all_files_buftext
    else
      if !empty(s:search_letters)
        call sort(a:buflist, function("s:compare_raw_names_with_search_noise"))
      elseif s:tablist_mode
        call sort(a:buflist, function("s:compare_tab_names"))
      else
        call sort(a:buflist, function("s:compare_raw_names"))
      endif

      " trim the list in search mode
      let buflist = s:search_mode && (len(a:buflist) > <SID>max_height()) ? a:buflist[-<SID>max_height() : -1] : a:buflist
      let buftext = <SID>prepare_buftext_to_display(buflist)
    endif

    silent! put! =buftext
    normal! GkJ
    let fill = <SID>make_filler()
    while winheight(0) > line(".")
      silent! put =fill
    endwhile

    let s:nop_mode = 0
  else
    let empty_list_message = "  List empty"

    if &columns < (strwidth(empty_list_message) + 2)
      let empty_list_message = strpart(empty_list_message, 0, &columns - 2 - s:symbol_sizes.dots) . g:ctrlspace_symbols.dots
    endif

    while strwidth(empty_list_message) < &columns
      let empty_list_message .= ' '
    endwhile

    silent! put! =empty_list_message
    normal! GkJ

    let fill = <SID>make_filler()

    while winheight(0) > line(".")
      silent! put =fill
    endwhile

    normal! 0

    let s:nop_mode = 1
  endif
  setlocal nomodifiable
endfunction

function! <SID>move_cursor(where)
  if a:where == "up"
    call <SID>goto(line(".") - 1)
  elseif a:where == "down"
    call <SID>goto(line(".") + 1)
  elseif a:where == "mouse"
    call <SID>goto(line("."))
  elseif a:where == "pgup"
    let newpos = line(".") - winheight(0)
    if newpos < 1
      let newpos = 1
    endif
    call <SID>goto(newpos)
  elseif a:where == "pgdown"
    let newpos = line(".") + winheight(0)
    if newpos > line("$")
      let newpos = line("$")
    endif
    call <SID>goto(newpos)
  elseif a:where == "half_pgup"
    let newpos = line(".") - winheight(0) / 2
    if newpos < 1
      let newpos = 1
    endif
    call <SID>goto(newpos)
  elseif a:where == "half_pgdown"
    let newpos = line(".") + winheight(0) / 2
    if newpos > line("$")
      let newpos = line("$")
    endif
    call <SID>goto(newpos)
  else
    call <SID>goto(a:where)
  endif
endfunction

" move the selection bar of the list:
" where can be "up"/"down"/"mouse" or
" a line number
function! <SID>move_selection_bar(where)
  if b:bufcount < 1
    return
  endif

  let newpos = 0

  if !exists('b:lastline')
    let b:lastline = 0
  endif

  setlocal modifiable

  " the mouse was pressed: remember which line
  " and go back to the original location for now
  if a:where == "mouse"
    let newpos = line(".")
    call <SID>goto(b:lastline)
  endif

  " exchange the first char (>) with a space
  call setline(line("."), " " . strpart(getline(line(".")), 1))

  " go where the user want's us to go
  if a:where == "up"
    call <SID>goto(line(".") - 1)
  elseif a:where == "down"
    call <SID>goto(line(".") + 1)
  elseif a:where == "mouse"
    call <SID>goto(newpos)
  elseif a:where == "pgup"
    let newpos = line(".") - winheight(0)
    if newpos < 1
      let newpos = 1
    endif
    call <SID>goto(newpos)
  elseif a:where == "pgdown"
    let newpos = line(".") + winheight(0)
    if newpos > line("$")
      let newpos = line("$")
    endif
    call <SID>goto(newpos)
  elseif a:where == "half_pgup"
    let newpos = line(".") - winheight(0) / 2
    if newpos < 1
      let newpos = 1
    endif
    call <SID>goto(newpos)
  elseif a:where == "half_pgdown"
    let newpos = line(".") + winheight(0) / 2
    if newpos > line("$")
      let newpos = line("$")
    endif
    call <SID>goto(newpos)
  else
    call <SID>goto(a:where)
  endif

  " and mark this line with a >
  call setline(line("."), ">" . strpart(getline(line(".")), 1))

  " remember this line, in case the mouse is clicked
  " (which automatically moves the cursor there)
  let b:lastline = line(".")

  setlocal nomodifiable
endfunction

" tries to set the cursor to a line of the buffer list
function! <SID>goto(line)
  if b:bufcount < 1 | return | endif
  if a:line < 1
    call <SID>goto(b:bufcount - a:line)
  elseif a:line > b:bufcount
    call <SID>goto(a:line - b:bufcount)
  else
    call cursor(a:line, 1)
  endif
endfunction

function! <SID>compare_jumps(a, b)
  if a:a.counter > a:b.counter
    return -1
  elseif a:a.counter < a:b.counter
    return 1
  else
    return 0
  endif
endfunction

function! <SID>create_tab_jumps()
  let b:jumplines = []
  let b:jumplines_len = tabpagenr("$")

  for t in range(1, b:jumplines_len)
    let counter = <SID>gettabvar_with_default(t, "ctrlspace_tablist_jump_counter", 0)
    call add(b:jumplines, { "line": t, "counter": counter })
  endfor
endfunction

function! <SID>create_bm_jumps()
  let b:jumplines = []
  let b:jumplines_len = len(b:buflist)

  for l in range(1, b:jumplines_len)
    let counter = s:bookmarks[b:buflist[l - 1].number - 1].jump_counter
    call add(b:jumplines, { "line": l, "counter": counter })
  endfor
endfunction

function! <SID>create_buffer_jumps()
  let b:jumplines = []
  let b:jumplines_len = len(b:buflist)

  for l in range(1, b:jumplines_len)
    let counter = <SID>getbufvar_with_default(b:buflist[l - 1]["number"], "ctrlspace_jump_counter", 0)
    call add(b:jumplines, { "line": l, "counter": counter })
  endfor
endfunction

function! <SID>jump(direction)
  if !exists("b:jumplines")
    if s:tablist_mode
      call <SID>create_tab_jumps()
    elseif s:bookmark_mode
      call <SID>create_bm_jumps()
    else
      call <SID>create_buffer_jumps()
    endif

    call sort(b:jumplines, function("s:compare_jumps"))
  endif

  if !exists("b:jumppos")
    let b:jumppos = 0
  endif

  if a:direction == "previous"
    let b:jumppos += 1

    if b:jumppos == b:jumplines_len
      let b:jumppos = b:jumplines_len - 1
    endif
  elseif a:direction == "next"
    let b:jumppos -= 1

    if b:jumppos < 0
      let b:jumppos = 0
    endif
  endif

  call <SID>move_selection_bar(string(b:jumplines[b:jumppos]["line"]))
endfunction

function! <SID>goto_buffer_or_file(direction)
  let nr          = <SID>get_selected_buffer()
  let current_tab = tabpagenr()
  let last_tab    = tabpagenr("$")

  let target_tab    = 0
  let target_buffer = 0

  if last_tab == 1
    let tabs_to_check = [1]
  elseif current_tab == 1
    if a:direction == "next"
      let tabs_to_check = range(2, last_tab) + [1]
    else
      let tabs_to_check = range(last_tab, current_tab, -1)
    endif
  elseif current_tab == last_tab
    if a:direction == "next"
      let tabs_to_check = range(1, last_tab)
    else
      let tabs_to_check = range(last_tab - 1, 1, -1) + [last_tab]
    endif
  else
    if a:direction == "next"
      let tabs_to_check = range(current_tab + 1, last_tab) + range(1, current_tab - 1) + [current_tab]
    else
      let tabs_to_check = range(current_tab - 1, 1, -1) + range(last_tab, current_tab + 1, -1) + [current_tab]
    endif
  endif

  if s:file_mode
    let file = fnamemodify(s:files[nr - 1], ":p")
  endif

  for t in tabs_to_check
    for [bufnr, name] in items(ctrlspace#buffers(t))
      if s:file_mode
        if fnamemodify(name, ":p") != file
          continue
        endif
      elseif str2nr(bufnr) != nr
        continue
      endif

      let target_tab    = t
      let target_buffer = str2nr(bufnr)
      break
    endfor

    if target_tab > 0
      break
    endif
  endfor

  if (target_tab > 0) && (target_buffer > 0)
    call <SID>kill(0, 1)
    silent! exe "normal! " . target_tab . "gt"
    call <SID>ctrlspace_toggle(0)
    for i in range(0, len(b:buflist) -1)
      if b:buflist[i].number == target_buffer
        call <SID>move_selection_bar(i + 1)
        break
      endif
    endfor
  else
    call <SID>msg("Cannot find a tab containing selected " . (s:file_mode ? "file" : "buffer"))
  endif
endfunction

function! <SID>collect_unsaved_buffers()
  let buffers = []

  for i in range(1, bufnr("$"))
    if getbufvar(i, "&modified") && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      call add(buffers, i)
    endif
  endfor

  if empty(buffers)
    return 0
  endif

  call <SID>kill(0, 1)

  tabnew

  call <SID>set_tab_label(tabpagenr(), "Unsaved buffers", 1)

  for b in buffers
    silent! exe ":b " . b
  endfor

  call <SID>ctrlspace_toggle(0)
  return 1
endfunction

function! <SID>load_many_buffers(...)
  let nr = <SID>get_selected_buffer()
  let current_line = line(".")

  call <SID>kill(0, 0)
  call <SID>goto_start_window()

  let commands = len(a:000)

  if commands > 0
    silent! exe ":" . a:1
  endif

  exec ":b " . nr
  normal! zb

  if commands > 1
    silent! exe ":" . a:2
  endif

  call <SID>ctrlspace_toggle(1)
  call <SID>move_selection_bar(current_line)
endfunction

function! <SID>load_buffer(...)
  let nr = <SID>get_selected_buffer()
  call <SID>kill(0, 1)

  let commands = len(a:000)

  if commands > 0
    silent! exe ":" . a:1
  endif

  silent! exe ":b " . nr

  if commands > 1
    silent! exe ":" . a:2
  endif
endfunction

function! <SID>load_file_or_buffer(file)
  if buflisted(a:file)
    silent! exe ":b " . bufnr(a:file)
  else
    exec ":e " . fnameescape(a:file)
  endif
endfunction

function! <SID>load_many_files(...)
  let file_number = <SID>get_selected_buffer()
  let file = fnamemodify(s:files[file_number - 1], ":p")
  let current_line = line(".")

  call <SID>kill(0, 0)
  call <SID>goto_start_window()

  let commands = len(a:000)

  if commands > 0
    exec ":" . a:1
  endif

  call <SID>load_file_or_buffer(file)
  normal! zb

  if commands > 1
    silent! exe ":" . a:2
  endif

  call <SID>ctrlspace_toggle(1)
  call <SID>move_selection_bar(current_line)
endfunction

function! <SID>load_file(...)
  let file_number = <SID>get_selected_buffer()
  let file = fnamemodify(s:files[file_number - 1], ":p")

  call <SID>kill(0, 1)

  let commands = len(a:000)

  if commands > 0
    exec ":" . a:1
  endif

  call <SID>load_file_or_buffer(file)

  if commands > 1
    silent! exe ":" . a:2
  endif
endfunction

function! <SID>zoom_buffer(nr, ...)
  if !s:zoom_mode
    let s:zoom_mode = 1
    let s:zoom_mode_original_buffer = winbufnr(t:ctrlspace_start_window)
  endif

  let nr = a:nr ? a:nr : <SID>get_selected_buffer()

  call <SID>kill(0, 0)

  call <SID>goto_start_window()
  silent! exe ":b " . nr

  let custom_commands = !empty(a:000) ? a:1 : ["normal! zb"]

  for c in custom_commands
    silent! exe c
  endfor

  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>load_buffer_into_window(winnr)
  let old_start_window = t:ctrlspace_start_window
  let t:ctrlspace_start_window = a:winnr
  call <SID>load_buffer()
  let t:ctrlspace_start_window = old_start_window
endfunction

" deletes the selected buffer
function! <SID>delete_buffer()
  let nr = <SID>get_selected_buffer()
  let modified = getbufvar(str2nr(nr), '&modified')

  if modified && !<SID>confirmed("The buffer contains unsaved changes. Proceed anyway?")
    return
  endif

  let selected_buffer_window = bufwinnr(str2nr(nr))
  let current_line = line(".")

  if selected_buffer_window != -1
    call <SID>move_selection_bar("down")
    if <SID>get_selected_buffer() == nr
      call <SID>move_selection_bar("up")
      if <SID>get_selected_buffer() == nr
        if bufexists(nr) && (!empty(getbufvar(nr, "&buftype")) || filereadable(bufname(nr)) || modified)
          let current_line = line(".")
          call <SID>kill(0, 0)
          silent! exe selected_buffer_window . "wincmd w"
          enew
        else
          return
        endif
      else
        call <SID>load_buffer_into_window(selected_buffer_window)
      endif
    else
      call <SID>load_buffer_into_window(selected_buffer_window)
    endif
  else
    let current_line = line(".")
    call <SID>kill(0, 0)
  endif

  let current_tab = tabpagenr()

  for t in range(1, tabpagenr('$'))
    if t == current_tab
      continue
    endif

    for b in tabpagebuflist(t)
      if b == nr
        silent! exe "tabn " . t

        let tab_window = bufwinnr(b)
        let ctrlspace_list = copy(gettabvar(t, "ctrlspace_list"))

        call remove(ctrlspace_list, nr)

        call settabvar(t, "ctrlspace_list", ctrlspace_list)

        silent! exe tab_window . "wincmd w"

        if !empty(ctrlspace_list)
          silent! exe "b" . keys(ctrlspace_list)[0]
        else
          enew
        endif
      endif
    endfor
  endfor

  silent! exe "tabn " . current_tab
  silent! exe "bdelete! " . nr

  call <SID>forget_buffers_in_all_tabs([nr])
  call <SID>ctrlspace_toggle(1)
  call <SID>move_selection_bar(current_line)
endfunction

function! <SID>forget_buffers_in_all_tabs(numbers)
  for t in range(1, tabpagenr("$"))
    let ctrlspace_list = copy(gettabvar(t, "ctrlspace_list"))

    if empty(ctrlspace_list)
      continue
    endif

    for nr in a:numbers
      if exists("ctrlspace_list[" . nr . "]")
        call remove(ctrlspace_list, nr)
      endif
    endfor

    call settabvar(t, "ctrlspace_list", ctrlspace_list)
  endfor
endfunction

function! <SID>keep_buffers_for_keys(dict)
  let removed = []

  for b in range(1, bufnr('$'))
    if buflisted(b) && !has_key(a:dict, b) && !getbufvar(b, '&modified')
      exe "bwipeout" b
      call add(removed, b)
    endif
  endfor

  return removed
endfunction

function! <SID>delete_hidden_noname_buffers(internal)
  let keep = {}

  " keep visible ones
  for t in range(1, tabpagenr('$'))
    for b in tabpagebuflist(t)
      let keep[b] = 1
    endfor
  endfor

  " keep all but nonames
  for b in range(1, bufnr("$"))
    if bufexists(b) && (!empty(getbufvar(b, "&buftype")) || filereadable(bufname(b)))
      let keep[b] = 1
    endif
  endfor

  if !a:internal
    call <SID>kill(0, 0)
  endif

  let removed = <SID>keep_buffers_for_keys(keep)

  if !empty(removed)
    call <SID>forget_buffers_in_all_tabs(removed)
  endif

  if !a:internal
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

" deletes all foreign buffers
function! <SID>delete_foreign_buffers(internal)
  let buffers = {}
  for t in range(1, tabpagenr('$'))
    silent! call extend(buffers, gettabvar(t, 'ctrlspace_list'))
  endfor

  if !a:internal
    call <SID>kill(0, 0)
  endif

  call <SID>keep_buffers_for_keys(buffers)

  if !a:internal
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>get_selected_buffer()
  let bufentry = b:buflist[line(".") - 1]
  return bufentry.number
endfunction

function! <SID>add_tab_buffer()
  if s:zoom_mode
    return
  endif

  if !exists('t:ctrlspace_list')
    let t:ctrlspace_list = {}
  endif

  let current = bufnr('%')

  if !exists("t:ctrlspace_list[" . current . "]") &&
        \ getbufvar(current, '&modifiable') &&
        \ getbufvar(current, '&buflisted') &&
        \ getbufvar(current, '&ft') != "ctrlspace"
    let t:ctrlspace_list[current] = len(t:ctrlspace_list) + 1
  endif
endfunction

function! <SID>add_jump()
  if s:zoom_mode
    return
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') &&
        \ getbufvar(current, '&buflisted') &&
        \ getbufvar(current, '&ft') != "ctrlspace"
    let s:jump_counter += 1
    let b:ctrlspace_jump_counter = s:jump_counter
  endif
endfunction

function! <SID>toggle_single_mode()
  let s:single_mode = !s:single_mode

  if !empty(s:search_letters)
    let s:new_search_performed = 1
  endif

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>refresh_files()
  let s:files = []
  call <SID>save_files_in_cache()
  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>update_file_list(path, new_path)
  if !exists("s:all_files_buftext") " exit if files haven't been collected yet
    return
  endif

  if empty(s:files)
    call <SID>load_files_from_cache()

    if empty(s:files)
      unlet s:all_files_buftext
      return
    endif
  endif

  let new_path = empty(a:new_path) ? "" : fnamemodify(a:new_path, ":.")

  if !empty(a:path)
    let index = index(s:files, a:path)

    if index >= 0
      call remove(s:files, index)
    endif
  endif

  if !empty(new_path)
    call add(s:files, new_path)
  endif

  let s:all_files_cached = map(s:files[0:g:ctrlspace_max_files - 1],
        \ '{ "number": v:key + 1, "raw": v:val, "search_noise": 0 }')
  call sort(s:all_files_cached, function("s:compare_raw_names"))

  let old_files_mode = s:file_mode

  let s:file_mode = 1
  let s:all_files_buftext = <SID>prepare_buftext_to_display(s:all_files_cached)
  let s:file_mode = old_files_mode

  call <SID>save_files_in_cache()
endfunction

function! <SID>remove_file()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.")

  if empty(path) || !filereadable(path) || isdirectory(path)
    return
  endif

  if !<SID>confirmed("Remove file '" . path . "'?")
    return
  endif

  call <SID>delete_buffer()
  call <SID>update_file_list(path, "")
  call delete(resolve(expand(path)))

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>rename_file_or_buffer()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.")

  let buffer_only = !filereadable(path) && !s:file_mode

  if !(filereadable(path) || buffer_only) || isdirectory(path)
    return
  endif

  let new_file = <SID>get_input((buffer_only ? "New buffer name: " : "Move file to: "), path, "file")

  if empty(new_file) || !<SID>ensure_path(new_file)
    return
  endif

  if isdirectory(new_file)
    if new_file !~ "/$"
      let new_file .= "/"
    endif

    let new_file .= fnamemodify(path, ":t")
  endif

  let buffer_names = {}

  " must be collected BEFORE actual file renaming
  for b in range(1, bufnr('$'))
    let buffer_names[b] = fnamemodify(resolve(bufname(b)), ":.")
  endfor

  if !buffer_only
    call rename(resolve(expand(path)), resolve(expand(new_file)))
  endif

  for [b, name] in items(buffer_names)
    if name == path
      let commands = ["f " . fnameescape(new_file)]

      if !buffer_only
        call add(commands, "w!")
      elseif !getbufvar(b, "&modified")
        call add(commands, "e") "reload filetype and syntax
      endif

      call <SID>zoom_buffer(str2nr(b), commands)
    endif
  endfor

  if !buffer_only
    call <SID>update_file_list(path, new_file)
  endif

  call <SID>kill(0, 1)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>goto_directory(back)
  if !exists("s:goto_directory_save")
    let s:goto_directory_save = []
  endif

  if a:back
    if !empty(s:goto_directory_save)
      let path = s:goto_directory_save[-1]
    else
      return
    endif
  else
    let nr   = <SID>get_selected_buffer()
    let path = s:file_mode ? s:files[nr - 1] : resolve(bufname(nr))
  endif

  let old_file_mode   = s:file_mode
  let old_single_mode = s:single_mode

  let directory = <SID>normalize_directory(fnamemodify(path, ":p:h"))

  if !isdirectory(directory)
    return
  endif

  call <SID>kill(0, 1)

  let cwd = <SID>normalize_directory(fnamemodify(getcwd(), ":p:h"))

  if cwd != directory
    if a:back
      call remove(s:goto_directory_save, -1)
    else
      call add(s:goto_directory_save, cwd)
    endif

    silent! exe "cd " . fnameescape(directory)
  endif

  call <SID>delayed_msg("CWD is now: " . directory)

  call <SID>ctrlspace_toggle(0)
  call <SID>kill(0, 0)

  let s:file_mode   = old_file_mode
  let s:single_mode = old_single_mode

  call <SID>ctrlspace_toggle(1)
  call <SID>delayed_msg()
endfunction

function! <SID>explore_directory()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.:h")

  if !isdirectory(path)
    return
  endif

  let path = fnamemodify(path, ":p")

  call <SID>kill(0, 1)
  silent! exe "e " . fnameescape(path)
endfunction

function! <SID>ensure_path(file)
  let directory = fnamemodify(a:file, ":.:h")

  if !isdirectory(directory)
    if !<SID>confirmed("Directory '" . directory . "' will be created. Continue?")
      return 0
    endif

    call mkdir(fnamemodify(directory, ":p"), "p")
  endif

  return 1
endfunction

function! <SID>edit_file()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.:h")

  if !isdirectory(path)
    return
  endif

  let new_file = <SID>get_input("Edit a new file: ", path . '/', "file")

  if empty(new_file)
    return
  endif

  let new_file = expand(new_file)

  if isdirectory(new_file)
    call <SID>kill(0, 1)
    enew
    return
  endif

  if !<SID>ensure_path(new_file)
    return
  endif

  let new_file = fnamemodify(new_file, ":p")

  call <SID>kill(0, 1)
  silent! exe "e " . fnameescape(new_file)
endfunction

function! <SID>copy_file_or_buffer()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.")

  let buffer_only = !filereadable(path) && !s:file_mode

  if !(filereadable(path) || buffer_only) || isdirectory(path)
    return
  endif

  let new_file = <SID>get_input((buffer_only ? "Copy buffer as: " : "Copy file to: "), path, "file")

  if empty(new_file) || isdirectory(new_file) || !<SID>ensure_path(new_file)
    return
  endif

  if buffer_only
    call <SID>zoom_buffer(str2nr(nr), ['normal! G""ygg'])
    call <SID>kill(0, 1)
    silent! exe "e " . fnameescape(new_file)
    silent! exe 'normal! ""pgg"_dd'
  else
    let new_file = fnamemodify(new_file, ":p")

    let lines = readfile(path, "b")
    call writefile(lines, new_file, "b")

    call <SID>update_file_list("", new_file)

    call <SID>kill(0, 1)

    if !s:file_mode
      silent! exe "e " . fnameescape(new_file)
    endif
  endif

  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>set_tab_label(tabnr, label, auto)
  call settabvar(a:tabnr, "ctrlspace_label", a:label)
  call settabvar(a:tabnr, "ctrlspace_autotab", a:auto)
endfunction

function! <SID>close_tab()
  if tabpagenr("$") == 1
    return
  endif

  if exists("t:ctrlspace_autotab") && (t:ctrlspace_autotab != 0)
    " do nothing
  elseif exists("t:ctrlspace_label") && !empty(t:ctrlspace_label)
    let buf_count = len(ctrlspace#buffers(tabpagenr()))

    if (buf_count > 1) && !<SID>confirmed("Close tab named '" . t:ctrlspace_label . "' with " . buf_count . " buffers?")
      return
    endif
  endif

  call <SID>kill(0, 1)

  tabclose

  call <SID>delete_hidden_noname_buffers(1)
  call <SID>delete_foreign_buffers(1)

  call <SID>ctrlspace_toggle(0)
endfunction

" Detach a buffer if it belongs to other tabs or delete it otherwise.
" It means, this function doesn't leave buffers without tabs.
function! <SID>close_buffer()
  let nr         = <SID>get_selected_buffer()
  let found_tabs = 0

  for t in range(1, tabpagenr('$'))
    let ctrlspace_list = gettabvar(t, 'ctrlspace_list')
    if !empty(ctrlspace_list) && exists("ctrlspace_list[" . nr . "]")
      let found_tabs += 1
    endif
  endfor

  if found_tabs > 1
    call <SID>detach_buffer()
  else
    call <SID>delete_buffer()
  endif
endfunction

function! <SID>detach_buffer()
  let nr = <SID>get_selected_buffer()

  if exists('t:ctrlspace_list[' . nr . ']')
    let selected_buffer_window = bufwinnr(nr)
    if selected_buffer_window != -1
      call <SID>move_selection_bar("down")
      if <SID>get_selected_buffer() == nr
        call <SID>move_selection_bar("up")
        if <SID>get_selected_buffer() == nr
          if bufexists(nr) && (!empty(getbufvar(nr, "&buftype")) || filereadable(bufname(nr)))
            call <SID>kill(0, 0)
            silent! exe selected_buffer_window . "wincmd w"
            enew
          else
            return
          endif
        else
          call <SID>load_buffer_into_window(selected_buffer_window)
        endif
      else
        call <SID>load_buffer_into_window(selected_buffer_window)
      endif
    else
      call <SID>kill(0, 0)
    endif
    call remove(t:ctrlspace_list, nr)
    call <SID>ctrlspace_toggle(1)
  endif

  return nr
endfunction

if g:ctrlspace_use_tabline
  set tabline=%!ctrlspace#tabline()

  if has("gui_running") && (&go =~# "e")
    set guitablabel=%{ctrlspace#guitablabel()}

    " Fix MacVim issues:
    " http://stackoverflow.com/questions/11595301/controlling-tab-names-in-vim
    au BufEnter * set guitablabel=%{ctrlspace#guitablabel()}
  endif
endif

if !(has("ruby") && g:ctrlspace_use_ruby_bindings)
  finish
endif

let s:ctrlspace_folder = fnamemodify(resolve(expand('<sfile>:p')), ':h')

ruby << EOF
require "pathname"
require Pathname.new(VIM.evaluate("s:ctrlspace_folder")).parent.join("ruby", "ctrlspace").to_s
EOF
