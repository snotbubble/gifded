REBOL []
;; script to:
;; - replace org headline indentation with html details+summary tags
;; - replace todo tag with html+js filter & scroll-to
;; - replace org tags with html+js filter & scroll-to
;; made for orgnqq
;; by cpbrown 2022

oph: function [t s d f b] [
	w: format/pad t "" "^-"
	o: join w [
		"<div class=^"" d "^">^/"
		w "^-<details class=^"" b "^">^/"
		w "^-^-<summary class=^"" d "^" id=^"" s "^">" f "</summary>^/"
		w "^-^-<div class=^"cc^">"
	]
	o
]
cla: function [t] [
	w: format/pad t "" "^-"
	o: join w [
		"^-^-</div>"
	]
	o
]
clh: function [t] [
	w: format/pad t "" "^-"
	o: join w [
		;"^-^-</div>^/"
		"^-</details>^/"
		w "</div>^/"
	]
	o
]

ic: [ "a" "b" "c" "d" "e" "f" ]
px: 0
pg: 0
tx: 0
cx: 0
ff: false
dos: copy ""
todos: copy []
cols: copy []

lines: read/lines to-file system/script/args
foreach l lines [
	if parse l [ "<!-- todos:" copy dos to "-->" to end ] [
		replace/all dos "[" ""
		replace/all dos "]" ""
		trim dos
		todos: split dos " "
		repeat x (length? todos)  [
			bb: 1 - (abs ((((x - 1) / ((length? todos) - 1)) * 2.0) - 1))
			bb: ((bb * 0.1) + 0.1)
			gg: ((x - 1) / ((length? todos) - 1))
			rr: 1 - gg
			gg: ((gg * 0.9) + 0.1)
			rr: ((rr * 0.9) + 0.1)
			rr: to-integer (rr * 255)
			gg: to-integer (gg * 255)
			bb: to-integer (bb * 255)
			cc: to-tuple reduce [ rr gg bb ]
			cc: to-hex cc
			append cols todos/:x 
			append cols cc 
		]
	]
	hl: copy ""
	tg: copy ""
	aa: copy ""
	bb: copy ""
	tgs: copy []
	dd: copy ""
	tt: copy ""
	tb: copy ""
	either parse l [ 1 6 "*" " " copy hl to end ] [
		parse l [ copy aa thru "* " ]
		parse hl [ copy hl to ":" copy bb to end ] 
		parse l [ to " [" thru "]" copy hl to end ]
		parse l [ to " [" thru "]" copy hl to ":" copy bb to end ]
		trim hl
		trim bb
		if hl <> "" [
			hlx: copy hl
			replace/all hlx " " "_"
			parse hlx [ to "_[" remove thru "]" ]
			if parse l [ thru "[" copy tg to "]"  to end ] [
				replace tg " " "_"
				tb: join tb [ " " tg ]
				either (length? cols) > 1 [
					dd: join "" [ "<span class=^"ttag^" style=^"color:#" (select cols tg) "; mix-blend-mode: screen;^"><a href=^"#" hlx "^" onclick=^"tc('" tg "', '" hlx "');^">[" tg "]</a></span>" ]
				] [
									dd: join "" [ "<span class=^"ttag^"><a href=^"#" hlx "^" onclick=^"tc('" tg "', '" hlx "');^">[" tg "]</a></span>" ]
				]
			]
			if bb <> "" [
				tg: ""
				parse bb [ 1 5 [ thru ":" copy tg (append tgs tg) to ":" ] ]
				replace tg " " "_"
				if (length? tgs) > 0 [
					foreach t tgs [
						unless t = "" [
							tb: join tb [ " " t ]
							tt: join tt [ "<span class=^"htag^"><a href=^"#" hlx "^" onclick=^"tc('" t "', '" hlx "');^">:" t ":</a></span>" ]
						]
					]
				]
			]
			trim tb
			cx: (length? aa) - 2
			pp: cx + cx
			gg: cx + cx
			ll: join "" [ dd hl tt ]
			;print ll
			ss: copy ""
			ee: copy ""
			cc: copy ""
			;gg = px
			if ff == true [ cc: cla pg ]
			if px >= cx [
				if px > cx [ gg: (px + px) ]
				if ff = true [ ee: clh pg ]
				loop (px - cx) [
					gg: gg - 2
					hh: clh gg
					ee: join "" [ ee hh ]
				]
			]
			ss: oph pp hlx ic/(cx + 1) ll tb
			;print ss
			ee: join "" [ cc "^/" ee ss ]
			ff: true
			px: cx
			pg: gg
			;l: join ee [ ll ]
			;print ee
			l: ee
		]
		print l
	] [
		print l
	]
]
ee: copy ""
gg: 0
px: px + 1
print cla px
if px >= 0 [
	if px > 0 [ gg: (px + px) ]
	loop (px) [ 
		gg: gg - 2 
		hh: clh gg
		print hh
	]
]
print "</HTML>"
