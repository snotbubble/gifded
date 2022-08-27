REBOL []
;; script to replace org property bins with html tables
;; made for orgnqq
;; by cpbrown 2022

lines: read/lines to-file system/script/args
amproperty: false
doproperty: false
amxmp: false
foreach l lines [
	if parse l [ to "<xmp" to end ] [ amxmp: true ]
	if parse l [ to "</xmp" to end ] [ amxmp: false ]
	if parse l [ to "#+ATTR_ORG: prop: t" to end ] [ doproperty: true continue ]
	if (not amxmp) and (doproperty) [
		either parse/case l [ to ":PROPERTIES:" to end ] [
			parse l [ insert "<TABLE>^/<TR><TD COLSPAN=^"2^">" to ":PROP"]
			l: join l "</TD></TR>"
			parse l [ some [to ":" remove thru ":"] ]
			amproperty: true
		] [ 
			if parse/case l [ to ":END:" to end ] [ amproperty: false doproperty: false l: "</TABLE>" ]
			if amproperty [
				parse l [ insert "<TR><TD class=^"propname^">" thru ":" to ":"  change ":" "</TD><TD>" ]
				parse l [ 2 [to ":" remove thru ":"] ]
				l: join l "</TD></TR>"
			]
		]
	]
	if (not amxmp) and (not doproperty) [
		either parse/case l [ to ":PROPERTIES:" to end ] [
			amproperty: true
			continue
		] [
			if parse/case l [ to ":END:" to end ] [ amproperty: false doproperty: false continue ]
			if amproperty [ continue ]
		]
	]
	print l
]
