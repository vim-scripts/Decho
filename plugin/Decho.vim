" Decho.vim:   Debugging support for VimL
" Last Change: Jun 07, 2004
" Maintainer:  Charles E. Campbell, Jr. PhD <cec@NgrOyphSon.gPsfAc.nMasa.gov>
" Version:     8	ASTRO-ONLY
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
if !exists("g:decho_winheight")
 let g:decho_winheight= 5
endif

" ---------------------------------------------------------------------
"  User Interface:
com! -nargs=+ -complete=expression Decho call Decho(<args>)
com! -nargs=0 DechoOn  call DechoOn()
com! -nargs=0 DechoOff call DechoOff()
com! -nargs=0 Dhide    call <SID>Dhide(1)
com! -nargs=0 Dshow    call <SID>Dhide(0)

" ---------------------------------------------------------------------
" Decho: this splits the screen and writes messages to a small
"        window (g:decho_winheight lines) on the bottom of the screen
fun! Decho(...)
 
  let curbuf         = bufnr("%")

  " As needed, create/switch-to the DBG buffer
  if !bufexists(g:decho_bufname)
   " if requested DBG-buffer doesn't exist, create a new one
   " at the bottom of the screen.
   exe "silent bot ".g:decho_winheight."new ".g:decho_bufname

  elseif bufwinnr(g:decho_bufname) > 0
   " if requested DBG-buffer exists in a window,
   " go to that window (by window number)
   exe bufwinnr(g:decho_bufname)."wincmd W"

  else
   " user must have closed the DBG-buffer window.
   " create a new one at the bottom of the screen.
   exe "silent bot ".g:decho_winheight."new"
   setlocal bh=wipe
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
  exe "res ".g:decho_winheight
  norm! G
  if exists("g:decho_hide")
   setlocal hidden
   q
  endif
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
" DechoOn:
fun! DechoOn()
  call SaveWinPosn()
  g/\<D\(echo\|func\|ret\)\>/s/^"//
  call RestoreWinPosn()
endfun

" ---------------------------------------------------------------------
" DechoOff:
fun! DechoOff()
  call SaveWinPosn()
  g/\<D\(echo\|func\|ret\)\>/s/^/"/
  call RestoreWinPosn()
endfun

" ---------------------------------------------------------------------

" DechoDepth: allow user to force depth value
fun! DechoDepth(depth)
  let s:decho_depth= a:depth
endfun

" ---------------------------------------------------------------------
" Dhide: (un)hide DBG buffer
fun! <SID>Dhide(hide)

  if !bufexists(g:decho_bufname)
   " DBG-buffer doesn't exist, simply set g:decho_hide
   let g:decho_hide= a:hide

  elseif bufwinnr(g:decho_bufname) > 0
   " DBG-buffer exists in a window, so its not currently hidden
   if a:hide == 0
   	" already visible!
    let g:decho_hide= a:hide
   else
   	" need to hide window.  Goto window and make hidden
	let curwin = winnr()
	let dbgwin = bufwinnr(g:decho_bufname)
    exe bufwinnr(g:decho_bufname)."wincmd W"
	setlocal hidden
	q
	if dbgwin != curwin
	 " return to previous window
     exe bufwinnr(curwin)."wincmd W"
	endif
   endif

  else
   " The DBG-buffer window is currently hidden.
   if a:hide == 0
	let curwin= winnr()
    exe "silent bot ".g:decho_winheight."new"
    setlocal bh=wipe
    exe "b ".bufnr(g:decho_bufname)
    exe bufwinnr(curwin)."wincmd W"
   else
   	let g:decho_hide= a:hide
   endif
  endif
  let g:decho_hide= a:hide
endfun

" ---------------------------------------------------------------------
