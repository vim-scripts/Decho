" Decho.vim:   Debugging support for VimL
" Last Change: Apr 21, 2004
" Maintainer:  Charles E. Campbell, Jr. PhD <cec@NgrOyphSon.gPsfAc.nMasa.gov>
" Version:     6
"
" Usage:
"   Decho "a string"
"   call Decho("another string")
"   let g:decho_bufname= "ANewDBGBufName"
"   call Decho("one","thing","after","another")
"   DechoOn  : removes any first-column '"' from lines containing Decho
"   DechoOff : inserts a '"' into the first-column in lines containing Decho

" ---------------------------------------------------------------------

" Prevent duplicate loading
if exists("g:loaded_Decho") || &cp
 finish
endif

"  Default Values For Variables:
if !exists("g:decho_bufname")
 let g:decho_bufname= "DBG"
endif
if !exists("s:decho_depth")
 let s:decho_depth  = 0
endif

" ---------------------------------------------------------------------
"  User Interface:
com! -nargs=+ -complete=expression Decho call Decho(<args>)
com! -nargs=0 DechoOn  g/\<D\(echo\|func\|ret\)\>/s/^"//
com! -nargs=0 DechoOff g/\<D\(echo\|func\|ret\)\>/s/^/"/

" ---------------------------------------------------------------------
" Decho: this splits the screen and writes messages to a small
"        window (5 lines) on the bottom of the screen
fun! Decho(...)
 
  let curbuf= bufnr("%")

  " As needed, create/switch-to the DBG buffer
  if !bufexists(g:decho_bufname)
   " if requested DBG-buffer doesn't exist, create a new one
   " at the bottom of the screen.
   bot 5new
   exe "file ".g:decho_bufname

  elseif bufwinnr(g:decho_bufname) > 0
   " if requested DBG-buffer exists in a window,
   " go to that window (by window number)
   exe bufwinnr(g:decho_bufname)."wincmd W"

  else
   " user must have closed the DBG-buffer window.
   " create a new one at the bottom of the screen.
   bot 5new
   exe "b ".bufnr(g:decho_bufname)
  endif
  set ft=Decho
  setlocal noswapfile noro nobl

  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile

  " Initialize message
  let smsg   = ""
  let idepth = 0
  while idepth < s:decho_depth
   let smsg   = "|".smsg
   let idepth = idepth + 1
  endwhile

  " Handle special characters (\t \r \n)
  let i    = 1
  while msg != ""
   let chr  = strpart(msg,0,1)
   let msg  = strpart(msg,1)
   if char2nr(chr) < 32
   	let smsg = smsg.'^'.nr2char(64+char2nr(chr))
   else
    let smsg = smsg.chr
   endif
  endwhile

  " Write Message to DBG buffer
  let res=append("$",smsg)
  set nomod

  " Put cursor at bottom of DBG window, then return to original window
  norm! G
  wincmd p
endfun

" ---------------------------------------------------------------------
"  Dfunc: just like Decho, except that it also bumps up the depth
"         It also appends a "{" to facilitate use of %
fun! Dfunc(...)
  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile
  let msg= msg." {"
  call Decho(msg)
  let s:decho_depth= s:decho_depth + 1
  let s:Dfunclist_{s:decho_depth}= substitute(msg,'[( \t].*$','','')
endfun

" ---------------------------------------------------------------------
"  Dret: just like Decho, except that it also bumps down the depth
"        It also appends a "}" to facilitate use of %
fun! Dret(...)
  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile
  let msg= msg." }"
  call Decho("return ".msg)
  if s:decho_depth > 0
   let retfunc= substitute(msg,'\s.*$','','')
   if  retfunc != s:Dfunclist_{s:decho_depth}
   	echoerr "Dret: appears to be called by<".s:Dfunclist_{s:decho_depth}."> but returning from<".retfunc.">"
   endif
   unlet s:Dfunclist_{s:decho_depth}
   let s:decho_depth= s:decho_depth - 1
  endif
endfun

" ---------------------------------------------------------------------
