REBOL []
;; replace org links with html links
;; made for orgnqq
;; by cpbrown 2022

imgs: [ "gif" "jpg" "jpeg" "png" ]
dw: charset [#"A" - #"Z" #"a" - #"z" #"0" - #"9"]
dwh: charset [#"A" - #"Z" #"a" - #"z" #"0" - #"9" #":" #"/" #"." #"-" #"_" #"?" #"%" #"&"]

amxmp: false
ampre: false
amsum: false
amprop: false
amcomment: false

lines: read/lines to-file system/script/args
foreach l lines [
	hlink: copy ""
	alt: copy ""
	tbl: false
	lnk: true
	t: copy l
	trim t

;; block checks

	if parse t [ to "<xmp" to end ] [ amxmp: true lnk: false ]
	;;if parse t [ to "<pre" to end ] [ ampre: true lnk: false ]
	if parse t [ to "<summary" to end ] [ amsum: true lnk: false ]
	;if parse t [ to "<TR><TD class=^"propname^">" to end ] [ amprop: true lnk: false ]
	if parse t [ to "</xmp" to end ] [ amxmp: false ]
	;;if parse t [ to "</pre" to end ] [ ampre: false ]
	if parse t [ to "</summary" to end ] [ amsum: false ]
	;if parse t [ to "</TD>" to end ] [ amprop: false ]

;; html comment
;; this script doesn't handle multiline comments that start mid-line, 
;; keep thes on their own line if possible
	if parse t [ to "<!--" to end ] [ amcomment: true lnk: false ]
	if parse t [ to "-->" to end ] [ amcomment: false ]

;; org escape check
	if t/1 = #"," [ lnk: false ]

;; special case checks
	if parse t [ [ "#+" | "<details" ] to end ] [ lnk: false ]

	if lnk and (not amxmp) and (not amsum) and (not amcomment) [

;; are we in a table?? do a rough check, refine if there's a link
		tbl: parse l [ thru "|" to "|" to end ]
;; is there a code block on the line?
		;blk: parse l [ thru "~" to "~" to end ]

		if parse l [thru "[[" to "]]" to end ] [
			parse l [ s: any [
				[ "~" thru "~"] | 
				[ "<TR><TD class=^"propname^">" thru "</TD><TD>" ] |
				[ 
					;(print "check external link")
					a:
					"[["
					b: 
					some dwh "]["
					:b
					copy hlink to "][" 
					thru "][" 
					copy alt to "]]" 
					( 
						;print ["^-found external link:" alt hlink ]
						hext: last split hlink "."
						trim hext
						nh: join "<a href=^"" [ hlink "^" target=^"new^">" ]
						na: join "" [ alt "</a>" ]
						if hext <> "" [
							if (select imgs hext) <> none [
								nh: join "<img src=^"" [ hlink "^"" ]
								na: join " alt=^"" [ alt "^">" ]
							]
						]
						if tbl [
							if parse l [ to "|" to "[[" to "]]" to "|" to end ] [
								nh: join "<a href=^"" [ hlink "^" target=^"new^">" ]
								na: join "<span style=^"font-family: exacto;^">" [ alt "</span></a>" ]
							]
						]
					)
					:a remove thru "["
					insert nh
					insert na
					remove thru "]]"
					;(print [ "^-" nh na ])
				] |
				[
					;(print "check local link")
					c:
					"[["
					copy taglink to "]]"
					(
						;print [ "^-found local link:" taglink ]
						tagname: copy taglink
						replace taglink " " "_"
						k: join "" [ "<span class=^"itag^"><a href=^"#" taglink "^" onclick=^"jto('" taglink "');^">" tagname "</a></span>" ]
						if tbl [
							if parse l [ to "|" to "[[" to "]]" to "|" to end ] [
								k: join "" [ "<span style=^"font-family: exacto;^"><a href=^"#" taglink "^" onclick=^"jto('" taglink "');^">" tagname "</a></span>" ]
							]
						]
						;print [ "^-" k ]
					)
					:c
					remove thru "]]"
					insert k
				] |
				skip
			]]
		]
	]
	print l
]
