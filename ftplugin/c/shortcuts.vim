if exists("g:loaded_shortcuts")
    delfun s:CreateForLoop
endif
let g:loaded_shortcuts = 1

" `b to create two {}s.
:imap `b o{}=ko

" `s to create a std::cout << std::endl;
:imap `s std::cout << std::endl;Bha

" `h to turn a pasted function from .cpp file into a header declaration
:imap `h p=^Wllbdwxx$a;

" `i to create an if statement
:imap `i if ()`bddkk$ba

" `n to run ninja in insert mode?
:imap `n :Ninja
:nmap `n :Ninja

imap `f :call <SID>CreateForLoop()<CR>

fun s:CreateForLoop()
	let lnum = line('.')
	call setline(lnum, "for (;;)")
	normal =f;
	redraw!
	let vartype = input("type i for int, s for size_t, none to stop: ")
	
	if vartype == ""
		return
	elseif vartype == "i"
		normal iint 
	elseif vartype == "s"
		normal isize_t 
	endif

	redraw!
	let varname = input("enter your variable name: ")

	normal "=varnamepa =  

	normal i0f;li "=varnamepa < f;a "=varnamepa++$a`bddkk$BBa

	startinsert
endfun

