let s:config         = ctrlspace#context#Configuration()
let s:modes          = ctrlspace#modes#Modes()
let s:keyNames       = []
let s:keyMap         = {}
let s:characters     = {}

function! ctrlspace#keys#KeyNames() abort
    return s:keyNames
endfunction

function! ctrlspace#keys#CharacterClasses() abort
    return s:characters
endfunction

function! ctrlspace#keys#KeyMap() abort
    return s:keyMap
endfunction

" Run by the <Esc>[ mapping of the plugin buffer in a terminal. Read the rest
" of the control sequence, so that none of its characters is taken for a key
" of its own, and press the key it encodes, if any. Hand terminal responses,
" such as the reply to Vim's keyboard protocol query, back to the editor.
function! ctrlspace#keys#EscSequence() abort
    let params = ""
    let final  = ""
    let waited = 0

    while waited <= 100
        let char = getcharstr(0)

        if empty(char)
            sleep 10m
            let waited += 10
        elseif char =~# '^[\x20-\x3f]$'
            let params .= char
        else
            let final = char
            break
        endif
    endwhile

    " Neovim parses terminal responses before they reach mappings.
    if params =~# '^[?>=<]'
        if !has("nvim")
            call feedkeys("\<Esc>[" . params . final, "nt")
        endif
        return
    endif

    let key = ctrlspace#keys#SequenceKey(params, final)

    if !empty(key) && index(s:keyNames, key) >= 0
        call ctrlspace#keys#Keypressed(key)
    endif
endfunction

