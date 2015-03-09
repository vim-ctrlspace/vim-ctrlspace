function! ctrlspace#tabs#SetTabLabel(tabnr, label, auto)
  call settabvar(a:tabnr, "CtrlSpaceLabel", a:label)
  call settabvar(a:tabnr, "CtrlSpaceAutotab", a:auto)
endfunction
