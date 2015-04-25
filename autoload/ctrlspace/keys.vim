s:config = g:ctrlspace#context#Configuration.Instance()

function! g:ctrlspace#keys#Keypressed(key)
  let termSTab = g:ctrlspace#context#KeyEscSequence && (a:key ==# "Z")
  let g:ctrlspace#context#KeyEscSequence = 0

  if s:handleHelpKey(a:key)
    return 1
  elseif s:handleNopKey(a:key)
    return 1
  elseif s:handleSearchKey(a:key)
    return 1
  elseif s:handleCommonKeys(a:key)
    return 1
  else
    return 0
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

function! s:handleHelpKey(key)
  if !g:ctrlspace#modes#Help.Enabled
    return 0
  endif

  return 1
endfunction

function! s:handleNopKey(key)
  if !g:ctrlspace#modes#Nop.Enabled
    return 0
  endif

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

  return 1
endfunction

function! s:handleSearchKey(key)
  if !g:ctrlspace#modes#Search.Enabled
    return 0
  endif

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

  return 1
endfunction

function! s:handleCommonKeys(key)
  if g:ctrlspace#modes#Workspace.Enabled
    let g:ctrlspace#modes#Workspace.Data.LastBrowsed = line(".")
  endif

  if (a:key ==# "q") || (a:key ==# "Esc") || (a:key ==# "C-c")
    call g:ctrlspace#window#Kill(0, 1)
  elseif a:key ==# "Q"
    call g:ctrlspace#window#QuitVim()
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
  else
    return 0
  endif

  return 1
endfunction
