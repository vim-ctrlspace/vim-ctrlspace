let s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#api#BufferList(tabnr)
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

function! ctrlspace#api#Buffers(tabnr)
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

function! ctrlspace#api#StatuslineTabSegment()
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

function! ctrlspace#api#StatuslineModeSegment(...)
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

function! ctrlspace#api#TabBuffersNumber(tabnr)
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

function! ctrlspace#api#TabTitle(tabnr, bufnr, bufname)
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

function! ctrlspace#api#Guitablabel()
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

function! ctrlspace#api#Tabline()
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

function! ctrlspace#api#bufnr()
  return bufexists(s:plugin_buffer) ? s:plugin_buffer : -1
endfunction

function! ctrlspace#api#tab_modified(tabnr)
  for b in map(keys(ctrlspace#buffers(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction
