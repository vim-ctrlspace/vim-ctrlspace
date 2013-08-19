" Vim-Tabb - Tab buffers tool
" Maintainer:   Szymon Wrozynski
" Version:      3.0.7
"
" Installation:
" Place in ~/.vim/plugin/tabb.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-tabb.git
"
" License:
" Copyright (c) 2013 Szymon Wrozynski <szymon@wrozynski.com>
" Distributed under the same terms as Vim itself.
" Original BufferList plugin code - copyright (c) 2005 Robert Lillack <rob@lillack.de>
" Redistribution in any form with or without modification permitted.
" Licensed under MIT License conditions.
"
" Usage:
" https://github.com/szw/vim-tabb/blob/master/README.md

if exists('g:tabb_loaded')
  finish
endif

let g:tabb_loaded = 1

function! <SID>define_config_variable(name, default_value)
  if !exists("g:tabb_" . a:name)
    let g:{"tabb_" . a:name} = a:default_value
  endif
endfunction

call <SID>define_config_variable("height", 1)
call <SID>define_config_variable("max_height", 25)
call <SID>define_config_variable("show_unnamed", 2)
call <SID>define_config_variable("set_default_mapping", 1)
call <SID>define_config_variable("default_mapping_key", "<F2>")
call <SID>define_config_variable("default_label_mapping_key", "<F12>")
call <SID>define_config_variable("cyclic_list", 1)
call <SID>define_config_variable("max_jumps", 100)
call <SID>define_config_variable("default_sort_order", 2) " 0 - no sort, 1 - chronological, 2 - alphanumeric
call <SID>define_config_variable("enable_tabline", 1)

command! -nargs=0 -range Tabb :call <SID>tabb_toggle(0)
command! -nargs=0 -range TabbLabel :call <SID>new_tab_label()

if g:tabb_enable_tabline
  set tabline=%!TabbTabLine()
endif

if g:tabb_set_default_mapping
  if !empty(g:tabb_default_mapping_key)
    silent! exe 'nnoremap <silent>' . g:tabb_default_mapping_key . ' :Tabb<CR>'
    silent! exe 'vnoremap <silent>' . g:tabb_default_mapping_key . ' :Tabb<CR>'
    silent! exe 'inoremap <silent>' . g:tabb_default_mapping_key . ' <C-[>:Tabb<CR>'
  endif

  if !empty(g:tabb_default_label_mapping_key)
    silent! exe 'nnoremap <silent>' . g:tabb_default_label_mapping_key . ' :TabbLabel<CR>'
    silent! exe 'vnoremap <silent>' . g:tabb_default_label_mapping_key . ' :TabbLabel<CR>gv'
    silent! exe 'inoremap <silent>' . g:tabb_default_label_mapping_key . ' <C-o>:TabbLabel<CR>'
  endif
endif

let s:preview_mode = 0

au BufEnter * call <SID>add_tab_buffer()

let s:tabb_jumps = []
au BufEnter * call <SID>add_jump()

