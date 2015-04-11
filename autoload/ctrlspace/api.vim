let s:config = g:ctrlspace#context#Configuration.Instance()

function! g:ctrlspace#api#BufferList(tabnr)
  let bufferList     = []
  let singleList     = g:ctrlspace#context#Buffers(a:tabnr)
  let visibleBuffers = tabpagebuflist(a:tabnr)

  for i in keys(singleList)
    let i = str2nr(i)

    let bufname = bufname(i)

    if !strlen(bufname) && (getbufvar(i, '&modified') || (index(visibleBuffers, i) != -1))
      let bufname = '[' . i . '*No Name]'
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable')
      call add(bufferList, { "index": i, "text": bufname })
    endif
  endfor

  call sort(bufferList, function("g:ctrlspace#engine#CompareByText"))

  return bufferList
endfunction

function! g:ctrlspace#api#Buffers(tabnr)
  let bufferList     = {}
  let ctrlspaceList  = g:ctrlspace#context#Buffers(a:tabnr)
  let visibleBuffers = tabpagebuflist(a:tabnr)

  for i in keys(ctrlspaceList)
    let i = str2nr(i)

    let bufname = bufname(i)

    if !strlen(bufname) && (getbufvar(i, '&modified') || (index(visibleBuffers, i) != -1))
      let bufname = '[' . i . '*No Name]'
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable')
      let bufferList[i] = bufname
    endif
  endfor

  return bufferList
endfunction

