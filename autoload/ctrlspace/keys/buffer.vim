let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#buffer#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#SearchParentDirectory", "Buffer", ["BSlash"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#SearchParentDirectoryInFile", "Buffer", ["Bar"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadBuffer", "Buffer", ["CR"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadManyBuffers", "Buffer", ["Space"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#GoToWindow", "Buffer", ["Tab"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#GoToWindowAndBack", "Buffer", ["S-Tab"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#VisibleMode", "Buffer", ["*"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#ZoomMode", "Buffer", ["z"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadBufferVS", "Buffer", ["v"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadManyBuffersVS", "Buffer", ["V"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadBufferSP", "Buffer", ["s"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadManyBuffersSP", "Buffer", ["S"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CloseWindow", "Buffer", ["x"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CloseManyWindows", "Buffer", ["X"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadBufferT", "Buffer", ["t"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadManyBuffersT", "Buffer", ["T"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#LoadManyBuffersCT", "Buffer", ["C-t"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#NewTabLabel", "Buffer", ["="])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#RemoveTabLabel", "Buffer", ["_"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#MoveTab", "Buffer", ["+", "-"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#SwitchTab", "Buffer", ["[", "]"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CopyBufferToTab", "Buffer", ["<", ">"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#MoveBufferToTab", "Buffer", ["{", "}"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#DeleteBuffer", "Buffer", ["d"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#DeleteHiddenNonameBuffers", "Buffer", ["D"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#ToggleAllMode", "Buffer", ["a"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#ToggleAllModeAndSearch", "Buffer", ["A"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#DetachBuffer", "Buffer", ["f"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#DeleteForeignBuffers", "Buffer", ["F"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CloseBuffer", "Buffer", ["c"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CloseTab", "Buffer", ["C"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#EditFile", "Buffer", ["e"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#ExploreDirectory", "Buffer", ["E"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#GoToDirectory", "Buffer", ["i", "I"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#RemoveFile", "Buffer", ["R"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#RenameFileOrBuffer", "Buffer", ["m"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#CopyFileOrBuffer", "Buffer", ["y"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#GoToBufferOrFile", "Buffer", ["g", "G"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#NewWorkspace", "Buffer", ["N"])
endfunction

function! ctrlspace#keys#buffer#SearchParentDirectory(k)
	call ctrlspace#search#SearchParentDirectoryCycle()
endfunction

function! ctrlspace#keys#buffer#SearchParentDirectoryInFile(k)
	call ctrlspace#search#SearchParentDirectoryCycle()
	call ctrlspace#keys#common#ToggleFileMode(a:k)
endfunction

function! ctrlspace#keys#buffer#LoadBuffer(k)
	call ctrlspace#buffers#LoadBuffer()
endfunction

function! ctrlspace#keys#buffer#LoadManyBuffers(k)
	call ctrlspace#buffers#LoadManyBuffers()
endfunction

function! ctrlspace#keys#buffer#GoToWindow(k)
	call ctrlspace#window#GoToWindow()
endfunction

function! ctrlspace#keys#buffer#GoToWindowAndBack(k)
	let subMode = s:modes.Buffer.Data.SubMode

	if ctrlspace#window#GoToWindow()
		call ctrlspace#window#Toggle(0)

		if subMode !=# "single"
			call ctrlspace#window#Kill(0, 0)
			call s:modes.Buffer.SetData("SubMode", subMode)
			call ctrlspace#window#Toggle(1)
		endif
	endif
endfunction

function! ctrlspace#keys#buffer#VisibleMode(k)
	if s:modes.Buffer.Data.SubMode ==# "visible"
		call s:modes.Buffer.SetData("SubMode", "single")
	else
		call s:modes.Buffer.SetData("SubMode", "visible")
	endif

	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#Toggle(1)
endfunction

