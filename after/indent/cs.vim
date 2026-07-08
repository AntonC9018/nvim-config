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

function! s:EndsWithLambdaBodyIntro(line) abort
  return a:line =~# '=>\s*\%(new\s*\)\?\%(//.*\)\=$'
endfunction

function! s:EndsWithTargetTypedNewArgument(line) abort
  return a:line =~# '\<new\s*(\s*)\s*\%(//.*\)\=$'
endfunction

function! s:EndsWithTargetTypedNewConstructorStart(line) abort
  return a:line =~# '\<new\s*(\s*\%(//.*\)\=$'
endfunction

function! s:HasUnclosedParen(line) abort
  let l:code = substitute(a:line, '//.*$', '', '')
  let l:open_count = strlen(substitute(l:code, '[^(]', '', 'g'))
  let l:close_count = strlen(substitute(l:code, '[^)]', '', 'g'))
  return l:open_count > l:close_count
endfunction

function! s:IsLambdaBlockOpen(lnum) abort
  if a:lnum <= 1 || getline(a:lnum) !~# '^\s*{\s*\%(//.*\)\=$'
    return v:false
  endif

  let l:previous = prevnonblank(a:lnum - 1)
  return l:previous > 0 && s:EndsWithLambdaBodyIntro(getline(l:previous))
endfunction

function! s:IsTargetTypedNewInitializerOpen(lnum) abort
  if a:lnum <= 1 || getline(a:lnum) !~# '^\s*{\s*\%(//.*\)\=$'
    return v:false
  endif

  let l:previous = prevnonblank(a:lnum - 1)
  return l:previous > 0 && s:EndsWithTargetTypedNewArgument(getline(l:previous))
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

function! s:FindEnclosingOpenParen(lnum) abort
  let l:view = winsaveview()
  try
    let l:line = getline(a:lnum)
    let l:closing_paren = match(l:line, ')')
    let l:before_closing_paren = l:closing_paren > 0 ? l:line[:l:closing_paren - 1] : ''
    if l:closing_paren >= 0 && l:before_closing_paren =~# '^\s*$'
      call cursor(a:lnum, l:closing_paren + 1)
    else
      call cursor(a:lnum, 1)
    endif

    return searchpairpos('(', '', ')', 'bnW')
  finally
    call winrestview(l:view)
  endtry
endfunction

function! s:IsTargetTypedNewConstructorParen(pos) abort
  let l:line_number = a:pos[0]
  let l:column = a:pos[1]
  return l:line_number > 0 && strpart(getline(l:line_number), 0, l:column) =~# '\<new\s*($'
endfunction

function! s:FindEnclosingTargetTypedNewConstructor(lnum) abort
  let l:open_paren = s:FindEnclosingOpenParen(a:lnum)
  return s:IsTargetTypedNewConstructorParen(l:open_paren) ? l:open_paren[0] : 0
endfunction

function! s:IsInitializerEntryLine(line) abort
  return a:line =~# '^\s*\%(//\|$\)' || a:line =~# '^\s*\%(@\=\k\+\|\[[^]]*\]\)\s*='
endfunction

function! s:AntonCSIndent(lnum) abort
  let l:line = getline(a:lnum)
  let l:default_indent = GetCSIndent(a:lnum)

  if l:line =~# '^\s*{'
    let l:previous = prevnonblank(a:lnum - 1)
    if l:previous > 0 && s:EndsWithLambdaBodyIntro(getline(l:previous))
      return indent(l:previous)
    endif

    if l:previous > 0 && s:EndsWithTargetTypedNewArgument(getline(l:previous))
      return indent(l:previous)
    endif
  endif

  if l:line =~# '^\s*)'
    let l:previous = prevnonblank(a:lnum - 1)
    if l:previous > 0 && s:EndsWithTargetTypedNewArgument(getline(l:previous)) && s:HasUnclosedParen(getline(l:previous))
      return indent(l:previous)
    endif

    if l:previous > 0 && s:EndsWithTargetTypedNewConstructorStart(getline(l:previous)) && s:HasUnclosedParen(getline(l:previous))
      return indent(l:previous) + shiftwidth()
    endif
  endif

  let l:open_brace = s:FindEnclosingOpenBrace(a:lnum)
  if l:open_brace > 0 && s:IsTargetTypedNewInitializerOpen(l:open_brace)
    if l:line =~# '^\s*}'
      return indent(l:open_brace)
    endif

    let l:initializer_indent = indent(l:open_brace) + shiftwidth()
    if s:FindEnclosingTargetTypedNewConstructor(l:open_brace) > 0 && s:IsInitializerEntryLine(l:line)
      return l:initializer_indent
    endif

    return max([l:default_indent, l:initializer_indent])
  endif

  if l:open_brace > 0 && s:IsLambdaBlockOpen(l:open_brace)
    if l:line =~# '^\s*}'
      return indent(l:open_brace)
    endif

    return max([l:default_indent, indent(l:open_brace) + shiftwidth()])
  endif

  let l:constructor_start = s:FindEnclosingTargetTypedNewConstructor(a:lnum)
  if l:constructor_start > 0
    return indent(l:constructor_start) + shiftwidth()
  endif

  return l:default_indent
endfunction
