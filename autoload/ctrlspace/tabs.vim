let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

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

function! ctrlspace#tabs#CloseTab()
  if tabpagenr("$") == 1
    return
  endif

  if exists("t:CtrlSpaceAutotab") && (t:CtrlSpaceAutotab != 0)
    " do nothing
  elseif exists("t:CtrlSpaceLabel") && !empty(t:CtrlSpaceLabel)
    let bufCount = len(ctrlspace#buffers(tabpagenr()))

    if (bufCount > 1) && !ctrlspace#ui#Confirmed("Close tab named '" . t:CtrlSpaceLabel . "' with " . bufCount . " buffers?")
      return
    endif
  endif

  call ctrlspace#window#Kill(0, 1)

  tabclose

  call ctrlspace#buffers#DeleteHiddenNonameBuffers(1)
  call ctrlspace#buffers#DeleteForeignBuffers(1)

  call ctrlspace#window#Toggle(0)
endfunction

