" Vim-F2 - A buffers manager
" Maintainer:   Szymon Wrozynski
" Version:      3.1.3
"
" Installation:
" Place in ~/.vim/plugin/f2.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-f2.git
"
" License:
" Copyright (c) 2013 Szymon Wrozynski <szymon@wrozynski.com>
" Distributed under the same terms as Vim itself.
" Original BufferList plugin code - copyright (c) 2005 Robert Lillack <rob@lillack.de>
" Redistribution in any form with or without modification permitted.
" Licensed under MIT License conditions.
"
" Usage:
" https://github.com/szw/vim-f2/blob/master/README.md

if exists('g:f2_loaded')
  finish
endif

let g:f2_loaded = 1

function! <SID>define_config_variable(name, default_value)
  if !exists("g:f2_" . a:name)
    let g:{"f2_" . a:name} = a:default_value
  endif
endfunction

call <SID>define_config_variable("height", 1)
call <SID>define_config_variable("max_height", 15)
call <SID>define_config_variable("show_unnamed", 2)
call <SID>define_config_variable("set_default_mapping", 1)
call <SID>define_config_variable("default_mapping_key", "<F2>")
call <SID>define_config_variable("default_label_mapping_key", "<F12>")
call <SID>define_config_variable("cyclic_list", 1)
call <SID>define_config_variable("max_jumps", 100)
call <SID>define_config_variable("max_searches", 100)
call <SID>define_config_variable("default_sort_order", 2) " 0 - no sort, 1 - chronological, 2 - alphanumeric
call <SID>define_config_variable("default_file_sort_order", 2) " 1 - by length, 2 - alphanumeric

" 0 - no custom tabline, 1 - current label without filename, 2 - current label with filename
call <SID>define_config_variable("custom_tabline", 1)

call <SID>define_config_variable("session_file", [".git/f2_session", ".svn/f2_session", "CVS/f2_session", ".f2_session"])
call <SID>define_config_variable("unicode_font", 1)
call <SID>define_config_variable("ignored_files", '\v(tmp|temp)[\/]')
call <SID>define_config_variable("show_key_info", 100)

command! -nargs=0 -range F2 :call <SID>f2_toggle(0)
command! -nargs=0 -range F2Label :call <SID>new_tab_label()
command! -nargs=0 -range F2SessionSave :call <SID>save_session()
command! -nargs=0 -range -bang F2SessionLoad :call <SID>load_session(<bang>0)

if g:f2_custom_tabline
  set tabline=%!F2TabLine()
endif

function! <SID>set_default_mapping(key, action)
  let key = a:key
  if !empty(key)
    if key ==? "<C-Space>" && !has("gui_running")
      let key = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . key . ' ' . a:action
  endif
endfunction

if g:f2_set_default_mapping
  call <SID>set_default_mapping(g:f2_default_mapping_key, ":F2<CR>")
  call <SID>set_default_mapping(g:f2_default_label_mapping_key, ":F2Label<CR>")
endif

let s:files           = []
let s:file_sort_order = g:f2_default_file_sort_order
let s:preview_mode    = 0

au BufEnter * call <SID>add_tab_buffer()

let s:f2_jumps = []
au BufEnter * call <SID>add_jump()

