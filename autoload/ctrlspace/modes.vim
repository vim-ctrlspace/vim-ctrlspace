let s:collection      = {}
let s:noLists         = []
let s:lists           = []
let s:currentListView = {}

let s:mode = {
	\ "Name":     "",
	\ "Enabled":  0,
	\ "Data":     {},
	\ "ListView": 0
	\ }

function! s:mode.new(name, listView, data) dict
	let instance          = copy(self)
	let instance.Name     = a:name
	let instance.Data     = a:data
	let instance.ListView = a:listView

	let s:collection[a:name] = instance

	if a:listView
		call add(s:lists, instance)
	else
		call add(s:noLists, instance)
	endif

	return instance
endfunction

function! s:mode.SetData(key, value) dict
	let self.Data[a:key] = a:value
	return a:value
endfunction

function! s:mode.HasData(key) dict
	return has_key(self.Data, a:key)
endfunction

function! s:mode.RemoveData(key) dict
	if self.HasData(a:key)
		call remove(self.Data, a:key)
		return 1
	endif
	return 0
endfunction

function! s:mode.Enable() dict
	if self.ListView
		for m in s:lists
			call m.Disable()
		endfor

		let s:currentListView = self
	endif

	let self.Enabled = 1
endfunction

function! s:mode.Disable() dict
	let self.Enabled = 0
endfunction

function! s:init()
	call s:mode.new("Zoom", 0, { "Buffer": 0, "Mode": "", "SubMode": "", "Line": "", "Letters": [] })
	call s:mode.new("NextTab", 0, {})
	call s:mode.new("Search", 0, { "Letters": [], "NewSearchPerformed": 0, "Restored": 0, "HistoryIndex": -1 })
	call s:mode.new("Help", 0, {})
	call s:mode.new("Nop", 0, {})
	call s:mode.new("Buffer", 1, { "SubMode": "single" })
	call s:mode.new("File", 1, {})
	call s:mode.new("Tab", 1, {})
	call s:mode.new("Workspace", 1, { "SubMode": "load", "Active": { "Name": "", "Digest": "", "Root": "" }, "LastActive": "", "LastBrowsed": 0 })
	call s:mode.new("Bookmark", 1, { "Active": {} })
endfunction

call s:init()

function! ctrlspace#modes#Modes()
	return s:collection
endfunction

function! ctrlspace#modes#Enabled()
	let result = []

	for m in values(s:collection)
		if m.Enabled
			call add(result, m)
		endif
	endfor

	return result
endfunction

function! ctrlspace#modes#ListViews()
	return s:lists
endfunction

function! ctrlspace#modes#CurrentListView()
	return s:currentListView
endfunction
