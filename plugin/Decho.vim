" Decho.vim:   Debugging support for VimL
" Maintainer:  Charles E. Campbell, Jr. PhD <cec@NgrOyphSon.gPsfAc.nMasa.gov>
" Date:        Nov 22, 2005
" Version:     12
"
" Usage: {{{1
"   Decho "a string"
"   call Decho("another string")
"   let g:decho_bufname = "ANewDBGBufName"
"   let g:decho_bufenter= 1    " tells Decho to ignore BufEnter, WinEnter,
"                              " WinLeave events while Decho is working
"   call Decho("one","thing","after","another")
"   DechoOn     : removes any first-column '"' from lines containing Decho
"   DechoOff    : inserts a '"' into the first-column in lines containing Decho
"   DechoMsgOn  : use echomsg instead of DBG buffer
"   DechoMsgOff : turn debugging off
"   DechoVarOn [varname] : use variable to write debugging messages to
"   DechoVarOff : turn debugging off
"
" GetLatestVimScripts: 642 1 :AutoInstall: Decho.vim
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_Decho") || &cp
 finish
endif
let g:loaded_Decho = "v12"
let s:keepcpo      = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Default Values For Variables: {{{1
if !exists("g:decho_bufname")
 let g:decho_bufname= "DBG"
endif
if !exists("s:decho_depth")
 let s:decho_depth  = 0
endif
if !exists("g:decho_winheight")
 let g:decho_winheight= 5
endif
if !exists("g:decho_bufenter")
 let g:decho_bufenter= 0
endif
if !exists("g:dechomsg")
 let g:dechomsg= 0
endif
if !exists("g:dechovar_enabled")
 let g:dechovar_enabled= 0
endif
if !exists("g:dechovarname")
 let g:dechovarname = "g:dechovar"
endif

" ---------------------------------------------------------------------
"  User Interface: {{{1
com! -nargs=+ -complete=expression Decho	call Decho(<q-args>)
com! -nargs=+ -complete=expression Dredir	call Dredir(<q-args>)
com! -nargs=0 -range=% DechoOn				call DechoOn(<line1>,<line2>)
com! -nargs=0 -range=% DechoOff				call DechoOff(<line1>,<line2>)
com! -nargs=0 Dhide    						call s:Dhide(1)
com! -nargs=0 Dshow    						call s:Dhide(0)
com! -nargs=0 DechoMsgOn					let  g:dechomsg= 1
com! -nargs=0 DechoMsgOff					let  g:dechomsg= 0
com! -nargs=? DechoVarOn					call s:DechoVarOn(<args>)
com! -nargs=0 DechoVarOff					call s:DechoVarOff()

" ---------------------------------------------------------------------
" Decho: the primary debugging function: splits the screen as necessary and {{{1
"        writes messages to a small window (g:decho_winheight lines)
"        on the bottom of the screen
fun! Decho(...)
 
  " make sure that SaveWinPosn() and RestoreWinPosn() are available
  if !exists("g:loaded_cecutil")
   runtime plugin/cecutil.vim
   if !exists("g:loaded_cecutil") && exists("g:loaded_asneeded")
   	AN SaveWinPosn
   endif
   if !exists("g:loaded_cecutil")
   	echoerr "***Decho*** need to load <cecutil.vim>"
	return
   endif
  endif

  if !g:dechomsg && !g:dechovar_enabled
   call SaveWinPosn()
   let curbuf= bufnr("%")
   if g:decho_bufenter
    let eikeep= &ei
    set ei=BufEnter,WinEnter,WinLeave
   endif
 
   " As needed, create/switch-to the DBG buffer
   if !bufexists(g:decho_bufname) && bufnr("*/".g:decho_bufname."$") == -1
    " if requested DBG-buffer doesn't exist, create a new one
    " at the bottom of the screen.
    exe "keepjumps silent bot ".g:decho_winheight."new ".g:decho_bufname
    setlocal bt=nofile
 
   elseif bufwinnr(g:decho_bufname) > 0
    " if requested DBG-buffer exists in a window,
    " go to that window (by window number)
    exe "keepjumps ".bufwinnr(g:decho_bufname)."wincmd W"
    exe "res ".g:decho_winheight
 
   else
    " user must have closed the DBG-buffer window.
    " create a new one at the bottom of the screen.
    exe "keepjumps silent bot ".g:decho_winheight."new"
    setlocal bt=nofile
    exe "keepjumps b ".bufnr(g:decho_bufname)
   endif
 
   set ft=Decho
   setlocal noswapfile noro nobl
 
   "  make sure DBG window is on the bottom
   wincmd J
  endif

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

  if g:dechomsg
   exe "echomsg '".substitute(smsg,"'","'.\"'\".'","ge")."'"
  elseif g:dechovar_enabled
   if exists(g:dechovarname)
    exe "let ".g:dechovarname."= '".g:dechovarname."'.'\n".smsg."'"
   else
    exe "let ".g:dechovarname."= '".smsg."'"
   endif
  else
   " Write Message to DBG buffer
   setlocal ma
   keepjumps $
   keepjumps let res= append("$",smsg)
   setlocal nomod
 
   " Put cursor at bottom of DBG window, then return to original window
   exe "res ".g:decho_winheight
   keepjumps norm! G
   if exists("g:decho_hide") && g:decho_hide > 0
    setlocal hidden
    q
   endif
   keepjumps wincmd p
   call RestoreWinPosn()
 
   if g:decho_bufenter
    let &ei= eikeep
   endif
  endif
endfun

" ---------------------------------------------------------------------
"  Dfunc: just like Decho, except that it also bumps up the depth {{{1
"         It also appends a "{" to facilitate use of %
"         Usage:  call Dfunc("functionname([opt arglist])")
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
"  Dret: just like Decho, except that it also bumps down the depth {{{1
"        It also appends a "}" to facilitate use of %
"         Usage:  call Dret("functionname [optional return] [: optional extra info]")
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
   let retfunc= substitute(msg,'\s.*$','','e')
   if  retfunc != s:Dfunclist_{s:decho_depth}
   	echoerr "Dret: appears to be called by<".s:Dfunclist_{s:decho_depth}."> but returning from<".retfunc.">"
   endif
   unlet s:Dfunclist_{s:decho_depth}
   let s:decho_depth= s:decho_depth - 1
  endif
endfun

" ---------------------------------------------------------------------
" DechoOn: {{{1
fun! DechoOn(line1,line2)
"  call Dfunc("DechoOn(line1=".a:line1." line2=".a:line2.")")

  call SaveWinPosn()
  exe "keepjumps ".a:line1.",".a:line2.'g/\<D\%(echo\|func\|redir\|ret\|echo\%(Msg\|Var\)O\%(n\|ff\)\)\>/s/^"\+//'
  call RestoreWinPosn()

"  call Dret("DechoOn")
endfun

" ---------------------------------------------------------------------
" DechoOff: {{{1
fun! DechoOff(line1,line2)
"  call Dfunc("DechoOff(line1=".a:line1." line2=".a:line2.")")

  call SaveWinPosn()
  exe "keepjumps ".a:line1.",".a:line2.'g/\<D\%(echo\|func\|redir\|ret\|echo\%(Msg\|Var\)O\%(n\|ff\)\)\>/s/^[^"]/"&/'
  call RestoreWinPosn()

"  call Dret("DechoOff")
endfun

" ---------------------------------------------------------------------

" DechoDepth: allow user to force depth value {{{1
fun! DechoDepth(depth)
  let s:decho_depth= a:depth
endfun

" ---------------------------------------------------------------------
" Dhide: (un)hide DBG buffer {{{1
fun! <SID>Dhide(hide)

  if !bufexists(g:decho_bufname) && bufnr("*/".g:decho_bufname."$") == -1
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
     exe curwin."wincmd W"
	endif
   endif

  else
   " The DBG-buffer window is currently hidden.
   if a:hide == 0
	let curwin= winnr()
    exe "silent bot ".g:decho_winheight."new"
    setlocal bh=wipe
    exe "b ".bufnr(g:decho_bufname)
    exe curwin."wincmd W"
   else
   	let g:decho_hide= a:hide
   endif
  endif
  let g:decho_hide= a:hide
endfun

" ---------------------------------------------------------------------
" Dredir: this function performs a debugging redir by temporarily using {{{1
"         register a in a redir @a of the given command.  Register a's
"         original contents are restored.
fun! Dredir(...)
  if a:0 <= 0
   return
  endif
  let cmd  = a:1
  let icmd = 2
  while icmd <= a:0
   call Decho(a:{icmd})
   let icmd= icmd + 1
  endwhile

  " save register a, initialize
  let keep_rega = @a
  let v:errmsg  = ''

  " do the redir of the command to the register a
  try
   redir @a
    exe "keepjumps silent ".cmd
  catch /.*/
   let v:errmsg= substitute(v:exception,'^[^:]\+:','','e')
  finally
   redir END
   if v:errmsg == ''
   	let output= @a
   else
   	let output= v:errmsg
   endif
   let @a= keep_rega
  endtry

  " process output via Decho()
  while output != ""
   if output =~ "\n"
   	let redirline = substitute(output,'\n.*$','','e')
   	let output    = substitute(output,'^.\{-}\n\(.*$\)$','\1','e')
   else
   	let redirline = output
   	let output    = ""
   endif
   call Decho("redir<".cmd.">: ".redirline)
  endwhile
endfun

" ---------------------------------------------------------------------
"  DechoVarOn: turu debugging-to-a-variable on.  The variable is given {{{1
"  by the user;   DechoVarOn [varname]
fun! s:DechoVarOn(...)
  let g:dechovar_enabled= 1
  if a:0 > 0
   if a:1 =~ '^g:'
    exe "let ".a:1.'= ""'
   else
    exe "let g:".a:1.'= ""'
   endif
  else
   let g:dechovarname= "g:dechovar"
  endif
endfun

" ---------------------------------------------------------------------
" DechoVarOff: {{{1
fun! s:DechoVarOff()
"  call Dfunc("DechoVarOff()")
  if exists("g:dechovarname")
   if exists(g:dechovarname)
    exe "unlet ".g:dechovarname
   endif
  endif
  let g:dechovar_enabled= 0
"  call Dret("DechoVarOff")
endfun

let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
"  vim: ts=4 fdm=marker
