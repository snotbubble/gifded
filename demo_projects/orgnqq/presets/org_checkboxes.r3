REBOL []
;; script to style org checkboxes
;; made for orgnqq
;; by cpbrown 2002

spc: charset " ^-"
cqq: charset " -X"

amxmp: false
ampre: false
amsum: false
amprop: false
amcomment: false

lines: read/lines to-file system/script/args
foreach l lines [
	h: copy ""
	c: copy ""
	t: copy l
	chq: true
	trim t

;; block checks

	if parse t [ to "<xmp" to end ] [ amxmp: true chq: false ]
	if parse t [ to "<pre" to end ] [ ampre: true chq: false ]
	if parse t [ to "<summary" to end ] [ amsum: true chq: false ]
	if parse/case t [ to ":PROPERTIES:" to end ] [ amprop: true chq: false ]

	if parse t [ to "</xmp" to end ] [ amxmp: false ]
	if parse t [ to "</pre" to end ] [ ampre: false ]
	if parse t [ to "</summary" to end ] [ amsum: false ]
	if parse/case t [ to ":END:" to end ] [ amprop: false ]

;; html comment
;; this script doesn't handle multiline comments that start mid-line, 
;; keep thes on their own line if possible
	if parse t [ to "<!--" to end ] [ amcomment: true chq: false ]
	if parse t [ to "-->" to end ] [ amcomment: false ]

;; org escape check
	if t/1 = #"," [ lst: false ]

;; special case checks
	if parse t [ [ "#+" | "<details" ] to end ] [ chq: false ]

	if chq and (not amxmp) and (not ampre) and (not amsum) and (not amprop) and (not amcomment) [
		if parse l [ 0 16 spc "- [" some cqq "]" copy h to end ] [
			parse l [ to "- [" thru "- " copy c thru "]" to end ]
			t: join "" [ "<span style=^"box-shadow: 1px 1px 1px #222222, -1px -1px 1px #666666; font-family: exacto; mix-blend-mode: luminosity;^">" c "</span>" ]
			parse l [ to "- [" thru "- " a: remove thru "]" :a insert (t) ]
		]
	]
	print l
]
