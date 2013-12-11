" Vim-CtrlSpace - Vim Workspace Controller
" Maintainer:   Szymon Wrozynski
" Version:      3.2.4
"
" The MIT License (MIT)

" Copyright (c) 2013 Szymon Wrozynski <szymon@wrozynski.com> and Contributors
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
          \ "cs"      : "▢",
          \ "tab"     : "⊙",
          \ "all"     : "∷",
          \ "add"     : "○",
          \ "load"    : "⋮ → ∙",
          \ "save"    : "∙ → ⋮",
          \ "ord"     : "₁²₃",
          \ "abc"     : "авс",
          \ "prv"     : "⌕",
          \ "s_left"  : "›",
          \ "s_right" : "‹"
          \ }
  else
    let symbols = {
          \ "cs"      : "CS",
          \ "tab"     : "TAB",
          \ "all"     : "ALL",
          \ "add"     : "ADD",
          \ "load"    : "LOAD",
          \ "save"    : "SAVE",
          \ "ord"     : "123",
          \ "abc"     : "ABC",
          \ "prv"     : "*",
          \ "s_left"  : "[",
          \ "s_right" : "]"
          \ }
  endif

  return symbols
endfunction

call <SID>define_config_variable("height", 1)
call <SID>define_config_variable("max_height", 0)
call <SID>define_config_variable("show_unnamed", 2)
call <SID>define_config_variable("set_default_mapping", 1)
call <SID>define_config_variable("default_mapping_key", "<C-Space>")
call <SID>define_config_variable("cyclic_list", 1)
call <SID>define_config_variable("max_jumps", 100)
call <SID>define_config_variable("max_searches", 100)
call <SID>define_config_variable("default_sort_order", 2) " 0 - no sort, 1 - chronological, 2 - alphanumeric
call <SID>define_config_variable("use_ruby_bindings", 1)
call <SID>define_config_variable("use_tabline", 1)
call <SID>define_config_variable("workspace_file",
      \ [".git/cs_workspaces", ".svn/cs_workspaces", ".hg/cs_workspaces", ".bzr/cs_workspaces", "CVS/cs_workspaces", ".cs_workspaces"])
