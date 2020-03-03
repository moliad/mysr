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


;--------------------------
;-     dbname:
;
;--------------------------
dbname: 'blah


;--------------------------
;-     session:
;
;--------------------------
session: none

;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------

do %../slim-libs/slim/slim.r
slim/vexpose
slim/add-path clean-path %mysr-libs/

mysr: slim/open/expose 'mysr none [ connect  list-dbs sql: mysql query query!  escape-sql  trace-sql do-mysql insert-sql ]


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

connect "localhost" "" "root" "123456"
;data: list-dbs session 
;v?? data

;------------
;vprobe sql "use inmail"
;vprobe sql "describe logs;"
;vprobe sql "insert into logs"
;vprobe sql "select * from logs;"
caca: none

;query [ "use" db " ger " aa " egehi"  db caca] context [db: "ggg" aa: 666]
;query [ "use" db " ger " aa " egehi"  db] ["inmail"  999]
;query [ "use" db "as" db] "inmail"
;query make query! [query:  [ "blah " db " ger " aa " egehi"  db]  ] context [ db: "ggg" aa: 777 ]

;------------
;-    Traces
;------------
von
mysr/von
;trace-sql %mysr-trace.log

;------------
;-     Queries
;------------
;vprobe query [ "use" db ] "inmail"
;foreach table head remove sql "show tables;" [
;	vprint ["===============================^/" table "^/==============================="]
;	time: dt [spec: query ["describe" table] table]
;	v?? time
;	v?? spec
;	vprobe extract next spec 6
;]

dbs: list-dbs
v?? dbs


;trace-sql %mysr-trace.log


if find dbs to-string dbname [
	query ["drop database " db] dbname
]	

do-mysql [
	CREATE DATABASE :dbname

	CREATE TABLE 'product [
		ProductID			autokey! 
		ProductCode 		120 primary
		MLFB				20
		Options				100
		SAPMaterialCode
		SpareNewStatus		5
		ProductMilestone	5
		RepairStatus		5
		NetWeight			decimal!
		WeightUnit			5
		L1SparePartPrice	decimal!
		L1RepairPrice		decimal!
		L1ExchangePrice		decimal!
		L2SparePartPrice	decimal!
		L2RepairPrice		decimal!
		L2ExchangePrice		decimal!
		SparePartLeadTime	integer!
		RepairLeadTime		integer!
		ShortDescription	text!
		PCK					10
	]
	;select [ ProductCode MLFB Options ] from product where ProductID = 4
]


dataset: []

repeat i 1000 [
	repend dataset [ to-string i rejoin [to-string i to-string i to-string i ] rejoin [to-string i "-options"] i ]
]

v?? dataset

columns:  [MLFB options ProductCode SparePartLeadTime ]
voff
mysr/voff
it: dt [
	foreach [MLFB options ProductCode SparePartLeadTime ] dataset [
		bind columns 'MLFB
		insert-sql 'product columns reduce columns
	]
]
mysr/von
von

vprint ["insert time: " it]
v?? it

;insert-sql 'product ["aaa" "111" "aaa-111" 1 "bbb" "222" "bbb-222" 10 ]

t: dt [
	result: sql "select * FROM product ;"
]
vprint ["select time: " t]
v?? result




;probe sql "SHOW CHARACTER SET;"

;escaped: escape-sql {aaa";drop database}
;v?? escaped

ask "..." 

