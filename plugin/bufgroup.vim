scriptencoding utf-8
" ninbufgroup.vim
" Last Change:	2025 Apr-29
" Maintainer:	Shoichiro Nakanishi <sheepwing@kyudai.jp>
" License:	Mit licence

if exists('g:loaded_ninbufgroup')
  finish
endif
let s:save_cpo = &cpo
set cpo&vim
let g:loaded_ninbufgroup = 1

function! bufgroup#get(flag='', vflag='')
  let result = []
  for line in execute('ls')->split("\n")
    let line_tmp = line[3:7]
    let selected = 1
    for f in a:flag
      let selected = match(line_tmp, f) == -1? -1 : selected
    endfor
    for f in a:vflag
      let selected = match(line_tmp, f) == -1? selected :-1
    endfor
    if selected ==1
      call insert(result, line[:2])
    endif
  endfor
  return result
endfunction

function! bufgroup#_filter(buf, word)
  let result = []
  for b in a:buf
    if str2nr(b)->bufname()->match(a:word) != -1
      call insert(result, b)
    endif
  endfor
  return result
endfunction

let s:BufGroups = #{all: []}
let s:BufGroupsLocation = #{all: 1}
let s:BufGroupName = 'all'

function bufgroup#get_groupname()
  return s:BufGroupName
endfunction

function bufgroup#open_group(key)
  " open buffer group named key.
  let s:BufGroups[s:BufGroupName] = bufgroup#get()
  call extend(s:BufGroupsLocation, {s:BufGroupName : bufnr()})
  let s:BufGroupName = a:key
  call bufgroup#open_buf(s:BufGroups[s:BufGroupName])
  exec s:BufGroupsLocation[a:key].'b'
endfunction

function bufgroup#next()
  " Go to next buffer group
  let keys = s:BufGroups->keys()
  call bufgroup#open_group(keys[(keys->index(s:BufGroupName)+1) % s:BufGroups->len()])
endfunction

function bufgroup#prev()
  " Go to previous buffer group
  let keys = s:BufGroups->keys()
  call bufgroup#open_group(keys[(keys->index(s:BufGroupName)-1) % s:BufGroups->len()])
endfunction


function bufgroup#add(key)
  let s:BufGroups[a:key] = uniq(s:BufGroups[a:key] + bufgroup#get('%'))
endfunction

function bufgroup#new(key)
  call extend(s:BufGroups, {a:key : []})
  let s:BufGroupName = a:key
  call bufgroup#open_group(a:key)
endfunction

function bufgroup#add_all(key)
  " Add all the buffers to other group
  let s:BufGroups[a:key] = uniq(s:BufGroups[a:key] + bufgroup#get())
endfunction

function bufgroup#filter(key)
  " Filter buffers
  eval bufgroup#get()->bufgroup#_filter(a:key)->bufgroup#open_buf()
endfunction

function bufgroup#new_filter(key)
  " Filter buffers and make new group
  call extend(s:BufGroups, {a:key : []})
  let s:BufGroupName = a:key
  eval bufgroup#get()->bufgroup#_filter(a:key)->bufgroup#open_buf()
  let s:BufGroups[a:key] = uniq(s:BufGroups[a:key] + bufgroup#get())
  call bufgroup#open_group(a:key)
endfunction

autocmd BufNewFile,BufReadPost * :call bufgroup#add('all')

function! _BufComp(x,y,z)
  return keys(s:BufGroups)
endfunction

function! bufgroup#open_buf(group, type=[''])
  " Open buffer
  " group: id list of buffer
  " type: type of buffer
  for line in execute('ls!')->split("\n")
    exec $"b {line[:2]}"
    setlocal nobuflisted
    let types = execute('set bt')->trim()->split('=')
    let type = types->len() == 1? '' : types[1]->trim()
    for buf in a:group
      if line[:2] == buf
        for t in a:type
          if type == t
            setlocal buflisted
          endif
        endfor
        break
      endif
    endfor
  endfor
  if len(execute('ls!')->split("\n")) == 0
    exec e
  endif
  exec 'silent! bn'
endfunction

function bufgroup#tabline(shownum=0)
  let result = ''
  let num = 0
  for n in execute('ls')->split('\n')
    let label = pathshorten(n[10: 9 + n[10:]->stridx("\"")])
    let num = num + 1
  endfor
  let length = winwidth(0) / num - 2
  for n in execute('ls')->split('\n')
    let label = n[10: 9 + n[10:]->stridx("\"")]->pathshorten(length)[:length]
    let label = n[4] == '%' ? '%#TabLineSel#'. label : '%#TabLine#'.label
    let result = result .' '. label
  endfor
  let start = result->stridx('%#TabLineSel#')
  let current_tab = string(tabpagenr()).'/'.string(tabpagenr('$'))
  return a:shownum? string(num).result.'%#TabLineFill#'
        \: result.'%#TabLineFill#'
endfunction

function bufgroup#_make_tab()
  tabnew
  bn
  $bd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
