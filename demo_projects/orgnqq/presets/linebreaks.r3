REBOL []
;; insert <br> breaks at the end of each line of plaintext content
;; css block white-space: pre accumulates linebreaks with lists
;; so have to do it the hard way
;;
;; made for orgnqq
;; by cpbrown 2022

lines: read/lines to-file system/script/args

amarticle: false
amxmp: false
ampre: false
amul: false
amol: false
amtbl: false

foreach l lines [
	skipme: false 
	if parse l [ to "</li>" to end ] [ skipme: true ]
	if parse l [ to "class=^"cc^"" to end ] [ amarticle: true skipme: true]
	if parse l [ to "<TABLE" to end ] [ amtbl: true skipme: true]
	if parse l [ to "<xmp" to end ] [ amxmp: true skipme: true ]
	if parse l [ to "<pre" to end ] [ ampre: true skipme: true ]
	if parse l [ to "<ul>" to end ] [ amul: true skipme: true ]
	if parse l [ to "<ol>" to end ] [ amol: true skipme: true ]
	if parse l [ to "</div>" to end ] [ if amarticle [ amarticle: false skipme: true ] ]
	if parse l [ to "</TABLE>" to end ] [ if amtbl [ amtbl: false skipme: true ] ]
	if parse l [ to "</xmp" to end ] [ amxmp: false skipme: true ]
	if parse l [ to "</pre" to end ] [ ampre: false skipme: true ]
	if parse l [ to "</ul>" to end ] [ amul: false skipme: true ]
	if parse l [ to "</ol>" to end ] [ amol: false skipme: true ]
	if amarticle [
		if (not amxmp) and (not ampre) and (not amul) and (not amol) and (not amtbl) and (not skipme) [
			l: join l "<br>"
		]
	]
	print l
]
