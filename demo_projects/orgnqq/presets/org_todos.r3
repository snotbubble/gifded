REBOL []
; <span class="htag"><a href="#vala gui program" onclick="tc('program', 'vala gui program');">:program:</a></span>

lines: split system/script/args "^/"
foreach l lines [
	hl: copy ""
	tg: copy ""
	aa: copy ""
	bb: copy ""
	tgs: copy []
	if parse l [ 1 6 "*" " [" thru "]" copy hl to end ] [
		parse l [ 1 6 "*" " [" thru "]" copy hl to ":" copy bb to end ]
		trim hl
		if hl <> "" [
			;print hl
			parse l [ copy aa thru "* " ]
			;print aa
			parse l [ thru "[" copy tg to "]" ]
			;print tg
			k: join "" [ "<span class=^"htag^"><a href=^"#" hl "^" onclick=^"tc('" tg "', '" hl "');"">[" tg "]</a></span>" ]
			;print k
			l: join aa [ k hl " " bb ]
			print l
		]
	]
	;print l
]

