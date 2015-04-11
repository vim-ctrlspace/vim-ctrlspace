function! g:ctrlspace#tabs#SetTabLabel(tabnr, label, auto)
  call settabvar(a:tabnr, "g:ctrlspaceLabel", a:label)
  call settabvar(a:tabnr, "g:ctrlspaceAutotab", a:auto)
endfunction
