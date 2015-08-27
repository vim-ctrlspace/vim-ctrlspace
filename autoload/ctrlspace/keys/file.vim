let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

function! ctrlspace#keys#file#Init()
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#SearchParentDirectory", "File", ["BSlash", "Bar"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#ZoomMode", "File", ["z"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadFile", "File", ["CR"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadManyFiles", "File", ["Space"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadFileVS", "File", ["v"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadManyFilesVS", "File", ["V"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadFileSP", "File", ["s"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadManyFilesSP", "File", ["S"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadFileT", "File", ["t"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadManyFilesT", "File", ["T"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#LoadManyFilesCT", "File", ["C-t"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#NewTabLabel", "File", ["="])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#RemoveTabLabel", "File", ["_"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#MoveTab", "File", ["+", "-"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#SwitchTab", "File", ["[", "]"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#Refresh", "File", ["r"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CloseTab", "File", ["C"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#EditFile", "File", ["e"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#ExploreDirectory", "File", ["E"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#GoToDirectory", "File", ["i", "I"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#RemoveFile", "File", ["R"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#RenameFileOrBuffer", "File", ["m"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#file#CopyFileOrBuffer", "File", ["y"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#GoToBufferOrFile", "File", ["g", "G"])
	call ctrlspace#keys#AddMapping("ctrlspace#keys#buffer#CollectUnsavedBuffers", "File", ["U"])
endfunction

function! ctrlspace#keys#file#SearchParentDirectory(k)
	call ctrlspace#search#SearchParentDirectoryCycle()
endfunction

function! ctrlspace#keys#file#ZoomMode(k)
	if !s:modes.Zoom.Enabled
		call ctrlspace#files#ZoomFile()
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

function! ctrlspace#keys#file#LoadFile(k)
	call ctrlspace#files#LoadFile()
endfunction

function! ctrlspace#keys#file#LoadManyFiles(k)
	call ctrlspace#files#LoadManyFiles()
endfunction

function! ctrlspace#keys#file#LoadFileVS(k)
	call ctrlspace#files#LoadFile("vs")
endfunction

function! ctrlspace#keys#file#LoadManyFilesVS(k)
	call ctrlspace#files#LoadManyFiles("vs")
endfunction

function! ctrlspace#keys#file#LoadFileSP(k)
	call ctrlspace#files#LoadFile("sp")
endfunction

function! ctrlspace#keys#file#LoadManyFilesSP(k)
	call ctrlspace#files#LoadManyFiles("sp")
endfunction

function! ctrlspace#keys#file#LoadFileT(k)
	call ctrlspace#files#LoadFile("tabnew")
endfunction

function! ctrlspace#keys#file#LoadManyFilesT(k)
	if s:modes.NextTab.Enabled
		call ctrlspace#files#LoadManyFiles("tabnext", "tabprevious")
	else
		call s:modes.NextTab.Enable()
		call ctrlspace#files#LoadManyFiles("tabnew", "tabprevious")
	endif
endfunction

function! ctrlspace#keys#file#LoadManyFilesCT(k)
	call s:modes.NextTab.Enable()
	call ctrlspace#files#LoadManyFiles("tabnew", "tabprevious")
endfunction

function! ctrlspace#keys#file#Refresh(k)
	call ctrlspace#files#RefreshFiles()
endfunction

function! ctrlspace#keys#file#EditFile(k)
	call ctrlspace#files#EditFile()
endfunction

function! ctrlspace#keys#file#ExploreDirectory(k)
	call ctrlspace#files#ExploreDirectory()
endfunction

function! ctrlspace#keys#file#GoToDirectory(k)
	call ctrlspace#files#GoToDirectory(a:k ==# "I")
endfunction

function! ctrlspace#keys#file#RemoveFile(k)
	call ctrlspace#files#RemoveFile()
endfunction

function! ctrlspace#keys#file#RenameFileOrBuffer(k)
	call ctrlspace#files#RenameFileOrBuffer()
endfunction

function! ctrlspace#keys#file#CopyFileOrBuffer(k)
	call ctrlspace#files#CopyFileOrBuffer()
endfunction
