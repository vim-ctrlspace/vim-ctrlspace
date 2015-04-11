let g:ctrlspace#modes#Collection = {}

let s:noLists         = []
let s:lists           = []
let s:currentListView = {}

let g:ctrlspace#modes#Mode = {
      \ "Name":     "",
      \ "Enabled":  0,
      \ "Data":     {},
      \ "ListView": 0
      \ }

function! g:ctrlspace#modes#Mode.new(name, listView, data) dict
  let instance          = copy(self)
  let instance.Name     = a:name
  let instance.Data     = a:data
  let instance.ListView = a:listView

  let g:ctrlspace#modes#Collection[a:name] = instance

  if a:listView
    call add(s:lists, instance)
  else
    call add(s:noLists, instance)
  endif

  return instance
endfunction

function! g:ctrlspace#modes#Mode.Enable() dict
  if self.ListView
    for mode in s:lists
      call mode.Disable()
    endfor

    let s:currentListView = self
  endif

  let self.Enabled = 1
endfunction

function! g:ctrlspace#modes#Mode.Disable() dict
  let self.Enabled = 0
endfunction

let g:ctrlspace#modes#Zoom      = g:ctrlspace#modes#Mode.new("Zoom", 0, { "OriginalBuffer": 0 })
let g:ctrlspace#modes#NextTab   = g:ctrlspace#modes#Mode.new("NextTab", 0, {})
let g:ctrlspace#modes#Search    = g:ctrlspace#modes#Mode.new("Search", 0, { "Letters": [], "NewSearchPerformed": 0, "Restored": 0, "HistoryIndex": -1 })
let g:ctrlspace#modes#Help      = g:ctrlspace#modes#Mode.new("Help", 0, {})
let g:ctrlspace#modes#Nop       = g:ctrlspace#modes#Mode.new("Nop", 0, {})
let g:ctrlspace#modes#Buffer    = g:ctrlspace#modes#Mode.new("Buffer", 1, { "SubMode": "single" })
let g:ctrlspace#modes#File      = g:ctrlspace#modes#Mode.new("File", 1, {})
let g:ctrlspace#modes#Tablist   = g:ctrlspace#modes#Mode.new("Tablist", 1, {})
let g:ctrlspace#modes#Workspace = g:ctrlspace#modes#Mode.new("Workspace", 1, { "SubMode": "load", "Active": { "Name": "", "Digest": "" }, "LastActive": "", "LastBrowsed": 0 })
let g:ctrlspace#modes#Bookmark  = g:ctrlspace#modes#Mode.new("Bookmark", 1, { "Active": {} })

function! g:ctrlspace#modes#Enabled()
  let result = []

  for mode in values(g:ctrlspace#modes#Collection)
    if mode.Enabled
      call add(result, mode)
    endif
  endfor

  return result
endfunction

function! g:ctrlspace#modes#ListViews()
  return s:lists
endfunction

function! g:ctrlspace#modes#CurrentListView()
  return s:currentListView
endfunction
