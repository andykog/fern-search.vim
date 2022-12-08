let s:Process = vital#fern#import('Async.Promise.Process')

function! fern#scheme#file#mapping#search#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-search-search) :<C-u>call <SID>call('search')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-search-replace) :<C-u>call <SID>call('replace')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-search-search-sensetive) :<C-u>call <SID>call('searchs')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-search-replace-sensetive) :<C-u>call <SID>call('replaces')<CR>

  if !a:disable_default_mappings
        \ && !g:fern#scheme#file#mapping#search#disable_default_mappings
    nmap <buffer><nowait> ms <Plug>(fern-action-search-search)
    nmap <buffer><nowait> mr <Plug>(fern-action-search-replace)
    nmap <buffer><nowait> mS <Plug>(fern-action-search-search-sensetive)
    nmap <buffer><nowait> mR <Plug>(fern-action-search-replace-sensetive)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_search(helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("search-search action requires 'file' scheme")
  endif
  let cd = a:helper.sync.get_cursor_node()._path
  if a:helper.sync.is_drawer()
    exe "normal \<c-w>\<c-w>"
  endif
  call fern#scheme#file#mapping#search#Search(1, cd)
endfunction

function! s:map_replace(helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("search-replace action requires 'file' scheme")
  endif
  let cd = a:helper.sync.get_cursor_node()._path
  if a:helper.sync.is_drawer()
    exe "normal \<c-w>\<c-w>"
  endif
  call fern#scheme#file#mapping#search#Replace(1, cd)
endfunction

function! s:map_searchs(helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("search-search action requires 'file' scheme")
  endif
  let cd = a:helper.sync.get_cursor_node()._path
  if a:helper.sync.is_drawer()
    exe "normal \<c-w>\<c-w>"
  endif
  call fern#scheme#file#mapping#search#Search(0, cd)
endfunction

function! s:map_replaces(helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("search-replace action requires 'file' scheme")
  endif
  let cd = a:helper.sync.get_cursor_node()._path
  if a:helper.sync.is_drawer()
    exe "normal \<c-w>\<c-w>"
  endif
  call fern#scheme#file#mapping#search#Replace(0, cd)
endfunction


let g:fern#scheme#file#mapping#search#disable_default_mappings = get(g:, 'fern#scheme#file#mapping#fern#scheme#file#mapping#search#disable_default_mappings', 0)

function! fern#scheme#file#mapping#search#doReplace(caseInsensetive, cd)
  let pattern = fern#scheme#file#mapping#search#Search(a:caseInsensetive, a:cd)
  if empty(pattern)
    return
  endif

  let replacement = input("Enter the replacement: ")
  if empty(replacement)
    return
  endif
  :hi Pattern cterm=bold gui=inverse
  call ack#Ack('grep!', "-i ".shellescape(pattern)." ".shellescape(a:cd))

  if empty(getqflist())
    return
  endif

  let yesAll = 0

  :cfirst

  let lines = getqflist()


  let i = -1

  for line in lines
    let i += 1

    let lnum = line.lnum
    let startCol = line.col
    let fullText = getline(lnum)
    let preText = strpart(fullText, 0, startCol - 1)
    let text = strpart(fullText, startCol - 1)
    let substituteFlags = a:caseInsensetive ? 'I' : 'i'
    let newText = substitute(text, pattern, replacement, substituteFlags)
    let newFullText = preText . newText
    let endCol = matchend(fullText, pattern, line.col - 1)
    let delta = len(newText) - len(text)

    if yesAll == 0
      let ms = startCol - 1
      let me = endCol + 1
      execute 'match Pattern /\%<'.me.'v\%>'.ms.'v\%'.lnum.'l/'
      redraw
      echo "Replace with ". replacement ."? (y/n/a/q)"
      let ans = '-'
      while ans !~? '[ynab]'
        let ans = nr2char(getchar())
        if ans == 'q' || ans == "\<Esc>"
          redraw " see :h echo-redraw
          echo
          :match
          return
        endif
      endwhile

      if ans == 'n'
      elseif ans == 'a'
        let yesAll = 1
      endif
    endif

    if (ans == 'y' || yesAll)
      call setline(lnum, newFullText)
      let lia = i + 1
      while (lia < len(lines) && lines[lia].bufnr == line.bufnr)
        let lines[lia].bufnr += delta
        let lia += 1
      endwhile
    endif

    redraw " see :h echo-redraw
    echo
    :match

    try
      :cnext
    catch /^Vim\%((\a\+)\)\=:E553/ " no more lines
    endtry
  endfor
endfunction


function! fern#scheme#file#mapping#search#Replace(caseInsensetive, cd)

  " ALE echoes errors. Interferes with promt
  let shouldToggleALE = exists('g:ale_enabled') && g:ale_enabled
  if shouldToggleALE
    ALEDisable
  endif

  call fern#scheme#file#mapping#search#doReplace(a:caseInsensetive, a:cd)

  if shouldToggleALE
    ALEEnable
  endif
endfunction


function! fern#scheme#file#mapping#search#Search(caseInsensetive, cd)
  let l:prompt = a:caseInsensetive ? "Enter the pattern: " : "Enter the pattern (case sensetive): "
  let pattern = input(l:prompt)
  if pattern == ''
    return
  endif
  let ackFlags = a:caseInsensetive ? '-i' : ''
  call ack#Ack('grep!', ackFlags . " " . shellescape(pattern) . " " . shellescape(a:cd))
  return pattern
endfunction
