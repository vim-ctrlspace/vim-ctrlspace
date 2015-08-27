let s:config = ctrlspace#context#Configuration()
let s:modes  = ctrlspace#modes#Modes()

let s:projectRoots       = {}
let s:lastProjectRoot    = ""
let s:currentProjectRoot = ""

function! ctrlspace#roots#ProjectRoots()
	return s:projectRoots
endfunction

function! ctrlspace#roots#SetProjectRoots(value)
	let s:projectRoots = a:value
	return s:projectRoots
endfunction

function! ctrlspace#roots#CurrentProjectRoot()
	return s:currentProjectRoot
endfunction

function! ctrlspace#roots#SetCurrentProjectRoot(value)
	let s:currentProjectRoot = a:value
	return s:currentProjectRoot
endfunction

function! ctrlspace#roots#LastProjectRoot()
	return s:lastProjectRoot
endfunction

function! ctrlspace#roots#SetLastProjectRoot(value)
	let s:lastProjectRoot = a:value
	return s:lastProjectRoot
endfunction

function! ctrlspace#roots#AddProjectRoot(directory)
	let directory = ctrlspace#util#NormalizeDirectory(fnamemodify(empty(a:directory) ? getcwd() : a:directory, ":p"))

	if !isdirectory(directory)
		call ctrlspace#ui#Msg("Invalid directory: '" . directory . "'")
		return
	endif

	let roots = copy(s:projectRoots)

	for bm in ctrlspace#bookmarks#Bookmarks()
		let roots[bm.Directory] = 1
	endfor

	if exists("roots[directory]")
		call ctrlspace#ui#Msg("Directory '" . directory . "' is already a permanent project root!")
		return
	endif

	call s:addProjectRoot(directory)
	call ctrlspace#ui#Msg("Directory '" . directory . "' has been added as a permanent project root.")
endfunction

function! ctrlspace#roots#RemoveProjectRoot(directory)
	let directory = ctrlspace#util#NormalizeDirectory(fnamemodify(empty(a:directory) ? getcwd() : a:directory, ":p"))

	if !exists("s:projectRoots[directory]")
		call ctrlspace#ui#Msg("Directory '" . directory . "' is not a permanent project root!" )
		return
	endif

	call s:removeProjectRoot(directory)
	call ctrlspace#ui#Msg("Project root '" . directory . "' has been removed.")
endfunction

function! s:removeProjectRoot(directory)
	let directory = ctrlspace#util#NormalizeDirectory(a:directory)

	if exists("s:projectRoots[directory]")
		unlet s:projectRoots[directory]
	endif

	let lines     = []
	let cacheFile = s:config.CacheDir . "/.cs_cache"

	if filereadable(cacheFile)
		for oldLine in readfile(cacheFile)
			if oldLine !~# "CS_PROJECT_ROOT: "
				call add(lines, oldLine)
			endif
		endfor
	endif

	for root in keys(s:projectRoots)
		call add(lines, "CS_PROJECT_ROOT: " . root)
	endfor

	call writefile(lines, cacheFile)
endfunction

function! s:addProjectRoot(directory)
	let directory = ctrlspace#util#NormalizeDirectory(a:directory)

	let s:projectRoots[directory] = 1

	let lines     = []
	let bmRoots   = {}
	let cacheFile = s:config.CacheDir . "/.cs_cache"

	for bm in ctrlspace#bookmarks#Bookmarks()
		let bmRoots[bm.Directory] = 1
	endfor

	if filereadable(cacheFile)
		for oldLine in readfile(cacheFile)
			if oldLine !~# "CS_PROJECT_ROOT: "
				call add(lines, oldLine)
			endif
		endfor
	endif

	for root in keys(s:projectRoots)
		if !exists("bmRoots[root]")
			call add(lines, "CS_PROJECT_ROOT: " . root)
		endif
	endfor

	call writefile(lines, cacheFile)
endfunction

function! ctrlspace#roots#FindProjectRoot()
	let projectRoot = fnamemodify(".", ":p:h")

	if !empty(s:config.ProjectRootMarkers)
		let rootFound     = 0
		let candidate     = fnamemodify(projectRoot, ":p:h")
		let lastCandidate = ""

		while candidate != lastCandidate
			for marker in s:config.ProjectRootMarkers
				let markerPath = candidate . "/" . marker
				if filereadable(markerPath) || isdirectory(markerPath)
					let rootFound = 1
					break
				endif
			endfor

			if !rootFound
				let rootFound = exists("s:projectRoots[candidate]")
			endif

			if rootFound
				let projectRoot = candidate
				break
			endif

			let lastCandidate = candidate
			let candidate = fnamemodify(candidate, ":p:h:h")
		endwhile

		return rootFound ? projectRoot : ""
	endif

	return projectRoot
endfunction

function! ctrlspace#roots#ProjectRootFound()
	if empty(s:currentProjectRoot)
		let s:currentProjectRoot = ctrlspace#roots#FindProjectRoot()

		if empty(s:currentProjectRoot)
			let projectRoot = ctrlspace#ui#GetInput("No project root found. Set the project root: ", fnamemodify(".", ":p:h"), "dir")

			if !empty(projectRoot) && isdirectory(projectRoot)
				call ctrlspace#files#ClearAll() " clear current files - force reload
				call s:addProjectRoot(projectRoot)
				let s:currentProjectRoot = projectRoot
			else
				call ctrlspace#ui#Msg("Cannot continue with the project root not set.")
				return 0
			endif
		endif
	endif
	return 1
endfunction