function! ctrlspace#keys#buffer#ZoomMode(k)
	if !s:modes.Zoom.Enabled
		call ctrlspace#buffers#ZoomBuffer(0)
	else
		call ctrlspace#window#Kill(0, 1)
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#Kill(0, 0)
		if s:modes.Zoom.Data.Mode ==# "File"
			call s:modes.File.Enable()
		else
			call s:modes.Buffer.SetData("SubMode", s:modes.Zoom.Data.SubMode)
		endif
		call s:modes.Search.SetData("Letters", copy(s:modes.Zoom.Data.Letters))
		call ctrlspace#window#Toggle(1)
		call ctrlspace#window#MoveSelectionBar(s:modes.Zoom.Data.Line)
	endif
endfunction

function! ctrlspace#keys#buffer#LoadBufferVS(k)
	call ctrlspace#buffers#LoadBuffer("vs")
endfunction

function! ctrlspace#keys#buffer#LoadManyBuffersVS(k)
	call ctrlspace#buffers#LoadManyBuffers("vs")
endfunction

function! ctrlspace#keys#buffer#LoadBufferSP(k)
	call ctrlspace#buffers#LoadBuffer("sp")
endfunction

function! ctrlspace#keys#buffer#LoadManyBuffersSP(k)
	call ctrlspace#buffers#LoadManyBuffers("sp")
endfunction

function! ctrlspace#keys#buffer#CloseWindow(k)
	let curln = line(".")
	if (winnr("$") > 2) && ctrlspace#window#GoToWindow()
		silent! exe "wincmd c"
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#MoveSelectionBar(curln)
	endif
endfunction

function! ctrlspace#keys#buffer#CloseManyWindows(k)
	let curln = line(".")
	if (winnr("$") > 2) && ctrlspace#window#GoToWindow()
		only
		call ctrlspace#window#Toggle(0)
		call ctrlspace#window#MoveSelectionBar(curln)
	endif
endfunction

function! ctrlspace#keys#buffer#LoadBufferT(k)
	call ctrlspace#buffers#LoadBuffer("tabnew")
endfunction

function! ctrlspace#keys#buffer#LoadManyBuffersT(k)
	if s:modes.NextTab.Enabled
		call ctrlspace#buffers#LoadManyBuffers("tabnext", "tabprevious")
	else
		call s:modes.NextTab.Enable()
		call ctrlspace#buffers#LoadManyBuffers("tabnew", "tabprevious")
	endif
endfunction

function! ctrlspace#keys#buffer#LoadManyBuffersCT(k)
	call s:modes.NextTab.Enable()
	call ctrlspace#buffers#LoadManyBuffers("tabnew", "tabprevious")
endfunction

function! ctrlspace#keys#buffer#NewTabLabel(k)
	call ctrlspace#tabs#NewTabLabel(0)
	call ctrlspace#util#SetStatusline()
	redraws
endfunction

function! ctrlspace#keys#buffer#MoveTab(k)
	if v:version < 704
		if a:k ==# "+"
			silent! exe "tabm" . tabpagenr()
		elseif a:k ==# "-"
			silent! exe "tabm" . (tabpagenr() - 2)
		endif
	else
		silent! exe "tabm" . a:k . "1"
	endif

	call ctrlspace#util#SetStatusline()
	redraws
endfunction

function! ctrlspace#keys#buffer#RemoveTabLabel(k)
	call ctrlspace#tabs#RemoveTabLabel(0)
	call ctrlspace#util#SetStatusline()
	redraw!
endfunction

function! ctrlspace#keys#buffer#SwitchTab(k)
	call ctrlspace#window#Kill(0, 1)

	if a:k ==# "["
		silent! exe "normal! gT"
	elseif a:k ==# "]"
		silent! exe "normal! gt"
	endif

	call ctrlspace#window#Toggle(0)
endfunction

