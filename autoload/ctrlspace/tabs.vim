let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#tabs#SetTabLabel(tabnr, label, auto)
	call settabvar(a:tabnr, "CtrlSpaceLabel", a:label)
	call settabvar(a:tabnr, "CtrlSpaceAutotab", a:auto)
endfunction

function! ctrlspace#tabs#NewTabLabel(tabnr)
	let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()
	let label = ctrlspace#ui#GetInput("Label for tab " . tabnr . ": ", ctrlspace#util#Gettabvar(tabnr, "CtrlSpaceLabel"))
	if empty(label)
		return 0
	endif

	call ctrlspace#tabs#SetTabLabel(tabnr, label, 0)
	return 1
endfunction

function! ctrlspace#tabs#RemoveTabLabel(tabnr)
	let tabnr = a:tabnr > 0 ? a:tabnr : tabpagenr()

	if empty(ctrlspace#util#Gettabvar(tabnr, "CtrlSpaceLabel"))
		return 0
	endif

	call ctrlspace#tabs#SetTabLabel(tabnr, "", 0)
	return 1
endfunction

function! ctrlspace#tabs#CloseTab()
	if tabpagenr("$") == 1
		return
	endif

	if exists("t:CtrlSpaceAutotab") && (t:CtrlSpaceAutotab != 0)
		" do nothing
	elseif exists("t:CtrlSpaceLabel") && !empty(t:CtrlSpaceLabel)
		let bufCount = len(ctrlspace#buffers#Buffers(tabpagenr()))

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

function! ctrlspace#tabs#CollectUnsavedBuffers()
	let buffers = []

	for i in range(1, bufnr("$"))
		if getbufvar(i, "&modified") && getbufvar(i, "&buflisted")
			call add(buffers, i)
		endif
	endfor

	if empty(buffers)
		call ctrlspace#ui#Msg("There are no unsaved buffers.")
		return 0
	endif

	call ctrlspace#window#Kill(0, 1)

	tabnew

	call ctrlspace#tabs#SetTabLabel(tabpagenr(), "Unsaved Buffers", 1)

	for b in buffers
		silent! exe ":b " . b
	endfor

	call ctrlspace#window#Toggle(0)
	call ctrlspace#window#Kill(0, 0)
	call s:modes.Tab.Enable()
	call ctrlspace#window#Toggle(1)
	return 1
endfunction

function! ctrlspace#tabs#CollectForeignBuffers()
	let buffers = {}

	for t in range(1, tabpagenr("$"))
		silent! call extend(buffers, ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceList", {}))
	endfor

	let foreignBuffers = []

	for b in keys(ctrlspace#buffers#Buffers(0))
		if !has_key(buffers, b)
			call add(foreignBuffers, b)
		endif
	endfor

	if empty(foreignBuffers)
		call ctrlspace#ui#Msg("There are no foreign buffers.")
		return 0
	endif

	call ctrlspace#window#Kill(0, 1)

	tabnew

	call ctrlspace#tabs#SetTabLabel(tabpagenr(), "Foreign Buffers", 1)

	for fb in foreignBuffers
		silent! exe ":b " . fb
	endfor

	call ctrlspace#window#Toggle(0)
	call ctrlspace#window#Kill(0, 0)
	call s:modes.Tab.Enable()
	call ctrlspace#window#Toggle(1)
	return 1
endfunction
