"
" gpl.vim - Helen's gpl plugin
"
" Version 0.0.0, 3 Jun 2018

if exists("g:loaded_gpl")
	delfun s:DeleteCurrentHeader
	delfun s:ProcessGPL
	delfun s:AddGPL
endif
let g:loaded_gpl = 1

fun s:DeleteCurrentHeader()
	while 1
		call cursor(1, 1)
		let line = getline(1)
		if line[0:1] == "//"
			d
		else
			break
		endif
	endwhile
endfun

fun s:AddGPL(heading)
	let heading = a:heading
	call append(0, "// " . heading)
	call append(1, "// Copyright (C) 2019 Helen Ginn")
	call append(2, "// ")
    call append(3, "// This program is free software: you can redistribute it and/or modify")
    call append(4, "// it under the terms of the GNU General Public License as published by")
    call append(5, "// the Free Software Foundation, either version 3 of the License, or")
    call append(6, "// (at your option) any later version.")
    call append(7, "// ")
    call append(8, "// This program is distributed in the hope that it will be useful,")
    call append(9, "// but WITHOUT ANY WARRANTY; without even the implied warranty of")
    call append(10, "// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the")
    call append(11, "// GNU General Public License for more details.")
    call append(12, "// ")
    call append(13, "// You should have received a copy of the GNU General Public License")
    call append(14, "// along with this program.  If not, see <https://www.gnu.org/licenses/>.")
    call append(15, "// ")
    call append(16, "// Please email: vagabond @ hginn.co.uk for more details.")

endfun


fun s:ProcessGPL()
	let heading = input("One line statement at top of GPL header: ")
	let devnull = s:DeleteCurrentHeader()
	let devnull = s:AddGPL(heading)
endfun

command! GPL :call s:ProcessGPL()

