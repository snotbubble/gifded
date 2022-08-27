REBOL []
;; script to reformat orgfile title 
;; made for orgnqq
;; by cpbrown 2022

lines: read/lines to-file system/script/args

orgtitle: copy ""
orgauth: copy ""
orgnote: copy ""
dotitle: true
todos: copy ""

wkd: [ "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday" ]
mon: [ "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December" ]

;; the whiggle, because english...
whiggle: function [ t ] [
	wh: [ "th" "st" "nd" "rd" ]
	th: ((t % 10) >= 4) or ((t >= 10) and (t <= 20))
	either th [ "th" ] [ pick wh (((t % 10) % 4) + 1) ]
]

n: now/date
orgdate: join "" [ n/day whiggle n/day " of " pick mon n/month " " n/year ]

foreach l lines [
	if dotitle [
		if parse l [ thru "-*-" to "-*-" to end ] [ 
			sdat: copy ""
			ldat: copy ""
			parse l [ thru "org-time-stamp-custom-formats:" thru "(^"" copy sdat to "^"" thru " ^"" copy ldat to "^"" to end ]
			if (sdat <> "") and (ldat <> "") [ l: join "<!-- dateformat:" [ sdat ";" ldat "-->" ] print l ]
			continue
		]
		if parse l [ thru "#+TITLE:" copy orgtitle to end ] [ continue ]
		if parse l [ thru "#+AUTHOR:" copy orgauth to end ] [ 
			l: join "<div class=^"x^">" [ orgtitle ". by " orgauth ", " orgdate "</div>" ]
		]
		if parse l [ thru "#+SUBTITLE:" copy orgnote to end ] [
			l: join "<div class=^"xs^">" [ orgnote "</div><BR><BR>" ]
		]
		if parse l [ thru "#+TODO:" copy todos to end ] [
			l: join "<!-- todos:" [ todos "-->" ]
			print l
			continue
		]
		if parse l [ "#+" to end ] [ continue ]
		if l/1 = #"*" [ dotitle: false ]
	]
	print l
]
