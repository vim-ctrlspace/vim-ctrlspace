let s:config = g:ctrlspace#context#Configuration.Instance()
let g:ctrlspace#workspaces#Workspaces = []

function! ctrlspace#workspaces#SetWorkspaceNames()
  let filename                                  = ctrlspace#util#WorkspaceFile()
  let g:ctrlspace#modes#Workspace.Data.LastActive = ""
  let g:ctrlspace#workspaces#Workspaces              = []

  if filereadable(filename)
    for line in readfile(filename)
      if line =~? "CS_WORKSPACE_BEGIN: "
        call add(g:ctrlspace#workspaces#Workspaces, line[20:])
      elseif line =~? "CS_LAST_WORKSPACE: "
        let g:ctrlspace#modes#Workspace.Data.LastActive = line[19:]
      endif
    endfor
  endif
endfunction

function! ctrlspace#workspaces#SetActiveWorkspaceName(name)
  let g:ctrlspace#modes#Workspace.Data.Active.Name = a:name
  let g:ctrlspace#modes#Workspace.Data.LastActive  = a:name

  let filename = ctrlspace#util#WorkspaceFile()
  let lines    = []

  if filereadable(filename)
    for line in readfile(filename)
      if !(line =~? "CS_LAST_WORKSPACE: ")
        call add(lines, line)
      endif
    endfor
  endif

  if !empty(g:ctrlspace#modes#Workspace.Data.Active.Name)
    call insert(lines, "CS_LAST_WORKSPACE: " . g:ctrlspace#modes#Workspace.Data.Active.Name)
  endif

  call writefile(lines, filename)
endfunction

function! ctrlspace#workspaces#GetSelectedWorkspaceName()
  return g:ctrlspace#workspaces#Workspaces[ctrlspace#window#SelectedIndex()]
endfunction

function! ctrlspace#workspaces#SaveWorkspace(name)
  if !ctrlspace#roots#ProjectRootFound()
    return
  endif

  call ctrlspace#util#HandleVimSettings("start")

  let cwdSave = fnamemodify(".", ":p:h")
  silent! exe "cd " . g:ctrlspace#roots#ProjectRoot

  if empty(a:name)
    if !empty(g:ctrlspace#modes#Workspace.Data.Active.Name)
      let name = g:ctrlspace#modes#Workspace.Data.Active.Name
    else
      silent! exe "cd " . cwdSave
      call ctrlspace#util#HandleVimSettings("stop")
      return
    endif
  else
    let name = a:name
  endif

  let filename = ctrlspace#util#WorkspaceFile()
  let lastTab  = tabpagenr("$")

  let lines       = []
  let inWorkspace = 0

  let workspaceStartMarker = "CS_WORKSPACE_BEGIN: " . name
  let workspaceEndMarker   = "CS_WORKSPACE_END: " . name

  if filereadable(filename)
    for oldLine in readfile(filename)
      if oldLine ==# workspaceStartMarker
        let inWorkspace = 1
      endif

      if !inWorkspace
        call add(lines, oldLine)
      endif

      if oldLine ==# workspaceEndMarker
        let inWorkspace = 0
      endif
    endfor
  endif

  call add(lines, workspaceStartMarker)

  let ssopSave = &ssop
  set ssop=winsize,tabpages,buffers,sesdir

  let tabData = []

  for t in range(1, lastTab)
    let data = {
          \ "label": gettabvar(t, "CtrlSpaceLabel"),
          \ "autotab": ctrlspace#util#GettabvarWithDefault(t, "CtrlSpaceAutotab", 0)
          \ }

    let ctrlspaceList = ctrlspace#api#Buffers(t)

    let bufs = []

    for [nr, bname] in items(ctrlspaceList)
      let bufname = fnamemodify(bname, ":.")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor

    let data.bufs = bufs
    call add(tabData, data)
  endfor

  silent! exe "mksession! CS_SESSION"

  if !filereadable("CS_SESSION")
    silent! exe "cd " . cwdSave
    silent! exe "set ssop=" . ssopSave

    call ctrlspace#util#HandleVimSettings("stop")
    call ctrlspace#ui#Msg("The workspace '" . name . "' cannot be saved at this moment.")
    return
  endif

  let tabIndex = 0

  for cmd in readfile("CS_SESSION")
    if ((cmd =~# "^edit") && (tabIndex == 0)) || (cmd =~# "^tabnew") || (cmd =~# "^tabedit")
      let data = tabData[tabIndex]

      if tabIndex > 0
        call add(lines, cmd)
      endif

      for b in data.bufs
        call add(lines, "edit " . b)
      endfor

      if !empty(data.label)
        call add(lines, "let t:CtrlSpaceLabel = '" . substitute(data.label, "'", "''","g") . "'")
      endif

      if !empty(data.autotab)
        call add(lines, "let t:CtrlSpaceAutotab = " . data.autotab)
      endif

      if tabIndex == 0
        call add(lines, cmd)
      elseif cmd =~# "^tabedit"
        call add(lines, cmd[3:]) "make edit from tabedit
      endif

      let tabIndex += 1
    else
      let baddList = matchlist(cmd, "\\m^badd \+\\d* \\(.*\\)$")

      if !(exists("baddList[1]") && !empty(baddList[1]) && !filereadable(baddList[1]))
        call add(lines, cmd)
      endif
    endif
  endfor

  call add(lines, workspaceEndMarker)

  call writefile(lines, filename)
  call delete("CS_SESSION")

  call ctrlspace#workspaces#SetActiveWorkspaceName(name)
  let g:ctrlspace#mode#Workspace.Data.Active.Digest = ctrlspace#workspaces#CreateWorkspaceDigest()

  call ctrlspace#workspaces#SetWorkspaceNames()

  silent! exe "cd " . cwdSave
  silent! exe "set ssop=" . ssopSave

  call ctrlspace#util#HandleVimSettings("stop")
  call ctrlspace#ui#Msg("The workspace '" . name . "' has been saved.")
endfunction

function! ctrlspace#workspaces#CreateDigest()
  let useNossl = exists("b:nosslSave") && b:nosslSave

  if useNossl
    set nossl
  endif

  let cpoSave = &cpo

  set cpo&vim

  let lines = []

  for t in range(1, tabpagenr("$"))
    let line     = [t, gettabvar(t, "CtrlSpaceLabel")]
    let bufs     = []
    let visibles = []

    let tabBuffers = ctrlspace#api#Buffers(t)

    for bname in values(tabBuffers)
      let bufname = fnamemodify(bname, ":p")

      if !filereadable(bufname)
        continue
      endif

      call add(bufs, bufname)
    endfor

    for visibleBuf in tabpagebuflist(t)
      if exists("tabBuffers[visibleBuf]")
        let bufname = fnamemodify(tabBuffers[visibleBuf], ":p")

        if !filereadable(bufname)
          continue
        endif

        call add(visibles, bufname)
      endif
    endfor

    call add(line, join(bufs, "|"))
    call add(line, join(visibles, "|"))
    call add(lines, join(line, ","))
  endfor

  let md5 = s:MD5Digest(s:str2bytes(join(lines, "&&&")))

  if useNossl
    set ssl
  endif

  let &cpo = cpoSave

  return md5
endfunction

function! s:MD5Digest(str)
  let context = deepcopy(s:MD5_CTX, 1)
  let digest = repeat([0], 16)

  call s:MD5Init(context)
  call s:MD5Update(context, a:str, len(a:str))
  call s:MD5Final(digest, context)

  return join(map(digest, 'printf("%02x", v:val)'), '')
endfunction

" MD5.H - header file for MD5C.C

" MD5 context.
let s:MD5_CTX = {}
let s:MD5_CTX.state = repeat([0], 4)    " state (ABCD)
let s:MD5_CTX.count = repeat([0], 2)    " number of bits, modulo 2^64 (lsb first)
let s:MD5_CTX.buffer = repeat([0], 64)  " input buffer

" MD5C.C - RSA Data Security, Inc., MD5 message-digest algorithm

" Constants for MD5Transform routine.

let s:S11 = 7
let s:S12 = 12
let s:S13 = 17
let s:S14 = 22
let s:S21 = 5
let s:S22 = 9
let s:S23 = 14
let s:S24 = 20
let s:S31 = 4
let s:S32 = 11
let s:S33 = 16
let s:S34 = 23
let s:S41 = 6
let s:S42 = 10
let s:S43 = 15
let s:S44 = 21

let s:PADDING = [
      \ 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      \ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      \ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      \ ]

" F, G, H and I are basic MD5 functions.

" (x & y) | (~x & z)
function! s:F(x, y, z)
  return s:bitwise_or(s:bitwise_and(a:x, a:y), s:bitwise_and(s:bitwise_not(a:x), a:z))
endfunction

" (x & z) | (y & ~z)
function! s:G(x, y, z)
  return s:bitwise_or(s:bitwise_and(a:x, a:z), s:bitwise_and(a:y, s:bitwise_not(a:z)))
endfunction

" x ^ y ^ z
function! s:H(x, y, z)
  return s:bitwise_xor(s:bitwise_xor(a:x, a:y), a:z)
endfunction

" y ^ (x | ~z)
function! s:I(x, y, z)
  return s:bitwise_xor(a:y, s:bitwise_or(a:x, s:bitwise_not(a:z)))
endfunction

" ROTATE_LEFT rotates x left n bits.
" (x << n) | (x >> (32 - n))
function! s:ROTATE_LEFT(x, n)
  return s:bitwise_or(s:bitwise_lshift(a:x, a:n), s:bitwise_rshift(a:x, 32 - a:n))
endfunction

" FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
" Rotation is separate from addition to prevent recomputation.

function! s:FF(a, b, c, d, x, s, ac)
  let a = a:a
  let a = a + s:F(a:b, a:c, a:d) + a:x + a:ac
  let a = s:ROTATE_LEFT(a, a:s)
  let a = a + a:b
  return a
endfunction

function! s:GG(a, b, c, d, x, s, ac)
  let a = a:a
  let a = a + s:G(a:b, a:c, a:d) + a:x + a:ac
  let a = s:ROTATE_LEFT(a, a:s)
  let a = a + a:b
  return a
endfunction

function! s:HH(a, b, c, d, x, s, ac)
  let a = a:a
  let a = a + s:H(a:b, a:c, a:d) + a:x + a:ac
  let a = s:ROTATE_LEFT(a, a:s)
  let a = a + a:b
  return a
endfunction

function! s:II(a, b, c, d, x, s, ac)
  let a = a:a
  let a = a + s:I(a:b, a:c, a:d) + a:x + a:ac
  let a = s:ROTATE_LEFT(a, a:s)
  let a = a + a:b
  return a
endfunction

" MD5 initialization. Begins an MD5 operation, writing a new context.
function! s:MD5Init(context)
  let context = a:context

  let context.count[0] = 0
  let context.count[1] = 0
  " Load magic initialization constants.
  let context.state[0] = 0x67452301
  let context.state[1] = 0xefcdab89
  let context.state[2] = 0x98badcfe
  let context.state[3] = 0x10325476
endfunction

" MD5 block update operation. Continues an MD5 message-digest
" operation, processing another message block, and updating the
" context.
function! s:MD5Update(context, input, inputLen)
  let context = a:context
  let input = a:input
  let inputLen = a:inputLen

  " Compute number of bytes mod 64
  let index = s:bitwise_and(s:bitwise_rshift(context.count[0], 3), 0x3F)

  " Update number of bits
  let context.count[0] += s:bitwise_lshift(inputLen, 3)
  if s:cmp(context.count[0], s:bitwise_lshift(inputLen, 3)) < 0
    let context.count[1] += 1
  endif
  let context.count[1] += s:bitwise_rshift(inputLen, 29)

  let partLen = 64 - index

  " Transform as many times as possible.
  if inputLen >= partLen
    call s:MD5_memcpy(context.buffer, index, input, partLen)
    call s:MD5Transform(context.state, context.buffer)

    let i = partLen
    while i + 63 < inputLen
      call s:MD5Transform(context.state, input[i :])
      let i += 64
    endwhile

    let index = 0
  else
    let i = 0
  endif

  " Buffer remaining input */
  call s:MD5_memcpy(context.buffer, index, input[i :], inputLen - i)
endfunction

" MD5 finalization. Ends an MD5 message-digest operation, writing the
" the message digest and zeroizing the context.
function! s:MD5Final(digest, context)
  let digest = a:digest
  let context = a:context

  let bits = repeat([0], 8)

  " Save number of bits
  call s:Encode(bits, context.count, 8)

  " Pad out to 56 mod 64.
  let index = s:bitwise_and(s:bitwise_rshift(context.count[0], 3), 0x3f)
  let padLen = (index < 56) ? (56 - index) : (120 - index)
  call s:MD5Update(context, s:PADDING, padLen)

  " Append length (before padding)
  call s:MD5Update(context, bits, 8)

  call s:Encode(digest, context.state, 16)

  " Zeroize sensitive information.
  "MD5_memset ((POINTER)context, 0, sizeof (*context));
endfunction

" MD5 basic transformation. Transforms state based on block.
function! s:MD5Transform(state, block)
  let state = a:state
  let block = a:block

  let a = state[0]
  let b = state[1]
  let c = state[2]
  let d = state[3]
  let x = repeat([0], 16)

  call s:Decode(x, block, 64)

  " Round 1
  let a = s:FF(a, b, c, d, x[ 0], s:S11, 0xd76aa478) " 1
  let d = s:FF(d, a, b, c, x[ 1], s:S12, 0xe8c7b756) " 2
  let c = s:FF(c, d, a, b, x[ 2], s:S13, 0x242070db) " 3
  let b = s:FF(b, c, d, a, x[ 3], s:S14, 0xc1bdceee) " 4
  let a = s:FF(a, b, c, d, x[ 4], s:S11, 0xf57c0faf) " 5
  let d = s:FF(d, a, b, c, x[ 5], s:S12, 0x4787c62a) " 6
  let c = s:FF(c, d, a, b, x[ 6], s:S13, 0xa8304613) " 7
  let b = s:FF(b, c, d, a, x[ 7], s:S14, 0xfd469501) " 8
  let a = s:FF(a, b, c, d, x[ 8], s:S11, 0x698098d8) " 9
  let d = s:FF(d, a, b, c, x[ 9], s:S12, 0x8b44f7af) " 10
  let c = s:FF(c, d, a, b, x[10], s:S13, 0xffff5bb1) " 11
  let b = s:FF(b, c, d, a, x[11], s:S14, 0x895cd7be) " 12
  let a = s:FF(a, b, c, d, x[12], s:S11, 0x6b901122) " 13
  let d = s:FF(d, a, b, c, x[13], s:S12, 0xfd987193) " 14
  let c = s:FF(c, d, a, b, x[14], s:S13, 0xa679438e) " 15
  let b = s:FF(b, c, d, a, x[15], s:S14, 0x49b40821) " 16

  " Round 2
  let a = s:GG(a, b, c, d, x[ 1], s:S21, 0xf61e2562) " 17
  let d = s:GG(d, a, b, c, x[ 6], s:S22, 0xc040b340) " 18
  let c = s:GG(c, d, a, b, x[11], s:S23, 0x265e5a51) " 19
  let b = s:GG(b, c, d, a, x[ 0], s:S24, 0xe9b6c7aa) " 20
  let a = s:GG(a, b, c, d, x[ 5], s:S21, 0xd62f105d) " 21
  let d = s:GG(d, a, b, c, x[10], s:S22,  0x2441453) " 22
  let c = s:GG(c, d, a, b, x[15], s:S23, 0xd8a1e681) " 23
  let b = s:GG(b, c, d, a, x[ 4], s:S24, 0xe7d3fbc8) " 24
  let a = s:GG(a, b, c, d, x[ 9], s:S21, 0x21e1cde6) " 25
  let d = s:GG(d, a, b, c, x[14], s:S22, 0xc33707d6) " 26
  let c = s:GG(c, d, a, b, x[ 3], s:S23, 0xf4d50d87) " 27
  let b = s:GG(b, c, d, a, x[ 8], s:S24, 0x455a14ed) " 28
  let a = s:GG(a, b, c, d, x[13], s:S21, 0xa9e3e905) " 29
  let d = s:GG(d, a, b, c, x[ 2], s:S22, 0xfcefa3f8) " 30
  let c = s:GG(c, d, a, b, x[ 7], s:S23, 0x676f02d9) " 31
  let b = s:GG(b, c, d, a, x[12], s:S24, 0x8d2a4c8a) " 32

  " Round 3
  let a = s:HH(a, b, c, d, x[ 5], s:S31, 0xfffa3942) " 33
  let d = s:HH(d, a, b, c, x[ 8], s:S32, 0x8771f681) " 34
  let c = s:HH(c, d, a, b, x[11], s:S33, 0x6d9d6122) " 35
  let b = s:HH(b, c, d, a, x[14], s:S34, 0xfde5380c) " 36
  let a = s:HH(a, b, c, d, x[ 1], s:S31, 0xa4beea44) " 37
  let d = s:HH(d, a, b, c, x[ 4], s:S32, 0x4bdecfa9) " 38
  let c = s:HH(c, d, a, b, x[ 7], s:S33, 0xf6bb4b60) " 39
  let b = s:HH(b, c, d, a, x[10], s:S34, 0xbebfbc70) " 40
  let a = s:HH(a, b, c, d, x[13], s:S31, 0x289b7ec6) " 41
  let d = s:HH(d, a, b, c, x[ 0], s:S32, 0xeaa127fa) " 42
  let c = s:HH(c, d, a, b, x[ 3], s:S33, 0xd4ef3085) " 43
  let b = s:HH(b, c, d, a, x[ 6], s:S34,  0x4881d05) " 44
  let a = s:HH(a, b, c, d, x[ 9], s:S31, 0xd9d4d039) " 45
  let d = s:HH(d, a, b, c, x[12], s:S32, 0xe6db99e5) " 46
  let c = s:HH(c, d, a, b, x[15], s:S33, 0x1fa27cf8) " 47
  let b = s:HH(b, c, d, a, x[ 2], s:S34, 0xc4ac5665) " 48

  " Round 4
  let a = s:II(a, b, c, d, x[ 0], s:S41, 0xf4292244) " 49
  let d = s:II(d, a, b, c, x[ 7], s:S42, 0x432aff97) " 50
  let c = s:II(c, d, a, b, x[14], s:S43, 0xab9423a7) " 51
  let b = s:II(b, c, d, a, x[ 5], s:S44, 0xfc93a039) " 52
  let a = s:II(a, b, c, d, x[12], s:S41, 0x655b59c3) " 53
  let d = s:II(d, a, b, c, x[ 3], s:S42, 0x8f0ccc92) " 54
  let c = s:II(c, d, a, b, x[10], s:S43, 0xffeff47d) " 55
  let b = s:II(b, c, d, a, x[ 1], s:S44, 0x85845dd1) " 56
  let a = s:II(a, b, c, d, x[ 8], s:S41, 0x6fa87e4f) " 57
  let d = s:II(d, a, b, c, x[15], s:S42, 0xfe2ce6e0) " 58
  let c = s:II(c, d, a, b, x[ 6], s:S43, 0xa3014314) " 59
  let b = s:II(b, c, d, a, x[13], s:S44, 0x4e0811a1) " 60
  let a = s:II(a, b, c, d, x[ 4], s:S41, 0xf7537e82) " 61
  let d = s:II(d, a, b, c, x[11], s:S42, 0xbd3af235) " 62
  let c = s:II(c, d, a, b, x[ 2], s:S43, 0x2ad7d2bb) " 63
  let b = s:II(b, c, d, a, x[ 9], s:S44, 0xeb86d391) " 64

  let state[0] += a
  let state[1] += b
  let state[2] += c
  let state[3] += d

  " Zeroize sensitive information.
  "MD5_memset ((POINTER)x, 0, sizeof (x));
endfunction

" Encodes input (UINT4) into output (unsigned char). Assumes len is
" a multiple of 4.
function! s:Encode(output, input, len)
  let output = a:output
  let input = a:input
  let len = a:len

  let i = 0
  let j = 0
  while j < len
    let output[j] = s:bitwise_and(input[i], 0xff)
    let output[j+1] = s:bitwise_and(s:bitwise_rshift(input[i], 8), 0xff)
    let output[j+2] = s:bitwise_and(s:bitwise_rshift(input[i], 16), 0xff)
    let output[j+3] = s:bitwise_and(s:bitwise_rshift(input[i], 24), 0xff)
    let i += 1
    let j += 4
  endwhile
endfunction

" Decodes input (unsigned char) into output (UINT4). Assumes len is
" a multiple of 4.
function! s:Decode(output, input, len)
  let output = a:output
  let input = a:input
  let len = a:len

  let i = 0
  let j = 0
  while j < len
    "let output[i] = s:bitwise_or(s:bitwise_or(s:bitwise_or(input[j], s:bitwise_lshift(input[j+1], 8)), s:bitwise_lshift(input[j+2], 16)), s:bitwise_lshift(input[j+3], 24))
    let output[i] = input[j] + s:bitwise_lshift(input[j+1], 8) + s:bitwise_lshift(input[j+2], 16) + s:bitwise_lshift(input[j+3], 24)
    let i += 1
    let j += 4
  endwhile
endfunction

" Note: Replace "for loop" with standard memcpy if possible.

function! s:MD5_memcpy(output, index, input, len)
  for i in range(a:len)
    let a:output[a:index + i] = a:input[i]
  endfor
endfunction

" Note: Replace "for loop" with standard memset if possible.

function! s:MD5_memset(output, value, len)
  for i in range(a:len)
    let a:output[i] = a:value
  endfor
endfunction

" MDDRIVER.C - test driver for MD2, MD4 and MD5

" Digests a reference suite of strings and prints the results.
function! s:MDTestSuite()
  echo "MD5 test suite:"

  call s:MDTest("", "d41d8cd98f00b204e9800998ecf8427e")
  call s:MDTest("a", "0cc175b9c0f1b6a831c399e269772661")
  call s:MDTest("abc", "900150983cd24fb0d6963f7d28e17f72")
  call s:MDTest("message digest", "f96b697d7cb7938d525a2f31aaf161d0")
  call s:MDTest("abcdefghijklmnopqrstuvwxyz", "c3fcd3d76192e4007dfb496cca67e13b")
  call s:MDTest("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", "d174ab98d277d9f5a5611c2c9f419d9f")
  call s:MDTest("12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57edf4a22be3c955ac49da2e2107b67a")
endfunction

function! s:MDTest(str, expected)
  let result = s:MD5Digest(s:str2bytes(a:str))
  echo printf("MD5 (\"%s\") = %s", a:str, result)
  if result != a:expected
    echoerr 'failed'
  endif
endfunction

function! s:str2bytes(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:cmp(a, b)
  let a = printf("%08x", a:a)
  let b = printf("%08x", a:b)
  return a < b ? -1 : a > b ? 1 : 0
endfunction

let s:k = [
      \ 0x1,        0x2,        0x4,        0x8,
      \ 0x10,       0x20,       0x40,       0x80,
      \ 0x100,      0x200,      0x400,      0x800,
      \ 0x1000,     0x2000,     0x4000,     0x8000,
      \ 0x10000,    0x20000,    0x40000,    0x80000,
      \ 0x100000,   0x200000,   0x400000,   0x800000,
      \ 0x1000000,  0x2000000,  0x4000000,  0x8000000,
      \ 0x10000000, 0x20000000, 0x40000000, 0x80000000,
      \ ]

let s:and = [
      \ [0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0],
      \ [0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1],
      \ [0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2],
      \ [0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3],
      \ [0x0, 0x0, 0x0, 0x0, 0x4, 0x4, 0x4, 0x4, 0x0, 0x0, 0x0, 0x0, 0x4, 0x4, 0x4, 0x4],
      \ [0x0, 0x1, 0x0, 0x1, 0x4, 0x5, 0x4, 0x5, 0x0, 0x1, 0x0, 0x1, 0x4, 0x5, 0x4, 0x5],
      \ [0x0, 0x0, 0x2, 0x2, 0x4, 0x4, 0x6, 0x6, 0x0, 0x0, 0x2, 0x2, 0x4, 0x4, 0x6, 0x6],
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
      \ [0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8],
      \ [0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x0, 0x1, 0x8, 0x9, 0x8, 0x9, 0x8, 0x9, 0x8, 0x9],
      \ [0x0, 0x0, 0x2, 0x2, 0x0, 0x0, 0x2, 0x2, 0x8, 0x8, 0xA, 0xA, 0x8, 0x8, 0xA, 0xA],
      \ [0x0, 0x1, 0x2, 0x3, 0x0, 0x1, 0x2, 0x3, 0x8, 0x9, 0xA, 0xB, 0x8, 0x9, 0xA, 0xB],
      \ [0x0, 0x0, 0x0, 0x0, 0x4, 0x4, 0x4, 0x4, 0x8, 0x8, 0x8, 0x8, 0xC, 0xC, 0xC, 0xC],
      \ [0x0, 0x1, 0x0, 0x1, 0x4, 0x5, 0x4, 0x5, 0x8, 0x9, 0x8, 0x9, 0xC, 0xD, 0xC, 0xD],
      \ [0x0, 0x0, 0x2, 0x2, 0x4, 0x4, 0x6, 0x6, 0x8, 0x8, 0xA, 0xA, 0xC, 0xC, 0xE, 0xE],
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF]
      \ ]

let s:or = [
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x1, 0x1, 0x3, 0x3, 0x5, 0x5, 0x7, 0x7, 0x9, 0x9, 0xB, 0xB, 0xD, 0xD, 0xF, 0xF],
      \ [0x2, 0x3, 0x2, 0x3, 0x6, 0x7, 0x6, 0x7, 0xA, 0xB, 0xA, 0xB, 0xE, 0xF, 0xE, 0xF],
      \ [0x3, 0x3, 0x3, 0x3, 0x7, 0x7, 0x7, 0x7, 0xB, 0xB, 0xB, 0xB, 0xF, 0xF, 0xF, 0xF],
      \ [0x4, 0x5, 0x6, 0x7, 0x4, 0x5, 0x6, 0x7, 0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF],
      \ [0x5, 0x5, 0x7, 0x7, 0x5, 0x5, 0x7, 0x7, 0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF],
      \ [0x6, 0x7, 0x6, 0x7, 0x6, 0x7, 0x6, 0x7, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF],
      \ [0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF],
      \ [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x9, 0x9, 0xB, 0xB, 0xD, 0xD, 0xF, 0xF, 0x9, 0x9, 0xB, 0xB, 0xD, 0xD, 0xF, 0xF],
      \ [0xA, 0xB, 0xA, 0xB, 0xE, 0xF, 0xE, 0xF, 0xA, 0xB, 0xA, 0xB, 0xE, 0xF, 0xE, 0xF],
      \ [0xB, 0xB, 0xB, 0xB, 0xF, 0xF, 0xF, 0xF, 0xB, 0xB, 0xB, 0xB, 0xF, 0xF, 0xF, 0xF],
      \ [0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF, 0xC, 0xD, 0xE, 0xF],
      \ [0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF, 0xD, 0xD, 0xF, 0xF],
      \ [0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF, 0xE, 0xF],
      \ [0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF, 0xF]
      \ ]

let s:xor = [
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6, 0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE],
      \ [0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5, 0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD],
      \ [0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4, 0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC],
      \ [0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3, 0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB],
      \ [0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2, 0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA],
      \ [0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1, 0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9],
      \ [0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0, 0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8],
      \ [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
      \ [0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE, 0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6],
      \ [0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD, 0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5],
      \ [0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC, 0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4],
      \ [0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB, 0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3],
      \ [0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA, 0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2],
      \ [0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9, 0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1],
      \ [0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0]
      \ ]

function! s:bitwise_lshift(a, n)
  return a:a * s:k[a:n]
endfunction

function! s:bitwise_rshift(a, n)
  let a = a:a < 0 ? a:a - 0x80000000 : a:a
  let a = a / s:k[a:n]
  if a:a < 0
    let a += 0x40000000 / s:k[a:n - 1]
  endif
  return a
endfunction

function! s:bitwise_not(a)
  return -a:a - 1
endfunction

function! s:bitwise_and(a, b)
  let a = a:a < 0 ? a:a - 0x80000000 : a:a
  let b = a:b < 0 ? a:b - 0x80000000 : a:b
  let r = 0
  let n = 1
  while a && b
    let r += s:and[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) && (a:b < 0)
    let r += 0x80000000
  endif
  return r
endfunction

function! s:bitwise_or(a, b)
  let a = a:a < 0 ? a:a - 0x80000000 : a:a
  let b = a:b < 0 ? a:b - 0x80000000 : a:b
  let r = 0
  let n = 1
  while a || b
    let r += s:or[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) || (a:b < 0)
    let r += 0x80000000
  endif
  return r
endfunction

function! s:bitwise_xor(a, b)
  let a = a:a < 0 ? a:a - 0x80000000 : a:a
  let b = a:b < 0 ? a:b - 0x80000000 : a:b
  let r = 0
  let n = 1
  while a || b
    let r += s:xor[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) != (a:b < 0)
    let r += 0x80000000
  endif
  return r
endfunction