call <SID>define_config_variable("cache_dir", expand($HOME))
call <SID>define_config_variable("project_root_markers", [".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]) " make empty to disable
call <SID>define_config_variable("unicode_font", 1)
call <SID>define_config_variable("symbols", <SID>define_symbols())
call <SID>define_config_variable("ignored_files", '\v(tmp|temp)[\/]') " in addition to 'wildignore' option
call <SID>define_config_variable("show_key_info", 0)
call <SID>define_config_variable("search_timing", [50, 500])

command! -nargs=0 -range CtrlSpace :call <SID>ctrlspace_toggle(0)
command! -nargs=0 -range CtrlSpaceTabLabel :call <SID>new_tab_label()
command! -nargs=+ -range CtrlSpaceSaveWorkspace :call <SID>save_workspace_externally(<q-args>)
command! -nargs=+ -range -bang CtrlSpaceLoadWorkspace :call <SID>load_workspace_externally(<bang>0, <q-args>)

if g:ctrlspace_use_tabline
  set tabline=%!ctrlspace#tabline()
endif

function! <SID>set_default_mapping(key, action)
  let s:default_key = a:key
  if !empty(s:default_key)
    if s:default_key ==? "<C-Space>" && !has("gui_running")
      let s:default_key = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . s:default_key . ' ' . a:action
  endif
endfunction

if g:ctrlspace_set_default_mapping
  call <SID>set_default_mapping(g:ctrlspace_default_mapping_key, ":CtrlSpace<CR>")
endif

let s:files                   = []
let s:preview_mode            = 0
let s:active_workspace_name   = ""
let s:active_workspace_digest = ""
let s:workspace_names         = []
let s:update_search_results   = 0
let s:project_root            = ""

function! <SID>init_project_roots()
  let cache_file = g:ctrlspace_cache_dir . "/.cs_cache"
  let s:project_roots = []

  if filereadable(cache_file)
    for line in readfile(cache_file)
      if line =~# "CS_PROJECT_ROOT: "
        call add(s:project_roots, line[17:])
      endif
    endfor
  endif
endfunction

call <SID>init_project_roots()

function! <SID>add_project_root(directory)
  call add(s:project_roots, a:directory)

  let lines      = []
  let cache_file = g:ctrlspace_cache_dir . "/.cs_cache"

  if filereadable(cache_file)
    for old_line in readfile(cache_file)
      if old_line !~# "CS_PROJECT_ROOT: "
        call add(lines, old_line)
      endif
    endfor
  endif

  for root in s:project_roots
    call add(lines, "CS_PROJECT_ROOT: " . root)
  endfor


  call writefile(lines, cache_file)
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
  let special_chars = "Space CR BS Tab S-Tab / ? ; : , . < > [ ] { } ( ) ' ` ~ + - _ = ! @ # $ % ^ & * C-f C-b C-u C-d " .
                    \ "MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse Down Up Home End Left Right BSlash Bar PageUp PageDown"

  let special_chars .= has("gui_running") ? " C-Space" : " Nul"

  let s:key_names = split(join([lowercase_letters, uppercase_letters, control_letters, numbers, special_chars], " "), " ")

  if exists("s:default_key")
    for i in range(0, len(s:key_names) - 1)
      if ("<" . s:key_names[i] . ">") ==# s:default_key
        call remove(s:key_names, i)
        break
      endif
    endfor
  endif
endfunction

call <SID>init_key_names()

au BufEnter * call <SID>add_tab_buffer()

let s:ctrlspace_jumps = []
au BufEnter * call <SID>add_jump()

function! ctrlspace#bufferlist(tabnr)
  let buffer_list     = {}
  let ctrlspace       = gettabvar(a:tabnr, "ctrlspace_list")
  let visible_buffers = tabpagebuflist(a:tabnr)

  if type(ctrlspace) != 4
    return buffer_list
  endif

  for i in keys(ctrlspace)
    let i = str2nr(i)

    let bufname = bufname(i)

    if g:ctrlspace_show_unnamed && !strlen(bufname)
      if !((g:ctrlspace_show_unnamed == 2) && !getbufvar(i, '&modified')) || (index(visible_buffers, i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      let buffer_list[i] = bufname
    endif
  endfor

  return buffer_list
endfunction

function! ctrlspace#statusline_key_info_segment(...)
  let separator = (a:0 > 0) ? a:1 : " "
  let keys      = ["?"]

  if s:nop_mode
    if !s:search_mode
      if !empty(s:search_letters)
        call add(keys, "BS")
      endif

      call add(keys, "q")
      call add(keys, "Q")
      call add(keys, "a")
      call add(keys, "A")
      call add(keys, "^p")
      call add(keys, "^n")
    else
      call add(keys, "BS")
    endif

    return join(keys, separator)
  endif

  if s:search_mode
    call add(keys, "BS")
    call add(keys, "CR")
    call add(keys, "/")
    if s:file_mode
      call add(keys, '\')
    endif
    call add(keys, "a..z")
    call add(keys, "0..9")
  elseif s:file_mode
    call add(keys, "CR")
    call add(keys, "Sp")
    call add(keys, "BS")
    call add(keys, "/")
    call add(keys, '\')
    call add(keys, "v")
    call add(keys, "s")
    call add(keys, "t")
    call add(keys, "T")
    call add(keys, "0..9")
    call add(keys, "-")
    call add(keys, "+")
    call add(keys, "=")
    call add(keys, "_")
    call add(keys, "[")
    call add(keys, "]")
    call add(keys, "q")
    call add(keys, "Q")
    call add(keys, "j")
    call add(keys, "J")
    call add(keys, "k")
    call add(keys, "K")
    call add(keys, "C")
    call add(keys, "e")
    call add(keys, "E")
    call add(keys, "r")
    call add(keys, "R")
    call add(keys, "m")
    call add(keys, "a")
    call add(keys, "A")
    call add(keys, "^p")
    call add(keys, "^n")
    call add(keys, "w")
    call add(keys, "^f")
    call add(keys, "^b")
    call add(keys, "^d")
    call add(keys, "^u")
  elseif s:workspace_mode
    call add(keys, "CR")
    call add(keys, "BS")
    call add(keys, "q")
    call add(keys, "Q")

    if s:workspace_mode == 1
      call add(keys, "a")
    endif

    call add(keys, "s")
    call add(keys, "S")
    call add(keys, "d")
    call add(keys, "j")
    call add(keys, "J")
    call add(keys, "k")
    call add(keys, "K")
    call add(keys, "w")
    call add(keys, "^f")
    call add(keys, "^b")
    call add(keys, "^d")
    call add(keys, "^u")
  else
    call add(keys, "CR")
    call add(keys, "Sp")
    call add(keys, "Tab")
    call add(keys, "BS")
    call add(keys, "/")
    call add(keys, '\')
    call add(keys, "v")
    call add(keys, "s")
    call add(keys, "t")
    call add(keys, "T")
    call add(keys, "0..9")
    call add(keys, "-")
    call add(keys, "+")
    call add(keys, "=")
    call add(keys, "_")
    call add(keys, "[")
    call add(keys, "]")
    call add(keys, "o")
    call add(keys, "q")
    call add(keys, "Q")
    call add(keys, "j")
    call add(keys, "J")
    call add(keys, "k")
    call add(keys, "K")
    call add(keys, "p")
    call add(keys, "P")
    call add(keys, "n")
    call add(keys, "d")
    call add(keys, "D")
    if s:single_tab_mode
      call add(keys, "f")
    endif
    call add(keys, "F")
    if s:single_tab_mode
      call add(keys, "c")
    endif
    call add(keys, "C")
    call add(keys, "e")
    call add(keys, "E")
    call add(keys, "R")
    call add(keys, "m")
    call add(keys, "a")
    call add(keys, "A")
    call add(keys, "^p")
    call add(keys, "^n")
    call add(keys, "S")
    call add(keys, "w")
    call add(keys, "^f")
    call add(keys, "^b")
    call add(keys, "^d")
    call add(keys, "^u")
  endif

  return join(keys, separator)
endfunction

function! ctrlspace#statusline_info_segment(...)
  let statusline_elements = []

  if s:file_mode
    call add(statusline_elements, g:ctrlspace_symbols.add)
  elseif s:workspace_mode == 1
    call add(statusline_elements, g:ctrlspace_symbols.load)
  elseif s:workspace_mode == 2
    call add(statusline_elements, g:ctrlspace_symbols.save)
  elseif s:single_tab_mode
    call add(statusline_elements, g:ctrlspace_symbols.tab)
  else
    call add(statusline_elements, g:ctrlspace_symbols.all)
  endif

  if !s:workspace_mode
    if empty(s:search_letters) && !s:search_mode
      if exists("t:sort_order") && !s:file_mode
        if t:sort_order == 1
          call add(statusline_elements, g:ctrlspace_symbols.ord)
        elseif t:sort_order == 2
          call add(statusline_elements, g:ctrlspace_symbols.abc)
        endif
      endif
    else
      let search_element = g:ctrlspace_symbols.s_left . join(s:search_letters, "")

      if s:search_mode
        let search_element .= "_"
      endif

      let search_element .= g:ctrlspace_symbols.s_right

      call add(statusline_elements, search_element)
    endif

    if s:preview_mode
      call add(statusline_elements, g:ctrlspace_symbols.prv)
    endif
  endif

  let separator = (a:0 > 0) ? a:1 : "  "
  return join(statusline_elements, separator)
endfunction

function! ctrlspace#tabline()
  let last_tab    = tabpagenr("$")
  let current_tab = tabpagenr()
  let tabline     = ''

  for t in range(1, last_tab)
    let winnr               = tabpagewinnr(t)
    let buflist             = tabpagebuflist(t)
    let bufnr               = buflist[winnr - 1]
    let bufname             = bufname(bufnr)
    let bufs_number         = len(ctrlspace#bufferlist(t))
    let bufs_number_to_show = ""

    if bufs_number > 1
      if g:ctrlspace_unicode_font
        let small_numbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
        let number_str    = string(bufs_number)

        for i in range(0, len(number_str) - 1)
          let bufs_number_to_show .= small_numbers[str2nr(number_str[i])]
        endfor
      else
        let bufs_number_to_show = ":" . bufs_number
      endif
    endif

    let title = gettabvar(t, "ctrlspace_label")

    if empty(title)
      if bufname ==# "__CS__"
        if s:preview_mode && exists("s:preview_mode_orginal_buffer")
          let bufnr = s:preview_mode_orginal_buffer
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

    let tabline .= '%' . t . 'T'
    let tabline .= (t == current_tab ? '%#TabLineSel#' : '%#TabLine#')
    let tabline .= ' ' . t . bufs_number_to_show . ' '

    if <SID>tab_contains_modified_buffers(t)
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

function! <SID>new_tab_label()
  let t:ctrlspace_label = <SID>get_input("Label for tab " . tabpagenr() . ": ", exists("t:ctrlspace_label") ? t:ctrlspace_label : "")
endfunction

function! <SID>tab_contains_modified_buffers(tabnr)
  for b in map(keys(ctrlspace#bufferlist(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction

function! <SID>max_height()
  if g:ctrlspace_max_height
    return g:ctrlspace_max_height
  else
    return &lines / 3
  endif
endfunction

function! <SID>workspace_file()
  for candidate in g:ctrlspace_workspace_file
    if isdirectory(fnamemodify(candidate, ":h:t"))
      return candidate
    endif
  endfor

  return g:ctrlspace_workspace_file[-1]
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
  let lines = []

  for t in range(1, tabpagenr("$"))
    let line = [t, gettabvar(t, "ctrlspace_label")]
    let bufs = []

    for bname in values(ctrlspace#bufferlist(t))
      let bufname = fnamemodify(bname, ":.")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor
    call add(line, join(bufs, "|"))
    call add(lines, join(line, ","))
  endfor

  return join(lines, "&&&")
endfunction

function! <SID>save_workspace(name)
  let name = <SID>get_input("Save current workspace as: ", a:name)

  if empty(name)
    return
  endif

  call <SID>kill(0, 1)
  call <SID>save_workspace_externally(name)
endfunction

function <SID>save_workspace_externally(name)
  if !<SID>project_root_found()
    return
  endif

  let old_cwd = fnamemodify(".", ":p:h")
  silent! exe "cd " . s:project_root

  let filename = <SID>workspace_file()
  let last_tab = tabpagenr("$")

  let lines        = []
  let in_workspace = 0

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . a:name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . a:name

  if filereadable(filename)
    for old_line in readfile(filename)
      if old_line ==? workspace_start_marker
        let in_workspace = 1
      endif

      if !in_workspace
        call add(lines, old_line)
      endif

      if old_line ==? workspace_end_marker
        let in_workspace = 0
      endif
    endfor
  endif

  call add(lines, workspace_start_marker)

  for t in range(1, last_tab)
    let line = [t, gettabvar(t, "ctrlspace_label"), tabpagenr() == t]

    let ctrlspace_list = ctrlspace#bufferlist(t)

    let bufs     = []
    let visibles = []

    let visible_buffers = tabpagebuflist(t)

    let ctrlspace_list_index = -1

    for [nr, bname] in items(ctrlspace_list)
      let ctrlspace_list_index += 1
      let bufname = fnamemodify(bname, ":.")
      let nr = str2nr(nr)

      if !filereadable(bufname)
        continue
      endif

      if index(visible_buffers, nr) != -1
        call add(visibles, ctrlspace_list_index)
      endif

      call add(bufs, bufname)
    endfor

    call add(line, join(bufs, "|"))
    call add(line, join(visibles, "|"))
    call add(lines, join(line, ","))
  endfor

  call add(lines, workspace_end_marker)

  call writefile(lines, filename)

  let s:active_workspace_name   = a:name
  let s:active_workspace_digest = <SID>create_workspace_digest()
  let s:workspace_names         = []

  silent! exe "cd " . old_cwd

  echo g:ctrlspace_symbols.cs . " - The workspace '" . a:name . "' has been saved."
endfunction

function! <SID>delete_workspace(name)
  if !<SID>confirmed("Delete workspace '" . a:name . "'?")
    return
  endif

  let filename = <SID>workspace_file()
  let last_tab = tabpagenr("$")

  let lines      = []
  let in_workspace = 0

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . a:name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . a:name

  if filereadable(filename)
    for old_line in readfile(filename)
      if old_line ==? workspace_start_marker
        let in_workspace = 1
      endif

      if !in_workspace
        call add(lines, old_line)
      endif

      if old_line ==? workspace_end_marker
        let in_workspace = 0
      endif
    endfor
  endif

  call writefile(lines, filename)

  if s:active_workspace_name ==? a:name
    let s:active_workspace_name   = ""
    let s:active_workspace_digest = ""
  endif

  echo g:ctrlspace_symbols.cs . " - The workspace '" . a:name . "' has been deleted."

  let s:workspace_names = []

  if empty(<SID>get_workspace_names())
    call <SID>kill(0, 1)
  else
    call <SID>kill(0, 0)
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>get_workspace_names()
  let filename = <SID>workspace_file()

  let names = []

  if filereadable(filename)
    for line in readfile(filename)
      if line =~? "CS_WORKSPACE_BEGIN: "
        call add(names, line[20:])
      endif
    endfor
  endif

  return names
endfunction

function! <SID>get_selected_workspace_name()
  return s:workspace_names[<SID>get_selected_buffer() - 1]
endfunction

function! <SID>get_input(msg, ...)
  let msg = g:ctrlspace_symbols.cs . " - " . a:msg

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
  return <SID>get_input(a:msg . " (type 'yes' to confirm): ") ==? "yes"
endfunction

function! <SID>load_workspace(bang, name)
  if !empty(s:active_workspace_name) && !a:bang
    let msg = ""

    if a:name == s:active_workspace_name
      let msg = "Reload current workspace: '" . a:name . "'?"
    elseif !empty(s:active_workspace_name)
      if s:active_workspace_digest !=# <SID>create_workspace_digest()
        let msg = "Current workspace not saved. Proceed anyway?"
      endif
    endif

    if !empty(msg) && !<SID>confirmed(msg)
      return
    endif
  endif

  call <SID>kill(0, 1)

  call <SID>load_workspace_externally(a:bang, a:name)

  if a:bang
    call <SID>ctrlspace_toggle(0)
    let s:workspace_mode = 1
    call <SID>kill(0, 0)
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

" bang == 0) load
" bang == 1) append
function! <SID>load_workspace_externally(bang, name)
  if !<SID>project_root_found()
    return
  endif

  let old_cwd = fnamemodify(".", ":p:h")
  silent! exe "cd " . s:project_root

  let filename = <SID>workspace_file()

  if !filereadable(filename)
    echo g:ctrlspace_symbols.cs . " - Workspaces file '" . filename . "' not found."
    silent! exe "cd " . old_cwd
    return
  endif

  let workspace_start_marker = "CS_WORKSPACE_BEGIN: " . a:name
  let workspace_end_marker   = "CS_WORKSPACE_END: " . a:name

  let lines      = []
  let in_workspace = 0

  for old_line in readfile(filename)
    if old_line ==? workspace_start_marker
      let in_workspace = 1
    elseif old_line ==? workspace_end_marker
      let in_workspace = 0
    elseif in_workspace
      call add(lines, old_line)
    endif
  endfor

  if empty(lines)
    echo g:ctrlspace_symbols.cs . " - Workspace '" . a:name . "' not found in file '" . filename . "'."
    let s:workspace_names = []
    silent! exe "cd " . old_cwd
    return
  endif

  let commands = []

  if !a:bang
    echo g:ctrlspace_symbols.cs . " - Loading workspace '" . a:name . "'..."
    call add(commands, "tabe")
    call add(commands, "tabo!")
    call add(commands, "call <SID>delete_hidden_noname_buffers(1)")
    call add(commands, "call <SID>delete_foreign_buffers(1)")

    let create_first_tab        = 0
    let s:active_workspace_name = a:name
  else
    echo g:ctrlspace_symbols.cs . " - Appending workspace '" . a:name . "'..."
    let create_first_tab = 1
  endif

  for line in lines
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
      call add(commands, "e " . fname)
      " jump to the last edited line
      call add(commands, "if line(\"'\\\"\") > 0 | " .
            \ "if line(\"'\\\"\") <= line('$') | " .
            \ "exe(\"norm '\\\"\") | else | exe 'norm $' | " .
            \ "endif | endif")
      call add(commands, "normal! zbze")
    endfor

    if !empty(visible_files)
      call add(commands, "e " . visible_files[0])

      for visible_fname in visible_files[1:-1]
        call add(commands, "vs " . visible_fname)
      endfor
    endif

    if is_current
      call add(commands, "let ctrlspace_workspace_current_tab = tabpagenr()")
    endif

    if !empty(tab_label)
      call add(commands, "let t:ctrlspace_label = '" . tab_label . "'")
    endif
  endfor

  call add(commands, "exe 'normal! ' . ctrlspace_workspace_current_tab . 'gt'")
  call add(commands, "redraw!")

  for c in commands
    silent! exe c
  endfor

  if !a:bang
    echo g:ctrlspace_symbols.cs . " - The workspace '" . a:name . "' has been loaded."
    let s:active_workspace_digest = <SID>create_workspace_digest()
  else
    let s:active_workspace_digest = ""
    echo g:ctrlspace_symbols.cs . " - The workspace '" . a:name . "' has been appended."
  endif

  silent! exe "cd " . old_cwd
endfunction

function! <SID>quit_vim()
  if !empty(s:active_workspace_name) && (s:active_workspace_digest !=# <SID>create_workspace_digest())
        \ && !<SID>confirmed("Current workspace not saved. Proceed anyway?")
    return
  endif

  " check for modified buffers
  for t in range(1, tabpagenr("$"))
    if <SID>tab_contains_modified_buffers(t)
      if !<SID>confirmed("Some buffers not saved. Proceed anyway?")
        return
      else
        break
      endif
    endif
  endfor

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

    if search_letters_count == 0
      return 0
    elseif search_letters_count == 1
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
        else
          let offset += 1
        endif
      endwhile
    endif

    if (noise > -1) && !empty(matched_string)
      let b:search_patterns[matched_string] = 1
    endif

    return noise
  endif
endfunction

function! <SID>display_search_patterns()
  for pattern in keys(b:search_patterns)
    call matchadd("CtrlSpaceFound", "\\c" . pattern)
  endfor
endfunction

function! <SID>append_to_search_history()
  if !empty(s:search_letters)
    if !exists("t:ctrlspace_search_history")
      let t:ctrlspace_search_history = []
    endif

    call add(t:ctrlspace_search_history, copy(s:search_letters))
    let t:ctrlspace_search_history = <SID>unique_list(t:ctrlspace_search_history)

    if len(t:ctrlspace_search_history) > g:ctrlspace_max_searches + 1
      unlet t:ctrlspace_jumps[0]
    endif
  endif
endfunction

function! <SID>restore_search_letters(direction)
  if !exists("t:ctrlspace_search_history")
    return
  endif

  if a:direction == "previous"
    let t:ctrlspace_search_history_index += 1

    if t:ctrlspace_search_history_index == len(t:ctrlspace_search_history)
      let t:ctrlspace_search_history_index = len(t:ctrlspace_search_history) - 1
    endif
  elseif a:direction == "next"
    let t:ctrlspace_search_history_index -= 1

    if t:ctrlspace_search_history_index < -1
      let t:ctrlspace_search_history_index = -1
    endif
  endif

  if t:ctrlspace_search_history_index < 0
    let s:search_letters = []
  else
    let s:search_letters = copy(reverse(copy(t:ctrlspace_search_history))[t:ctrlspace_search_history_index])
    let s:restored_search_mode = 1
  endif

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>prepare_buflist_to_display(buflist)
  for entry in a:buflist
    let bufname = entry.raw

    if strlen(bufname) + 6 > &columns
      if g:ctrlspace_unicode_font
        let dots_symbol = "…"
        let dots_symbol_size = 1
      else
        let dots_symbol = "..."
        let dots_symbol_size = 3
      endif

      let bufname = dots_symbol . strpart(bufname, strlen(bufname) - &columns + 6 + dots_symbol_size)
    endif

    if !s:file_mode && !s:workspace_mode
      let bufname = <SID>decorate_with_indicators(bufname, entry.number)
    elseif s:workspace_mode
      if entry.raw ==# s:active_workspace_name
        let bufname .= g:ctrlspace_unicode_font ? " ★" : " *"

        if s:active_workspace_digest !=# <SID>create_workspace_digest()
          let bufname .= "+"
        endif
      endif
    endif

    while strlen(bufname) < &columns
      let bufname .= " "
    endwhile

    " handle wrong strlen for unicode dots symbol
    if g:ctrlspace_unicode_font && bufname =~ "…"
      let bufname .= "  "
    endif

    let entry.text = "  " . bufname . "\n"
  endfor
endfunction

function! <SID>project_root_found()
  if empty(s:project_root)
    let s:project_root = <SID>find_project_root()
    if empty(s:project_root)
      echo g:ctrlspace_symbols.cs . " - Cannot continue with the project root not set."
      return 0
    endif
  endif
  return 1
endfunction

" toggled the buffer list on/off
function! <SID>ctrlspace_toggle(internal)
  if !a:internal
    let s:single_tab_mode                = 1
    let s:nop_mode                       = 0
    let s:new_search_performed           = 0
    let s:search_mode                    = 0
    let s:file_mode                      = 0
    let s:workspace_mode                 = 0
    let s:last_browsed_workspace         = 0
    let s:restored_search_mode           = 0
    let s:search_letters                 = []
    let t:ctrlspace_search_history_index = -1

    if !<SID>project_root_found()
      return
    endif

    if !exists("t:sort_order")
      let t:sort_order = g:ctrlspace_default_sort_order
    endif
  endif

  " if we get called and the list is open --> close it
  let buflistnr = bufnr("__CS__")
  if bufexists(buflistnr)
    if bufwinnr(buflistnr) != -1
      call <SID>kill(buflistnr, 1)
      return
    else
      call <SID>kill(buflistnr, 0)
      if !a:internal
        let t:ctrlspace_start_window = winnr()
        let t:ctrlspace_winrestcmd = winrestcmd()
      endif
    endif
  elseif !a:internal
    let t:ctrlspace_start_window = winnr()
    let t:ctrlspace_winrestcmd = winrestcmd()
  endif

  let bufcount      = bufnr('$')
  let displayedbufs = 0
  let activebuf     = bufnr('')
  let buflist       = []

  " create the buffer first & set it up
  silent! exe "noautocmd botright pedit __CS__"
  silent! exe "noautocmd wincmd P"
  silent! exe "resize" g:ctrlspace_height

  call <SID>set_up_buffer()

  if s:file_mode
    if empty(s:files)
      echo g:ctrlspace_symbols.cs . " - Collecting files..."

      let s:files            = []
      let s:all_files_cached = []


      let i = 1

      for fname in split(globpath('.', '**'), '\n')
        let fname_modified = fnamemodify(fname, ":.")

        if isdirectory(fname_modified) || (fname_modified =~# g:ctrlspace_ignored_files)
          continue
        endif

        call add(s:files, fname_modified)
        call add(s:all_files_cached, { "number": i, "raw": fname_modified, "search_noise": 0 })
        let i += 1
      endfor

      call <SID>prepare_buflist_to_display(s:all_files_cached)
      call sort(s:all_files_cached, function(<SID>SID() . "compare_file_entries"))

      redraw!
      echo g:ctrlspace_symbols.cs . " - Collecting files... Done (" . len(s:files) . ")."
    endif

    let bufcount = len(s:files)
  elseif s:workspace_mode
    if empty(s:workspace_names)
      let s:workspace_names = <SID>get_workspace_names()
    endif

    let bufcount = len(s:workspace_names)
  endif

  if s:file_mode && empty(s:search_letters)
    let buflist = s:all_files_cached
    let displayedbufs = len(buflist)
  else
    for i in range(1, bufcount)
      if s:file_mode
        let bufname = s:files[i - 1]
      elseif s:workspace_mode
        let bufname = s:workspace_names[i - 1]
      else
        if s:single_tab_mode && !exists('t:ctrlspace_list[' . i . ']')
          continue
        endif

        let bufname = fnamemodify(bufname(i), ":.")

        if g:ctrlspace_show_unnamed && !strlen(bufname)
          if !((g:ctrlspace_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
            let bufname = '[' . i . '*No Name]'
          endif
        endif
      endif

      if strlen(bufname) && (s:file_mode || s:workspace_mode || (getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')))
        let search_noise = <SID>find_lowest_search_noise(bufname)

        if search_noise == -1
          continue
        endif

        " count displayed buffers
        let displayedbufs += 1

        call add(buflist, { "number": i, "raw": bufname, "search_noise": search_noise })
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
  if displayedbufs < g:ctrlspace_search_timing[0]
    let search_timing = g:ctrlspace_search_timing[0]
  elseif displayedbufs > g:ctrlspace_search_timing[1]
    let search_timing = g:ctrlspace_search_timing[1]
  else
    let search_timing = displayedbufs
  endif

  silent! exe "set updatetime=" . search_timing

  call <SID>display_list(displayedbufs, buflist)
  call <SID>set_status_line()

  if !empty(s:search_letters)
    call <SID>display_search_patterns()
  endif

  if s:workspace_mode
    if s:last_browsed_workspace
      let activebufline = s:last_browsed_workspace
    else
      let activebufline = 1

      if !empty(s:active_workspace_name)
        let active_workspace_line = 0

        for workspace_name in buflist
          let active_workspace_line += 1

          if s:active_workspace_name ==# workspace_name.raw
            let activebufline = active_workspace_line
            break
          endif
        endfor
      endif
    endif
  else
    let activebufline = s:file_mode ? line("$") : <SID>find_activebufline(activebuf, buflist)
  endif

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:buflist = buflist
  let b:bufcount = displayedbufs

  if !s:file_mode && !s:workspace_mode
    let b:jumplines = <SID>create_jumplines(buflist, activebufline)
  endif

  " go to the correct line
  if !empty(s:search_letters) && s:new_search_performed
    call<SID>move(line("$"))
    if !s:search_mode
      let s:new_search_performed = 0
    endif
  else
    call <SID>move(activebufline)
  endif
  normal! zb
endfunction

function! <SID>create_jumplines(buflist, activebufline)
  let buffers = []
  for bufentry in a:buflist
    call add(buffers, bufentry.number)
  endfor

  if s:single_tab_mode && exists("t:ctrlspace_jumps")
    let bufferjumps = t:ctrlspace_jumps
  else
    let bufferjumps = s:ctrlspace_jumps
  endif

  let jumplines = []

  for jumpbuf in bufferjumps
    if bufwinnr(jumpbuf) == -1
      let jumpline = index(buffers, jumpbuf)
      if (jumpline >= 0)
        call add(jumplines, jumpline + 1)
      endif
    endif
  endfor

  call add(jumplines, a:activebufline)

  return reverse(<SID>unique_list(jumplines))
endfunction

function! <SID>clear_search_mode()
  let s:search_letters          = []
  let s:search_mode             = 0
  let t:ctrlspace_search_history_index = -1

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
  call <SID>set_status_line()
  redraw!
endfunction

function! <SID>remove_search_letter()
  call remove(s:search_letters, -1)
  let s:new_search_performed = 1
  let s:update_search_results = 1
  call <SID>set_status_line()
  redraw!
endfunction

function! <SID>switch_search_mode(switch)
  if (a:switch == 0) && !empty(s:search_letters)
    call <SID>append_to_search_history()
  endif

  let s:search_mode = a:switch
  let s:update_search_results = 1

  call <SID>set_status_line()
  redraw!
endfunction

function! <SID>unique_list(list)
  return filter(copy(a:list), 'index(a:list, v:val, v:key + 1) == -1')
endfunction

function! <SID>decorate_with_indicators(name, bufnum)
  let indicators = ' '

  if s:preview_mode && (s:preview_mode_orginal_buffer == a:bufnum)
    let indicators .= g:ctrlspace_unicode_font ? "☆" : "*"
  elseif bufwinnr(a:bufnum) != -1
    let indicators .= g:ctrlspace_unicode_font ? "★" : "*"
  endif

  if getbufvar(a:bufnum, "&modified")
    let indicators .= "+"
  endif

  if len(indicators) > 1
    return a:name . indicators
  else
    return a:name
  endif
endfunction

function! <SID>find_activebufline(activebuf, buflist)
  let activebufline = 0

  for bufentry in a:buflist
    let activebufline += 1
    if a:activebuf == bufentry.number
      return activebufline
    endif
  endfor

  return activebufline
endfunction

function! <SID>go_to_start_window()
  if exists("t:ctrlspace_start_window")
    silent! exe t:ctrlspace_start_window . "wincmd w"
  endif

  if exists("t:ctrlspace_winrestcmd") && (winrestcmd() != t:ctrlspace_winrestcmd)
    silent! exe t:ctrlspace_winrestcmd

    if winrestcmd() != t:ctrlspace_winrestcmd
      wincmd =
    endif
  endif
endfunction

function! <SID>kill(buflistnr, final)
  if exists("s:killing_now") && s:killing_now
    return
  endif

  let s:killing_now = 1

  if exists("b:old_updatetime")
    silent! exe "set updatetime=" . b:old_updatetime
  endif

  if exists("b:old_timeoutlen")
    silent! exe "set timeoutlen=" . b:old_timeoutlen
  endif

  if a:buflistnr
    silent! exe ':' . a:buflistnr . 'bwipeout'
  else
    bwipeout
  endif

  if a:final
    if s:restored_search_mode
      call <SID>append_to_search_history()
    endif

    call <SID>go_to_start_window()

    if s:preview_mode
      exec ":b " . s:preview_mode_orginal_buffer
      unlet s:preview_mode_orginal_buffer
      let s:preview_mode = 0
    endif
  endif

  unlet s:killing_now
endfunction

function! <SID>tab_command(key)
  call <SID>kill(0, 1)

  if a:key ==# "T"
    silent! exe "tabnew"
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

function! <SID>keypressed(key)
  if a:key ==# "?"
    let g:ctrlspace_show_key_info = !g:ctrlspace_show_key_info
    call <SID>set_status_line()
    redraw!
    return
  endif

  if s:nop_mode
    if !s:search_mode
      if a:key ==# "a"
        if s:file_mode
          call <SID>toggle_file_mode()
        else
          call <SID>toggle_single_tab_mode()
        endif
      elseif a:key ==# "A"
        call <SID>toggle_file_mode()
      elseif a:key ==# "q"
        call <SID>kill(0, 1)
      elseif a:key ==# "Q"
        call <SID>quit_vim()
      elseif a:key ==# "C-p"
        call <SID>restore_search_letters("previous")
      elseif a:key ==# "C-n"
        call <SID>restore_search_letters("next")
      endif
    endif

    if a:key ==# "BS"
      if s:search_mode
        if empty(s:search_letters)
          call <SID>clear_search_mode()
        else
          call <SID>remove_search_letter()
        endif
      elseif !empty(s:search_letters)
        call <SID>clear_search_mode()
      endif
    endif
    return
  endif

  if s:search_mode
    if a:key ==# "BS"
      if empty(s:search_letters)
        call <SID>clear_search_mode()
      else
        call <SID>remove_search_letter()
      endif
    elseif (a:key ==# "/") || (a:key ==# "CR") || (s:file_mode && a:key ==# "BSlash")
      call <SID>switch_search_mode(0)
    elseif a:key =~? "^[A-Z0-9]$"
      call <SID>add_search_letter(a:key)
    endif
  elseif s:workspace_mode == 1
    if a:key ==# "CR"
      call <SID>load_workspace(0, <SID>get_selected_workspace_name())
    elseif a:key ==# "q"
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "a"
      call <SID>load_workspace(1, <SID>get_selected_workspace_name())
    elseif a:key ==# "s"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 2
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "S"
      call <SID>save_workspace(s:active_workspace_name)
    elseif (a:key ==# "w") || (a:key ==# "BS")
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "d"
      call <SID>delete_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "j"
      call <SID>move("down")
    elseif a:key ==# "k"
      call <SID>move("up")
    elseif a:key ==# "MouseDown"
      call <SID>move("up")
    elseif a:key ==# "MouseUp"
      call <SID>move("down")
    elseif a:key ==# "LeftRelease"
      call <SID>move("mouse")
    elseif a:key ==# "2-LeftMouse"
      call <SID>move("mouse")
      call <SID>load_workspace(0, <SID>get_selected_workspace_name())
    elseif a:key ==# "Down"
      call feedkeys("j")
    elseif a:key ==# "Up"
      call feedkeys("k")
    elseif (a:key ==# "Home") || (a:key ==# "K")
      call <SID>move(1)
    elseif (a:key ==# "End") || (a:key ==# "J")
      call <SID>move(line("$"))
    elseif (a:key ==# "PageDown") || (a:key ==# "C-f")
      call <SID>move("pgdown")
    elseif (a:key ==# "PageUp") || (a:key ==# "C-b")
      call <SID>move("pgup")
    elseif a:key ==# "C-d"
      call <SID>move("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move("half_pgup")
    endif
  elseif s:workspace_mode == 2
    if a:key ==# "CR"
      call <SID>save_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "q"
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "s"
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 1
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "S"
      call <SID>save_workspace(s:active_workspace_name)
    elseif (a:key ==# "w") || (a:key ==# "BS")
      let s:last_browsed_workspace = line(".")
      call <SID>kill(0, 0)
      let s:workspace_mode = 0
      call <SID>ctrlspace_toggle(1)
    elseif a:key ==# "d"
      call <SID>delete_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "j"
      call <SID>move("down")
    elseif a:key ==# "k"
      call <SID>move("up")
    elseif a:key ==# "MouseDown"
      call <SID>move("up")
    elseif a:key ==# "MouseUp"
      call <SID>move("down")
    elseif a:key ==# "LeftRelease"
      call <SID>move("mouse")
    elseif a:key ==# "2-LeftMouse"
      call <SID>move("mouse")
      call <SID>save_workspace(<SID>get_selected_workspace_name())
    elseif a:key ==# "Down"
      call feedkeys("j")
    elseif a:key ==# "Up"
      call feedkeys("k")
    elseif (a:key ==# "Home") || (a:key ==# "K")
      call <SID>move(1)
    elseif (a:key ==# "End") || (a:key ==# "J")
      call <SID>move(line("$"))
    elseif (a:key ==# "PageDown") || (a:key ==# "C-f")
      call <SID>move("pgdown")
    elseif (a:key ==# "PageUp") || (a:key ==# "C-b")
      call <SID>move("pgup")
    elseif a:key ==# "C-d"
      call <SID>move("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move("half_pgup")
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
    elseif (a:key ==# "/") || (a:key ==# "BSlash")
      call <SID>switch_search_mode(1)
    elseif a:key ==# "v"
      call <SID>load_file("vs")
    elseif a:key ==# "s"
      call <SID>load_file("sp")
    elseif a:key ==# "t"
      call <SID>load_file("tabnew")
    elseif a:key ==# "T"
      call <SID>tab_command(a:key)
    elseif a:key ==# "="
      call <SID>new_tab_label()
    elseif a:key =~? "^[0-9]$"
      call <SID>tab_command(a:key)
    elseif a:key ==# "+"
      silent! exe "tabm+1"
    elseif a:key ==# "-"
      silent! exe "tabm-1"
    elseif a:key ==# "_"
      let t:ctrlspace_label = ""
      redraw!
    elseif a:key ==# "["
      call <SID>tab_command(a:key)
    elseif a:key ==# "]"
      call <SID>tab_command(a:key)
    elseif a:key ==# "r"
      call <SID>refresh_files()
    elseif a:key ==# "q"
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move("down")
    elseif a:key ==# "k"
      call <SID>move("up")
    elseif a:key ==# "MouseDown"
      call <SID>move("up")
    elseif a:key ==# "MouseUp"
      call <SID>move("down")
    elseif a:key ==# "LeftRelease"
      call <SID>move("mouse")
    elseif a:key ==# "2-LeftMouse"
      call <SID>move("mouse")
      call <SID>load_file()
    elseif a:key ==# "Down"
      call feedkeys("j")
    elseif a:key ==# "Up"
      call feedkeys("k")
    elseif (a:key ==# "Home") || (a:key ==# "K")
      call <SID>move(1)
    elseif (a:key ==# "End") || (a:key ==# "J")
      call <SID>move(line("$"))
    elseif (a:key ==# "PageDown") || (a:key ==# "C-f")
      call <SID>move("pgdown")
    elseif (a:key ==# "PageUp") || (a:key ==# "C-b")
      call <SID>move("pgup")
    elseif a:key ==# "C-d"
      call <SID>move("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move("half_pgup")
    elseif a:key ==? "A"
      call <SID>toggle_file_mode()
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif a:key ==# "C"
      call <SID>close_tab()
    elseif a:key ==# "e"
      call <SID>edit_file()
    elseif a:key ==# "E"
      call <SID>explore_directory()
    elseif a:key ==# "R"
      call <SID>remove_file()
    elseif a:key ==# "m"
      call <SID>move_file()
    elseif a:key ==# "w"
      if empty(<SID>get_workspace_names())
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:file_mode = !s:file_mode
        let s:workspace_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    endif
  else
    if a:key ==# "CR"
      call <SID>load_buffer()
    elseif a:key ==# "Space"
      call <SID>load_many_buffers()
    elseif (a:key ==# "Tab")
      call <SID>preview_buffer(0)
    elseif a:key ==# "BS"
      if !empty(s:search_letters)
        call <SID>clear_search_mode()
      elseif !s:single_tab_mode
        call <SID>toggle_single_tab_mode()
      else
        call <SID>kill(0, 1)
      endif
    elseif a:key ==# "/"
      call <SID>switch_search_mode(1)
    elseif a:key ==# "v"
      call <SID>load_buffer("vs")
    elseif a:key ==# "s"
      call <SID>load_buffer("sp")
    elseif a:key ==# "t"
      call <SID>load_buffer("tabnew")
    elseif a:key ==# "T"
      call <SID>tab_command(a:key)
    elseif a:key ==# "="
      call <SID>new_tab_label()
    elseif a:key =~? "^[0-9]$"
      call <SID>tab_command(a:key)
    elseif a:key ==# "+"
      silent! exe "tabm+1"
    elseif a:key ==# "-"
      silent! exe "tabm-1"
    elseif a:key ==# "_"
      let t:ctrlspace_label = ""
      redraw!
    elseif a:key ==# "["
      call <SID>tab_command(a:key)
    elseif a:key ==# "]"
      call <SID>tab_command(a:key)
    elseif a:key ==# "o" && empty(s:search_letters)
      call <SID>toggle_order()
    elseif a:key ==# "q"
      call <SID>kill(0, 1)
    elseif a:key ==# "Q"
      call <SID>quit_vim()
    elseif a:key ==# "j"
      call <SID>move("down")
    elseif a:key ==# "k"
      call <SID>move("up")
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
    elseif a:key ==# "MouseDown"
      call <SID>move("up")
    elseif a:key ==# "MouseUp"
      call <SID>move("down")
    elseif a:key ==# "LeftRelease"
      call <SID>move("mouse")
    elseif a:key ==# "2-LeftMouse"
      call <SID>move("mouse")
      call <SID>load_buffer()
    elseif a:key ==# "Down"
      call feedkeys("j")
    elseif a:key ==# "Up"
      call feedkeys("k")
    elseif (a:key ==# "Home") || (a:key ==# "K")
      call <SID>move(1)
    elseif (a:key ==# "End") || (a:key ==# "J")
      call <SID>move(line("$"))
    elseif (a:key ==# "PageDown") || (a:key ==# "C-f")
      call <SID>move("pgdown")
    elseif (a:key ==# "PageUp") || (a:key ==# "C-b")
      call <SID>move("pgup")
    elseif a:key ==# "C-d"
      call <SID>move("half_pgdown")
    elseif a:key ==# "C-u"
      call <SID>move("half_pgup")
    elseif a:key ==# "a"
      call <SID>toggle_single_tab_mode()
    elseif a:key ==# "f" && s:single_tab_mode
      call <SID>detach_buffer()
    elseif a:key ==# "F"
      call <SID>delete_foreign_buffers(0)
    elseif a:key ==# "c" && s:single_tab_mode
      call <SID>close_buffer()
    elseif a:key ==# "C"
      call <SID>close_tab()
    elseif a:key ==# "e"
      call <SID>edit_file()
    elseif a:key ==# "E"
      call <SID>explore_directory()
    elseif a:key ==# "R"
      call <SID>remove_file()
    elseif a:key ==# "m"
      call <SID>move_file()
    elseif a:key ==# "S"
      if empty(<SID>get_workspace_names())
        call <SID>save_first_workspace()
      else
        call <SID>save_workspace(s:active_workspace_name)
      endif
    elseif a:key ==# "w"
      if empty(<SID>get_workspace_names())
        call <SID>save_first_workspace()
      else
        call <SID>kill(0, 0)
        let s:workspace_mode = 1
        call <SID>ctrlspace_toggle(1)
      endif
    elseif a:key ==# "A"
      call <SID>toggle_file_mode()
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    elseif a:key ==# "BSlash"
      call <SID>toggle_file_mode()
      call <SID>switch_search_mode(1)
    endif
  endif
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
        let root_found = index(s:project_roots, candidate) != -1
      endif

      if root_found
        let project_root = candidate
        break
      endif

      let last_candidate = candidate
      let candidate = fnamemodify(candidate, ":p:h:h")
    endwhile

    if !root_found
      let project_root = <SID>get_input("No project root found. Set the project root: ", project_root, "dir")
      if !empty(project_root) && isdirectory(project_root)
        call <SID>add_project_root(project_root)
      else
        let project_root = ""
      endif
    endif
  endif

  return project_root
endfunction

function! <SID>toggle_file_mode()
  let s:file_mode = !s:file_mode

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>set_status_line()
  if has('statusline')
    hi default link User1 LineNr
    let &l:statusline = "%1*\ \ " . g:ctrlspace_symbols.cs . "\ \ %*\ \ " . ctrlspace#statusline_info_segment()

    if g:ctrlspace_show_key_info
      let key_info = "  %=%1* " . ctrlspace#statusline_key_info_segment() . " "

      if strlen(&l:statusline) + strlen(key_info) > &columns
        let key_info = "  %=%1* ? ... "
      endif

      let &l:statusline .= key_info
    endif
  endif
endfunction

function! <SID>set_up_buffer()
  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nomodifiable
  setlocal nowrap
  setlocal nonumber
  setlocal nocursorcolumn
  setlocal nocursorline

  silent! exe "lcd " . s:project_root

  let b:search_patterns = {}

  if &timeout
    let b:old_timeoutlen = &timeoutlen
    set timeoutlen=10
  endif

  let b:old_updatetime = &updatetime

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

    hi def CtrlSpaceNormal ctermfg=black ctermbg=white
    hi def CtrlSpaceSelected ctermfg=white ctermbg=black
  endif

  call clearmatches()
  hi def CtrlSpaceFound ctermfg=NONE ctermbg=NONE cterm=underline

  for key_name in s:key_names
    let key = strlen(key_name) > 1 ? ("<" . key_name . ">") : key_name
    silent! exe "noremap <silent><buffer> " . key . " :call <SID>keypressed(\"" . key_name . "\")<CR>"
  endfor
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

function! <SID>compare_bufentries(a, b)
  if t:sort_order == 1
    if s:single_tab_mode
      if exists("t:ctrlspace_list[" . a:a.number . "]") && exists("t:ctrlspace_list[" . a:b.number . "]")
        return t:ctrlspace_list[a:a.number] - t:ctrlspace_list[a:b.number]
      endif
    endif
    return a:a.number - a:b.number
  elseif t:sort_order == 2
    if a:a.raw < a:b.raw
      return -1
    elseif a:a.raw > a:b.raw
      return 1
    else
      return 0
    endif
  endif
endfunction

function! <SID>compare_file_entries(a, b)
  if a:a.raw < a:b.raw
    return -1
  elseif a:a.raw > a:b.raw
    return 1
  else
    return 0
  endif
endfunction

function! <SID>compare_workspace_names(a, b)
  if a:a.raw < a:b.raw
    return -1
  elseif a:a.raw > a:b.raw
    return 1
  else
    return 0
  endif
endfunction

function! <SID>compare_bufentries_with_search_noise(a, b)
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

function! <SID>SID()
  let fullname = expand("<sfile>")
  return matchstr(fullname, '<SNR>\d\+_')
endfunction

function! <SID>display_list(displayedbufs, buflist)
  setlocal modifiable
  if a:displayedbufs > 0
    if s:file_mode && empty(s:search_letters)
      let buflist = a:buflist
    else
      if !empty(s:search_letters)
        call sort(a:buflist, function(<SID>SID() . "compare_bufentries_with_search_noise"))
      elseif s:workspace_mode
        call sort(a:buflist, function(<SID>SID() . "compare_workspace_names"))
      elseif exists("t:sort_order")
        call sort(a:buflist, function(<SID>SID() . "compare_bufentries"))
      endif

      " trim the list in search mode
      let buflist = s:search_mode && (len(a:buflist) > <SID>max_height()) ? a:buflist[-<SID>max_height() : -1] : a:buflist

      call <SID>prepare_buflist_to_display(buflist)
    endif

    " input the buffer list, delete the trailing newline, & fill with blank lines
    let buftext = ""

    for bufentry in buflist
      let buftext .= bufentry.text
    endfor

    silent! put! =buftext
    " is there any way to NOT delete into a register? bummer...
    "normal! Gdd$
    normal! GkJ
    let fill = <SID>make_filler()
    while winheight(0) > line(".")
      silent! put =fill
    endwhile

    let s:nop_mode = 0
  else
    let empty_list_message = "  List empty"

    if &columns < (strlen(empty_list_message) + 2)
      if g:ctrlspace_unicode_font
        let dots_symbol = "…"
        let dots_symbol_size = 1
      else
        let dots_symbol = "..."
        let dots_symbol_size = 3
      endif

      let empty_list_message = strpart(empty_list_message, 0, &columns - 2 - dots_symbol_size) . dots_symbol
    endif

    while strlen(empty_list_message) < &columns
      let empty_list_message .= ' '
    endwhile

    " handle wrong strlen for unicode dots symbol
    if g:ctrlspace_unicode_font && empty_list_message =~ "…"
      let empty_list_message .= "  "
    endif

    silent! put! =empty_list_message
    normal! GkJ

    let fill = <SID>make_filler()

    while winheight(0) > line(".")
      silent! put =fill
    endwhile

    normal! 0

    " handle vim segfault on calling bd/bw if there are no buffers listed
    let any_buffer_listed = 0
    for i in range(1, bufnr("$"))
      if buflisted(i)
        let any_buffer_listed = 1
        break
      endif
    endfor

    if !any_buffer_listed
      au! CtrlSpaceLeave BufLeave
      noremap <silent> <buffer> q :q<CR>
      if g:ctrlspace_set_default_mapping
        silent! exe 'noremap <silent><buffer>' . g:ctrlspace_default_mapping_key . ' :q<CR>'
      endif
    endif

    let s:nop_mode = 1
  endif
  setlocal nomodifiable
endfunction

" move the selection bar of the list:
" where can be "up"/"down"/"mouse" or
" a line number
function! <SID>move(where)
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
  call setline(line("."), " ".strpart(getline(line(".")), 1))

  " go where the user want's us to go
  if a:where == "up"
    call <SID>goto(line(".")-1)
  elseif a:where == "down"
    call <SID>goto(line(".")+1)
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
  call setline(line("."), ">".strpart(getline(line(".")), 1))

  " remember this line, in case the mouse is clicked
  " (which automatically moves the cursor there)
  let b:lastline = line(".")

  setlocal nomodifiable
endfunction

" tries to set the cursor to a line of the buffer list
function! <SID>goto(line)
  if b:bufcount < 1 | return | endif
  if a:line < 1
    if g:ctrlspace_cyclic_list
      call <SID>goto(b:bufcount - a:line)
    else
      call cursor(1, 1)
    endif
  elseif a:line > b:bufcount
    if g:ctrlspace_cyclic_list
      call <SID>goto(a:line - b:bufcount)
    else
      call cursor(b:bufcount, 1)
    endif
  else
    call cursor(a:line, 1)
  endif
endfunction

function! <SID>jump(direction)
  if !exists("b:jumppos")
    let b:jumppos = 0
  endif

  if a:direction == "previous"
    let b:jumppos += 1

    if b:jumppos == len(b:jumplines)
      let b:jumppos = len(b:jumplines) - 1
    endif
  elseif a:direction == "next"
    let b:jumppos -= 1

    if b:jumppos < 0
      let b:jumppos = 0
    endif
  endif

  call <SID>move(string(b:jumplines[b:jumppos]))
endfunction

function! <SID>load_many_buffers()
  let nr = <SID>get_selected_buffer()
  let current_line = line(".")

  call <SID>kill(0, 0)
  call <SID>go_to_start_window()

  exec ":b " . nr

  call <SID>ctrlspace_toggle(1)
  call <SID>move(current_line)
endfunction

function! <SID>load_buffer(...)
  let nr = <SID>get_selected_buffer()
  call <SID>kill(0, 1)

  if !empty(a:000)
    exec ":" . a:1
  endif

  exec ":b " . nr
endfunction

function! <SID>load_many_files()
  let file_number = <SID>get_selected_buffer()
  let file = fnamemodify(s:files[file_number - 1], ":p")
  let current_line = line(".")

  call <SID>kill(0, 0)
  call <SID>go_to_start_window()

  exec ":e " . file

  call <SID>ctrlspace_toggle(1)
  call <SID>move(current_line)
endfunction

function! <SID>load_file(...)
  let file_number = <SID>get_selected_buffer()
  let file = fnamemodify(s:files[file_number - 1], ":p")

  call <SID>kill(0, 1)

  if !empty(a:000)
    exec ":" . a:1
  endif

  exec ":e " . file
endfunction

function! <SID>preview_buffer(nr, ...)
  if !s:preview_mode
    let s:preview_mode = 1
    let s:preview_mode_orginal_buffer = winbufnr(t:ctrlspace_start_window)
  endif

  let nr = a:nr ? a:nr : <SID>get_selected_buffer()

  call <SID>kill(0, 0)

  call <SID>go_to_start_window()
  silent! exe ":b " . nr

  let custom_commands = !empty(a:000) ? a:1 : ["normal! zb"]

  for c in custom_commands
    silent! exe c
  endfor

  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>load_buffer_into_window(winnr)
  if exists("t:ctrlspace_start_window")
    let old_start_window = t:ctrlspace_start_window
    let t:ctrlspace_start_window = a:winnr
  endif
  call <SID>load_buffer()
  if exists("old_start_window")
    let t:ctrlspace_start_window = old_start_window
  endif
endfunction

" deletes the selected buffer
function! <SID>delete_buffer()
  let nr = <SID>get_selected_buffer()
  if !getbufvar(str2nr(nr), '&modified')
    let selected_buffer_window = bufwinnr(str2nr(nr))
    if selected_buffer_window != -1
      call <SID>move("down")
      if <SID>get_selected_buffer() == nr
        call <SID>move("up")
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

    let current_tab = tabpagenr()

    for t in range(1, tabpagenr('$'))
      if t == current_tab
        continue
      endif

      for b in tabpagebuflist(t)
        if b == nr
          silent! exe "tabn " . t

          let tab_window = bufwinnr(b)
          let ctrlspace_list    = gettabvar(t, "ctrlspace_list")

          call remove(ctrlspace_list, nr)

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
    silent! exe "bdelete " . nr

    call <SID>forget_buffers_in_all_tabs([nr])
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>forget_buffers_in_all_tabs(numbers)
  for t in range(1, tabpagenr("$"))
    let ctrlspace_list = gettabvar(t, "ctrlspace_list")

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
      " use wipeout for nonames
      let cmd = empty(getbufvar(b, "&buftype")) && !filereadable(bufname(b)) ? "bwipeout" : "bdelete"
      exe cmd b
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
  if s:preview_mode
    return
  endif

  if !exists('t:ctrlspace_list')
    let t:ctrlspace_list = {}
  endif

  let current = bufnr('%')

  if !exists("t:ctrlspace_list[" . current . "]") &&
        \ getbufvar(current, '&modifiable') &&
        \ getbufvar(current, '&buflisted') &&
        \ current != bufnr("__CS__")
    let t:ctrlspace_list[current] = len(t:ctrlspace_list) + 1
  endif
endfunction

function! <SID>add_jump()
  if s:preview_mode
    return
  endif

  if !exists("t:ctrlspace_jumps")
    let t:ctrlspace_jumps = []
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__CS__")
    call add(s:ctrlspace_jumps, current)
    let s:ctrlspace_jumps = <SID>unique_list(s:ctrlspace_jumps)

    if len(s:ctrlspace_jumps) > g:ctrlspace_max_jumps + 1
      unlet s:ctrlspace_jumps[0]
    endif

    call add(t:ctrlspace_jumps, current)
    let t:ctrlspace_jumps = <SID>unique_list(t:ctrlspace_jumps)

    if len(t:ctrlspace_jumps) > g:ctrlspace_max_jumps + 1
      unlet t:ctrlspace_jumps[0]
    endif
  endif
endfunction

function! <SID>toggle_single_tab_mode()
  let s:single_tab_mode = !s:single_tab_mode

  if !empty(s:search_letters)
    let s:new_search_performed = 1
  endif

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>toggle_order()
  if exists("t:sort_order")
    if t:sort_order == 1
      let t:sort_order = 2
    else
      let t:sort_order = 1
    endif

    call <SID>kill(0, 0)
    call <SID>ctrlspace_toggle(1)
  endif
endfunction

function! <SID>refresh_files()
  let s:files = []
  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
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
  let s:files = []
  call delete(path)

  call <SID>kill(0, 0)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>move_file()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.")

  if !filereadable(path) || isdirectory(path)
    return
  endif

  let new_file = <SID>get_input("Move file to: ", path, "file")

  if empty(new_file)
    return
  endif

  let buffer_names = {}

  " must be collected BEFORE actual file renaming
  for b in range(1, bufnr('$'))
    let buffer_names[b] = fnamemodify(resolve(bufname(b)), ":.")
  endfor

  call rename(path, new_file)

  for [b, name] in items(buffer_names)
    if name == path
      let commands = ["f " . new_file, "w!"]
      call <SID>preview_buffer(str2nr(b), commands)
    endif
  endfor

  let s:files = []

  call <SID>kill(0, 1)
  call <SID>ctrlspace_toggle(1)
endfunction

function! <SID>explore_directory()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.:h")

  if !isdirectory(path)
    return
  endif

  let path = fnamemodify(path, ":p")

  call <SID>kill(0, 1)
  silent! exe "e " . path
endfunction!

function! <SID>edit_file()
  let nr   = <SID>get_selected_buffer()
  let path = fnamemodify(s:file_mode ? s:files[nr - 1] : resolve(bufname(nr)), ":.:h")

  if !isdirectory(path)
    return
  endif

  let new_file = <SID>get_input("Edit a new file: ", path . '/', "file")

  if empty(new_file) || isdirectory(new_file)
    return
  endif

  let new_file = fnamemodify(new_file, ":p")

  call <SID>kill(0, 1)
  silent! exe "e " . new_file
endfunction!

function! <SID>close_tab()
  if tabpagenr("$") == 1
    return
  endif

  if exists("t:ctrlspace_label") && !empty(t:ctrlspace_label)
    let buf_count = len(ctrlspace#bufferlist(tabpagenr()))

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
      call <SID>move("down")
      if <SID>get_selected_buffer() == nr
        call <SID>move("up")
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

if !(has("ruby") && g:ctrlspace_use_ruby_bindings)
  finish
endif

let s:ctrlspace_folder = fnamemodify(resolve(expand('<sfile>:p')), ':h')

ruby << EOF
require "pathname"
require Pathname.new(VIM.evaluate("s:ctrlspace_folder")).parent.join("ruby", "ctrlspace").to_s
EOF
