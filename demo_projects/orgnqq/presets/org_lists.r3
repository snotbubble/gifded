REBOL []
;; script to add html tags to org lists
;; made for orgnqq
;; by cpbrown 2022
;; special thaks to David Oliva for advice on using `to bitset` in parse,
;; which can't be done as `to charset` in r3

; use a block to keep track of indentation
; IDS = actual indentations @ index, indent incrament at value
; CLO = closure tags at incrament value
; O, V = old incrament value, incrament value
; P, S = old indent value, indent value
; +-------------------      --+----------+---+---------------+---------------------------+--------------------------------------------------------------+---------+
; | [O][V][P][S][LINE       ] | INDENT   | S | IDS           | CLO                       | NOTE                                                         | OUTPUT  |
; +--------------      ------ +----------+---+---------------+---------------------------+--------------------------------------------------------------+---------+
; | [0][1][0][2][  - A      ] | "  "     | 2 | [0 1]         | ["</ul>"]                 | 2 > 0 [ V += 1 O: V IDS/:L: V CLO/:V: "</ul>" PRINT "<ul>" ] | "<ul>"  |
; | [1][2][2][4][    1. A1  ] | "    "   | 4 | [0 1 0 2]     | ["</ul>" "</ol>"]         | 4 > 2 [ V += 1 O: V IDS/:L: V CLO/:V: "</ol>" PRINT "<ol>" ] | "<ol>"  |
; | [2][3][4][6][      - A1A] | "      " | 6 | [0 1 0 2 0 3] | ["</ul>" "</ol>" "</ul>"] | 6 > 4 [ V += 1 O: V IDS/:L: V CLO/:V: "</ul>" PRINT "<ul>" ] | "<ul>"  |
; | [3][1][6][2][  - B      ] | "  "     | 2 | [0 1 0 2 0 3] | ["</ul>" "</ol>" "</ul>"] | 2 < 6 [ V = IDS/:L                                           |         |
; |                           |          |   |               |                           | WHILE [O > V] PRINT CLO/:O O: O - 1                          | "</ul>" |
; |                           |          |   |               |                           |                                                              | "</ol>" |
; +---------      ------------+----------+---+---------------+---------------------------+--------------------------------------------------------------+---------+


amu: false
amo: false
aml: false

dnt: 0

nums: charset "0123456789"
spcs: charset " ^-"
digit: system/catalog/bitsets/numeric

clo: [ "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ]
ids: [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ]
o: 0
v: 0
s: 0
p: 0

amxmp: false
ampre: false
amsum: false
amprop: false
amcomment: false

lines: read/lines to-file system/script/args
foreach l lines [
	lst: true
	h: copy ""
	ind: copy ""
	opn: "<ol>"
	cls: "</ol>"
	t: copy l
	trim t

;; block checks

	if parse t [ to "<xmp" to end ] [ amxmp: true lst: false ]
	if parse t [ to "<pre" to end ] [ ampre: true lst: false ]
	if parse t [ to "<summary" to end ] [ amsum: true lst: false ]
	if parse/case t [ to ":PROPERTIES:" to end ] [ amprop: true lst: false ]

	if parse t [ to "</xmp" to end ] [ amxmp: false ]
	if parse t [ to "</pre" to end ] [ ampre: false ]
	if parse t [ to "</summary" to end ] [ amsum: false ]
	if parse/case t [ to ":END:" to end ] [ amprop: false ]

;; html comment
;; this script doesn't handle multiline comments that start mid-line, 
;; keep thes on their own line if possible
	if parse t [ to "<!--" to end ] [ amcomment: true lst: false ]
	if parse t [ to "-->" to end ] [ amcomment: false ]

;; org escape check
	if t/1 = #"," [ lst: false ]

;; special case checks
	if parse t [ [ "#+" | "<details" ] to end ] [ lst: false ]

	if lst and (not amxmp) and (not ampre) and (not amsum) and (not amprop) and (not amcomment) [
		either parse l [ 0 16 " " 1 5 digit ". " copy h to end ] [
			parse l [ copy ind to digit 1 5 digit ". " to end ]
			amo: true
		] [ amo: false ]
		either parse l [ 0 16 #" " a: "- " :a thru "- " copy h to end ] [
				parse l [ copy ind to "- " to end ]
				opn: "<ul>"
				cls: "</ul>"
				amu: true
		] [ amu: false ]
		if amo or amu [
			aml: true
			s: (length? ind) + 1
			ct: copy ""
			if s > p [ l: join ind [ opn "<li>" h "</li>" ] v: v + 1 ids/:s: v clo/:v: cls ]
			if s = p [ l: join ind [ "<li>" h "</li>" ] ]
			if s < p [
				v: ids/:s
				while [o > v] [ ct: join ct clo/:o o: o - 1 ]
				l: join "" [ ind ct "<li>" h "</li>" ]
			]
			p: s
			o: v
		]
	]
	if ((not amo) and (not amu) and aml) or ((not lst) and aml) [
		ct: copy ""
		while [o > 0] [ ct: join ct clo/:o o: o - 1 ]
		l: join ct l
		aml: false
		clo: [ "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ]
		nds: [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ]
		o: 0
		v: 0
		s: 0
		p: 0
	]
	print l
]
