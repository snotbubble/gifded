REBOL []
;; script to replace org table block tags with html pre tag
;; made for orgnqq
;; by cpbrown 2022

e: "<pre class=^"widetable^">"
c: "</pre>"
lines: read/lines to-file system/script/args
amtable: false
amxmp: false
n: 1
foreach l lines [
	if parse l [ to "#+BEGIN_EXAMPLE" to end ] [ amxmp: true ]
	if parse l [ to "#+END_EXAMPLE" to end ] [ amxmp: false ]
	if not amxmp [
		if parse l [ to "#+BEGIN_TABLE" to end ] [
			mvh: 0.9
			if (length? lines) > n [
				cco: (length? lines/(n + 1)) * 1.0
				mvh: min 200.0 (max (cco / 200.0) 0.0)
				mvh: (1.0 - mvh) + 0.5
				l: join "" [ "<pre class=^"widetable^" style=^"font-size:" mvh "vw;^">" ]
			]
		]
		if parse l [ to "#+END_TABLE" to end ] [
			parse l [ to "#+END_" remove thru "TABLE" insert (c) ]
		]

		if parse l [ to "#+BEGIN: columnview" to end ] [
			amtable: true
			mvh: 0.9
			if (length? lines) > n [
				cco: (length? lines/(n + 1)) * 1.0
				mvh: min 200.0 (max (cco / 200.0) 0.0)
				mvh: (1.0 - mvh) + 0.5
				l: join "" [ "<pre class=^"widetable^" style=^"font-size:" mvh "vw;^">" ]
			]
		]
		if parse l [ to "#+END" to end ] [
			if amtable [
				parse l [ to "#+END" remove to end insert (c) ]
				amtable: false
			]
		]
	]
	print l
	n: n + 1
]
