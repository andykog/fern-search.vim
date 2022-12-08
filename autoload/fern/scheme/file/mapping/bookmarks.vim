let s:Process = vital#fern#import('Async.Promise.Process')

let g:FernBookmarksFile = get(g:, 'FernBookmarksFile', expand('$HOME') . '/.FernBookmarks')
let s:Bookmark = {}
let g:FernBookmark = s:Bookmark

function! fern#scheme#file#mapping#bookmarks#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-search-bookmarks) :<C-u>call <SID>call('bookmarks')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-search-add-bookmark) :<C-u>call <SID>call('add')<CR>

  if !a:disable_default_mappings
        \ && !g:fern#scheme#file#mapping#search#disable_default_mappings
    nmap <buffer><nowait> B <Plug>(fern-action-search-bookmarks)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_bookmarks(helper) abort
  call s:Bookmark.CacheBookmarks(1)

  let l:idx = 0
  for i in s:Bookmark.Bookmarks()
    echo l:idx . " - " i.name
    let l:idx += 1
  endfor

  let l:seletedIdx = input("Bookmark number: ")
  if l:seletedIdx == ''
    return
  endif
  let l:selectedBookmark = s:Bookmark.Bookmarks()[l:seletedIdx]
  let l:path = l:selectedBookmark.path

  execute 'cd' fnameescape(l:path)
  execute "Fern" l:path
endfunction

function! s:map_add(helper) abort
  call s:Bookmark.CacheBookmarks(1)

  let l:node = a:helper.sync.get_cursor_node()
  let l:label = l:node.label
  let l:path = l:node._path
  call s:Bookmark.AddBookmark(l:label, l:path)
  call s:Bookmark.Write()
  echo "Added " . l:label . " (" . l:path . ")"
endfunction

function! s:Bookmark.AddBookmark(name, path)
  for i in s:Bookmark.Bookmarks()
    if i.name ==# a:name
      let i.path = a:path
      return
    endif
  endfor
  call add(s:Bookmark.Bookmarks(), s:Bookmark.New(a:name, a:path))
endfunction

function! s:Bookmark.Bookmarks()
  if !exists('g:FernBookmarks')
    let g:FernBookmarks = []
  endif
  return g:FernBookmarks
endfunction

function! s:Bookmark.CacheBookmarks(silent)
  if filereadable(g:FernBookmarksFile)
    let g:FernBookmarks = []
    let g:FernInvalidBookmarks = []
    let bookmarkStrings = readfile(g:FernBookmarksFile)
    let invalidBookmarksFound = 0
    for i in bookmarkStrings

      "ignore blank lines
      if i !=# ''

        let name = substitute(i, '^\(.\{-}\) .*$', '\1', '')
        let path = substitute(i, '^.\{-} \(.*\)$', '\1', '')
        let path = fnamemodify(path, ':p')

        let bookmark = s:Bookmark.New(name, path)
        call add(g:FernBookmarks, bookmark)
      endif
    endfor
    if invalidBookmarksFound
      call s:Bookmark.Write()
      if !a:silent
        echo(invalidBookmarksFound . ' invalid bookmarks were read. See :help FernInvalidBookmarks for info.')
      endif
    endif
  endif
endfunction

function! s:Bookmark.InvalidBookmarks()
  if !exists('g:FernInvalidBookmarks')
    let g:FernInvalidBookmarks = []
  endif
  return g:FernInvalidBookmarks
endfunction

function! s:Bookmark.New(name, path)
  if a:name =~# ' '
    throw 'FernBookmarks.IllegalBookmarkNameError: illegal name:' . a:name
  endif

  let newBookmark = copy(self)
  let newBookmark.name = a:name
  let newBookmark.path = a:path
  return newBookmark
endfunction

function! s:Bookmark.Write()
  let bookmarkStrings = []
  for i in s:Bookmark.Bookmarks()
    call add(bookmarkStrings, i.name . ' ' . fnamemodify(i.path, ':~'))
  endfor

  "add a blank line before the invalid ones
  call add(bookmarkStrings, '')

  for j in s:Bookmark.InvalidBookmarks()
    call add(bookmarkStrings, j)
  endfor

  try
    call writefile(bookmarkStrings, g:FernBookmarksFile)
  catch
    echoerr('Failed to write bookmarks file. Make sure g:FernBookmarksFile points to a valid location.')
  endtry
endfunction