function! g:ctrlspace#api#TabModified(tabnr)
  for b in map(keys(g:ctrlspace#context#Buffers(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction

function! g:ctrlspace#api#Statusline()
  hi def link User1 CtrlSpaceStatus

  let statusline = "%1*" . s:config.Symbols.CS . "    " . g:ctrlspace#api#StatuslineModeSegment("    ")

  if !&showtabline
    let statusline .= " %=%1* %<" . g:ctrlspace#api#StatuslineTabSegment()
  endif

  return statusline
endfunction

function! g:ctrlspace#api#StatuslineTabSegment()
  let currentTab = tabpagenr()
  let winnr      = tabpagewinnr(currentTab)
  let buflist    = tabpagebuflist(currentTab)
  let bufnr      = buflist[winnr - 1]
  let bufname    = bufname(bufnr)
  let bufsNumber = g:ctrlspace#api#TabBuffersNumber(currentTab)
  let title      = g:ctrlspace#api#TabTitle(currentTab, bufnr, bufname)

  if !s:config.UnicodeFont && !empty(bufsNumber)
    let bufsNumber = ":" . bufsNumber
  end

  let tabinfo = string(currentTab) . bufsNumber . " "

  if g:ctrlspace#api#TabModified(currentTab)
    let tabinfo .= "+ "
  endif

  let tabinfo .= title

  return tabinfo
endfunction

function! s:createStatusTabline()
  let current = tabpagenr()
  let line    = ""

  for i in range(1, tabpagenr("$"))
    let line .= (current == i ? s:config.Symbols.CTab : s:config.Symbols.Tabs)
  endfor

  return line
endfunction

function! g:ctrlspace#api#StatuslineModeSegment(...)
  let statuslineElements = []

  if g:ctrlspace#modes#Workspace.Enabled
    if g:ctrlspace#modes#Workspace.Data.SubMode == "load"
      call add(statuslineElements, s:config.Symbols.WLoad)
    elseif currentList.Data.SubMode == "save"
      call add(statuslineElements, s:config.Symbols.WSave)
    endif
  elseif g:ctrlspace#modes#Tablist.Enabled
    call add(statuslineElements, s:createStatusTabline())
  elseif g:ctrlspace#modes#Bookmark.Enabled
    call add(statuslineElements, s:config.Symbols.BM)
  else
    if g:ctrlspace#modes#File.Enabled
      let symbol = s:config.Symbols.File
    elseif g:ctrlspace#modes#Buffer.Enabled
      if g:ctrlspace#modes#Buffer.Data.SubMode == "visual"
        let symbol = s:config.Symbols.Vis
      elseif g:ctrlspace#modes#Buffer.Data.SubMode == "single"
        let symbol = s:config.Symbols.Sin
      elseif g:ctrlspace#modes#Buffer.Data.SubMode == "all"
        let symbol = s:config.Symbols.All
      endif
    endif

    if g:ctrlspace#modes#NextTab.Enabled
      let symbol .= s:config.Symbols.NTM . g:ctrlspace#api#TabBuffersNumber(tabpagenr() + 1)
    endif

    call add(statuslineElements, symbol)
  endif

  if !empty(g:ctrlspace#modes#Search.Data.Letters) || g:ctrlspace#modes#Search.Enabled
    let searchElement = s:config.Symbols.SLeft . join(g:ctrlspace#modes#Search.Data.Letters, "")

    if g:ctrlspace#modes#Search.Enabled
      let searchElement .= "_"
    endif

    let searchElement .= s:config.Symbols.SRight

    call add(statuslineElements, searchElement)
  endif

  if g:ctrlspace#modes#Zoom.Enabled
    call add(statuslineElements, s:config.Symbols.Zoom)
  endif

  if g:ctrlspace#modes#Help.Enabled
    call add(statuslineElements, s:config.Symbols.Help)
  endif

  let separator = (a:0 > 0) ? a:1 : "  "

  return join(statuslineElements, separator)
endfunction

function! g:ctrlspace#api#TabBuffersNumber(tabnr)
  let buffersNumber = len(g:ctrlspace#api#Buffers(a:tabnr))
  let numberToShow  = ""

  if buffersNumber > 1
    if s:config.UnicodeFont
      let smallNumbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
      let numberStr    = string(buffersNumber)

      for i in range(0, len(numberStr) - 1)
        let numberToShow .= smallNumbers[str2nr(numberStr[i])]
      endfor
    else
      let numberToShow = string(buffersNumber)
    endif
  endif

  return numberToShow
endfunction

function! g:ctrlspace#api#TabTitle(tabnr, bufnr, bufname)
  let bufname = a:bufname
  let bufnr   = a:bufnr
  let title   = gettabvar(a:tabnr, "CtrlSpaceLabel")

  if empty(title)
    if getbufvar(bufnr, "&ft") == "ctrlspace"
      if g:ctrlspace#modes#Zoom.Enabled && g:ctrlspace#modes#Zoom.Data.OriginalBuffer
        let bufnr = g:ctrlspace#modes#Zoom.Data.OriginalBuffer
      else
        let bufnr = winbufnr(t:CtrlSpaceStartWindow)
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

function! g:ctrlspace#api#Guitablabel()
  let winnr      = tabpagewinnr(v:lnum)
  let buflist    = tabpagebuflist(v:lnum)
  let bufnr      = buflist[winnr - 1]
  let bufname    = bufname(bufnr)
  let title      = g:ctrlspace#api#TabTitle(v:lnum, bufnr, bufname)
  let bufsNumber = g:ctrlspace#api#TabBuffersNumber(v:lnum)

  if !s:config.UnicodeFont && !empty(bufsNumber)
    let bufsNumber = ":" . bufsNumber
  end

  let label = '' . v:lnum . bufsNumber . ' '

  if g:ctrlspace#api#TabModified(v:lnum)
    let label .= '+ '
  endif

  let label .= title . ' '

  return label
endfunction

function! g:ctrlspace#api#Tabline()
  let lastTab    = tabpagenr("$")
  let currentTab = tabpagenr()
  let tabline    = ''

  for t in range(1, lastTab)
    let winnr      = tabpagewinnr(t)
    let buflist    = tabpagebuflist(t)
    let bufnr      = buflist[winnr - 1]
    let bufname    = bufname(bufnr)
    let bufsNumber = g:ctrlspace#api#TabBuffersNumber(t)
    let title      = g:ctrlspace#api#TabTitle(t, bufnr, bufname)

    if !s:config.UnicodeFont && !empty(bufsNumber)
      let bufsNumber = ":" . bufsNumber
    end

    let tabline .= '%' . t . 'T'
    let tabline .= (t == currentTab ? '%#TabLineSel#' : '%#TabLine#')
    let tabline .= ' ' . t . bufsNumber . ' '

    if g:ctrlspace#api#TabModified(t)
      let tabline .= '+ '
    endif

    let tabline .= title . ' '
  endfor

  let tabline .= '%#TabLineFill#%T'

  if lastTab > 1
    let tabline .= '%='
    let tabline .= '%#TabLine#%999XX'
  endif

  return tabline
endfunction

function! g:ctrlspace#api#BufNr()
  return bufexists(g:ctrlspace#context#PluginBuffer) ? g:ctrlspace#context#PluginBuffer : -1
endfunction

function! g:ctrlspace#api#TabModified(tabnr)
  for b in map(keys(g:ctrlspace#api#Buffers(a:tabnr)), "str2nr(v:val)")
    if getbufvar(b, '&modified')
      return 1
    endif
  endfor
  return 0
endfunction
