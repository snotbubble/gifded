REBOL []
;; script to reformat org dates
;; made for orgnqq
;; by cpbrown 2022

;; emacs date format cheatsheet:
;; sample date: Thursday 4rd of August 2022 10:45am
;;
;; %Y = 2022
;; %y = 22
;; %C = 20
;; %m = 8
;; %b = Aug
;; %B = August
;; %d = 4
;; %e =  4
;; %u = 3 (weekday, 0 to 6, mon - sun, don't use this)
;; %w = 4 (weekday, 0 to 6, sun - sat, don't use this)
;; %a = thu 
;; %A = Thursday
;; %U = 31 (week starting sunday, don't use this)
;; %W = 31 (week starting monday, don't use this)
;; %j = 216 (day of year)
;;
;; %H = 10 (hour, 24h)
;; %I = 10 (hour, 12h)
;; %p = AM
;; %M = 45
;; %S = 0 (second)
;; %Z = (timezone)
;; %z = (numeric timezone)
;; %s = (epoch seconds)
;;
;; %c = Aug 4 2012 10:45 AM ? ("locale preferred" = don't use this)
;; %x = Aug 4 2012 ? ("locale preferred" = don't use this)
;; %D = 08/04/2022 (ass-backwards non-sortable format - don't use this)

;; %F = 2022-08-04 (iso sortable format)
;;
;; %R = 10:45
;; %T = 10:45:00
;; %r = 10:45:00 AM
;; %X = 10:45 AM ? ("locale preferred" = don't use this)
;; 
;; %n = ^/
;; %t = ^-
;; %% = %


lines: read/lines to-file system/script/args

amxmp: false
amtbl: false
nums: charset "0123456789"
wkd: [ "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday" ]
swkd: [ "Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun" ]
mon: [ "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December" ]
smon: [ "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec" ]

;; the whiggle, because english...
whiggle: function [ t ] [
	wh: [ "th" "st" "nd" "rd" ]
	th: ((t % 10) >= 4) or ((t >= 10) and (t <= 20))
	either th [ "th" ] [ pick wh (((t % 10) % 4) + 1) ]
]
sdat: copy ""
ldat: copy ""
locsdat: copy ""
locldat: copy ""
csdat: copy ""
cldat: copy ""
ldfn: false
sdfn: false
dovr: false

foreach l lines [
	amcell: false
	sl: copy l
	trim sl
	if parse sl [ "#+ATTR_ORG: org-time-stamp-custom-formats:" to end ] [
		parse l [ thru "^"<" copy locsdat to ">" thru "<" copy locldat to ">" to end ]
		if locsdat <> "" [ sdovr: true csdat: copy locsdat]
		if locldat <> "" [ ldovr: true cldat: copy locldat] 
		continue
	]
	if parse l [ to "</div" to end ] [ sdovr: false ldovr: false ]
	if parse l [ thru "<!-- dateformat:<" copy sdat to ">" thru "<" copy ldat to ">" to end] [
		if ldat <> "" [ ldfn: true cldat: copy ldat ]
		if sdat <> "" [ sdfn: true csdat: copy sdat ]
	]
	if parse l [ to "<xmp" to end ] [ amxmp: true ]
	if parse l [ to "</xmp" to end ] [ amxmp: false ]
	if parse l [ thru "|" to "|" to end ] [ amcell: true ]
	if parse l [ to "<TABLE" to end ] [ amtbl: true ]
	if parse l [ to "</TABLE" to end ] [ amtbl: false ]
	if (not amxmp) and (not amtbl) and (not amcell) [
		d: copy ""
		ds: copy []
;; ugly parse, surprised this works...
		parse l [
			some [
				to "<" e: thru "<" [
					a: 4 nums "-" 1 2 nums "-" 1 2 nums to ">"
					:a copy d to ">"
					:a remove to ">" insert (
						s: split d " "
						t: to-date s/1
						m: copy ""
						foreach p s [ if parse p [ to ":" to end ] [ m: join p " " ] ]
;; falback format
						o: compose [ (m) (pick wkd t/weekday) " " (t/day) (whiggle t/day) " of " (pick mon t/month) " " (t/year) ]
;; do overrides if they exist
;; these are do-once parses, I'm assuming there's no repetition in the override
						if (m <> "") and (ldfn or ldovr) [
							t/time: to-time m
							parse cldat [ to "%Y" remove thru "%Y" insert (t/year - 2000) ]
							parse cldat [ to "%y" remove thru "%y" insert (t/year) ]
							parse cldat [ to "%m" remove thru "%m" insert (format/pad -2 t/month 0) ]
							parse cldat [ to "%b" remove thru "%b" insert (pick smon t/month) ]
							parse cldat [ to "%B" remove thru "%B" insert (pick mon t/month) ]
							parse cldat [ to "%d" remove thru "%d" insert (format/pad -2 t/day 0) ]
							parse cldat [ to "%e" remove thru "%e" insert (format/pad -2 t/day 0) ]
							parse cldat [ to "%a" remove thru "%a" insert (pick swkd t/weekday) ]
							parse cldat [ to "%A" remove thru "%A" insert (pick wkd t/weekday) ]
							parse cldat [ to "%H" remove thru "%H" insert (format/pad -2 t/hour 0) ]
							parse cldat [ to "%I" remove thru "%I" insert (format/pad -2 (t/hour % 12) 0) ]
							parse cldat [ to "%p" remove thru "%p" insert (either (t/hour > 12) ["PM"] ["AM"]) ]
							parse cldat [ to "%M" remove thru "%M" insert (format/pad -2 t/minute 0) ]
							parse cldat [ to "%S" remove thru "%S" insert (format/pad -2 t/second 0) ]
							parse cldat [ to "%F" remove thru "%F" insert (compose [ (t/year) "-" (format/pad -2 t/month 0) "-" (format/pad -2 t/day 0) ]) ]
							parse cldat [ to "%R" remove thru "%R" insert (compose [ (format/pad -2 t/hour 0) ":" (format/pad -2 t/minute 0) ]) ]
							parse cldat [ to "%T" remove thru "%T" insert (compose [ (format/pad -2 t/hour 0) ":" (format/pad -2 t/minute 0) ":" (format/pad -2 t/second 0) ]) ]
							parse cldat [ to "%r" remove thru "%r" insert (compose [ (format/pad -2 (t/hour % 12) 0) ":" (format/pad -2 t/minute 0) ":" (format/pad -2 t/second 0) " " (either (t/hour > 12) ["PM"] ["AM"] ) ]) ]
							o: copy cldat
						]
						if (m = "") and (sdfn or sdovr) [
							parse csdat [ to "%Y" remove thru "%Y" insert (t/year - 2000) ]
							parse csdat [ to "%y" remove thru "%y" insert (t/year) ]
							parse csdat [ to "%m" remove thru "%m" insert (format/pad -2 t/month 0) ]
							parse csdat [ to "%b" remove thru "%b" insert (pick smon t/month) ]
							parse csdat [ to "%B" remove thru "%B" insert (pick mon t/month) ]
							parse csdat [ to "%d" remove thru "%d" insert (format/pad -2 t/day 0) ]
							parse csdat [ to "%e" remove thru "%e" insert (format/pad -2 t/day 0) ]
							parse csdat [ to "%a" remove thru "%a" insert (pick swkd t/weekday) ]
							parse csdat [ to "%A" remove thru "%A" insert (pick wkd t/weekday) ]
							parse csdat [ to "%F" remove thru "%F" insert (compose [ (format/pad -2 t/year 0) "-" (format/pad -2 t/month 0) "-" (format/pad -2 t/day 0) ]) ]
							o: copy csdat
						]
						o
					)
					remove thru ">"
					:e remove thru "<"
				] | skip
			] to end
		] ;[
			;print l ;; just show lines with dates
		;]
	]
	print l
]