function! ctrlspace#keys#buffer#CopyBufferToTab(k)
	if s:modes.Buffer.Data.SubMode ==# "all"
		return 0
	endif

	let curTab = tabpagenr()

	if a:k ==# "<"
		if curTab > 1
			call ctrlspace#buffers#CopyBufferToTab(curTab - 1)
		endif
	elseif a:k ==# ">"
		if curTab < tabpagenr("$")
			call ctrlspace#buffers#CopyBufferToTab(curTab + 1)
		endif
	endif
endfunction

function! ctrlspace#keys#buffer#MoveBufferToTab(k)
	if s:modes.Buffer.Data.SubMode ==# "all"
		return 0
	endif

	let curTab = tabpagenr()

	if a:k ==# "{"
		if curTab > 1
			call ctrlspace#buffers#MoveBufferToTab(curTab - 1)
		endif
	elseif a:k ==# "}"
		if curTab < tabpagenr("$")
			call ctrlspace#buffers#MoveBufferToTab(curTab + 1)
		endif
	endif
endfunction

function! ctrlspace#keys#buffer#DeleteBuffer(k)
	call ctrlspace#buffers#DeleteBuffer()
endfunction

function! ctrlspace#keys#buffer#DeleteHiddenNonameBuffers(k)
	call ctrlspace#buffers#DeleteHiddenNonameBuffers(0)
	call ctrlspace#ui#DelayedMsg()
endfunction

function! ctrlspace#keys#buffer#DetachBuffer(k)
	if s:modes.Buffer.Data.SubMode ==# "single"
		call ctrlspace#buffers#DetachBuffer()
	endif
endfunction

function! ctrlspace#keys#buffer#DeleteForeignBuffers(k)
	call ctrlspace#buffers#DeleteForeignBuffers(0)
	call ctrlspace#ui#DelayedMsg()
endfunction

function! ctrlspace#keys#buffer#CloseBuffer(k)
	call ctrlspace#buffers#CloseBuffer()
endfunction

function! ctrlspace#keys#buffer#CloseTab(k)
	call ctrlspace#tabs#CloseTab()
	call ctrlspace#ui#Msg("Current tab closed.")
endfunction

function! ctrlspace#keys#buffer#ToggleAllMode(k)
	call s:toggleAllMode()
endfunction

function! ctrlspace#keys#buffer#ToggleAllModeAndSearch(k)
	if s:modes.Buffer.Data.SubMode !=# "all"
		call s:toggleAllMode()
	endif
	call ctrlspace#search#SwitchSearchMode(1)
endfunction

function! ctrlspace#keys#buffer#GoToBufferOrFile(k)
	call ctrlspace#buffers#GoToBufferOrFile(a:k ==# "g" ? "next" : "previous")
endfunction

function! ctrlspace#keys#buffer#NewWorkspace(k)
	let saveWorkspaceBefore = 0
	let active = ctrlspace#workspaces#ActiveWorkspace()

	if active.Status == 2
		if s:config.SaveWorkspaceOnSwitch
			let saveWorkspaceBefore = 1
		elseif !ctrlspace#ui#Confirmed("Current workspace ('" . active.Name . "') not saved. Proceed anyway?")
			return 0
		endif
	endif

	if !ctrlspace#ui#ProceedIfModified()
		return 0
	endif

	call ctrlspace#window#Kill(0, 1)

	if saveWorkspaceBefore
		call ctrlspace#workspaces#SaveWorkspace("")
	endif

	call ctrlspace#workspaces#NewWorkspace()
	call ctrlspace#window#Toggle(0)
	return 1
endfunction

function! s:toggleAllMode()
	if s:modes.Buffer.Data.SubMode !=# "all"
		call s:modes.Buffer.SetData("SubMode", "all")
	else
		call s:modes.Buffer.SetData("SubMode", "single")
	endif

	if !empty(s:modes.Search.Data.Letters)
		call s:modes.Search.SetData("NewSearchPerformed", 1)
	endif

	call ctrlspace#window#Kill(0, 0)
	call ctrlspace#window#Toggle(1)
endfunction