function! F2List(tabnr)
  let buffer_list     = {}
  let f2              = gettabvar(a:tabnr, "f2_list")
  let visible_buffers = tabpagebuflist(a:tabnr)

  if type(f2) != 4
    return buffer_list
  endif

  for i in keys(f2)
    let i = str2nr(i)

    let bufname = bufname(i)

    if g:f2_show_unnamed && !strlen(bufname)
      if !((g:f2_show_unnamed == 2) && !getbufvar(i, '&modified')) || (index(visible_buffers, i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      let buffer_list[i] = bufname
    endif
  endfor

  return buffer_list
endfunction

function! F2StatusLineKeyInfoSegment(...)
  let separator = (a:0 > 0) ? a:1 : " "
  let keys      = []

  if s:nop_mode
    if !s:search_mode
      if !empty(s:search_letters)
        call add(keys, "BS")
      endif

      call add(keys, "q")
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
    call add(keys, "?")
    call add(keys, "v")
    call add(keys, "s")
    call add(keys, "t")
    call add(keys, "o")
    call add(keys, "q")
    call add(keys, "r")
    call add(keys, "j")
    call add(keys, "k")
    call add(keys, "a")
    call add(keys, "A")
    call add(keys, "^p")
    call add(keys, "^n")
  else
    call add(keys, "CR")
    call add(keys, "Sp")
    call add(keys, "^Sp")
    call add(keys, "BS")
    call add(keys, "/")
    call add(keys, '\')
    call add(keys, "?")
    call add(keys, "v")
    call add(keys, "s")
    call add(keys, "t")
    call add(keys, "o")
    call add(keys, "q")
    call add(keys, "j")
    call add(keys, "k")
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
    call add(keys, "e")
    call add(keys, "a")
    call add(keys, "A")
    call add(keys, "^p")
    call add(keys, "^n")
    call add(keys, "S")
    call add(keys, "L")
    call add(keys, "l")
  endif

  return join(keys, separator)
endfunction

function! F2StatusLineInfoSegment(...)
  if g:f2_unicode_font
    let symbols = {
          \ "tab"     : "⊙",
          \ "all"     : "∷",
          \ "add"     : "○",
          \ "ord"     : "₁²₃",
          \ "abc"     : "∧вс",
          \ "len"     : "●∙⋅",
          \ "prv"     : "⌕",
          \ "s_left"  : "›",
          \ "s_right" : "‹"
          \ }
  else
    let symbols = {
          \ "tab"     : "TAB",
          \ "all"     : "ALL",
          \ "add"     : "ADD",
          \ "ord"     : "123",
          \ "abc"     : "ABC",
          \ "len"     : "LEN",
          \ "prv"     : "*",
          \ "s_left"  : "[",
          \ "s_right" : "]"
          \ }
  endif

  let statusline_elements = []

  if s:file_mode
    call add(statusline_elements, symbols.add)
  elseif s:single_tab_mode
    call add(statusline_elements, symbols.tab)
  else
    call add(statusline_elements, symbols.all)
  endif

  if empty(s:search_letters) && !s:search_mode
    if s:file_mode
      if s:file_sort_order == 1
        call add(statusline_elements, symbols.len)
      elseif s:file_sort_order == 2
        call add(statusline_elements, symbols.abc)
      endif
    elseif exists("t:sort_order")
      if t:sort_order == 1
        call add(statusline_elements, symbols.ord)
      elseif t:sort_order == 2
        call add(statusline_elements, symbols.abc)
      endif
    endif
  else
    let search_element = symbols.s_left . join(s:search_letters, "")

    if s:search_mode
      let search_element .= "_"
    endif

    let search_element .= symbols.s_right

    call add(statusline_elements, search_element)
  endif

  if s:preview_mode
    call add(statusline_elements, symbols.prv)
  endif

  let separator = (a:0 > 0) ? a:1 : "  "
  return join(statusline_elements, separator)
endfunction

function! F2TabLine()
  let last_tab    = tabpagenr("$")
  let current_tab = tabpagenr()
  let tabline     = ''

  for t in range(1, last_tab)
    let winnr               = tabpagewinnr(t)
    let buflist             = tabpagebuflist(t)
    let bufnr               = buflist[winnr - 1]
    let bufname             = bufname(bufnr)
    let bufs_number         = len(F2List(t))
    let bufs_number_to_show = ""

    if bufs_number > 1
      if g:f2_unicode_font
        let small_numbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
        let number_str    = string(bufs_number)

        for i in range(0, len(number_str) - 1)
          let bufs_number_to_show .= small_numbers[str2nr(number_str[i])]
        endfor
      else
        let bufs_number_to_show = ":" . bufs_number
      endif
    endif

    if empty(bufname)
      let title = "[" . bufnr . "*No Name]"
    elseif bufname ==# "__F2__"
      let title = "[" . (g:f2_unicode_font ? "ϝ₂" : "F2") . "]"
    else
      let title = "[" . fnamemodify(bufname, ':t') . "]"
    endif

    let label = gettabvar(t, "f2_label")

    if !empty(label)
      let title = ((t == current_tab) && (g:f2_custom_tabline == 2) ? label . " " . title : label)
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
  call inputsave()
  let t:f2_label = input('Label for tab ' . tabpagenr() . ': ')
  call inputrestore()
  redraw!
endfunction

function! <SID>tab_contains_modified_buffers(tabnr)
  for b in map(keys(F2List(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction

function! <SID>session_file()
  for candidate in g:f2_session_file
    if isdirectory(fnamemodify(candidate, ":h:t"))
      return candidate
    endif
  endfor

  return g:f2_session_file[-1]
endfunction

function! <SID>save_session()
  let filename = <SID>session_file()
  let last_tab = tabpagenr("$")

  let lines = []

  for t in range(1, last_tab)
    let line = [t, gettabvar(t, "f2_label"), tabpagenr() == t]

    let f2_list = F2List(t)

    let bufs     = []
    let visibles = []

    let visible_buffers = tabpagebuflist(t)

    let f2_list_index = -1

    for [nr, bname] in items(f2_list)
      let f2_list_index += 1
      let bufname = fnamemodify(bname, ":.")
      let nr = str2nr(nr)

      if !filereadable(bufname)
        continue
      endif

      if index(visible_buffers, nr) != -1
        call add(visibles, f2_list_index)
      endif

      call add(bufs, bufname)
    endfor

    call add(line, join(bufs, "|"))
    call add(line, join(visibles, "|"))
    call add(lines, join(line, ","))
  endfor

  call writefile(lines, filename)

  echo "F2: The session been saved (" . filename . ")."
endfunction

function! <SID>load_session(bang)
  let filename = <SID>session_file()

  if !filereadable(filename)
    echo "F2: No session to load."
    return
  endif

  echo "F2: Session loading..."

  let lines = readfile(filename)

  let commands = []

  let create_new_tab = !a:bang

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

    if create_new_tab
      call add(commands, "tabe")
    else
      let create_new_tab = 1 " we want omit only first tab creation if a:bang == 1
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
      call add(commands, "let f2_session_current_tab = tabpagenr()")
    endif

    if !empty(tab_label)
      call add(commands, "let t:f2_label = '" . tab_label . "'")
    endif
  endfor

  call add(commands, "exe 'normal! ' . f2_session_current_tab . 'gt'")
  call add(commands, "redraw!")

  for c in commands
    silent! exe c
  endfor

  echo "F2: The session has been loaded (" . filename . ")."
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
endfunction

function! <SID>display_search_patterns()
  for pattern in keys(b:search_patterns)
    call matchadd("F2ItemFound", "\\c" . pattern)
  endfor
endfunction

function! <SID>append_to_search_history()
  if !empty(s:search_letters)
    if !exists("t:f2_search_history")
      let t:f2_search_history = []
    endif

    call add(t:f2_search_history, copy(s:search_letters))
    let t:f2_search_history = <SID>unique_list(t:f2_search_history)

    if len(t:f2_search_history) > g:f2_max_searches + 1
      unlet t:f2_jumps[0]
    endif
  endif
endfunction

function! <SID>restore_search_letters(direction)
  if !exists("t:f2_search_history")
    return
  endif

  if a:direction == "previous"
    let t:f2_search_history_index += 1

    if t:f2_search_history_index == len(t:f2_search_history)
      let t:f2_search_history_index = len(t:f2_search_history) - 1
    endif
  elseif a:direction == "next"
    let t:f2_search_history_index -= 1

    if t:f2_search_history_index < -1
      let t:f2_search_history_index = -1
    endif
  endif

  if t:f2_search_history_index < 0
    let s:search_letters = []
  else
    let s:search_letters = copy(reverse(copy(t:f2_search_history))[t:f2_search_history_index])
    let s:restored_search_mode = 1
  endif

  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

" toggled the buffer list on/off
function! <SID>f2_toggle(internal)
  if !a:internal
    let s:single_tab_mode         = 1
    let s:nop_mode                = 0
    let s:new_search_performed    = 0
    let s:search_mode             = 0
    let s:file_mode               = 0
    let s:restored_search_mode    = 0
    let s:search_letters          = []
    let t:f2_search_history_index = -1

    if !exists("t:sort_order")
      let t:sort_order = g:f2_default_sort_order
    endif
  endif

  " if we get called and the list is open --> close it
  let buflistnr = bufnr("__F2__")
  if bufexists(buflistnr)
    if bufwinnr(buflistnr) != -1
      call <SID>kill(buflistnr, 1)
      return
    else
      call <SID>kill(buflistnr, 0)
      if !a:internal
        let t:f2_start_window = winnr()
        let t:f2_winrestcmd = winrestcmd()
      endif
    endif
  elseif !a:internal
    let t:f2_start_window = winnr()
    let t:f2_winrestcmd = winrestcmd()
  endif

  let bufcount      = bufnr('$')
  let displayedbufs = 0
  let activebuf     = bufnr('')
  let buflist       = []

  " create the buffer first & set it up
  silent! exe "noautocmd botright pedit __F2__"
  silent! exe "noautocmd wincmd P"
  silent! exe "resize" g:f2_height

  call <SID>set_up_buffer()

  let width = winwidth(0)

  if s:file_mode
    if empty(s:files)
      let s:files = split(globpath('.', '**'), '\n')
    endif

    let bufcount = len(s:files)
  endif

  for i in range(1, bufcount)
    if s:file_mode
      let bufname = fnamemodify(s:files[i - 1], ":.")

      if isdirectory(bufname) || (bufname =~# g:f2_ignored_files)
        continue
      endif
    else
      if s:single_tab_mode && !exists('t:f2_list[' . i . ']')
        continue
      endif

      let bufname = fnamemodify(bufname(i), ":.")

      if g:f2_show_unnamed && !strlen(bufname)
        if !((g:f2_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
          let bufname = '[' . i . '*No Name]'
        endif
      endif
    endif

    if strlen(bufname) && ((getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')) || s:file_mode)
      let search_noise = <SID>find_lowest_search_noise(bufname)

      if search_noise == -1
        continue
      endif

      let raw_name = bufname

      " TODO add unicode modifier condition here
      if strlen(bufname) + 6 > width
        let bufname = '…' . strpart(bufname, strlen(bufname) - width + 7)
      endif

      if !s:file_mode
        let bufname = <SID>decorate_with_indicators(bufname, i)
      endif

      " count displayed buffers
      let displayedbufs += 1
      " fill the name with spaces --> gives a nice selection bar
      " use MAX width here, because the width may change inside of this 'for' loop
      while strlen(bufname) < width
        let bufname .= ' '
      endwhile
      " add the name to the list
      call add(buflist, { "text": '  ' . bufname . "\n", "number": i, "raw": raw_name, "search_noise": search_noise })
    endif
  endfor

  " set up window height
  if displayedbufs > g:f2_height
    if displayedbufs < g:f2_max_height
      silent! exe "resize " . displayedbufs
    else
      silent! exe "resize " . g:f2_max_height
    endif
  endif

  call <SID>display_list(displayedbufs, buflist, width)
  call <SID>set_status_line(width)

  if !empty(s:search_letters)
    call <SID>display_search_patterns()
  endif

  let activebufline = s:file_mode ? line("$") : <SID>find_activebufline(activebuf, buflist)

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:buflist = buflist
  let b:bufcount = displayedbufs

  if !s:file_mode
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

  if s:single_tab_mode && exists("t:f2_jumps")
    let bufferjumps = t:f2_jumps
  else
    let bufferjumps = s:f2_jumps
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
  let t:f2_search_history_index = -1

  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>add_search_letter(letter)
  call add(s:search_letters, a:letter)
  let s:new_search_performed = 1
  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>remove_search_letter()
  call remove(s:search_letters, -1)
  let s:new_search_performed = 1
  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>switch_search_mode(switch)
  if (a:switch == 0) && !empty(s:search_letters)
    call <SID>append_to_search_history()
  endif

  let s:search_mode = a:switch

  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>unique_list(list)
  return filter(copy(a:list), 'index(a:list, v:val, v:key + 1) == -1')
endfunction

function! <SID>decorate_with_indicators(name, bufnum)
  let indicators = ' '

  if s:preview_mode && (s:preview_mode_orginal_buffer == a:bufnum)
    let indicators .= g:f2_unicode_font ? "☆" : "*"
  elseif bufwinnr(a:bufnum) != -1
    let indicators .= g:f2_unicode_font ? "★" : "*"
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
  if exists("t:f2_start_window")
    silent! exe t:f2_start_window . "wincmd w"
  endif

  if exists("t:f2_winrestcmd") && (winrestcmd() != t:f2_winrestcmd)
    silent! exe t:f2_winrestcmd

    if winrestcmd() != t:f2_winrestcmd
      wincmd =
    endif
  endif
endfunction

function! <SID>kill(buflistnr, final)
  if exists("s:killing_now") && s:killing_now
    return
  endif

  let s:killing_now = 1

  if a:buflistnr
    silent! exe ':' . a:buflistnr . 'bwipeout'
  else
    bwipeout
  end

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

function! <SID>show_help()
  call <SID>kill(0, 1)
  silent! exe "help f2-keys"
endfunction

function! <SID>keypressed(key)
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
      elseif a:key ==# "C-p"
        call <SID>restore_search_letters("previous")
      elseif a:key ==# "C-n"
        call <SID>restore_search_letters("next")
      end
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
    elseif a:key ==# "?"
      call <SID>show_help()
    elseif a:key ==# "v"
      call <SID>load_file("vs")
    elseif a:key ==# "s"
      call <SID>load_file("sp")
    elseif a:key ==# "t"
      call <SID>load_file("tabnew")
    elseif a:key ==# "o" && empty(s:search_letters)
      call <SID>toggle_files_order()
    elseif a:key ==# "r"
      call <SID>refresh_files()
    elseif a:key ==# "q"
      call <SID>kill(0, 1)
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
    elseif a:key ==# "Home"
      call <SID>move(1)
    elseif a:key ==# "End"
      call <SID>move(line("$"))
    elseif a:key ==? "A"
      call <SID>toggle_file_mode()
    elseif a:key ==# "C-p"
      call <SID>restore_search_letters("previous")
    elseif a:key ==# "C-n"
      call <SID>restore_search_letters("next")
    endif
  else
    if a:key ==# "CR"
      call <SID>load_buffer()
    elseif a:key ==# "Space"
      call <SID>load_many_buffers()
    elseif (a:key ==# "C-Space") || (a:key ==# "Nul")
      call <SID>preview_buffer()
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
    elseif a:key ==# "?"
      call <SID>show_help()
    elseif a:key ==# "v"
      call <SID>load_buffer("vs")
    elseif a:key ==# "s"
      call <SID>load_buffer("sp")
    elseif a:key ==# "t"
      call <SID>load_buffer("tabnew")
    elseif a:key ==# "o" && empty(s:search_letters)
      call <SID>toggle_order()
    elseif a:key ==# "q"
      call <SID>kill(0, 1)
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
      call <SID>delete_hidden_noname_buffers()
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
    elseif a:key ==# "Home"
      call <SID>move(1)
    elseif a:key ==# "End"
      call <SID>move(line("$"))
    elseif a:key ==# "a"
      call <SID>toggle_single_tab_mode()
    elseif a:key ==# "f" && s:single_tab_mode
      call <SID>detach_buffer()
    elseif a:key ==# "F"
      call <SID>delete_foreign_buffers()
    elseif a:key ==# "c" && s:single_tab_mode
      call <SID>close_buffer()
    elseif a:key ==# "e"
      call <SID>edit_new_sibling()
    elseif a:key ==# "S"
      call <SID>kill(0, 1)
      call <SID>save_session()
    elseif a:key ==# "L"
      call <SID>kill(0, 1)
      call <SID>load_session(1)
    elseif a:key ==# "l"
      call <SID>kill(0, 1)
      call <SID>load_session(0)
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

function! <SID>toggle_file_mode()
  let s:file_mode = !s:file_mode
  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>set_status_line(width)
  if has('statusline')
    hi default link User1 LineNr
    let f2_name = g:f2_unicode_font ? "ϝ₂" : "F2"
    let &l:statusline = "%1* " . f2_name . "  %*  " . F2StatusLineInfoSegment()

    if g:f2_show_key_info && a:width >= g:f2_show_key_info
      let &l:statusline .= "  %=%1* " . F2StatusLineKeyInfoSegment() . " "
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

  let b:search_patterns = {}

  if &timeout
    let b:old_timeoutlen = &timeoutlen
    set timeoutlen=10
    au BufEnter <buffer> set timeoutlen=10
    au BufLeave <buffer> silent! exe "set timeoutlen=" . b:old_timeoutlen
  endif

  augroup F2Leave
    au!
    au BufLeave <buffer> call <SID>kill(0, 1)
  augroup END

  " set up syntax highlighting
  if has("syntax")
    syn clear
    syn match F2ItemNormal /  .*/
    syn match F2ItemSelected /> .*/hs=s+1

    hi def F2ItemNormal ctermfg=black ctermbg=white
    hi def F2ItemSelected ctermfg=white ctermbg=black
  endif

  call clearmatches()
  hi def F2ItemFound ctermfg=NONE ctermbg=NONE cterm=underline

  " set up the keymap
  let lowercase_letters = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
  let uppercase_letters = toupper(lowercase_letters)
  let numbers           = "1 2 3 4 5 6 7 8 9 0"
  let special_chars     = "Space CR BS / ? ; : , . < > [ ] { } ( ) ' ` ~ + - _  = ! @ # $ % ^ & * " .
        \ "MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse Down Up Home End Left Right BSlash Bar C-n C-p"

  let special_chars .= has("gui_running") ? " C-Space" : " Nul"

  let key_chars = split(lowercase_letters . " " . uppercase_letters . " " . numbers . " " . special_chars, " ")

  for key_char in key_chars
    if strlen(key_char) > 1
      let key = "<" . key_char . ">"
    else
      let key = key_char
    endif
    silent! exe "noremap <silent><buffer> " . key . " :call <SID>keypressed(\"" . key_char . "\")<CR>"
  endfor
endfunction

function! <SID>make_filler(width)
  " generate a variable to fill the buffer afterwards
  " (we need this for "full window" color :)
  let fill = "\n"
  let i = 0 | while i < a:width | let i += 1
    let fill = ' ' . fill
  endwhile

  return fill
endfunction

function! <SID>compare_bufentries(a, b)
  if t:sort_order == 1
    if s:single_tab_mode
      if exists("t:f2_list[" . a:a.number . "]") && exists("t:f2_list[" . a:b.number . "]")
        return t:f2_list[a:a.number] - t:f2_list[a:b.number]
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
  if s:file_sort_order == 1
    if strlen(a:a.raw) < strlen(a:b.raw)
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
  elseif s:file_sort_order == 2
    if a:a.raw < a:b.raw
      return -1
    elseif a:a.raw > a:b.raw
      return 1
    else
      return 0
    endif
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

function! <SID>display_list(displayedbufs, buflist, width)
  setlocal modifiable
  if a:displayedbufs > 0
    if !empty(s:search_letters)
      call sort(a:buflist, function(<SID>SID() . "compare_bufentries_with_search_noise"))
    elseif s:file_mode
      call sort(a:buflist, function(<SID>SID() . "compare_file_entries"))
    elseif exists("t:sort_order")
      call sort(a:buflist, function(<SID>SID() . "compare_bufentries"))
    endif

    " trim the list in search mode
    let buflist = s:search_mode && (len(a:buflist) > g:f2_max_height) ? a:buflist[-g:f2_max_height : -1] : a:buflist

    " input the buffer list, delete the trailing newline, & fill with blank lines
    let buftext = ""

    for bufentry in buflist
      let buftext .= bufentry.text
    endfor

    silent! put! =buftext
    " is there any way to NOT delete into a register? bummer...
    "normal! Gdd$
    normal! GkJ
    let fill = <SID>make_filler(a:width)
    while winheight(0) > line(".")
      silent! put =fill
    endwhile

    let s:nop_mode = 0
  else
    let empty_list_message = "  List empty"
    let width = a:width

    if width < (strlen(empty_list_message) + 2)
      " TODO Add a conditional for unicode modifier here
      let empty_list_message = strpart(empty_list_message, 0, width - 3) . "…"
    endif

    while strlen(empty_list_message) < width
      let empty_list_message .= ' '
    endwhile

    silent! put! =empty_list_message
    normal! GkJ

    let fill = <SID>make_filler(width)

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
      au! F2Leave BufLeave
      noremap <silent> <buffer> q :q<CR>
      if g:f2_set_default_mapping
        silent! exe 'noremap <silent><buffer>' . g:f2_default_mapping_key . ' :q<CR>'
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
    if g:f2_cyclic_list
      call <SID>goto(b:bufcount - a:line)
    else
      call cursor(1, 1)
    endif
  elseif a:line > b:bufcount
    if g:f2_cyclic_list
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

  call <SID>f2_toggle(1)
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
  let file = s:files[file_number - 1]
  let current_line = line(".")

  call <SID>kill(0, 0)
  call <SID>go_to_start_window()

  exec ":e " . file

  call <SID>f2_toggle(1)
  call <SID>move(current_line)
endfunction

function! <SID>load_file(...)
  let file_number = <SID>get_selected_buffer()
  let file = s:files[file_number - 1]

  call <SID>kill(0, 1)

  if !empty(a:000)
    exec ":" . a:1
  endif

  exec ":e " . file
endfunction

function! <SID>preview_buffer()
  if !s:preview_mode
    let s:preview_mode = 1
    let s:preview_mode_orginal_buffer = winbufnr(t:f2_start_window)
  endif

  let nr = <SID>get_selected_buffer()

  call <SID>kill(0, 0)

  call <SID>go_to_start_window()
  exec ":b " . nr
  exec "normal! zb"

  call <SID>f2_toggle(1)
endfunction

function! <SID>load_buffer_into_window(winnr)
  if exists("t:f2_start_window")
    let old_start_window = t:f2_start_window
    let t:f2_start_window = a:winnr
  endif
  call <SID>load_buffer()
  if exists("old_start_window")
    let t:f2_start_window = old_start_window
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
          call <SID>kill(0, 0)
        else
          call <SID>load_buffer_into_window(selected_buffer_window)
        endif
      else
        call <SID>load_buffer_into_window(selected_buffer_window)
      endif
    else
      call <SID>kill(0, 0)
    endif
    exec ":bdelete " . nr
    call <SID>forget_buffers_in_all_tabs([nr])
    call <SID>f2_toggle(1)
  endif
endfunction

function! <SID>forget_buffers_in_all_tabs(numbers)
  for t in range(1, tabpagenr("$"))
    let f2_list = gettabvar(t, "f2_list")

    for nr in a:numbers
      if exists("f2_list[" . nr . "]")
        call remove(f2_list, nr)
      endif
    endfor

    call settabvar(t, "f2_list", f2_list)
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

function! <SID>delete_hidden_noname_buffers()
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

  call <SID>kill(0, 0)

  let removed = <SID>keep_buffers_for_keys(keep)

  if !empty(removed)
    call <SID>forget_buffers_in_all_tabs(removed)
  endif

  call <SID>f2_toggle(1)
endfunction

" deletes all foreign buffers
function! <SID>delete_foreign_buffers()
  let buffers = {}
  for t in range(1, tabpagenr('$'))
    silent! call extend(buffers, gettabvar(t, 'f2_list'))
  endfor
  call <SID>kill(0, 0)
  call <SID>keep_buffers_for_keys(buffers)
  call <SID>f2_toggle(1)
endfunction

function! <SID>get_selected_buffer()
  let bufentry = b:buflist[line(".") - 1]
  return bufentry.number
endfunction

function! <SID>add_tab_buffer()
  if s:preview_mode
    return
  endif

  if !exists('t:f2_list')
    let t:f2_list = {}
  endif

  let current = bufnr('%')

  if !exists("t:f2_list[" . current . "]") &&
        \ getbufvar(current, '&modifiable') &&
        \ getbufvar(current, '&buflisted') &&
        \ current != bufnr("__F2__")
    let t:f2_list[current] = len(t:f2_list) + 1
  endif
endfunction

function! <SID>add_jump()
  if s:preview_mode
    return
  endif

  if !exists("t:f2_jumps")
    let t:f2_jumps = []
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__F2__")
    call add(s:f2_jumps, current)
    let s:f2_jumps = <SID>unique_list(s:f2_jumps)

    if len(s:f2_jumps) > g:f2_max_jumps + 1
      unlet s:f2_jumps[0]
    endif

    call add(t:f2_jumps, current)
    let t:f2_jumps = <SID>unique_list(t:f2_jumps)

    if len(t:f2_jumps) > g:f2_max_jumps + 1
      unlet t:f2_jumps[0]
    endif
  endif
endfunction

function! <SID>toggle_single_tab_mode()
  let s:single_tab_mode = !s:single_tab_mode

  if !empty(s:search_letters)
    let s:new_search_performed = 1
  endif

  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>toggle_order()
  if exists("t:sort_order")
    if t:sort_order == 1
      let t:sort_order = 2
    else
      let t:sort_order = 1
    endif

    call <SID>kill(0, 0)
    call <SID>f2_toggle(1)
  endif
endfunction

function! <SID>toggle_files_order()
  if s:file_sort_order == 1
    let s:file_sort_order = 2
  else
    let s:file_sort_order = 1
  endif

  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>refresh_files()
  let s:files = []
  call <SID>kill(0, 0)
  call <SID>f2_toggle(1)
endfunction

function! <SID>edit_new_sibling()
  let nr      = <SID>get_selected_buffer()
  let current = bufname(nr)
  let path    = fnamemodify(resolve(current), ":h")

  if !filereadable(current)
    return
  endif

  call inputsave()
  let new_file = input("F2: edit a sibling: " . path . '/')
  call inputrestore()
  redraw!

  if empty(new_file)
    return
  endif

  call <SID>kill(0, 0)
  call <SID>go_to_start_window()

  silent! exe "e " . path . "/" . new_file

  call <SID>f2_toggle(1)
endfunction!

" Detach a buffer if it belongs to other tabs or delete it otherwise.
" It means, this function doesn't leave buffers without tabs.
function! <SID>close_buffer()
  let nr         = <SID>get_selected_buffer()
  let found_tabs = 0

  for t in range(1, tabpagenr('$'))
    let f2_list = gettabvar(t, 'f2_list')
    if !empty(f2_list) && exists("f2_list[" . nr . "]")
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

  if exists('t:f2_list[' . nr . ']')
    let selected_buffer_window = bufwinnr(nr)
    if selected_buffer_window != -1
      call <SID>move("down")
      if <SID>get_selected_buffer() == nr
        call <SID>move("up")
        if <SID>get_selected_buffer() == nr
          return
        endif
      endif
      call <SID>load_buffer_into_window(selected_buffer_window)
    else
      call <SID>kill(0, 0)
    endif
    call remove(t:f2_list, nr)
    call <SID>f2_toggle(1)
  endif

  return nr
endfunction
