let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()
let s:files  = []
let s:items  = []

function! ctrlspace#files#Files()
    return s:files
endfunction

function! ctrlspace#files#ClearAll()
    let s:files = []
    let s:items = []
endfunction

function! ctrlspace#files#Items()
    return s:items
endfunction

function! ctrlspace#files#SelectedFileName()
    return s:modes.File.Enabled ? s:files[ctrlspace#window#SelectedIndex()] : ""
endfunction

function! ctrlspace#files#LoadFiles()
    if empty(s:files)
        let s:items = []

        " try to pick up files from cache
        call s:loadFilesFromCache()

        if empty(s:files)
            let action = "Collecting files..."
            call ctrlspace#uiMsg(action)

            let uniqueFiles = {}

            for fname in empty(s:config.GlobCommand) ? split(globpath('.', '**'), '\n') : split(system(s:config.GlobCommand), '\n')
                let fnameModified = fnamemodify(has("win32") ? substitute(fname, "\r$", "", "") : fname, ":.")

                if isdirectory(fnameModified) || (fnameModified =~# s:config.IgnoredFiles)
                    continue
                endif

                let uniqueFiles[fnameModified] = 1
            endfor

            let s:files = keys(uniqueFiles)
            call s:saveFilesInCache()
        else
            let action = "Loading files..."
            call ctrlspace#ui#Msg(action)
        endif

        let s:items = map(copy(s:files), '{ "index": v:key, "text": v:val, "indicators": "" }')

        redraw!

        call ctrlspace#ui#Msg(action . " Done (" . len(s:files) . ").")
    endif

    return s:files
endfunction

function! s:saveFilesInCache()
    let filename = ctrlspace#util#FilesCache()

    if empty(filename)
        return
    endif

    call writefile(s:files, filename)
endfunction

function! s:loadFilesFromCache()
    let filename = ctrlspace#util#FilesCache()

    if empty(filename) || !filereadable(filename)
        return
    endif

    let s:files = readfile(filename)
endfunction