" Return the name of the key encoded by the control sequence "<Esc>[" .
" a:params . a:final, or an empty string. Understands the shifted Tab and
" the key encoding of the kitty keyboard protocol that Vim enables in kitty,
" Ghostty, foot and WezTerm.
function! ctrlspace#keys#SequenceKey(params, final) abort
    if a:final ==# "Z" && empty(a:params)
        return "S-Tab"
    elseif a:final !=# "u" || a:params !~# '^\d\+\%(:\d*\)*\%(;\d*\%(:\d*\)\=\)\=\%(;[0-9:]*\)\=$'
        return ""
    endif

    let fields = split(a:params, ";", 1)
    let code   = str2nr(fields[0])
    let modstr = get(fields, 1, "")
    let mods   = empty(modstr) ? 0 : str2nr(modstr) - 1
    let event  = str2nr(get(split(modstr, ":", 1), 1, "1"))
    let shift  = and(mods, 1)
    let ctrl   = and(mods, 4)

    " Ignore key releases and other modifiers than Shift and Control.
    if event > 2 || and(mods, invert(5))
        return ""
    elseif code == 27 && !mods
        return "Esc"
    elseif code == 13 && !mods
        return "CR"
    elseif (code == 127 || code == 8) && !mods
        return "BS"
    elseif code == 9 && !ctrl
        return shift ? "S-Tab" : "Tab"
    elseif code == 32 && !shift
        return ctrl ? ((has("gui_running") || has("win32")) ? "C-Space" : "Nul") : "Space"
    elseif ctrl && !shift && (code >= 97 && code <= 122 || code == 94 || code == 93)
        return "C-" . nr2char(code)
    elseif !ctrl && code >= 33 && code <= 126
        return shift ? toupper(nr2char(code)) : nr2char(code)
    endif

    return ""
endfunction

function! ctrlspace#keys#Init() abort
    call s:initKeyNames()
    call s:initKeyMap()
    call ctrlspace#keys#common#Init()
    call ctrlspace#keys#help#Init()
    call ctrlspace#keys#nop#Init()
    call ctrlspace#keys#search#Init()
    call ctrlspace#keys#buffer#Init()
    call ctrlspace#keys#file#Init()
    call ctrlspace#keys#tab#Init()
    call ctrlspace#keys#workspace#Init()
    call ctrlspace#keys#bookmark#Init()
    call s:initCustomMappings()
    call ctrlspace#keys#nop#DbmdexInit()
endfunction

function! s:initCustomMappings() abort
    for m in ["Search", "Help", "Nop", "Buffer", "File", "Tab", "Workspace", "Bookmark"]
        if has_key(s:config.Keys, m)
            for [k, fn] in items(s:config.Keys[m])
                " normalize synomymous keynames Enter, Return and CR all to CR
                let k = (k ==? 'return' || k ==? 'enter' ? 'CR' : k)
                call ctrlspace#keys#AddMapping(fn, m, [k])
            endfor
        endif
    endfor
endfunction

function! s:initKeyNames() abort
    let lowercase = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
    let uppercase = toupper(lowercase)

    let controlList = []

    for l in split(lowercase, " ")
        call add(controlList, "C-" . l)
    endfor

    call add(controlList, "C-^")
    call add(controlList, "C-]")

    let controls = join(controlList, " ")

    let numbers  = "1 2 3 4 5 6 7 8 9 0"
    let punctuation = "; : , . < > [ ] { } ( ) ' ` ~ + - _ = ! @ # $ % ^ & * / \ " . 
                \ '"'
    let specials = "Space CR BS Tab S-Tab / ? C-f C-b C-u C-d C-h C-w " .
                 \ "Bar BSlash MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse " .
                 \ "Down Up Home End Left Right PageUp PageDown " .
                 \ "F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12"

    if !s:config.UseMouseAndArrowsInTerm || has("gui_running")
        let specials .= " Esc"
    endif

    let specials .= (has("gui_running") || has("win32")) ? " C-Space" : " Nul"

    let keyNames = split(join([lowercase, uppercase, controls, numbers, punctuation, specials], " "), " ")

    " won't work with leader mappings
    if ctrlspace#keys#IsDefaultKey()
        for i in range(len(keyNames))
            let fullKeyName = (strlen(keyNames[i]) > 1) ? ("<" . keyNames[i] . ">") : keyNames[i]

            if fullKeyName ==# ctrlspace#keys#DefaultKey()
                call remove(keyNames, i)
                break
            endif
        endfor
    endif

    let s:keyNames             = keyNames
    let s:characters.lowercase = split(lowercase, " ")
    let s:characters.uppercase = split(uppercase, " ")
    let s:characters.controls  = split(controls, " ")
    let s:characters.numbers   = split(numbers, " ")
    let s:characters.punctuation   = split(punctuation, " ")
    let s:characters.specials  = split(specials, " ")
endfunction

function! ctrlspace#keys#Undefined(k) abort
    call ctrlspace#ui#Msg("Key '" . a:k . "' doesn't work in this view.")
endfunction

function! s:initKeyMap() abort
    let Undefined = function("ctrlspace#keys#Undefined")
    let blankMap    = {}

    for k in s:keyNames
        let blankMap[k] = Undefined
    endfor

    for m in ["Search", "Help", "Nop", "Buffer", "File", "Tab", "Workspace", "Bookmark"]
        let s:keyMap[m] = copy(blankMap)
    endfor
endfunction

function! ctrlspace#keys#AddMapping(funcName, mapName, keys) abort
    let keys = []

    for entry in a:keys
        if has_key(s:characters, entry)
            call extend(keys, s:characters[entry])
        else
            call add(keys, entry)
        endif

        call ctrlspace#help#AddMapping(a:funcName, a:mapName, entry)
    endfor

    let FuncRef = function(a:funcName)

    for k in keys
        let s:keyMap[a:mapName][k] = FuncRef
    endfor
endfunction

function! ctrlspace#keys#Keypressed(key) abort
    if s:modes.Help.Enabled
        let mapName = "Help"
    elseif s:modes.Search.Enabled
        let mapName = "Search"
    elseif s:modes.Nop.Enabled
        let mapName = "Nop"
    else
        let mapName = ctrlspace#modes#CurrentListView().Name
    endif

    call s:keyMap[mapName][a:key](a:key)
endfunction

function! ctrlspace#keys#SetDefaultMapping(key, action) abort
    let s:defaultKey = a:key
    if !empty(s:defaultKey)
        if s:defaultKey ==? "<C-Space>" && !has("gui_running") && !has("win32")
            let s:defaultKey = "<Nul>"
        endif

        silent! exe 'nnoremap <unique><silent>' . s:defaultKey . ' ' . a:action
    endif
endfunction

function! ctrlspace#keys#IsDefaultKey() abort
    return exists("s:defaultKey")
endfunction

function! ctrlspace#keys#DefaultKey() abort
    return s:defaultKey
endfunction
