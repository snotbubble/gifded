;; convert rebol keywords into a gtkview lang file
;; by cpbrown 2022
;;
;; keywords obtained from code-colorizer.r by David Oliva
;; http://www.rebol.org/view-script.r?script=code-colorizer.r

lines: split system/script/args "^/"

s: copy []
k: copy []
h: copy []

append s "^-<styles>"
append h "^-^-<context id=^"rebol^">"
append h "^-^-^-<include>"
append k "^-<definitions>"

thestrings: {		<context id="line-comment" style-ref="comment" end-at-line-end="true" class="comment" class-disabled="no-spell-check">
			<start>;</start>
		</context>

		<context id="rstring" style-ref="string" class="string" end-at-line-end="true">
			<start>"</start>
			<end>"</end>
			<include>
				<context id="rescape" style-ref="escaped">
					<match>\^^.</match>
				</context>
			</include>
		</context>

		<context id="rbigstring" style-ref="comment" class="comment">
			<start>^{</start>
			<end>^}</end>
			<include>
				<context id="rbigescape" style-ref="escaped">
					<match>\^^.</match>
				</context>
			</include>
		</context>}

append k thestrings

thestringstyles: {		<style id="escaped" name="escaped"/>
		<style id="comment" name="comment"/>
		<style id="string" name="string"/>}

append s thestringstyles

thestringids: {				<context ref="rescape"/>
				<context ref="rbigescape"/>
				<context ref="line-comment"/>
				<context ref="rstring"/>
				<context ref="rbigstring"/>}

append h thestringids

foreach l lines [
	g: split l " "
	foreach w g [
		replace/all w {"} ""
		trim/with w "^-"
		replace/all w {*} ""
		replace w {[} ""
		replace w {]} ""
		replace/all w {>} ""
		replace/all w {<} ""
		replace w {+} ""
		replace/all w {=} ""
		replace/all w {/} ""
		replace/all w {\} ""
		replace w {-} "\-"
		if w = {\-} [ w: "" ]
		if w = {?} [ w: "" ]
		if w = {??} [ w: "" ]
		if w <> "" [
			either (take/last (copy w)) = #":" [
				if (length? w) > 3 [
					replace w "rl_" ""
					trim/with w "^-"
					take/last w
					d: copy w
					c: copy w
					w: join "^-^-" [ "<context id=^"r" w "^" style-ref=^"" w "^">" ]
					if (length? k) > 1 [ append k "^-^-</context>" ]
					append k ""
					append k w
					append k "^-^-^-<suffix>(?!\w)</suffix>"
					d: join "^-^-" [ "<style id=^"" d "^" name=^"" d "^"/>" ]
					append s d
					c: join "^-^-^-^-" [ "<context ref=^"r" c "^"/>" ]
					append h c
				]
			] [
				if w <> "" [
					w: join "^-^-^-" [ "<keyword>" w "</keyword>" ]
					append k w
				]
			]
		]
		;probe w
	]
]

append k "^-^-</context>"
append k ""
append s "^-</styles>^/"
append h "^-^-^-</include>"
append h "^-^-</context>"

intro: {<?xml version="1.0" encoding="UTF-8"?>
<!--
keywords copied from code-colorizer.r by David Oliva
http://www.rebol.org/view-script.r?script=code-colorizer.r
-->

<language id="rebol" _name="Rebol" version="2.0" _section="Source">

^-<metadata>
^-^-<property name="globs">*.r3;*.r;*.reb</property>
^-^-<property name="line-comment-start">;</property>
^-^-<property name="block-comment-start">^{</property>
^-^-<property name="block-comment-end">^}</property>
^-^-<property name="suggested-suffix">.r3</property>
^-</metadata>
}

outro: {^-</definitions>^/</language>}

print intro
foreach i s [ print i ]
foreach i k [ print i ]
foreach i h [ print i ]
print outro
