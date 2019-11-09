function! lsc#uri#documentUri(...) abort
  if a:0 >= 1
    let l:file_path = a:1
  else
    let l:file_path = lsc#file#fullPath()
  endif

  if has('win32')
    let l:file_path = s:fromWindowsPath(l:file_path)
  endif

  return s:filePrefix().s:EncodePath(l:file_path)
endfunction

function! lsc#uri#documentPath(uri) abort
  let l:decoded_path = s:DecodePath(substitute(a:uri, '^'.s:filePrefix(), '', 'v'))

  if has('win32')
    let l:decoded_path = s:toWindowsPath(l:decoded_path)
  endif

  return l:decoded_path
endfunction

function! s:EncodePath(value) abort
  return substitute(a:value, '\([^a-zA-Z0-9-_.~/]\)',
      \ '\=s:EncodeChar(submatch(1))', 'g')
endfunction

function! s:EncodeChar(char) abort
  let charcode = char2nr(a:char)
  return printf('%%%02x', charcode)
endfunction

function! s:DecodePath(value) abort
  return substitute(a:value, '%\([a-fA-F0-9]\{2}\)',
      \ '\=s:DecodeChar(submatch(1))', 'g')
endfunction

function! s:DecodeChar(hexcode) abort
  let charcode = str2nr(a:hexcode, 16)
  return nr2char(charcode)
endfunction

function! s:filePrefix(...) abort
  if has('win32')
    return 'file:///'
  else
    return 'file://'
  endif
endfunction

function! s:fromWindowsPath(path)
    return substitute(a:path, '\','/','g')
endfunction

function! s:toWindowsPath(path)
    return substitute(a:path, '/','\','g')
endfunction
