;; convert org keywords into a gtkview lang file
;; by cpbrown 2022
;;
;; keywords obtained from org docs
;; https://orgmode.org/manual/Publishing-options.html
;; startup options obtained from docs
;; https://orgmode.org/manual/In_002dbuffer-Settings.html
;; Rebol whitespace charset copied from:
;; https://en.wikibooks.org/wiki/Rebol_Programming/Language_Features/Parse/Simple_splitting
;;
;; source text structured as:
;; contextname [ 
;; 1st-word-of-line ... 
;; ]

lines: split system/script/args "^/"

s: copy []
k: copy []
h: copy []

append s "^-<styles>"
append h "^-^-<context id=^"orgmode^">"
append h "^-^-^-<include>"
append k "^-<definitions>"

thestrings: {		<context id="ocomment" style-ref="comment" end-at-line-end="true">
			<start>\\</start>
		</context>

		<context id="oheadline" style-ref="headline">
			<start>(^^)[\*]+\s</start>
			<end>(?=(\:|$))</end>
			<include>
			<context id="otag" style-ref="tag" end-parent="true">
				<start>(?&lt;!(^^))\:(?=[\w\d\:]+\:($))</start>
				<end>\:(?=($))</end>
			</context>
			</include>
		</context>

		<context id="opreconfig" style-ref="preconfig" end-at-line-end="true">
			<start>\# \-\*\- </start>
		</context>

		<context id="osourceblock" style-ref="sourceblock">
			<start>\#\+BEGIN\_SRC</start>
			<end>\#\+END\_SRC</end>
		</context>

		<context id="otable" style-ref="table">
			<start>\#\+BEGIN\_TABLE</start>
			<end>\#\+END\_TABLE</end>
		</context>

		<context id="oproperty" style-ref="property">
			<start>\:PROPERTIES\:</start>
			<end>\:END\:</end>
		</context>

		<context id="otodo" style-ref="todo">
			<start>\s\[(?=\[^^\#]+\])</start>
			<end>\]\s</end>
		</context>

		<context id="opriority" style-ref="priority">
			<start>\s\[(?=\#[\w\s\d]+\])</start>
			<end>\]\s</end>
		</context>

		<context id="odate" style-ref="date">
			<start>\&lt;(?=([\d\:\-amp\s]+\&gt;))</start>
			<end>\&gt;(?!\w\s)</end>
		</context>

		<context id="olink" style-ref="link">
			<start>\[\[(?=([\S]+\]))</start>
			<end>\]\](?!([\S]+))</end>}

append k thestrings

thestringstyles: {		<style id="sourceblock" name="sourceblock"/>
		<style id="preconfig" name="preconfig"/>
		<style id="headline" name="headline"/>
		<style id="tag" name="tag"/>
		<style id="priority" name="priority"/>
		<style id="property" name="property"/>
		<style id="comment" name="comment"/>
		<style id="table" name="table"/>
		<style id="latex" name="latex"/>
		<style id="todo" name="todo"/>
		<style id="date" name="date"/>
		<style id="link" name="link"/>}

append s thestringstyles

thestringids: {				<context ref="osourceblock"/>
				<context ref="opreconfig"/>
				<context ref="oheadline"/>
				<context ref="otag"/>
				<context ref="oproperty"/>
				<context ref="opriority"/>
				<context ref="ocomment"/>
				<context ref="olatex"/>
				<context ref="otable"/>
				<context ref="odate"/>
				<context ref="olink"/>
				<context ref="otodo"/>}

append h thestringids

foreach l lines [
	if (trim l) <> "" [
		g: split l charset [#"^A" - #" " "^(7F)^(A0)"]
		w: copy g/1
		replace/all w {-} "\-"
		replace w {]} ""
		if w <> "" [
			either (take/last (copy l)) = #"[" [
				if (length? w) > 3 [
					;take/last w
					trim w
					d: copy w
					c: copy w
					w: join "^-^-" [ "<context id=^"o" w "^" style-ref=^"" w "^">" ]
					if (length? k) > 1 [ append k "^-^-</context>" ]
					append k ""
					append k w
					if d = "specialproperties" [
						append k "^-^-^-<prefix>(?&lt;=\:)</prefix>"	
						append k "^-^-^-<suffix>(?=\:)</suffix>"
					]
					if d = "config" [
						append k "^-^-^-<prefix>(?&lt;=(^^)\#\+)</prefix>"
						append k "^-^-^-<suffix>(?=\:)</suffix>"
					]
					if d = "latex" [
						append k "^-^-^-<prefix>(?&lt;=\\)</prefix>"
					]
					d: join "^-^-" [ "<style id=^"" d "^" name=^"" d "^"/>" ]
					append s d
					c: join "^-^-^-^-" [ "<context ref=^"o" c "^"/>" ]
					append h c
				]
			] [
				if w <> "" [
					w: join "^-^-^-" [ "<keyword>" w "</keyword>" ]
					append k w
				]
			]
			;probe w
		]
	]
]

append k "^-^-</context>"
append k ""
append s "^-</styles>^/"
append h "^-^-^-</include>"
append h "^-^-</context>"

intro: {<?xml version="1.0" encoding="UTF-8"?>
<!--
keywords obtained from org docs
https://orgmode.org/manual/Publishing-options.html
options obtained from docs
https://orgmode.org/manual/In_002dbuffer-Settings.html
-->

<language id="orgmode" _name="Orgmode" version="2.0" _section="Source">

^-<metadata>
^-^-<property name="globs">*.org;*.orgmode</property>
^-^-<property name="line-comment-start">\\</property>
^-^-<property name="block-comment-start">\#\+BEGIN</property>
^-^-<property name="block-comment-end">\#\+END</property>
^-^-<property name="suggested-suffix">.org</property>
^-</metadata>
}

outro: {^-</definitions>^/</language>}

print intro
foreach i s [ print i ]
foreach i k [ print i ]
foreach i h [ print i ]
print outro


