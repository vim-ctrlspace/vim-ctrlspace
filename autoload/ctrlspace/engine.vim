let s:config            = ctrlspace#context#Configuration()
let s:maxSearchedItems  = 200
let s:maxDisplayedItems = 500

" returns [patterns, indices, size, text]
function! ctrlspace#engine#Content()
  let items = s:contentSource()

  if !empty(s:config.Engine)
    return s:contentFromExternalEngine(s:config.Engine, items)
  endif

  if !empty(ctrlspace#modes#Search("Letters"))
    let items = s:computeLowestNoises(items, s:maxSearchedItems)
    call sort(items, function("ctrlspace#engine#CompareByNoiseAndText"))
  else
    if len(items) > s:maxDisplayedItems
      let items = items[0, s:maxDisplayedItems - 1]
    endif

    if ctrlspace#modes#Tablist().Enabled
      call sort(items, function("ctrlspace#engine#CompareByIndex"))
    else
      call sort(items, function("ctrlspace#engine#CompareByText"))
    endif
  endif

  " trim the list in search mode
  if ctrlspace#modes#Search().Enabled
    let maxHeight = ctrlspace#window#MaxHeight()

    if len(items) > maxHeight
      let items = items[-maxHeight: -1]
    endif
  endif

  return s:prepareContent(items)
endfunction

function! s:contentFromExternalEngine(engine, items)
  let engineCommand = ctrlspace#context#PluginFolder() . "/bin/" . a:engine
  let engineData = [s:vimContextJSON()]

  if ctrlspace#modes#File().Enabled
    call add(engineData, a:items[0].path])
  else
    for item in a:items
      call add(engineData, '{"Index":' . item.index, ',"Text":"' .
            \ escape(item.text, '"') '", "Indicators": "' .
            \ escape(item.indicators, '"') . '"}')
    endfor
  endif

  let results  = split(system(engineCommand, engineData), "\n")
  let patterns = eval(results[0])
  let indices  = eval(results[1])
  let size     = str2nr(results[2])
  let text     = join(results[3:], "\n")

  return [patterns, indices, size, text]
endfunction

function! ctrlspace#engine#CompareByText(a, b)
  if a:a.text < a:b.text
    return -1
  elseif a:a.text > a:b.text
    return 1
  else
    return 0
  endif
endfunction

function! ctrlspace#engine#CompareByIndex(a, b)
  if a:a.index < a:b.index
    return -1
  elseif a:a.index > a:b.index
    return 1
  else
    return 0
  endif
endfunction

function! ctrlspace#engine#CompareByNoiseAndText(a, b)
  if a:a.noise < a:b.noise
    return 1
  elseif a:a.noise > a:b.noise
    return -1
  elseif strlen(a:a.text) < strlen(a:b.text)
    return 1
  elseif strlen(a:a.text) > strlen(a:b.text)
    return -1
  elseif a:a.text < a:b.text
    return -1
  elseif a:a.text > a:b.text
    return 1
  else
    return 0
  endif
endfunction

function! s:computeLowestNoises(source, maxItems)
  let results       = []
  let noises        = []
  let resultsCount  = 0
  let maxNoiseValue = -1
  let maxNoiseIndex = -1

  for index in range(0, len(a:source) - 1)
    let item = a:source[index]
    let [noise, pattern] = s:findLowestSearchNoise(item.text)

    if noise == -1
      continue
    else
      let item.noise   = noise
      let item.pattern = pattern

      if resultsCount < a:maxItems
        call insert(results, item, resultsCount)
        call insert(noises, noise, resultsCount)

        if noise > maxNoiseValue
          let maxNoiseValue = noise
          let maxNoiseIndex = resultsCount
        endif

        let resultsCount += 1
      elseif noise < maxNoiseValue
        call insert(results, item, maxNoiseIndex)
        call insert(noises, noise, maxNoiseIndex)

        let maxNoiseValue = max(noises)
        let maxNoiseIndex = index(noises, maxNoiseValue)
      endif
    endif
  endfor

  return results
endfunction

