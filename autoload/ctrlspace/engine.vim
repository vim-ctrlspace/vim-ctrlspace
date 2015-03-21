s:config = ctrlspace#context#Configuration.Instance()

function! ctrlspace#engine#Content()
  if !empty(s:config.Engine)
    return s:configFromExternalEngine(s:config.Engine)
  endif

  let source = s:contentSource()

  " check mode
  " collect for current mode
  " collect state of current tab (windows, buffers, tab variables)
  " compute noises
  " sort and trim
  " return patterns, mappings, window text
endfunction

function! s:vimContext()
  {
        \ "VisibleBuffers": tabpagebuflist(a:tabnr),
        \ "Plugin": {
          \ "Configuration": s:config,
          \ "Modes":         ctrlspace#modes#Collection,
          \ "Context": {
            \ "PluginFolder": ctrlspace#context#PluginFolder,
            \ "PluginBuffer": ctrlspace#context#PluginBuffer,
            \ "SymbolSizes":  ctrlspace#context#SymbolSizes,
          \ },
          \ "Vim": {
            \ "Columns":     &columns,
            \ "StartWindow": t:CtrlSpaceStartWindow,
          \ }
        \ }
  \ }
endfunction

function! s:contentSource()
  if ctrlspace#modes#Buffer.Enabled
    return s:bufferListContent()
  elseif ctrlspace#modes#File.Enabled
    return s:fileListContent()
  elseif ctrlspace#modes#Tablist.Enabled
    return s:tabListContent()
  elseif ctrlspace#modes#Workspace.Enabled
    return s:workspaceListContent()
  elseif ctrlspace#modes#Bookmark.Enabled
    return s:bookmarkListContent()
  endif
endfunction

function! s:bookmarkListContent()
  let content = []

  for i in range(0, len(ctrlspace#context#Bookmarks) - 1)
    call add(content, { "index": i, "text": ctrlspace#content#Bookmarks[i].name })
  endfor

  return content
endfunction

function! s:workspaceListContent()
  let content = []

  for i in range(0, len(ctrlspace#context#Workspaces) - 1)
    call add(content, { "index": i, "text": ctrlspace#context#Workspaces[i]})
  endfor

  return content
endfunction

function! s:tabListContent()
  let content = []

  for i in range(1, tabpagenr("$"))
    let winnr         = tabpagewinnr(i)
    let buflist       = tabpagebuflist(i)
    let bufnr         = buflist[winnr - 1]
    let bufname       = bufname(bufnr)
    let tabBufsNumber = ctrlspace#api#TabBuffersNumber(i)
    let title         = ctrlspace#api#TabTitle(i, bufnr, bufname)

    if !s:config.UnicodeFont && !empty(tabBufsNumber)
      let tabBufsNumber = ":" . tabBufsNumber
    endif

    call add(content, { "index": i, "text": string(i) . tabBufsNumber . " " . title })
  endfor

  return content
endfunction

function! s:fileListContent()
  if empty(ctrlspace#context#Files)

    " try to pick up files from cache
    call ctrlspace#util#LoadFilesFromCache()

    if empty(ctrlspace#context#Files)
      let action = "Collecting files..."
      call ctrlspace#ui#Msg(action)

      let uniqueFiles = {}

      for fname in empty(s:config.GlobCommand) ? split(globpath('.', '**'), '\n') : split(system(s:config.GlobCommand), '\n')
        let fnameModified = fnamemodify(has("win32") ? substitute(fname, "\r$", "", "") : fname, ":.")

        if isdirectory(fnameModified) || (fnameModified =~# s:config.IgnoredFiles)
          continue
        endif

        let uniqueFiles[fnameModified] = 1
      endfor

      let ctrlspace#context#Files = keys(uniqueFiles)
      call ctrlspace#util#SaveFilesInCache()
    else
      let action = "Loading files..."
      call ctrlspace#ui#Msg(action)
    endif

    redraw!
    call ctrlspace#ui#Msg(action . " Done (" . len(ctrlspace#context#Files) . " files).")
  endif

  return [{ "path": fnamemodify(ctrlspace#util#FilesCache(), ":p") }]
endfunction

function! s:bufferListContent()
  let content = []

  if ctrlspace#modes#Buffer.Data.SubMode == "single"
    let ctrlspaceList  = gettabvar(a:tabnr, "CtrlSpaceList")

    if type(ctrlspaceList) != 4
      return content
    endif

    for i in keys(ctrlspaceList)
      let entry = s:bufferEntry(str2nr(i))
      if !empty(entry)
        call add(content, entry)
      endif
    endfor
  elseif ctrlspace#modes#Buffer.Data.SubMode == "all"
    for i in range(1, bufnr("$"))
      if bufexists(i)
        let entry = s:bufferEntry(i)

        if !empty(entry)
          call add(content, entry)
        endif
      endif
    endfor
  elseif ctrlspace#modes#Buffer.Data.SubMode == "visual"
    for i in tabpagebuflist()
      let entry = s:bufferEntry(i)
      if !empty(entry)
        call add(content, entry)
      endif
    endfor
  endif

  return content
endfunction

function! s:bufferEntry(bufnr)
  let bufname = fnamemodify(bufname(i), ":.")

  if !strlen(bufname) && (getbufvar(i, "&modified") || (bufwinnr(i) != -1))
    let bufname = "[" . i . "*No Name]"
  endif

  if strlen(bufname) && getbufvar(i, "&modifiable") && getbufvar(i, "&buflisted")
    return { "index": i, "text": bufname }
  else
    return {}
  endif
endfunction
