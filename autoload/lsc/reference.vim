function! lsc#reference#goToDefinition() abort
  call lsc#file#flushChanges()
  let s:goto_definition_id += 1
  let old_pos = getcurpos()
  let goto_definition_id = s:goto_definition_id
  function! Jump(result) closure abort
    if !s:isGoToValid(old_pos, goto_definition_id)
      echom 'GoToDefinition skipped'
      return
    endif
    if type(a:result) == v:t_none ||
        \ (type(a:result) == v:t_list && len(a:result) == 0)
      call lsc#util#error('No definition found')
      return
    endif
    if type(a:result) == type([])
      let location = a:result[0]
    else
      let location = a:result
    endif
    let file = lsc#util#documentPath(location.uri)
    let line = location.range.start.line + 1
    let character = location.range.start.character + 1
    call s:goTo(file, line, character)
  endfunction
  call lsc#server#call(&filetype, 'textDocument/definition',
      \ s:TextDocumentPositionParams(), function('Jump'))
endfunction

function! s:TextDocumentPositionParams() abort
  return { 'textDocument': {'uri': lsc#util#documentUri()},
      \ 'position': {'line': line('.') - 1, 'character': col('.') - 1}
      \ }
endfunction

function! lsc#reference#findReferences() abort
  call lsc#file#flushChanges()
  let params = s:TextDocumentPositionParams()
  let params.context = {'includeDeclaration': v:true}
  call lsc#server#call(&filetype, 'textDocument/references',
      \ params, function('<SID>setQuickFixReferences'))
endfunction

function! s:setQuickFixReferences(results) abort
  call map(a:results, {_, ref -> s:QuickFixItem(ref)})
  call sort(a:results, 'lsc#util#compareQuickFixItems')
  call setqflist(a:results)
  copen
endfunction

" Convert an LSP Location to a item suitable for the vim quickfix list.
"
" Both representations are dictionaries.
"
" Location:
" 'uri': file:// URI
" 'range': {'start': {'line', 'character'}, 'end': {'line', 'character'}}
"
" QuickFix Item: (as used)
" 'filename': file path if file is not open
" 'bufnr': buffer number if the file is open in a buffer
" 'lnum': line number
" 'col': column number
" 'text': The content of the referenced line
"
" LSP line and column are zero-based, vim is one-based.
function! s:QuickFixItem(location) abort
  let item = {'lnum': a:location.range.start.line + 1,
      \ 'col': a:location.range.start.character + 1}
  let file_path = lsc#util#documentPath(a:location.uri)
  let item.filename = fnamemodify(file_path, ':~:.')
  let bufnr = bufnr(file_path)
  if bufnr != -1 && bufloaded(bufnr)
    let item.text = getbufline(bufnr, item.lnum)[0]
  else
    let item.text = readfile(file_path, '', item.lnum)[item.lnum - 1]
  endif
  return item
endfunction

if !exists('s:initialized')
  let s:goto_definition_id = 1
  let s:initialized = v:true
endif

function! s:isGoToValid(old_pos, goto_definition_id) abort
  return a:goto_definition_id == s:goto_definition_id &&
      \ a:old_pos == getcurpos()
endfunction

function! s:goTo(file, line, character) abort
  if a:file != expand('%:p')
    let relative_path = fnamemodify(a:file, ':~:.')
    exec 'edit '.relative_path
    " 'edit' already left a jump
    call cursor(a:line, a:character)
    redraw
  else
    " Move with 'G' to ensure a jump is left
    exec 'normal! '.a:line.'G'.a:character.'|'
  endif
endfunction

function! lsc#reference#hover() abort
  call lsc#file#flushChanges()
  let params = s:TextDocumentPositionParams()
  call lsc#server#call(&filetype, 'textDocument/hover',
      \ params, function('<SID>showHover'))
endfunction

function! s:showHover(result) abort
  if empty(a:result) || empty(a:result.contents)
    echom 'No hover information'
    return
  endif
  let contents = a:result.contents
  if type(contents) == v:t_list
    let contents = contents[0]
  endif
  if type(contents) == v:t_dict
    let contents = contents.value
  endif
  let lines = split(contents, "\n")
  call lsc#util#displayAsPreview(lines)
endfunction
