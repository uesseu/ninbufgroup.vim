# Ninbufgroup.vim
## What is this?
Simple buffer group manager for vim.

This plugin makes simple dictionary of buffers,
and offers ui like 'tab group' of web browsers.

## Why?
This is a simple program. For me, searching, learning and configuring such plugin takes more time than writing code by myself. This is the only reason. ;-(

## Example
Enable the plugin.

```vim
au VimEnter * call bufgroup#toggle()
```


And then, I wrote some keymaps and commands.
```vim
noremap gN :call bufgroup#next()<CR>
noremap gP :call bufgroup#prev()<CR>
noremap gn :bn<CR>
noremap gp :bp<CR>
noremap gd :call bufgroup#remove_group()<CR>
command! -nargs=1 BufGroupNew :call bufgroup#new(<f-args>)
command! -nargs=1 -complete=customlist,_BufComp
      \ BufGroupAdd :call bufgroup#add(<f-args>)
command! -nargs=1 -complete=customlist,_BufComp
      \ BufGroupAddAll :call bufgroup#add_all('<args>')
command! -nargs=1 -complete=customlist,_BufComp
      \ BufgroupOpen :call bufgroup#open_group('<args>')
command! -nargs=1 BufGroupFilter :call bufgroup#filter(<f-args>)
command! -nargs=1 BufGroupNewFilter :call bufgroup#new_filter(<f-args>)
```


## TODO
Documentation is not written yet.
