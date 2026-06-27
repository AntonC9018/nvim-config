if !exists('*GetCSIndent')
  finish
endif

setlocal indentexpr=s:AntonCSIndent(v:lnum)
setlocal cinoptions=J1,(s

if exists('b:undo_indent')
  let b:undo_indent .= ' | setlocal cinoptions<'
else
  let b:undo_indent = 'setlocal indentexpr< cinoptions<'
endif

function! s:EndsWithLambdaArrow(line) abort
  return a:line =~# '=>\s*\%(//.*\)\=$'
endfunction

function! s:IsLambdaBlockOpen(lnum) abort
  if a:lnum <= 1 || getline(a:lnum) !~# '^\s*{\s*\%(//.*\)\=$'
    return v:false
  endif

  let l:previous = prevnonblank(a:lnum - 1)
  return l:previous > 0 && s:EndsWithLambdaArrow(getline(l:previous))
endfunction

function! s:FindEnclosingOpenBrace(lnum) abort
  let l:view = winsaveview()
  try
    let l:line = getline(a:lnum)
    let l:closing_brace = match(l:line, '}')
    let l:before_closing_brace = l:closing_brace > 0 ? l:line[:l:closing_brace - 1] : ''
    if l:closing_brace >= 0 && l:before_closing_brace =~# '^\s*$'
      call cursor(a:lnum, l:closing_brace + 1)
    else
      call cursor(a:lnum, 1)
    endif

    return searchpairpos('{', '', '}', 'bnW')[0]
  finally
    call winrestview(l:view)
  endtry
endfunction

function! s:AntonCSIndent(lnum) abort
  let l:line = getline(a:lnum)
  let l:default_indent = GetCSIndent(a:lnum)

  if l:line =~# '^\s*{'
    let l:previous = prevnonblank(a:lnum - 1)
    if l:previous > 0 && s:EndsWithLambdaArrow(getline(l:previous))
      return indent(l:previous)
    endif
  endif

  let l:open_brace = s:FindEnclosingOpenBrace(a:lnum)
  if l:open_brace > 0 && s:IsLambdaBlockOpen(l:open_brace)
    if l:line =~# '^\s*}'
      return indent(l:open_brace)
    endif

    return max([l:default_indent, indent(l:open_brace) + shiftwidth()])
  endif

  return l:default_indent
endfunction