function! s:vimContextJSON()
  let sm = ctrlspace#modes#Search()
  return '{"CurrentListView":"' . ctrlspace#modes#CurrentListView() .
        \ '","SearchModeEnabled":' . sm.Enabled .
        \ ',"SearchText":"' . join(sm.Data.Letters, "") .
        \ '","Columns":' . &columns . ',"MaxHeight":' . ctrlspace#window#MaxHeight()
        \ ',"MaxSearchedItems":' . s:maxSearchedItems . ',"MaxDisplayedItems":' .
        \  s:maxDisplayedItems . '}'
endfunction

function! s:contentSource()
  let clv = ctrlspace#modes#CurrentListView()

  if clv.Name ==# "Buffer"
    return s:bufferListContent(clv)
  elseif clv.Name ==# "File"
    return s:fileListContent(clv)
  elseif clv.Name ==# "Tablist"
    return s:tabListContent(clv)
  elseif clv.Name ==# "Workspace"
    return s:workspaceListContent(clv)
  elseif clv.Name ==# "Bookmark"
    return s:bookmarkListContent(clv)
  endif
endfunction

function! s:bookmarkListContent(clv)
  let content = []

  for i in range(0, len(ctrlspace#bookmarks#Bookmarks()) - 1)
    let bm         = ctrlspace#content#Bookmarks(i)
    let indicators = ""

    if !empty(a:clv.Data.Active) && (bm.Directory ==# a:clv.Data.Active.Directory)
      let indicators .= s:config.Symbols.IA
    endif

    call add(content, { "index": i, "text": bm.Name, "indicators": indicators })
  endfor

  return content
endfunction

function! s:workspaceListContent(clv)
  let content    = []

  for i in range(0, len(ctrlspace#workspaces#Workspaces()) - 1)
    let name = ctrlspace#workspaces#Workspaces(i)
    let indicators = ""

    if name ==# a:clv.Data.Active.Name
      if a:clv.Data.Active.Digest !=# ctrlspace#workspaces#CreateDigest()
        let indicators .= s:config.Symbols.IM
      endif

      let indicators .= s:config.Symbols.IA
    elseif name ==# a:clv.Data.LastActive
      let indicators .= s:config.Symbols.IV
    endif

    call add(content, { "index": i, "text": name, "indicators": indicators })
  endfor

  return content
endfunction

function! s:tabListContent(clv)
  let content    = []
  let currentTab = tabpagenr()

  for i in range(1, tabpagenr("$"))
    let winnr         = tabpagewinnr(i)
    let buflist       = tabpagebuflist(i)
    let bufnr         = buflist[winnr - 1]
    let bufname       = bufname(bufnr)
    let tabBufsNumber = ctrlspace#api#TabBuffersNumber(i)
    let title         = ctrlspace#api#TabTitle(i, bufnr, bufname)

    if !s:config.UnicodeFont && !empty(tabBufsNumber)
      let tabBufsNumber = ":" . tabBufsNumber
    endif

    let indicators = ""

    if ctrlspace#api#TabModified(i)
      let indicators .= s:config.Symbols.IM
    endif

    if i == currentTab
      let indicators .= s:config.Symbols.IA
    endif

    call add(content, { "index": i, "text": string(i) . tabBufsNumber . " " . title, "indicators": indicators })
  endfor

  return content
endfunction

function! s:fileListContent(clv)
  if !empty(s:config.Engine)
    call ctrlspace#files#Files()
    return [{ "path": fnamemodify(ctrlspace#util#FilesCache(), ":p") }]
  else
    return copy(ctrlspace#files#FileItems())
  endif
endfunction

function! s:bufferListContent(clv)
  let content = []

  if a:clv.Data.SubMode ==# "single"
    let buffers = map(keys(ctrlspace#buffers#Buffers(tabpagenr())), "str2nr(v:val)")
  elseif a:clv.Data.SubMode ==# "all"
    let buffers = map(keys(ctrlspace#buffers#Buffers(0)), "str2nr(v:val)")
  elseif a:clv.Data.SubMode ==# "visual"
    let buffers = tabpagebuflist()
  endif

  for i in buffers
    let entry = s:bufferEntry(i)
    if !empty(entry)
      call add(content, entry)
    endif
  endfor

  return content
endfunction

function! s:bufferEntry(bufnr)
  let bufname  = fnamemodify(bufname(a:bufnr), ":.")
  let modified = getbufvar(a:bufnr, "&modified")
  let winnr    = bufwinnr(a:bufnr)

  if !strlen(bufname) && (modified || (winnr != -1))
    let bufname = "[" . a:bufnr . "*No Name]"
  endif

  if strlen(bufname) && getbufvar(a:bufnr, "&modifiable")
    let indicators = ""

    if modified
      let indicators .= s:config.Symbols.IM
    endif

    if winnr == t:CtrlSpaceStartWindow
      let indicators .= s:config.Symbols.IA
    elseif winnr != -1
      let indicators .= s:config.Symbols.IV
    endif

    return { "index": a:bufnr, "text": bufname, "indicators": indicators }
  else
    return {}
  endif
endfunction

function! s:findSubsequence(searchLetters, text, offset)
  let positions     = []
  let noise         = 0
  let currentOffset = a:offset

  for letter in a:searchLetters
    let matchedPosition = match(a:text, "\\m\\c" . letter, currentOffset)

    if matchedPosition == -1
      return [-1, []]
    else
      if !empty(positions)
        let noise += abs(matchedPosition - positions[-1]) - 1
      endif
      call add(positions, matchedPosition)
      let currentOffset = matchedPosition + 1
    endif
  endfor

  return [noise, positions]
endfunction

function! s:findLowestSearchNoise(text)
  let searchLetters      = ctrlspace#modes#Search("Letters")
  let searchLettersCount = len(searchLetters)
  let noise              = -1
  let matchedString      = ""

  if searchLettersCount == 1
    let noise         = match(a:text, "\\m\\c" . searchLetters[0])
    let matchedString = searchLetters[0]
  else
    let offset   = 0
    let text_len = strlen(a:text)

    while offset < text_len
      let subseq = s:findSubsequence(searchLetters, a:text, offset)

      if subseq[0] == -1
        break
      elseif (noise == -1) || (subseq[0] < noise)
        let noise         = subseq[0]
        let offset        = subseq[1][0] + 1
        let matchedString = a:text[subseq[1][0]:subseq[1][-1]]

        if !empty(s:config.SearchResonators)
          if subseq[1][0] != 0
            let noise += 1

            if index(s:config.SearchResonators, a:text[subseq[1][0] - 1]) == -1
              let noise += 1
            endif
          endif

          if subseq[1][-1] != text_len - 1
            let noise += 1

            if index(s:config.SearchResonators, a:text[subseq[1][-1] + 1]) == -1
              let noise += 1
            endif
          endif
        endif
      else
        let offset += 1
      endif
    endwhile
  endif

  let pattern = ""

  if (noise > -1) && !empty(matchedString)
    let pattern = matchedString
  endif

  return [noise, pattern]
endfunction

function! s:prepareContent(items)
  if ctrlspace#modes#File().Enabled
    let itemSpace = 5
  elseif ctrlspace#modes#Bookmark().Enabled
    let itemSpace = 5 + ctrlspace#context#SymbolSizes("IAV")
  else
    let itemSpace = 5 + ctrlspace#context#SymbolSizes("IAV") + ctrlspace#context#SymbolSizes("IM")
  endif

  let content  = ""
  let patterns = {}
  let indices  = []

  for item in a:items
    let line = item.text

    if strwidth(line) + itemSpace > &columns
      let line = s:config.Symbols.Dots . strpart(line, strwidth(line) - &columns + itemSpace + ctrlspace#context#SymbolSizes("Dots"))
    endif

    if !empty(item.indicators)
      let line .= " " . item.indicators
    endif

    while strwidth(line) < &columns
      let line .= " "
    endwhile

    let content .= "  " . line . "\n"

    if exists("item.pattern")
      let patterns[item.pattern] = 1
    endif

    call add(indices, item.index)
  endfor

  return [keys(patterns), indices, len(a:items), content]
endfunction