function! TabbList(tabnr)
  let buffer_list = {}
  let tabb = gettabvar(a:tabnr, "tabb_list")
  let visible_buffers = tabpagebuflist(a:tabnr)

  if type(tabb) != 4
    return buffer_list
  endif

  for i in keys(tabb)
    let i = str2nr(i)

    let bufname = bufname(i)

    if g:tabb_show_unnamed && !strlen(bufname)
      if !((g:tabb_show_unnamed == 2) && !getbufvar(i, '&modified')) || (index(visible_buffers, i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      let buffer_list[i] = bufname
    endif
  endfor

  return buffer_list
endfunction

function! TabbTabLine()
  let last_tab = tabpagenr("$")
  let tabline = ''

  for t in range(1, last_tab)
    let winnr = tabpagewinnr(t)
    let buflist = tabpagebuflist(t)
    let bufnr = buflist[winnr - 1]
    let bufname = bufname(bufnr)
    let bufs_number = len(TabbList(t))
    let bufs_number_to_show = ""

    if bufs_number > 1
      let small_numbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
      let number_str = string(bufs_number)

      for i in range(0, len(number_str) - 1)
        let bufs_number_to_show .= small_numbers[str2nr(number_str[i])]
      endfor
    endif

    let label = gettabvar(t, "tabb_label")

    if empty(label)
      if empty(bufname)
        let label = '[' . bufnr . '*No Name]'
      elseif bufname ==# "__TABB__"
        let label = "Select a buffer..."
      else
        let label = fnamemodify(bufname, ':t')
      endif
    endif

    let tabline .= '%' . t . 'T'
    let tabline .= (t == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
    let tabline .= ' ' . t . bufs_number_to_show . ' '

    if <SID>tab_contains_modified_buffers(t)
      let tabline .= '+ '
    endif

    let tabline .= label . ' '
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
  let t:tabb_label = input('Label for tab ' . tabpagenr() . ': ')
  call inputrestore()
  redraw!
endfunction

function! <SID>tab_contains_modified_buffers(tabnr)
  for b in map(keys(TabbList(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction

" toggled the buffer list on/off
function! <SID>tabb_toggle(internal)
  if !a:internal
    let s:tab_toggle = 1
    let s:nopmode = 0
    let s:search_letters = []
    let s:searchmode = 0
    if !exists("t:sort_order")
      let t:sort_order = g:tabb_default_sort_order
    endif
  endif

  " if we get called and the list is open --> close it
  let buflistnr = bufnr("__TABB__")
  if bufexists(buflistnr)
    if bufwinnr(buflistnr) != -1
      call <SID>kill(buflistnr, 1)
      return
    else
      call <SID>kill(buflistnr, 0)
      if !a:internal
        let t:tabb_start_window = winnr()
        let t:tabb_winrestcmd = winrestcmd()
      endif
    endif
  elseif !a:internal
    let t:tabb_start_window = winnr()
    let t:tabb_winrestcmd = winrestcmd()
  endif

  let bufcount = bufnr('$')
  let displayedbufs = 0
  let activebuf = bufnr('')
  let buflist = []

  " create the buffer first & set it up
  exec 'silent! new __TABB__'
  silent! exe "wincmd J"
  silent! exe "resize" g:tabb_height
  call <SID>set_up_buffer()

  let width = winwidth(0)

  " iterate through the buffers

  for i in range(1, bufcount)
    if s:tab_toggle && !exists('t:tabb_list[' . i . ']')
      continue
    endif

    let bufname = fnamemodify(bufname(i), ":.")

    if g:tabb_show_unnamed && !strlen(bufname)
      if !((g:tabb_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      " adapt width and/or buffer name
      if strlen(bufname) + 6 > width
        let bufname = '…' . strpart(bufname, strlen(bufname) - width + 7)
      endif

      if !empty(s:search_letters) && !(bufname =~? "\\m" . join(s:search_letters, ".\\{-}"))
        continue
      endif

      let bufname = <SID>decorate_with_indicators(bufname, i)

      " count displayed buffers
      let displayedbufs += 1
      " fill the name with spaces --> gives a nice selection bar
      " use MAX width here, because the width may change inside of this 'for' loop
      while strlen(bufname) < width
        let bufname .= ' '
      endwhile
      " add the name to the list
      call add(buflist, { "text": '  ' . bufname . "\n", "number": i })
    endif
  endfor

  " set up window height
  if displayedbufs > g:tabb_height
    if displayedbufs < g:tabb_max_height
      silent! exe "resize " . displayedbufs
    else
      silent! exe "resize " . g:tabb_max_height
    endif
  endif

  call <SID>display_list(displayedbufs, buflist, width)

  let activebufline = <SID>find_activebufline(activebuf, buflist)

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:buflist = buflist
  let b:bufcount = displayedbufs
  let b:jumplines = <SID>create_jumplines(buflist, activebufline)

  " go to the correct line
  call <SID>move(activebufline)
  normal! zb
endfunction

function! <SID>create_jumplines(buflist, activebufline)
  let buffers = []
  for bufentry in a:buflist
    call add(buffers, bufentry.number)
  endfor

  if s:tab_toggle && exists("t:tabb_jumps")
    let bufferjumps = t:tabb_jumps
  else
    let bufferjumps = s:tabb_jumps
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

function! <SID>clear_searchmode()
  let s:search_letters = []
  let s:searchmode = 0
  call <SID>kill(0, 0)
  call <SID>tabb_toggle(1)
endfunction

function! <SID>add_search_letter(letter)
  call add(s:search_letters, a:letter)
  call <SID>kill(0, 0)
  call <SID>tabb_toggle(1)
endfunction

function! <SID>remove_search_letter()
  call remove(s:search_letters, -1)
  call <SID>kill(0, 0)
  call <SID>tabb_toggle(1)
endfunction

function! <SID>switch_searchmode(switch)
  let s:searchmode = a:switch
  call <SID>kill(0, 0)
  call <SID>tabb_toggle(1)
endfunction

function! <SID>unique_list(list)
  return filter(copy(a:list), 'index(a:list, v:val, v:key + 1) == -1')
endfunction

function! <SID>decorate_with_indicators(name, bufnum)
  let indicators = ' '

  if s:preview_mode && (s:preview_mode_orginal_buffer == a:bufnum)
    let indicators .= "☆"
  elseif bufwinnr(a:bufnum) != -1
    let indicators .= "★"
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
  if exists("t:tabb_start_window")
    silent! exe t:tabb_start_window . "wincmd w"
  endif

  if exists("t:tabb_winrestcmd") && (winrestcmd() != t:tabb_winrestcmd)
    silent! exe t:tabb_winrestcmd

    if winrestcmd() != t:tabb_winrestcmd
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
  call <SID>kill(0, 0)
  silent! exe "help tabb-keys"
  call <SID>tabb_toggle(1)
endfunction

function! <SID>keypressed(key)
  if s:nopmode
    if (a:key ==# "a") && !s:searchmode
      call <SID>toggle_tab()
    end

    if a:key ==# "BS"
      if s:searchmode
        if empty(s:search_letters)
          call <SID>clear_searchmode()
        else
          call <SID>remove_search_letter()
        endif
      elseif !empty(s:search_letters)
        call <SID>clear_searchmode()
      endif
    endif
    return
  endif

  if s:searchmode
    if a:key ==# "BS"
      if empty(s:search_letters)
        call <SID>clear_searchmode()
      else
        call <SID>remove_search_letter()
      endif
    elseif (a:key ==# "/") || (a:key ==# "CR")
      call <SID>switch_searchmode(0)
    elseif strlen(a:key) == 1
      call <SID>add_search_letter(a:key)
    endif
  else
    if a:key ==# "CR"
      call <SID>load_buffer()
    elseif a:key ==# "Space"
      call <SID>preview_buffer()
    elseif a:key ==# "BS"
      call <SID>clear_searchmode()
    elseif a:key ==# "/"
      call <SID>switch_searchmode(1)
    elseif a:key ==# "?"
      call <SID>show_help()
    elseif a:key ==# "v"
      call <SID>load_buffer("vs")
    elseif a:key ==# "s"
      call <SID>load_buffer("sp")
    elseif a:key ==# "t"
      call <SID>load_buffer("tabnew")
    elseif a:key ==# "o"
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
      call <SID>delete_hidden_buffers()
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
      call <SID>toggle_tab()
    elseif a:key ==# "f"
      call <SID>detach_tabb_buffer()
    elseif a:key ==# "F"
      call <SID>delete_foreign_buffers()
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

  if has('statusline')
    if s:tab_toggle
      let &l:statusline = "[⊙]"
    else
      let &l:statusline = "[∷]"
    endif

    if exists("t:sort_order")
      if t:sort_order == 1
        let &l:statusline .= "  [₁²₃]"
      elseif t:sort_order == 2
        let &l:statusline .= "  [∧вс]"
      endif
    endif

    if s:preview_mode
      let &l:statusline .= "  [⌕]"
    endif

    if s:searchmode || !empty(s:search_letters)
      let &l:statusline .=  "  →[" . join(s:search_letters, "")

      if s:searchmode
        let &l:statusline .= "_"
      endif

      let &l:statusline .= "]←"
    endif
  endif

  if &timeout
    let b:old_timeoutlen = &timeoutlen
    set timeoutlen=10
    au BufEnter <buffer> set timeoutlen=10
    au BufLeave <buffer> silent! exe "set timeoutlen=" . b:old_timeoutlen
  endif

  augroup TabbLeave
    au!
    au BufLeave <buffer> call <SID>kill(0, 1)
  augroup END

  " set up syntax highlighting
  if has("syntax")
    syn clear
    syn match TabbBufferNormal /  .*/
    syn match TabbBufferSelected /> .*/hs=s+1
    hi def TabbBufferNormal ctermfg=black ctermbg=white
    hi def TabbBufferSelected ctermfg=white ctermbg=black
  endif

  " set up the keymap
  let lowercase_letters = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
  let uppercase_letters = toupper(lowercase_letters)
  let numbers = "1 2 3 4 5 6 7 8 9 0"
  let special_chars = "Space CR BS / ? MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse Down Up Home End Left Right"
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
    if s:tab_toggle
      if exists("t:tabb_list[" . a:a.number . "]") && exists("t:tabb_list[" . a:b.number . "]")
        return t:tabb_list[a:a.number] - t:tabb_list[a:b.number]
      endif
    endif
    return a:a.number - a:b.number
  elseif t:sort_order == 2
    if (a:a.text < a:b.text)
      return -1
    elseif (a:a.text > a:b.text)
      return 1
    else
      return 0
    endif
  endif
endfunction

function! <SID>SID()
  let fullname = expand("<sfile>")
  return matchstr(fullname, '<SNR>\d\+_')
endfunction

function! <SID>display_list(displayedbufs, buflist, width)
  setlocal modifiable
  if a:displayedbufs > 0
    if exists("t:sort_order")
      call sort(a:buflist, function(<SID>SID() . "compare_bufentries"))
    endif
    " input the buffer list, delete the trailing newline, & fill with blank lines
    let buftext = ""

    for bufentry in a:buflist
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

    let s:nopmode = 0
  else
    let empty_list_message = "  List empty"
    let width = a:width

    if width < (strlen(empty_list_message) + 2)
      if strlen(empty_list_message) + 2 < g:tabb_max_width
        let width = strlen(empty_list_message) + 2
      else
        let width = g:tabb_max_width
        let empty_list_message = strpart(empty_list_message, 0, width - 3) . "…"
      endif
      silent! exe "vert resize " . width
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
      au! TabbLeave BufLeave
      noremap <silent> <buffer> q :q<CR>
      noremap <silent> <buffer> a <Nop>
      if g:tabb_set_default_mapping
        silent! exe 'noremap <silent><buffer>' . g:tabb_default_mapping_key . ' :q<CR>'
      endif
    endif

    let s:nopmode = 1
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
    if g:tabb_cyclic_list
      call <SID>goto(b:bufcount - a:line)
    else
      call cursor(1, 1)
    endif
  elseif a:line > b:bufcount
    if g:tabb_cyclic_list
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

" loads the selected buffer
function! <SID>load_buffer(...)
  " get the selected buffer
  let nr = <SID>get_selected_buffer()
  " kill the buffer list
  call <SID>kill(0, 1)

  if !empty(a:000)
    exec ":" . a:1
  endif

  " ...and switch to the buffer number
  exec ":b " . nr
endfunction

function! <SID>preview_buffer()
  if !s:preview_mode
    let s:preview_mode = 1
    let s:preview_mode_orginal_buffer = winbufnr(t:tabb_start_window)
  endif

  let nr = <SID>get_selected_buffer()

  call <SID>kill(0, 0)

  call <SID>go_to_start_window()
  exec ":b " . nr
  exec "normal! zb"

  call <SID>tabb_toggle(1)
endfunction

function! <SID>load_buffer_into_window(winnr)
  if exists("t:tabb_start_window")
    let old_start_window = t:tabb_start_window
    let t:tabb_start_window = a:winnr
  endif
  call <SID>load_buffer()
  if exists("old_start_window")
    let t:tabb_start_window = old_start_window
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
    call <SID>tabb_toggle(1)
  endif
endfunction

function! <SID>forget_buffers_in_all_tabs(numbers)
  for t in range(1, tabpagenr("$"))
    let tabb_list = gettabvar(t, "tabb_list")

    for nr in a:numbers
      if exists("tabb_list[" . nr . "]")
        call remove(tabb_list, nr)
      endif
    endfor

    call settabvar(t, "tabb_list", tabb_list)
  endfor
endfunction

function! <SID>keep_buffers_for_keys(dict)
  let removed = []

  for b in range(1, bufnr('$'))
    if buflisted(b) && !has_key(a:dict, b) && !getbufvar(b, '&modified')
      exe ':bdelete ' . b
      call add(removed, b)
    endif
  endfor

  return removed
endfunction

" deletes all hidden buffers
" taken from: http://stackoverflow.com/a/3180886
function! <SID>delete_hidden_buffers()
  let visible = {}
  for t in range(1, tabpagenr('$'))
    for b in tabpagebuflist(t)
      let visible[b] = 1
    endfor
  endfor

  call <SID>kill(0, 0)

  let removed = <SID>keep_buffers_for_keys(visible)

  if !empty(removed)
    call <SID>forget_buffers_in_all_tabs(removed)
  endif

  call <SID>tabb_toggle(1)
endfunction

" deletes all foreign buffers
function! <SID>delete_foreign_buffers()
  let buffers = {}
  for t in range(1, tabpagenr('$'))
    silent! call extend(buffers, gettabvar(t, 'tabb_list'))
  endfor
  call <SID>kill(0, 0)
  call <SID>keep_buffers_for_keys(buffers)
  call <SID>tabb_toggle(1)
endfunction

function! <SID>get_selected_buffer()
  let bufentry = b:buflist[line(".") - 1]
  return bufentry.number
endfunction

function! <SID>add_tab_buffer()
  if s:preview_mode
    return
  endif

  if !exists('t:tabb_list')
    let t:tabb_list = {}
  endif

  let current = bufnr('%')

  if !exists("t:tabb_list[" . current . "]") && getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__TABB__")
    let t:tabb_list[current] = len(t:tabb_list) + 1
  endif
endfunction

function! <SID>add_jump()
  if s:preview_mode
    return
  endif

  if !exists("t:tabb_jumps")
    let t:tabb_jumps = []
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__TABB__")
    call add(s:tabb_jumps, current)
    let s:tabb_jumps = <SID>unique_list(s:tabb_jumps)

    if len(s:tabb_jumps) > g:tabb_max_jumps + 1
      unlet s:tabb_jumps[0]
    endif

    call add(t:tabb_jumps, current)
    let t:tabb_jumps = <SID>unique_list(t:tabb_jumps)

    if len(t:tabb_jumps) > g:tabb_max_jumps + 1
      unlet t:tabb_jumps[0]
    endif
  endif
endfunction

function! <SID>toggle_tab()
  let s:tab_toggle = !s:tab_toggle
  call <SID>kill(0, 0)
  call <SID>tabb_toggle(1)
endfunction

function! <SID>toggle_order()
  if exists("t:sort_order")
    if t:sort_order == 1
      let t:sort_order = 2
    else
      let t:sort_order = 1
    endif

    call <SID>kill(0, 0)
    call <SID>tabb_toggle(1)
  endif
endfunction

function! <SID>detach_tabb_buffer()
  let nr = <SID>get_selected_buffer()
  if exists('t:tabb_list[' . nr . ']')
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
    call remove(t:tabb_list, nr)
    call <SID>tabb_toggle(1)
  endif
endfunction
