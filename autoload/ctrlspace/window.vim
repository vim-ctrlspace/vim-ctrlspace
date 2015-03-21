s:config = ctrlspace#context#Configuration.Instance()

function! s:resetWindow()
  call ctrlspace#modes#Help.Disable()
  call ctrlspace#modes#Buffer.Enable()
  call ctrlspace#modes#Nop.Disable()
  call ctrlspace#modes#Search.Disable()
  call ctrlspace#modes#NextTab.Disable()

  let ctrlspace#modes#Buffer.Data.SubMode            = "single"
  let ctrlspace#modes#Search.Data.NewSearchPerformed = 0
  let ctrlspace#modes#Search.Data.Restored           = 0
  let ctrlspace#modes#Search.Data.Letters            = []
  let ctrlspace#modes#Search.Data.HistoryIndex       = -1
  let ctrlspace#modes#Workspace.Data.LastBrowsed     = 0

  let t:CtrlSpaceSearchHistoryIndex = -1

  let ctrlspace#context#ProjectRoot       = ctrlspace#roots#FindProjectRoot()
  let ctrlspace#mode#Bookmark.Data.Active = ctrlspace#bookmarks#FindActiveBookmark()

  unlet! ctrlspace#modes#Search.Data.LastSearchedDirectory

  if ctrlspace#context#LastProjectRoot != ctrlspace#context#ProjectRoot
    let ctrlspace#context#Files           = []
    let ctrlspace#context#LastProjectRoot = ctrlspace#context#ProjectRoot

    call ctrlspace#workspaces#SetWorkspaceNames()
  endif

  if empty(ctrlspace#context#SymbolSizes)
    let ctrlspace#context#SymbolSizes.IAV  = max([strwidth(s:config.Symbols.IV), strwidth(s:config.Symbols.IA)])
    let ctrlspace#context#SymbolSizes.IM   = strwidth(s:config.Symbols.IM)
    let ctrlspace#context#SymbolSizes.Dots = strwidth(s:config.Symbols.Dots)
  endif

  call ctrlspace#util#HandleVimSettings("start")
endfunction

function! ctrlspace#window#Toggle(internal)
  if !a:internal
    call s:resetWindow()
  endif

  " if we get called and the list is open --> close it
  if bufexists(ctrlspace#context#PluginBuffer)
    if bufwinnr(ctrlspace#context#PluginBuffer) != -1
      call <SID>kill(ctrlspace#context#PluginBuffer, 1)
      return
    else
      call <SID>kill(ctrlspace#context#PluginBuffer, 0)
      if !a:internal
        let t:CtrlSpaceStartWindow = winnr()
        let t:CtrlSpaceWinrestcmd  = winrestcmd()
        let t:CtrlSpaceActivebuf   = bufnr("")
      endif
    endif
  elseif !a:internal
    " make sure zoom window is closed
    silent! exe "pclose"
    let t:CtrlSpaceStartWindow = winnr()
    let t:CtrlSpaceWinrestcmd  = winrestcmd()
    let t:CtrlSpaceActivebuf   = bufnr("")
  endif

  if ctrlspace#modes#Zoom.Enabled
    let t:CtrlSpaceActivebuf = bufnr("")
  endif

  " let bufcount      = bufnr("$")
  " let displayedbufs = 0
  " let buflist       = []

  " let max_results   = g:ctrlspace_max_search_results

  " if max_results == -1
  "   let max_results = <SID>max_height()
  " endif

  " create the buffer first & set it up
  silent! exe "noautocmd botright pedit CtrlSpace"
  silent! exe "noautocmd wincmd P"
  silent! exe "resize" s:config.CtrlSpaceHeight

  " zoom start window in Zoom Mode
  if ctrlspace#modes#Zoom.Enabled
    silent! exe t:CtrlSpaceStartWindow . "wincmd w"
    vert resize | resize
    silent! exe "noautocmd wincmd P"
  endif

  call s:setUpBuffer()
  call ctrlspace

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

function! s:setUpBuffer()
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

  let ctrlspace#context#PluginBuffer = bufnr("%")

  if !empty(ctrlspace#context#ProjectRoot)
    silent! exe "lcd " . ctrlspace#context#ProjectRoot
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

function! ctrlspace#window#Kill(plugin_buffer, final)
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
