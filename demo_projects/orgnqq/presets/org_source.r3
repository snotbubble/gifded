REBOL []
;; script to replace source block tags with html xmp tags
;; made for orgnqq
;; by cpbrown 2022

e: "<xmp>"
c: "</xmp>"
lines: read/lines to-file system/script/args
amexample: false
foreach l lines [
	if parse l [ to "#+BEGIN_SRC" to end ] [
		parse l [ to "#+BEGIN" remove to end insert (e) ]
	]
	if parse l [ to "#+END_SRC" to end ] [
		parse l [ to "#+END_" remove to end insert (c) ]
	]
	if parse l [ to "#+BEGIN_EXAMPLE" to end ] [
		parse l [ to "#+BEGIN" remove to end insert (e) ]
	]
	if parse l [ to "#+END_EXAMPLE" to end ] [
			parse l [ to "#+END_" remove to end insert (c) ]
	]
	print l
]
