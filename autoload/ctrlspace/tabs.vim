let s:config = g:ctrlspace#context#Configuration.Instance()

function! ctrlspace#tabs#SetTabLabel(tabnr, label, auto)
  call settabvar(a:tabnr, "CtrlSpaceLabel", a:label)
  call settabvar(a:tabnr, "CtrlSpaceAutotab", a:auto)
endfunction

function! ctrlspace#tabs#NewTabLabel(tabnr)
  let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
  let label = ctrlspace#ui#GetInput("Label for tab " . tabnr . ": ", gettabvar(tabnr, "CtrlSpaceLabel"))
  if !empty(label)
    call ctrlspace#tabs#SetTabLabel(tabnr, label, 0)
  endif
endfunction

function! ctrlspace#tabs#RemoveTabLabel(tabnr)
  let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
  call ctrlspace#tabs#SetTabLabel(tabnr, "", 0)
endfunction
