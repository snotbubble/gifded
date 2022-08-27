REBOL []
;; script to replace org include with html embed
;; made for orgnqq
;; by cpbrown 2022

lines: read/lines to-file system/script/args
foreach l lines [
	t: copy l
	trim t
	efile: copy ""
	etype: copy ""
	if parse t [ "#+INCLUDE:" thru "^"" copy efile to "^"" thru "src " copy etype to end ] [
		l: join "<br><embed src=^"" [ efile "^" width=^"95%^" height=^"400^" type=^"text/plain^">" ]
	]
	print l
]
