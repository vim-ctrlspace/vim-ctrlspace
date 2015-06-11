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

function! s:initialize()
  call s:mode.new("Zoom", 0, { "OriginalBuffer": 0 })
  call s:mode.new("NextTab", 0, {})
  call s:mode.new("Search", 0, { "Letters": [], "NewSearchPerformed": 0, "Restored": 0, "HistoryIndex": -1 })
  call s:mode.new("Help", 0, {})
  call s:mode.new("Nop", 0, {})
  call s:mode.new("Buffer", 1, { "SubMode": "single" })
  call s:mode.new("File", 1, {})
  call s:mode.new("Tablist", 1, {})
  call s:mode.new("Workspace", 1, { "SubMode": "load", "Active": { "Name": "", "Digest": "" }, "LastActive": "", "LastBrowsed": 0 })
  call s:mode.new("Bookmark", 1, { "Active": {} })
endfunction

call s:initialize()

function! s:modeOrData(mode, args)
  if !empty(a:args)
    return s:collection[a:mode]["Data"][a:args[0]]
  else
    return s:collection[a:mode]
  endif
endfunction

function! ctrlspace#modes#Zoom(...)
  return s:modeOrData("Zoom", a:000)
endfunction

function! ctrlspace#modes#NextTab(...)
  return s:modeOrData("NextTab", a:000)
endfunction

function! ctrlspace#modes#Search(...)
  return s:modeOrData("Search", a:000)
endfunction

function! ctrlspace#modes#Help(...)
  return s:modeOrData("Help", a:000)
endfunction

function! ctrlspace#modes#Nop(...)
  return s:modeOrData("Nop", a:000)
endfunction

function! ctrlspace#modes#Buffer(...)
  return s:modeOrData("Buffer", a:000)
endfunction

function! ctrlspace#modes#File(...)
  return s:modeOrData("File", a:000)
endfunction

function! ctrlspace#modes#Tablist(...)
  return s:modeOrData("Tablist", a:000)
endfunction

function! ctrlspace#modes#Workspace(...)
  return s:modeOrData("Workspace", a:000)
endfunction

function! ctrlspace#modes#Bookmark(...)
  return s:modeOrData("Bookmark", a:000)
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
