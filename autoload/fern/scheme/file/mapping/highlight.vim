function! fern#scheme#file#mapping#highlight#init(disable_default_mappings) abort
  let g:fernHighlightHelper = fern#helper#new()
endfunction

function! s:focus(helper, key) abort
  if len(a:key) < 1
    return
  endif
  let index = fern#internal#node#index(a:key, a:helper.fern.visible_nodes)
  if index is# -1
    return s:focus(a:helper, a:key[:-2])
  endif

  call a:helper.sync.focus_node(a:key)
endfunction

function! s:highlight() abort
  if exists("g:fernHighlightHelper")
    let path = expand('%:p')
    let root = g:fernHighlightHelper.sync.get_root_node()._path
    if path[0:len(root)-1] ==# root
      let path = substitute(path, root, '', '')
      call s:focus(g:fernHighlightHelper, split(path, '/'))
    endif
  endif
endfunction

autocmd BufEnter * call s:highlight()
