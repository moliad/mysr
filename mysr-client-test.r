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
;-     tracelog?:
;
;--------------------------
tracelog?: false


;--------------------------
;-     mysr.buffersize:
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

mysr: slim/open/expose 'mysr none [ connect  list-dbs sql: mysql query query!  escape-sql  trace-sql]
von
mysr/von


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
trace-sql %mysr-trace.log

session: connect "localhost" "" "root" "123456"
;data: list-dbs session 
;v?? data

;------------
;vprobe sql "use inmail"
;vprobe sql "describe logs;"
;vprobe sql "insert into logs"
;vprobe sql "select * from logs;"
caca: none

db: "iguerhgseliughseli"

;query [ "use" db " ger " aa " egehi"  db caca] context [db: "ggg" aa: 666]
;query [ "use" db " ger " aa " egehi"  db] ["inmail"  999]
;query [ "use" db "as" db] "inmail"
;query make query! [query:  [ "blah " db " ger " aa " egehi"  db]  ] context [ db: "ggg" aa: 777 ]
;query [ "use inmail" ] none


;probe sql "SHOW CHARACTER SET;"

escaped: escape-sql {aaa";drop database}
v?? escaped

ask "..." 

