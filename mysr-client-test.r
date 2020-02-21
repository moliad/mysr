rebol [
	purpose: "setup and Test mysql dll routines"
]


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- GLOBALS
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;-     debug?:
;
; use debug lib?
;--------------------------
debug?: false


;--------------------------
;-     default-session:
;
; connect will set this each time it is called, thus the last connection is always the default session.
;--------------------------
default-session: none


;--------------------------
;-     tracelog-path:
;
;--------------------------
tracelog-path:  to-local-file clean-path %mysr-tracelog.txt


;--------------------------
;- tracelog?:
;
;--------------------------
tracelog?: false


;--------------------------
;- mysr.buffersize:
;
; if this is set BEFORE importing mysr lib, then it uses this
; instead of its default when initializing itself.
;--------------------------
MYSR-QUERY-BUFFERSIZE: 12'000'000





;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------

do %../slim-libs/slim/slim.r
slim/vexpose
slim/add-path clean-path %mysr-libs/

slim/open/expose 'mysr none [ connect  list-dbs sql: mysql]
von
;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- SHIM FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------




;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- MAIN
;
;-----------------------------------------------------------------------------------------------------------
vprint "testing mysr dll... extpecting result of 10"

session: connect "localhost" "" "root" "123456"
data: list-dbs session
v?? data


vprobe sql "use inmail"
vprobe sql "describe logs;"

ask "..."

