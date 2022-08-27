REBOL []
; <span class="htag"><a href="#vala gui program" onclick="tc('program', 'vala gui program');">:program:</a></span>

lines: split system/script/args "^/"
foreach l lines [
	hl: copy ""
	tg: copy ""
	aa: copy ""
	tgs: copy []
	;if parse l [ 1 9 "*" thru " " thru ":" copy tg to ":" to end ] [ probe tg ]
	if parse l [ 1 6 "*" thru " " copy hl to ":" to end ] [
		parse l [ copy aa thru "* " ]
		;probe aa
		parse l [ 1 5 [ thru ":" copy tg (append tgs tg) to ":" ]]
		if (length? tgs) > 0 [
			trim hl
			k: copy ""
			foreach t tgs [
				unless t = "" [
					;probe t
					k: join k [ "<span class=^"htag^"><a href=^"#" hl "^"onclick=^"tc('" t "', '" hl "');"">:" t ":</a></span>" ]
				]
			]
			;probe k
			parse l [ to ":" remove thru end insert (k) ]
			l: join "" [ aa hl k ]
			;print l
		]
	]
	print l
]
