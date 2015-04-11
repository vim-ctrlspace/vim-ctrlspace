let s:config = g:ctrlspace#context#Configuration.Instance()

function! g:ctrlspace#ui#AddProjectRoot(directory)
  let directory = g:ctrlspace#util#NormalizeDirectory(empty(a:directory) ? getcwd() : a:directory)

  if !isdirectory(directory)
    call g:ctrlspace#ui#Msg("Invalid directory: '" . directory . "'")
    return
  endif

  let roots = copy(g:ctrlspace#context#ProjectRoots)

  for bookmark in g:ctrlspace#context#Bookmarks
    let roots[bookmark.directory] = 1
  endfor

  if exists("roots[directory]")
    call g:ctrlspace#ui#Msg("Directory is already a permanent project root!")
    return
  endif

  call g:ctrlspace#roots#AddProjectRoot(directory)
  call g:ctrlspace#ui#Msg("Directory '" . directory . "' has been added as a permanent project root.")
endfunction

function! g:ctrlspace#ui#RemoveProjectRoot(directory)
  let directory = g:ctrlspace#util#NormalizeDirectory(empty(a:directory) ? getcwd() : a:directory)

  if !exists("g:ctrlspace#context#ProjectRoots[directory]")
    call g:ctrlspace#ui#Msg("Directory '" . directory . "' is not a permanent project root!" )
    return
  endif

  call g:ctrlspace#roots#RemoveProjectRoot(directory)
  call g:ctrlspace#ui#Msg("The project root '" . directory . "' has been removed.")
endfunction

function! g:ctrlspace#ui#Msg(message)
  echo s:config.Symbols.CS . "  " . a:message
endfunction

function! g:ctrlspace#ui#DelayedMsg(...)
  if !empty(a:000)
    let s:delayedMessage = a:1
  elseif exists("s:delayedMessage") && !empty(s:delayedMessage)
    redraw
    call g:ctrlspace#ui#Msg(s:delayedMessage)
    unlet s:delayedMessage
  endif
endfunction

function! g:ctrlspace#ui#StartAndFeedkeys(keys)
  call g:ctrlspace#window#Toggle(0)

  if !empty(a:keys)
    call feedkeys(a:keys)
  endif
endfunction

function! g:ctrlspace#ui#GetInput(msg, ...)
  let msg = s:config.Symbols.CS . "  " . a:msg

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

function! g:ctrlspace#ui#Confirmed(msg)
  return g:ctrlspace#ui#GetInput(a:msg . " (yN): ") =~? "y"
endfunction

function! g:ctrlspace#ui#GoToBufferListPosition(direction)
  let bufferList    = g:ctrlspace#api#BufferList(tabpagenr())
  let currentBuffer = bufnr("%")
  let currentIndex  = -1
  let bufferListLen = len(bufferList)

  for index in range(0, bufferListLen - 1)
    if bufferList[index]["number"] == currentBuffer
      let currentIndex = index
      break
    endif
  endfor

  if currentIndex == -1
    return
  endif

  if a:direction == "down"
    let targetIndex = currentIndex + 1

    if targetIndex == bufferListLen
      let targetIndex = 0
    endif
  else
    let targetIndex = currentIndex - 1

    if targetIndex < 0
      let targetIndex = bufferListLen - 1
    endif
  endif

  silent! exe ":b " . bufferList[targetIndex]["number"]
endfunction

function! g:ctrlspace#ui#NewTabLabel(tabnr)
  let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
  let label = g:ctrlspace#ui#GetInput("Label for tab " . tabnr . ": ", gettabvar(tabnr, "CtrlSpaceLabel"))
  if !empty(label)
    call g:ctrlspace#tabs#SetTabLabel(tabnr, label, 0)
  endif
endfunction

function! g:ctrlspace#ui#RemoveTabLabel(tabnr)
  let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
  call g:ctrlspace#tabs#SetTabLabel(tabnr, "", 0)
endfunction

function g:ctrlspace#ui#SaveWorkspace(name)
  if !g:ctrlspace#roots#ProjectRootFound()
    return
  endif

  call g:ctrlspace#util#HandleVimSettings("start")

  let cwdSave = fnamemodify(".", ":p:h")
  silent! exe "cd " . g:ctrlspace#context#ProjectRoot

  if empty(a:name)
    if !empty(g:ctrlspace#modes#Workspace.Data.Active.Name)
      let name = g:ctrlspace#modes#Workspace.Data.Active.Name
    else
      silent! exe "cd " . cwdSave
      call g:ctrlspace#util#HandleVimSettings("stop")
      return
    endif
  else
    let name = a:name
  endif

  let filename = g:ctrlspace#util#WorkspaceFile()
  let lastTab  = tabpagenr("$")

  let lines       = []
  let inWorkspace = 0

  let workspaceStartMarker = "CS_WORKSPACE_BEGIN: " . name
  let workspaceEndMarker   = "CS_WORKSPACE_END: " . name

  if filereadable(filename)
    for oldLine in readfile(filename)
      if oldLine ==# workspaceStartMarker
        let inWorkspace = 1
      endif

      if !inWorkspace
        call add(lines, oldLine)
      endif

      if oldLine ==# workspaceEndMarker
        let inWorkspace = 0
      endif
    endfor
  endif

  call add(lines, workspaceStartMarker)

  let ssopSave = &ssop
  set ssop=winsize,tabpages,buffers,sesdir

  let tabData = []

  for t in range(1, lastTab)
    let data = {
          \ "label": gettabvar(t, "CtrlSpaceLabel"),
          \ "autotab": g:ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceAutotab", 0)
          \ }

    let ctrlspaceList = g:ctrlspace#api#Buffers(t)

    let bufs = []

    for [nr, bname] in items(ctrlspaceList)
      let bufname = fnamemodify(bname, ":.")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor

    let data.bufs = bufs
    call add(tabData, data)
  endfor

  silent! exe "mksession! CS_SESSION"

  if !filereadable("CS_SESSION")
    silent! exe "cd " . cwdSave
    silent! exe "set ssop=" . ssopSave

    call g:ctrlspace#util#HandleVimSettings("stop")
    call g:ctrlspace#ui#Msg("The workspace '" . name . "' cannot be saved at this moment.")
    return
  endif

  let tabIndex = 0

  for cmd in readfile("CS_SESSION")
    if ((cmd =~# "^edit") && (tabIndex == 0)) || (cmd =~# "^tabnew") || (cmd =~# "^tabedit")
      let data = tabData[tabIndex]

      if tabIndex > 0
        call add(lines, cmd)
      endif

      for b in data.bufs
        call add(lines, "edit " . b)
      endfor

      if !empty(data.label)
        call add(lines, "let t:CtrlSpaceLabel = '" . substitute(data.label, "'", "''","g") . "'")
      endif

      if !empty(data.autotab)
        call add(lines, "let t:CtrlSpaceAutotab = " . data.autotab)
      endif

      if tabIndex == 0
        call add(lines, cmd)
      elseif cmd =~# "^tabedit"
        call add(lines, cmd[3:]) "make edit from tabedit
      endif

      let tabIndex += 1
    else
      let baddList = matchlist(cmd, "\\m^badd \+\\d* \\(.*\\)$")

      if !(exists("baddList[1]") && !empty(baddList[1]) && !filereadable(baddList[1]))
        call add(lines, cmd)
      endif
    endif
  endfor

  call add(lines, workspaceEndMarker)

  call writefile(lines, filename)
  call delete("CS_SESSION")

  call g:ctrlspace#workspaces#SetActiveWorkspaceName(name)
  let g:ctrlspace#mode#Workspace.Data.Active.Digest = g:ctrlspace#workspaces#CreateWorkspaceDigest()

  call g:ctrlspace#workspaces#SetWorkspaceNames()

  silent! exe "cd " . cwdSave
  silent! exe "set ssop=" . ssopSave

  call g:ctrlspace#util#HandleVimSettings("stop")
  call g:ctrlspace#ui#Msg("The workspace '" . name . "' has been saved.")
endfunction
