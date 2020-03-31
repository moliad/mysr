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
;-     dir:
;
;--------------------------
dir: clean-path %../../git/semantic-api/cheyenne/web-api/clientfiles/siemens/

;--------------------------
;-     debug?:
;
; use debug lib?
;--------------------------
debug?: false


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

bulk-lib: slim/open/expose 'bulk none [ realign-bulk-rows csv-to-bulk make-bulk insert-objects bulk-to-csv select-bulk sort-bulk column-labels bulk-columns add-column]
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
bulk-lib/von

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


if find dbs to-string dbname [
	query ["drop database " db] dbname
]	

do-mysql [
	CREATE DATABASE :dbname

	CREATE TABLE 'product [
		ProductCode 		120 primary
		MLFB				20
		SAPMaterialCode
		SpareNewStatus		5
		Price				decimal!
		RepairLeadTime		integer!
		ShortDescription	text!
		PCK					10
	]
	
	CREATE TABLE 'client [
		ClientID			autokey!
		CompanyNumber		100
		Name				30
		PL					integer!  ; [1 | 2]
		Discount			decimal!
	]

	CREATE TABLE 'contact [
		ContactID			autokey!
		Email				100 primary
		name				40
		CompanyNumber		100
	]
]

bulk-lib/default-null: ""



;vprint ["insert time: " it]
;v?? it

vprint "========================="


t: dt [
	result: sql "select * FROM product ;"
]

v?? result
;vprint ["select time: " t]
;v?? result


;probe sql "SHOW CHARACTER SET;"

;escaped: escape-sql {aaa";drop database}
;v?? escaped

ask "..." 

