" File:    branch.vim
" Author:  kmnk <kmnknmk+vim@gmail.com>
" Version: 0.1.0
" License: MIT Licence

let s:save_cpo = &cpo
set cpo&vim

function! giti#branch#list()"{{{
  return map(
\   split(giti#system('branch'), '\n'),
\   's:build_branch_data(v:val)'
\ )
endfunction"}}}

function! giti#branch#list_all()"{{{
  return map(
\   split(giti#system('branch -a'), '\n'),
\   's:build_branch_data(v:val)'
\ )
endfunction"}}}

function! giti#branch#recent()"{{{
  let branch_list = split(
\   giti#system('for-each-ref --sort=-committerdate --format="%(refname:short),%(committerdate:relative),%(objectname:short),%(contents:subject)" refs/heads/'),
\ '\n')

  return s:build_formatted_branch_data(branch_list)
endfunction"}}}

function! giti#branch#current_name()"{{{
  let current_branch = giti#branch#current()
  return has_key(current_branch, 'name') ? current_branch['name'] : 'master'
endfunction"}}}

function! giti#branch#current()"{{{
  let branches = filter(
\   map(
\     split(giti#system('branch -a'), '\n'),
\     's:build_branch_data(v:val)'
\   ),
\   'v:val.is_current'
\ )
  return len(branches) > 0 ? remove(branches, 0) : {}
endfunction"}}}

function! giti#branch#delete(branches)"{{{
  return giti#system_with_specifics({
\   'command' : 'branch -d ' . join(a:branches),
\   'with_confirm' : 1,
\ })
endfunction"}}}

function! giti#branch#delete_force(branches)"{{{
  return giti#system_with_specifics({
\   'command' : 'branch -D ' . join(a:branches),
\   'with_confirm' : 1,
\ })
endfunction"}}}

function! giti#branch#delete_remote(params) abort "{{{
  if len(a:params) <= 0
    return
  endif

  let results = []
  for param in a:params
    if !has_key(param, 'branch') || len(param.branch) <= 0
      throw 'branch required'
    endif
    call add(results, giti#push#delete_remote_branch(param))
  endfor

  return results
endfunction"}}}

function! giti#branch#create(branch)"{{{
  return giti#checkout#create({'name' : a:branch})
endfunction"}}}

function! giti#branch#switch(branch)"{{{
  return giti#checkout#switch({'name' : a:branch})
endfunction"}}}

" local function {{{
function! s:build_branch_data(line)"{{{
  return {
\   'full_name'  : s:pickup_full_branch_name(a:line),
\   'name'       : s:pickup_branch_name(a:line),
\   'is_current' : s:is_current(a:line),
\   'is_remote'  : s:is_remote(a:line),
\ }
endfunction"}}}

function! s:build_formatted_branch_data(branch_list)"{{{
  let branch_data = map(
\   a:branch_list,
\   's:build_branch_data_from_formatted_line(v:val)'
\ )
  let name_width = 0
  for branch in branch_data
    if strlen(branch.name) > name_width
      let name_width = strlen(branch.name)
    endif
  endfor

  let name_width = name_width + 1
  let name_format = '%-' . name_width . 's'
  return map(
\   branch_data, '{
\    "name" : printf(name_format, v:val.name),
\    "relativedate" : v:val.relativedate,
\    "objectname"   : v:val.objectname,
\    "message"      : v:val.message,
\ }')
endfunction"}}}

function! s:build_branch_data_from_formatted_line(line)"{{{
  let splitted = split(a:line, ",")
  return {
\   'name'         : splitted[0],
\   'relativedate' : splitted[1],
\   'objectname'   : splitted[2],
\   'message'      : join(splitted[3:], ","),
\ }
endfunction"}}}

function! s:pickup_full_branch_name(line)
  return substitute(a:line, '^*\?\s*\(.\+\)', '\1', '')
endfunction

function! s:pickup_branch_name(line)
  if match(a:line, '^*\s*\%((no branch)\)') >= 0
    return '(no branch)'
  endif
  return substitute(a:line, '^*\?\s*\%(remotes/\)\?\([^ ]\+\).*', '\1', '')
endfunction

function! s:is_current(line)"{{{
  return match(a:line, '^*\s*.\+$') < 0 ? 0 : 1
endfunction"}}}

function! s:is_remote(line)"{{{
  return match(a:line, '^*\?\s*remotes/') < 0 ? 0 : 1
endfunction"}}}

" }}}


let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
