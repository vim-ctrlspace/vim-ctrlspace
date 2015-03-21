function! ctrlspace#workspaces#SetWorkspaceNames()
  let filename                = <SID>workspace_file()
  let s:last_active_workspace = ""
  let s:workspace_names       = []

  if filereadable(filename)
    for line in readfile(filename)
      if line =~? "CS_WORKSPACE_BEGIN: "
        call add(s:workspace_names, line[20:])
      elseif line =~? "CS_LAST_WORKSPACE: "
        let s:last_active_workspace = line[19:]
      endif
    endfor
  endif
endfunction

function! ctrlspace#workspaces#SetActiveWorkspaceName(name)
  let s:active_workspace_name = a:name
  let s:last_active_workspace = a:name

  let filename = <SID>workspace_file()
  let lines    = []

  if filereadable(filename)
    for line in readfile(filename)
      if !(line =~? "CS_LAST_WORKSPACE: ")
        call add(lines, line)
      endif
    endfor
  endif

  if !empty(s:active_workspace_name)
    call insert(lines, "CS_LAST_WORKSPACE: " . s:active_workspace_name)
  endif

  call writefile(lines, filename)
endfunction

function! ctrlspace#workspaces#GetSelectedWorkspaceName()
  return s:workspace_names[<SID>get_selected_buffer() - 1]
endfunction

function! ctrlspace#workspaces#CreateWorkspaceDigest()
  let use_nossl = exists("b:nossl_save") && b:nossl_save

  if use_nossl
    set nossl
  endif

  let lines = []

  for t in range(1, tabpagenr("$"))
    let line     = [t, gettabvar(t, "ctrlspace_label")]
    let bufs     = []
    let visibles = []

    let tab_buffers = ctrlspace#buffers(t)

    for bname in values(tab_buffers)
      let bufname = fnamemodify(bname, ":p")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor

    for visible_buf in tabpagebuflist(t)
      if exists("tab_buffers[visible_buf]")
        let bufname = fnamemodify(tab_buffers[visible_buf], ":p")

        if !filereadable(bufname)
          continue
        endif

        call add(visibles, bufname)
      endif
    endfor

    call add(line, join(bufs, "|"))
    call add(line, join(visibles, "|"))
    call add(lines, join(line, ","))
  endfor

  if use_nossl
    set ssl
  endif

  return join(lines, "&&&")
endfunction
