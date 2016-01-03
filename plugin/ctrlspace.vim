" Vim-CtrlSpace - Vim Space Controller
" Maintainer: Szymon Wrozynski
" Version:    5.0.7
"
" The MIT License (MIT)

" Copyright (c) 2013-2015 Szymon Wrozynski <szymon@wrozynski.com> and Contributors
" BufferList plugin code parts - copyright (c) 2005 Robert Lillack <rob@lillack.de>

" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:

" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.

" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
"
" Usage:
" https://github.com/vim-ctrlspace/vim-ctrlspace/blob/master/README.md

scriptencoding utf-8

if exists("g:CtrlSpaceLoaded")
	finish
endif

let g:CtrlSpaceLoaded = 1
let s:errors = []

if &cp
	call add(s:errors, "CtrlSpace requires 'nocompatible' option enabled!")
endif

if !&hid
	call add(s:errors, "CtrlSpace requires 'hidden' option enabled!")
endif

if v:version < 703
	call add(s:errors, "CtrlSpace requires Vim 7.3 or higher!")
endif

if !empty(s:errors)
	echohl WarningMsg
	for msg in s:errors
		echom msg
	endfor
	echohl None

	finish
endif

call ctrlspace#init#Init()
