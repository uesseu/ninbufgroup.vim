
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
  return result->sort()->uniq()
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

let t:BufGroups = #{all: []}
let t:BufGroupsLocation = #{all: 1}
let t:BufGroupName = 'all'
let t:BufGroupOn = 1

function bufgroup#get_groupname()
  return t:BufGroupName
endfunction

function bufgroup#open_group(key)
  " open buffer group named key.
  if t:BufGroupOn == 1
    let t:BufGroups[t:BufGroupName] = bufgroup#get()
  endif
  call extend(t:BufGroupsLocation, {t:BufGroupName : bufnr()})
  let t:BufGroupName = a:key
  call bufgroup#open_buf(t:BufGroups[t:BufGroupName])
  exec t:BufGroupsLocation[a:key].'b'
endfunction

function bufgroup#remove_group(key='.')
  if a:key == 'all'
    return
  elseif a:key == '.'
    let key = t:BufGroupName
  else
    let key = a:key
  endif
  call bufgroup#next()
  unlet t:BufGroups[key]
  unlet t:BufGroupsLocation[key]
endfunction

function bufgroup#rename_group(key)
  if a:key == 'all'
    return
  endif
  call extend(t:BufGroups, {a:key : t:BufGroups[t:BufGroupName]})
  call bufgroup#remove_group(t:BufGroupName)
  let t:BufGroupName = a:key
  call bufgroup#open_group(a:key)
endfunction

function bufgroup#next()
  " Go to next buffer group
  let keys = t:BufGroups->keys()
  call bufgroup#open_group(
        \keys[(keys->index(t:BufGroupName)+1) % t:BufGroups->len()])
endfunction

function bufgroup#prev()
  " Go to previous buffer group
  let keys = t:BufGroups->keys()
  call bufgroup#open_group(
        \keys[(keys->index(t:BufGroupName)-1) % t:BufGroups->len()])
endfunction


function bufgroup#add(key)
  let t:BufGroups[a:key] = (t:BufGroups[a:key] + bufgroup#get('%'))->sort()->uniq()
endfunction

function bufgroup#new(key)
  call extend(t:BufGroups, {a:key : []})
  let t:BufGroupName = a:key
  call bufgroup#open_group(a:key)
endfunction

function bufgroup#add_all(key)
  " Add all the buffers to other group
  let t:BufGroups[a:key] = (t:BufGroups[a:key] + bufgroup#get())->sort()->uniq()
endfunction

function bufgroup#filter(key)
  " Filter buffers
  eval bufgroup#get()->bufgroup#_filter(a:key)->bufgroup#open_buf()
endfunction

function bufgroup#new_filter(key)
  " Filter buffers and make new group
  call extend(t:BufGroups, {a:key : []})
  let t:BufGroupName = a:key
  eval bufgroup#get()->bufgroup#_filter(a:key)->bufgroup#open_buf()
  let t:BufGroups[a:key] = (t:BufGroups[a:key] + bufgroup#get())->sort()->uniq()
  call bufgroup#open_group(a:key)
endfunction


function! _BufComp(x,y,z)
  return keys(t:BufGroups)
endfunction

function! bufgroup#open_buf(group, type=[''])
  " Open buffer
  " group: id list of buffer
  " type: type of buffer
  call bufgroup#add_all('all')
  for line in execute('ls!')->split("\n")
    let loaded = bufloaded(str2nr(line[:2]))? 1 : 0
    if loaded == 0
      set ei=BufEnter,BufReadPost,BufLeave
    endif
    exec $"b {line[:2]}"
    setlocal nobuflisted
    let types = execute('set bt')->trim()->split('=')
    let type = types->len() == 1? '' : types[1]->trim()
    for buf in a:group->sort()->uniq()
      if line[:2] == buf
        for t in a:type
          if type == t
            setlocal buflisted
          endif
        endfor
        break
      endif
    endfor
    "if loaded == 0
    "  bun
    "endif
    set ei=
  endfor
  if len(execute('ls!')->split("\n")) == 0
    exec e
  endif
  exec 'silent! bn'
endfunction

function bufgroup#tabline(shownum=0, edge=5)
  let result = ''
  let num = 0
  for n in execute('ls')->split('\n')
    let label = pathshorten(n[10: 9 + n[10:]->stridx("\"")])
    let num = num + 1
  endfor
  let length = (winwidth(0) - a:edge) / num - 2
  if length > winwidth(0) / 4
    let length = winwidth(0) / 4
  endif
  for n in execute('ls')->split('\n')
    let label = n[10: 9 + n[10:]->stridx("\"")]->pathshorten(length)[:length]
    let label = n[4] == '%' ? '%#TabLineSel#'. label : '%#TabLine#'.label
    let label = n[7] == '+' ? label . ' +' : label
    let result = result .' '. label 
  endfor
  let start = result->stridx('%#TabLineSel#')
  let current_tab = string(tabpagenr()).'/'.string(tabpagenr('$'))
  return a:shownum? string(num).result.'%#TabLineFill#'
        \: result.'%#TabLineFill#'
endfunction

function bufgroup#_change_tab()
  if exists('t:BufGroupName')
    call bufgroup#open_group(t:BufGroupName)
  endif
  let t:BufGroupOn = 1
endfunction

function bufgroup#_make_tab()
  let new_group = t:BufGroups['all']->deepcopy()->uniq()
  let t:BufGroupOn = 0
  tabnew
  let t:BufGroups = #{all: new_group}
  let t:BufGroupsLocation = #{all: 1}
  let t:BufGroupName = 'all'
  let t:BufGroupOn = 1
  call bufgroup#open_buf(s:BufGroupPrev)
endfunction

function bufgroup#_leave_tab()
  let t:BufGroupOn = 0
  call bufgroup#open_group(t:BufGroupName)
  let s:BufGroupPrev = t:BufGroups['all']
endfunction


function bufgroup#enable()
  autocmd BufNewFile,BufReadPost * :call bufgroup#add('all')
  autocmd TabLeave * :call bufgroup#_leave_tab()
  autocmd TabEnter * :call bufgroup#_change_tab()

  if g:bufgroupmode == 1
    set tabline=
    set showtabline=1
    noremap T :tabnew<CR>
    let g:bufgroupmode=0
  else
    set tabline=%!BufGroupTabLine()
    set showtabline=2
    noremap T :call bufgroup#_make_tab()<CR>
    let g:bufgroupmode=1
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
