let ctrlspace#modes#Collection = {}

let s:noLists         = []
let s:lists           = []
let s:currentListView = {}

let ctrlspace#modes#Mode = {
      \ "Name":     "",
      \ "Enabled":  0,
      \ "Data":     {},
      \ "ListView": 0
}

function! ctrlspace#modes#Mode.new(name, listView, data) dict
  let instance          = copy(self)
  let instance.Name     = a:name
  let instance.Data     = a:data
  let instance.ListView = a:listView

  let ctrlspace#modes#Collection[name] = instance

  if a:listView
    call add(s:lists, instance)
  else
    call add(s:noLists, instance)
  endif

  return instance
endfunction

function! ctrlspace#modes#Mode.Enable() dict
  if self.ListView
    for mode in s:lists
      call mode.Disable()
    endfor

    let s:currentListView = self
  endif

  let self.Enabled = 1
endfunction

function! ctrlspace#modes#Mode.Disable() dict
  let self.Enabled = 0
endfunction

let ctrlspace#modes#Zoom      = ctrlspace#modes#Mode.new("Zoom", 0, { "OriginalBuffer": 0 })
let ctrlspace#modes#NextTab   = ctrlspace#modes#Mode.new("NextTab", 0, {})
let ctrlspace#modes#Search    = ctrlspace#modes#Mode.new("Search", 0, { "Letters": [], "NewSearchPerformed": 0, "Restored": 0, "HistoryIndex": -1 })
let ctrlspace#modes#Help      = ctrlspace#modes#Mode.new("Help", 0, {})
let ctrlspace#modes#Nop       = ctrlspace#modes#Mode.new("Nop", 0, {})
let ctrlspace#modes#Buffer    = ctrlspace#modes#Mode.new("Buffer", 1, { "SubMode": "single" })
let ctrlspace#modes#File      = ctrlspace#modes#Mode.new("File", 1, {})
let ctrlspace#modes#Tablist   = ctrlspace#modes#Mode.new("Tablist", 1, {})
let ctrlspace#modes#Workspace = ctrlspace#modes#Mode.new("Workspace", 1, { "SubMode": "load", "Active": { "Name": "", "Digest": "" } "LastActive": "", "LastBrowsed": 0 })
let ctrlspace#modes#Bookmark  = ctrlspace#modes#Mode.new("Bookmark", 1, { "Active": {} })

function! ctrlspace#modes#Enabled()
  let result = []

  for mode in values(ctrlspace#modes#Collection)
    if mode.Enabled
      call add(result, mode)
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
