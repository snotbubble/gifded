REBOL []
;; replace org style markers with html tags
;; made for orgnqq
;; by cpbrown 2022

dw: charset [#"A" - #"Z" #"a" - #"z" #"0" - #"9"]
cw: charset [
	#" " 
	#"^-" 
	#"^/" 
	#"(" 
	#")" 
	#"=" 
	#"[" 
	#"]" 
	#"&" 
	#";" 
	#":" 
	#"," 
	#"." 
	#"?" 
	#"<" 
	#">" 
	#"/" 
	#"+" 
	#"_" 
	#"*" 
	#"~" 
	#"'" 
	#"^""
]
tt: [ "<i>" "</i>" ]
bt: [ "<b>" "</b>" ]
ut: [ "<u>" "</u>" ]
st: [ "<s>" "</s>" ]
qt: [ "^"" "^"" ]
ct: [ "<span class=^"situ^">" "</span>" ]

;; just check for pairs, don't change the line
ispaired: function [ s x t ] [
	haspair: false
	h: x
	if (s/:x = t) [
		o: copy s
		tbr: true
;; don't include char-quotes within words like don't, also skip underlines inside words as they're often used to join strings
		if ((t = #"'") or (t = #"_")) [
			tbr: false
			ee: s/(max (x - 1) 1)
			nn: s/(min (x + 1) (length? s))
;; acceptable word boundaries
			tbr: ( 
				(x = 1) or 
				(ee = #" ") or 
				(ee = #"^-") or 
				(ee = #"(") or 
				(ee = #"=") or 
				(ee = #":") or
				(ee = #">") or
				(nn = #"<") or
				(nn = #")") or
				(nn = #";") or
				(nn = #",") or
				(nn = #".") or
				(nn = #" ") or 
				(nn = #"^-") or 
				(x = (length? s))
			)
		]
		if tbr [
			y: 1
			repeat r ((length? s) - x) [
				obr: true
				h: x + r
;; skip if escaped
				if (s/(max (h - 1) 0) <> #"\") [
					if ((t = #"'") or (t = #"_")) [ 
						obr: false
						bb: s/(max (h - 1) 1)
						ff: s/(min (h + 1) (length? s))
						obr: (
							(h = 1) or 
							(bb = #" ") or 
							(bb = #"^-") or 
							(bb = #"(") or 
							(bb = #"=") or 
							(bb = #":") or
							(bb = #">") or
							(ff = #"<") or
							(ff = #")") or
							(ff = #";") or
							(ff = #",") or
							(ff = #".") or
							(ff = #" ") or 
							(ff = #"^-") or 
							(ff = #"^/") or
							(h = (length? s))
						)
					]
					if s/(h) = t and obr [
						m: ((y % 2) + 1)
						if m = 2 [
							haspair: true
							break
						]
						y: y + 1
					]
				]
			]
		]
	]
	if not haspair [ h: x ]
	compose reduce [ (haspair) (h) ]
]

;; check for pairs, inject tags if allgood
injecttag: function [ s x t aa  ] [
	o: copy s
	haspair: false
	tbr: true
	h: 1
	c: copy ""
	if t = #"+" [
;; don't dick with org tables...	
		tbr: ((s/(max (x - 1) 1) <> #"-") and (s/(min (x + 1) (length? s)) <> #"-"))
	]
	if ((t = #"_") or (t = #"/")) [
		tbr: false
		mk: charset "/_"
		bb: s/(max (x - 1) 1)
		ff: s/(min (x + 1) (length? s))
		seg: join bb [ s/:x ff ]
		tbr: (
			(x = 1) or 
			(x = (length? s)) or
			(parse seg [ not [dw mk dw] to end ])
		)
	]
	if t = #"/" [ if (s/(max (x - 1) 1) = #"<") [ tbr: false ] ]
	if (s/:x = t) and tbr [
		y: 1
;; look-ahead for a matching pair
		repeat r ((length? s) - x) [
			obr: true
			h: x + r
			c: join c s/:h
;; skip if escaped
			if (s/(max (h - 1) 1) <> #"\") [
;; special case checks
				if t = #"+" [ obr: ((s/(max (h - 1) 1) <> #"-") and (s/(min (h + 1) (length? s)) <> #"-")) ]
				if ((t = #"_") or (t = #"/")) [
					obr: false
					mk: charset "/_"
					bb: s/(max (h - 1) 1)
					ff: s/(min (h + 1) (length? s))
					seg: join bb [ s/:h ff ]
					obr: (
						(h = 1) or 
						(h = (length? s)) or
						(parse seg [ not [dw mk dw] to end ])
					)
				]
				if t = #"/" [ if (s/(max (h - 1) 1) = #"<") [ obr: false ] ]
				if obr [
					if s/(h) = t [
;; found it, use tag count for a modulo sanity check
						m: ((y % 2) + 1)
						if m = 2 [
							take/last c
							remove at o h
							insert at o h aa/2
							haspair: true
							break
						]
						y: y + 1
					]
				]
			]
		]
		if haspair = true [
;; deal with html if in a code tag
			either (t = #"~") [
				replace/all c "&" "&amp;"
				replace/all c "<" "&lt;"
				replace/all c ">" "&gt;"
				g: copy s
				g: take/part g (x - 1)
				k: copy s
				k: take/last/part k ((length? s) - h)
				;;print [ "HTML: " g aa/1 c aa/2 k ]
				o: join g [ aa/1 c aa/2 k ]
			] [
;; insert the opening tag if a closing marker was found
				remove at o x
				insert at o x aa/1
			]
		]
	]
  o
]

lines: read/lines to-file system/script/args

amxmp: false
ampre: false
amsum: false
amprop: false
amcomment: false

foreach l lines [
	notchar: true
	notstring: true
	notcode: true
	syl: true
	t: copy l
	trim t

;; block checks

	if parse t [ to "<xmp" to end ] [ amxmp: true syl: false ]
	if parse t [ to "<pre" to end ] [ ampre: true syl: false ]
	if parse t [ to "<summary" to end ] [ amsum: true syl: false ]
	if parse/case t [ to ":PROPERTIES:" to end ] [ amprop: true syl: false ]

	if parse t [ to "</xmp" to end ] [ amxmp: false ]
	if parse t [ to "</pre" to end ] [ ampre: false ]
	if parse t [ to "</summary" to end ] [ amsum: false ]
	if parse/case t [ to ":END:" to end ] [ amprop: false ]

;; html comment
;; this script doesn't handle multiline comments that start mid-line, 
;; keep thes on their own line if possible
	if parse t [ to "<!--" to end ] [ amcomment: true syl: false ]
	if parse t [ to "-->" to end ] [ amcomment: false ]

;; org escape check
	if t/1 = #"," [ syl: false ]

;; special case checks
	if parse t [ [ "#+" | "<details" ] to end ] [ syl: false ]

	o: copy ""
	if syl and (not amxmp) and (not ampre) and (not amsum) and (not amprop) and (not amcomment) [
		c: 1
		while [c <= (length? l)] [
;; skip escaped
			if (l/(max (c - 1) 0) <> #"\") [

;; quote: check if closed, move past closed
				if (l/:c = #"^"") [
					ip: ispaired l c #"^""
					if ip/1 [
						c: ip/2
					]
				]

;; comma: check if closed, move past closed
				if (l/:c = #"'") [
					ip: ispaired l c #"'"
					if ip/1 [
						c: ip/2
					]
				]
				
;; inline code - we're double-handling to get a bool to exclude subsequent styling
				if l/:c = #"~" [
					ip: ispaired l c #"~"
					j: injecttag l c #"~" ct l: j
;; move to end of code + span
					if ip/1 [ c: ( ip/2 + 24 ) ]
				]
				if notcode [
;; underlines are an odd case as they're often used to avoid spaces in strings
;; checking if its paired outside of a word, tags if true
					if l/:c = #"_" [ j: injecttag l c #"_" ut l: j ]
	;; italic - avoid closed tags, implied closed tags are unhandled '/>'
					if (l/(max (c - 1) 0) <> #"<") [
						if l/:c = #"/" [ j: injecttag l c #"/" tt l: j ]
					]
	;; the rest
					if l/:c = #"*" [ j: injecttag l c #"*" bt l: j ]
					if l/:c = #"+" [ j: injecttag l c #"+" st l: j ]
				]
			]
			c: c + 1
		]
;; remove escapes before markup and quotes, this is post styling, so shouldn't be problematic...
		parse l [ any [ to "\/" change "\/" "/" skip ] ]
		parse l [ any [ to "\+" change "\+" "+" skip ] ]
		parse l [ any [ to "\*" change "\*" "*" skip ] ]
		parse l [ any [ to "\_" change "\_" "_" skip ] ]
		parse l [ any [ to "\~" change "\~" "~" skip ] ]
		parse l [ any [ to "\^"" change "\^"" "^"" skip ] ]
		parse l [ any [ to "\'" change "\'" "'" skip ] ]
		;print l
	]
	print l
]
