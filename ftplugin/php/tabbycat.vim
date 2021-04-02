"
" Tabbycat.vim - Tom's indentation plugin
"
" Version 0.0.2, 7 Dec 2016
"
" (Plus a few modifications by Helen for robustness - 24 Feb 2018)
" (+ even more modifications to deal with comments etc.)

"if exists("g:loaded_tabbycat")
"    delfun s:OpenLine
"    delfun s:OpenLineAbove
"    delfun s:NoTrail
"    delfun s:PairedCount
"    delfun s:SpaceCount
"    delfun s:CurlyCount
"    delfun s:TabCount
"    delfun s:GetIndent
"    delfun s:EditReturn
"    delfun s:TabbycatIndent
"    delfun s:LineLabelVeto
"    delfun s:IndentLine
"    delfun s:BlankLine
"endif
let g:loaded_tabbycat = 1

setlocal noautoindent
setlocal nocindent
setlocal nosmartindent
setlocal indentexpr=<SNR>TabbycatIndent()

nnoremap <buffer> <silent> o :call <SID>OpenLine()<cr>A
nnoremap <buffer> <silent> O :call <SID>OpenLineAbove()<cr>A
inoremap <buffer> <silent> <expr> <return> <SID>EditReturn()
nnoremap <buffer> <silent> = :call <SID>IndentLine()<cr>
vnoremap <buffer> <silent> = :call <SID>IndentLine()<cr>

" Check on blanks
aug tabbycat
    au!
    au InsertLeave * call <SID>NoTrail(line('.'))
aug END

" Overrule any other automatic indentation
" Shouldn't be necessary?
fun s:TabbycatIndent(line)
    echomsg "Tabbycat indent"
    return 0
endfun

" ---------------------------------------------------------------------------

" Clean up blank lines (indents only) when leaving insert mode
fun s:NoTrail(line)
    if ('cpo' !~ 'I')
        s/^\s*$//e
    endif
endfun


fun s:BlankLine(lcon)
    let bcheck = a:lcon
    let bcheck = substitute(bcheck, "\s+", "", "")
    if len(a:lcon) == 0
        return 1
    endif
    return 0
endfun

" Count total number of opens and closes on previous line
" If get_index is 1, it will return the index of the
" last unmatched open character.
" if get_index is 2, it will return the index of the
" previous unmatched open character.
fun s:PairedCount(line, open, close, get_index)
    let line = a:line
    let open = a:open
    let close = a:close
    let get_index = a:get_index
	let nbrackets = 0
	let check = 0
	let squote = 0
	let dquote = 0
	let comment = 0
	let stack = []
	
	while check < strlen(line)
		" what is it? it's a comment!
		if line[check:check+1] == "//"
		 	if get_index == 0
				return 0
			else
				return -1
			endif
		endif
		if line[check:check+1] == "/*"
			let comment = 1
		endif
		if line[check:check+1] == "*/"
			let comment = 0
		endif
		" escape the next character
		if line[check] == "\\"
			let check += 1
		else
			if line[check] == "\""
				let dquote = !dquote
			endif
			if line[check] == "'" && !dquote
				let squote = !squote
			endif
			if !squote && !dquote && !comment
				if line[check] == open
					let nbrackets += 1
					call add(stack, check)
				endif
				if line[check] == close
					let nbrackets -= 1
					if len(stack) > 0
						call remove(stack, -1)
					endif
				endif
			endif
		endif
		let check += 1
	endwhile
	
	if get_index == 0
		return nbrackets
	elseif get_index > 0 && len(stack) < get_index
		return -1
	elseif get_index > 0
		return stack[-get_index]
	endif
endfun

" Labelled lines should have no indent
fun s:LineLabelVeto(line)
	let line = a:line
	let veto = 0
	if line[-1:] == ":"
		let veto = 1
	endif
	" make exception for switch statements
	if line =~ "case" || line =~ "default" || line =~ "\*"
		let veto = 0
	endif
	return veto
endfun

fun s:TabCount(line)
	let line = a:line
    let nind = 0
    while line[nind] == "\t"
        let nind += 1
    endwhile
	return nind
endfun

fun s:SpaceCount(line)
	let line = a:line
	let nspace = 0
    let nind = s:TabCount(line)
    while line[nind+nspace] == " "
        let nspace += 1
    endwhile
	return nspace
endfun

fun s:CurlyCount(line)
	let line = a:line
	let foundClosed = 0
	let n = 0
    while n < strlen(line)
		if !foundClosed && line[n] == "}"
			let foundClosed = 1
		elseif foundClosed == 1 && line[n] == "{"
			let foundClosed = 2
		elseif !foundClosed && line[n] == "{"
			return 0
		elseif foundClosed == 2 && (line[n] == "{" || line[n] == "}")
			return 0
		endif
		let n += 1
    endwhile
	return foundClosed
endfun

