let s:config = g:ctrlspace#context#Configuration.Instance()

function! ctrlspace#window#Toggle(internal)
  if !a:internal
    call s:resetWindow()
  endif

  " if we get called and the list is open --> close it
  if bufexists(g:ctrlspace#context#PluginBuffer)
    if bufwinnr(g:ctrlspace#context#PluginBuffer) != -1
      call ctrlspace#window#Kill(g:ctrlspace#context#PluginBuffer, 1)
      return
    else
      call ctrlspace#window#Kill(g:ctrlspace#context#PluginBuffer, 0)
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

  if g:ctrlspace#modes#Zoom.Enabled
    let t:CtrlSpaceActivebuf = bufnr("")
  endif

  " create the buffer first & set it up
  silent! exe "noautocmd botright pedit CtrlSpace"
  silent! exe "noautocmd wincmd P"
  silent! exe "resize" s:config.Height

  " zoom start window in Zoom Mode
  if g:ctrlspace#modes#Zoom.Enabled
    silent! exe t:CtrlSpaceStartWindow . "wincmd w"
    vert resize | resize
    silent! exe "noautocmd wincmd P"
  endif

  call s:setUpBuffer()

  if g:ctrlspace#modes#Help.Enabled
    call ctrlspace#help#DisplayHelp()
    call ctrlspace#util#SetStatusline()
    return
  endif

  let [b:patterns, b:indices, b:size, b:text] = ctrlspace#engine#Content()

  " set up window height
  if b:size > s:config.Height
    let maxHeight = ctrlspace#context#MaxHeight()

    if b:size < maxHeight
      silent! exe "resize " . b:size
    else
      silent! exe "resize " . maxHeight
    endif
  endif

  silent! exe "set updatetime=100"

  call s:displayContent()
  call ctrlspace#util#SetStatusline()

  " display search patterns
  for pattern in b:patterns
    " escape ~ sign because of E874: (NFA) Could not pop the stack !
    call matchadd("CtrlSpaceSearch", "\\c" .substitute(pattern, '\~', '\\~', "g"))
  endfor

  call s:setActiveLine()

  normal! zb
endfunction

function! ctrlspace#window#GoToStartWindow()
  silent! exe t:CtrlSpaceStartWindow . "wincmd w"

  if winrestcmd() != t:CtrlSpaceWinrestcmd
    silent! exe t:CtrlSpaceWinrestcmd

    if winrestcmd() != t:CtrlSpaceWinrestcmd
      wincmd =
    endif
  endif
endfunction

function! ctrlspace#window#Kill(pluginBuffer, final)
  " added workaround for strange Vim behavior when, when kill starts with some delay
  " (in a wrong buffer). This happens in some Nop modes (in a File List view).
  if (exists("s:killingNow") && s:killingNow) || (!a:pluginBuffer && &ft != "ctrlspace")
    return
  endif

  let s:killingNow = 1

  if exists("b:updatetimeSave")
    silent! exe "set updatetime=" . b:updatetimeSave
  endif

  if exists("b:timeoutlenSave")
    silent! exe "set timeoutlen=" . b:timeoutlenSave
  endif

  if exists("b:mouseSave")
    silent! exe "set mouse=" . b:mouseSave
  endif

  " shellslash support for win32
  if exists("b:nosslSave") && b:nosslSave
    set nossl
  endif

  if a:pluginBuffer
    silent! exe ':' . a:pluginBuffer . 'bwipeout'
  else
    bwipeout
  endif

  if a:final
    call ctrlspace#util#HandleVimSettings("stop")

    if g:ctrlspace#modes#Search.Data.Restored
      call ctrlspace#search#AppendToSearchHistory()
    endif

    call ctrlspace#window#GoToStartWindow()

    if g:ctrlspace#modes#Zoom.Enabled
      exec ":b " . g:ctrlspace#modes#Zoom.Data.OriginalBuffer
      let g:ctrlspace#modes#Zoom.Data.OriginalBuffer = 0
      call g:ctrlspace#modes#Zoom.Disable()
    endif
  endif

  unlet s:killingNow
endfunction

function! ctrlspace#window#QuitVim()
  if !s:config.SaveWorkspaceOnExit && !empty(g:ctrlspace#modes#Workspace.Data.Active.Name) &&
        \ (g:ctrlspace#modes#Workspace.Data.Active.Digest !=# ctrlspace#workspaces#CreateDigest()) &&
        \ !ctrlspace#ui#Confirmed("Current workspace ('" . g:ctrlspace#modes#Workspace.Data.Active.Name . "') not saved. Proceed anyway?")
    return
  endif

  if !ctrlspace#ui#ProceedIfModified()
    return
  endif

  call ctrlspace#window#Kill(0, 1)
  qa!
endfunction

function! ctrlspace#window#MoveSelectionBar(where)
  if b:size < 1
    return
  endif

  let newpos = 0

  if !exists("b:lastline")
    let b:lastline = 0
  endif

  setlocal modifiable

  " the mouse was pressed: remember which line
  " and go back to the original location for now
  if a:where == "mouse"
    let newpos = line(".")
    call s:goto(b:lastline)
  endif

  " exchange the first char (>) with a space
  call setline(line("."), " " . strpart(getline(line(".")), 1))

  " go where the user want's us to go
  if a:where == "up"
    call s:goto(line(".") - 1)
  elseif a:where == "down"
    call s:goto(line(".") + 1)
  elseif a:where == "mouse"
    call s:goto(newpos)
  elseif a:where == "pgup"
    let newpos = line(".") - winheight(0)
    if newpos < 1
      let newpos = 1
    endif
    call s:goto(newpos)
  elseif a:where == "pgdown"
    let newpos = line(".") + winheight(0)
    if newpos > line("$")
      let newpos = line("$")
    endif
    call s:goto(newpos)
  elseif a:where == "half_pgup"
    let newpos = line(".") - winheight(0) / 2
    if newpos < 1
      let newpos = 1
    endif
    call s:goto(newpos)
  elseif a:where == "half_pgdown"
    let newpos = line(".") + winheight(0) / 2
    if newpos > line("$")
      let newpos = line("$")
    endif
    call s:goto(newpos)
  else
    call s:goto(a:where)
  endif

  " and mark this line with a >
  call setline(line("."), ">" . strpart(getline(line(".")), 1))

  " remember this line, in case the mouse is clicked
  " (which automatically moves the cursor there)
  let b:lastline = line(".")

  setlocal nomodifiable
endfunction

function! ctrlspace#window#MoveCursor(where)
  if a:where == "up"
    call s:goto(line(".") - 1)
  elseif a:where == "down"
    call s:goto(line(".") + 1)
  elseif a:where == "mouse"
    call s:goto(line("."))
  elseif a:where == "pgup"
    let newpos = line(".") - winheight(0)
    if newpos < 1
      let newpos = 1
    endif
    call s:goto(newpos)
  elseif a:where == "pgdown"
    let newpos = line(".") + winheight(0)
    if newpos > line("$")
      let newpos = line("$")
    endif
    call s:goto(newpos)
  elseif a:where == "half_pgup"
    let newpos = line(".") - winheight(0) / 2
    if newpos < 1
      let newpos = 1
    endif
    call s:goto(newpos)
  elseif a:where == "half_pgdown"
    let newpos = line(".") + winheight(0) / 2
    if newpos > line("$")
      let newpos = line("$")
    endif
    call s:goto(newpos)
  else
    call s:goto(a:where)
  endif
endfunction

function! ctrlspace#window#SelectedIndex()
  return b:indices[line(".") - 1]
endfunction

function! ctrlspace#window#GoToWindow()
  let nr = ctrlspace#window#SelectedIndex()

  if bufwinnr(nr) != -1
    call ctrlspace#window#Kill(0, 1)
    silent! exe bufwinnr(nr) . "wincmd w"
    return 1
  endif

  return 0
endfunction

" tries to set the cursor to a line of the buffer list
function! s:goto(line)
  if b:size < 1
    return
  endif

  if a:line < 1
    call s:goto(b:size - a:line)
  elseif a:line > b:size
    call s:goto(a:line - b:size)
  else
    call cursor(a:line, 1)
  endif
endfunction

function! s:resetWindow()
  call g:ctrlspace#modes#Help.Disable()
  call g:ctrlspace#modes#Buffer.Enable()
  call g:ctrlspace#modes#Nop.Disable()
  call g:ctrlspace#modes#Search.Disable()
  call g:ctrlspace#modes#NextTab.Disable()

  let g:ctrlspace#modes#Buffer.Data.SubMode            = "single"
  let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 0
  let g:ctrlspace#modes#Search.Data.Restored           = 0
  let g:ctrlspace#modes#Search.Data.Letters            = []
  let g:ctrlspace#modes#Search.Data.HistoryIndex       = -1
  let g:ctrlspace#modes#Workspace.Data.LastBrowsed     = 0

  let t:CtrlSpaceSearchHistoryIndex = -1

  let g:ctrlspace#context#ProjectRoot       = ctrlspace#roots#FindProjectRoot()
  let g:ctrlspace#modes#Bookmark.Data.Active = ctrlspace#bookmarks#FindActiveBookmark()

  if exists("g:ctrlspace#modes#Search.Data.LastSearchedDirectory")
    unlet! g:ctrlspace#modes#Search.Data.LastSearchedDirectory
  endif

  if g:ctrlspace#context#LastProjectRoot != g:ctrlspace#context#ProjectRoot
    let g:ctrlspace#context#Files           = []
    let g:ctrlspace#context#LastProjectRoot = g:ctrlspace#context#ProjectRoot

    call ctrlspace#workspaces#SetWorkspaceNames()
  endif

  if empty(g:ctrlspace#context#SymbolSizes)
    let g:ctrlspace#context#SymbolSizes.IAV  = max([strwidth(s:config.Symbols.IV), strwidth(s:config.Symbols.IA)])
    let g:ctrlspace#context#SymbolSizes.IM   = strwidth(s:config.Symbols.IM)
    let g:ctrlspace#context#SymbolSizes.Dots = strwidth(s:config.Symbols.Dots)
  endif

  call ctrlspace#util#HandleVimSettings("start")
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

  let g:ctrlspace#context#PluginBuffer = bufnr("%")

  if !empty(g:ctrlspace#context#ProjectRoot)
    silent! exe "lcd " . g:ctrlspace#context#ProjectRoot
  endif

  if &timeout
    let b:timeoutlenSave = &timeoutlen
    set timeoutlen=10
  endif

  let b:updatetimeSave = &updatetime

  " shellslash support for win32
  if has("win32") && !&ssl
    let b:nosslSave = 1
    set ssl
  endif

  augroup CtrlSpaceUpdateSearch
    au!
    au CursorHold <buffer> call ctrlspace#util#UpdateSearchResults()
  augroup END

  augroup CtrlSpaceLeave
    au!
    au BufLeave <buffer> call ctrlspace#window#Kill(0, 1)
  augroup END

  " set up syntax highlighting
  if has("syntax")
    syn clear
    syn match CtrlSpaceNormal /  .*/
    syn match CtrlSpaceSelected /> .*/hs=s+1
  endif

  call clearmatches()

  if !s:config.UseMouseAndArrowsInTerm && !has("gui_running")
    " Block unnecessary escape sequences!
    noremap <silent><buffer><esc>[ :call s:markKeyEscSequence()<CR>
    let b:mouseSave = &mouse
    set mouse=
  endif

  for keyName in g:ctrlspace#context#KeyNames
    let key = strlen(keyName) > 1 ? ("<" . keyName . ">") : keyName

    if keyName == '"'
      let keyName = '\' . keyName
    endif

    silent! exe "noremap <silent><buffer> " . key . " :call ctrlspace#keys#Keypressed(\"" . keyName . "\")<CR>"
  endfor
endfunction

function! s:markKeyEscSequence()
  let g:ctrlspace#context#KeyEscSequence = 1
endfunction

function! s:setActiveLine()
  if !empty(g:ctrlspace#modes#Search.Data.Letters) && g:ctrlspace#modes#Search.Data.NewSearchPerformed
    call ctrlspace#window#MoveSelectionBar(line("$"))

    if !g:ctrlspace#modes#Search.Enabled
      let g:ctrlspace#modes#Search.Data.NewSearchPerformed = 0
    endif
  elseif g:ctrlspace#modes#Workspace.Enabled
    if g:ctrlspace#modes#Workspace.Data.LastBrowsed
      let activeLine = g:ctrlspace#modes#Workspace.Data.LastBrowsed
    else
      let activeLine = 1

      if !empty(g:ctrlspace#modes#Workspace.Data.Active.Name)
        let currentWorkspace = g:ctrlspace#modes#Workspace.Data.Active.Name
      elseif !empty(g:ctrlspace#modes#Workspace.Data.LastActive)
        let currentWorkspace = g:ctrlspace#modes#Workspace.Data.LastActive
      else
        let currentWorkspace = ""
      endif

      if !empty(currentWorkspace)
        for i in range(0, b:size - 1)
          if currentWorkspace ==# g:ctrlspace#context#Workspaces[b:indices[i]]
            let activeLine = i + 1
            break
          endif
        endfor
      endif
    endif
  elseif g:ctrlspace#modes#Tablist.Enabled
    let activeLine = tabpagenr()
  elseif g:ctrlspace#modes#Bookmark.Enabled
    let activeLine = 1

    if !empty(g:ctrlspace#modes#Bookmark.Data.Active)
      for i in range(0, b:size - 1)
        if g:ctrlspace#modes#Bookmark.Data.Active.Name ==# g:ctrlspace#context#Bookmarks[b:indices[i]].Name
          let activeLine = i + 1
          break
        endif
      endfor
    endif
  elseif g:ctrlspace#modes#File.Enabled
    let activeLine = line("$")
  else
    let activeLine = 0
    let maxCounter = 0
    let lastLine   = 0

    for i in range(0, b:size - 1)
      if b:indices[i] == t:CtrlSpaceActivebuf
        let activeLine = i + 1
        break
      endif

      let currentJumpCounter = ctrlspace#util#GetbufvarWithDefault(b:indices[i], "CtrlSpaceJumpCounter", 0)

      if currentJumpCounter > maxCounter
        let maxCounter = currentJumpCounter
        let lastLine = i + 1
      endif
    endfor

    if !activeLine
      let activeLine = (lastLine > 0) ? lastLine : b:size - 1
    endif
  endif

  call ctrlspace#window#MoveSelectionBar(activeLine)
endfunction

function! s:filler()
  " generate a variable to fill the buffer afterwards
  " (we need this for "full window" color :)
  if !exists("s:filler['" . &columns . "']")
    let fill = "\n"
    let i    = 0

    while i < &columns
      let i += 1
      let fill = ' ' . fill
    endwhile

    if !exists("s:filler")
      let s:filler = {}
    endif

    let s:filler[string(&columns)] = fill
  endif

  return s:filler[string(&columns)]
endfunction

function! s:fillBufferSpace()
  let fill = s:filler()

  while winheight(0) > line(".")
    silent! put =fill
  endwhile
endfunction

function! s:displayContent()
  setlocal modifiable

  if b:size > 0
    silent! put! =b:text
    normal! GkJ
    call s:fillBufferSpace()
    call g:ctrlspace#modes#Nop.Disable()
  else
    let emptyListMessage = "  List empty"

    if &columns < (strwidth(emptyListMessage) + 2)
      let emptyListMessage = strpart(emptyListMessage, 0, &columns - 2 - g:ctrlspace#context#SymbolSizes.Dots) . s:config.Symbols.Dots
    endif

    while strwidth(emptyListMessage) < &columns
      let emptyListMessage .= ' '
    endwhile

    silent! put! =emptyListMessage
    normal! GkJ

    call s:fillBufferSpace()

    normal! 0

    call g:ctrlspace#modes#Nop.Enable()
  endif

  setlocal nomodifiable
endfunction