fun s:GetIndent(lnum, thismod)
    let lnum = a:lnum
    let bb = 0
	let lthis = getline(lnum+1)
    let lcon = getline(lnum)
	let thismod = a:thismod

    " Find the last non-blank line to base the indent off
    while s:BlankLine(lcon)
		let lnum -= 1
        let lcon = getline(lnum)
		if lnum < 0
			return ""
		endif
        let bb += 1
    endwhile

    " Count number of indents
    let nind = s:TabCount(lcon)

    " Count number of alignment spaces
    let nspace = s:SpaceCount(lcon)
 
    " If previous line had indentation veto,
    " we want to reset the indentation to the last non-vetoed
    " line before that.
    if s:LineLabelVeto(lcon)
		let nvnum = lnum
		let veto = 1
		while veto > 0 && nvnum >= 0
			let nvnum -= 1
			if s:LineLabelVeto(getline(nvnum)) == 0
				let nind = s:TabCount(getline(nvnum))
				if nind > 0
					let veto = 0
				endif
			endif
		endwhile
    endif

    " Get all the curly brackets {} from previous and current line
	
	let lastcurlies = s:PairedCount(lcon, "{", "}", 0)
	let thiscurlies = s:PairedCount(lthis, "{", "}", 0)

	" This line is allowed one free { which is not indented
	" but if it is present then we reset space alignment
	if thiscurlies > 0
		let nspace = 0
		let thiscurlies -= 1
	endif
	"
	" Last line is allowed one free } which is not indented
	if lastcurlies < 0
		let lastcurlies += 1
	endif

	if thismod == 0
		let thiscurlies = 0
	endif
	
	let nind += lastcurlies + thiscurlies

	" One exception is: } ... { as in else clauses.
	if s:CurlyCount(lthis) == 2 && thiscurlies == 0
		let nind -= 1
	endif

	if s:CurlyCount(lcon) == 2 && lastcurlies == 0
		let nind += 1
	endif

	" Never go below zero tabs
	if nind < 0
		let nind = 0
	endif	

	" First we need to determine if there have been any unmatched brackets.
	" We stop counting when the previous line no longer has spaces.
	" Also need to keep track of last positive unmatched pair (last_pos).
	let last_pos = 0
    let unm = s:PairedCount(strpart(lcon, nind), "(", ")", 0)
    let unm += s:PairedCount(strpart(lcon, nind), "[", "]", 0)
	let change = unm

	if unm > 0
		let last_pos = lnum
	endif

	let nspace = s:SpaceCount(lcon)

	let prevnum = lnum
	while nspace > 0 && prevnum >= 0
		let prevnum -= 1
		let lcon = getline(prevnum)
		let newunm = s:PairedCount(strpart(lcon, nind), "(", ")", 0)
		let newunm += s:PairedCount(strpart(lcon, nind), "[", "]", 0)
		let unm += newunm
		if newunm > 0 && last_pos == 0
			let last_pos = prevnum
		endif
		let nspace = s:SpaceCount(lcon)
	endwhile

    " If there are unmatched brackets, position cursor at the first one
    " on the previous line
    if change >= 0
	    let unm = s:PairedCount(strpart(lcon, nind), "(", ")", 1)
    	if unm != -1
	    	let nspace = unm + 1
		else
	    	let unm = s:PairedCount(strpart(lcon, nind), "[", "]", 1)
	    	if unm != -1
	    		let nspace = unm + 1
	  	  	else
	 	   		let nspace = 0
	 	  	endif
   		 endif
	endif

	let lcon = getline(lnum)
	let comment = 0

	let curr = s:TabCount(lcon) + s:SpaceCount(lcon)
	if lcon[curr:curr+1] == '/*' || lcon[curr] == '*'
		let comment = 1
	endif
	let lthis = getline(lnum+1)
	let curr = s:TabCount(lthis) + s:SpaceCount(lthis)
	if lthis[curr] != '*'
		let comment = 0
	endif
    
	if comment > 0
		let nspace = 1
	endif
    
    " Sometimes a keyword will veto any indent!
    if s:LineLabelVeto(lthis) && thismod == 1
    	let nind = 0
    endif

    let a = repeat("\t", nind)
    let b = repeat(" ", nspace)
"   echomsg "Back ".bb." lines (".nind.":".nspace.")"
    return a.b

endfun


fun s:EditReturn()
    return "\n".<SID>GetIndent(line('.'), 0)
endfun


fun s:OpenLine()
    let lnum = line('.')
    let ind = <SID>GetIndent(lnum, 0)
    call append(lnum, ind)
    call cursor(lnum+1, 1)
endfun


fun s:OpenLineAbove()
    let lnum = line('.')
    let ind = <SID>GetIndent(lnum-1, 0)
    call append(lnum-1, ind)
    call cursor(lnum, 1)
endfun


fun s:IndentLine()
    let lnum = line('.')
    let ind=<SID>GetIndent(lnum-1, 1)
    sil exe "normal 0c^".ind
endfun
