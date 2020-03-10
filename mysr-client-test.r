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

connect "localhost" "" "root" "root"
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

trace-sql %mysr-trace.log

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

;--------------------------
;-     make-product-code()
;--------------------------
; purpose: Get a product code using mlfb-options
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
make-product-code: funcl [
	mlfb		[string!]
	options 	[string! none!]
][
	;vin "make-product-code()"
	code: copy MLFB
	;v?? options
	if all [
		string? options
		empty? trim options
	][
		options: none
	]
	
	if options [
		;append code join "-" options
		;--------------
		; split the options into groups of 3 chars with separators
		;--------------
		;duplicate the row information!
		;.row
		alt-options: clear ""
		parse/all options [
			some [copy opt 3 skip  ( append alt-options "-" append alt-options opt  ) ]
		]
		append code alt-options
	]
	;vout
	code
]

if find dbs to-string dbname [
	query ["drop database " db] dbname
]	

do-mysql [
	CREATE DATABASE :dbname

	CREATE TABLE 'product [
		ProductCode 		120 primary
		MLFB				20
		Options				100
		SAPMaterialCode
		SpareNewStatus		5
		ProductMilestone	20
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
]

bulk-lib/default-null: ""

print "PROCESSING SAP DB"
sap-db: csv-to-bulk/select/every join dir %data/siemens-sap-products-db.csv [ProductCode Material] [ProductCode: make-product-code ProductNumberPrint Options] 
sap-db: to-hash next sap-db

;write rdata-dir/sap.rdata mold/all sap-db
print "PROCESSING SAP DB DONE"
print "LOADING SAP DB"
;delay: dt [sap-db: load rdata-dir/sap.rdata]
;vprint ["LOADING SAP DB DONE (" delay ")" ]

vprint "PROCESSING PRODUCT DB"
product-filter-file: join dir %data/siemens-product-filter.txt
filter-data: none
if exists? product-filter-file [
	filter-data: read/lines 
	filter-data: to-hash filter-data
]
;[NetWeight: decimal! L1SparePartPrice: decimal! L1RepairPrice: decimal! L1ExchangePrice: decimal! L2SparePartPrice: decimal! L2RepairPrice: decimal! L2ExchangePrice: decimal! SparePartLeadTime: integer! RepairLeadTime: integer!]
products-db: csv-to-bulk/select/every/where/types dir/data/siemens-product-db-extractor3.csv [ProductCode MLFB Options SAPMaterialCode SpareNewStatus ProductMilestone RepairStatus NetWeight WeightUnit L1SparePartPrice L1RepairPrice L1ExchangePrice L2SparePartPrice L2RepairPrice L2ExchangePrice SparePartLeadTime RepairLeadTime ShortDescription PCK][
	ProductCode: make-product-code MLFB options
	SAPMaterialCode: select sap-db ProductCode
	;v?? ProductCode
	opt: none
	;v?? L2_SP_Price
	if [
		string? options
		empty? trim options
	][
		options: none
	]
][
	;where statement
	any [
		not filter-data
		find filter-data mlfb
	]
][
	;types statement
	NetWeight: decimal! 
	L1SparePartPrice: decimal! 
	L1RepairPrice: decimal! 
	L1ExchangePrice: decimal! 
	L2SparePartPrice: decimal! 
	L2RepairPrice: decimal! 
	L2ExchangePrice: decimal! 
	SparePartLeadTime: integer! 
	RepairLeadTime: integer!
]
sort-bulk/reverse/using products-db 'ProductCode

;write rdata-dir/products-sort.rdata mold/all products-db
vprint "PROCESSING PRODUCT DB DONE"

;v?? products-db

dataset: []

repeat i 1000 [
	repend dataset [ to-string i rejoin [to-string i to-string i to-string i ] rejoin [to-string i "-options"] i ]
]


columns: products-db/1/4
;v?? columns
;ask "..."
;v?? products-db
;ask "..."
;voff
;mysr/voff
it: dt probe compose/only [
	vprint "====================="
	vprint "====================="
	vprint "====================="
	vprint "====================="
	foreach (columns) next products-db[ ;products-db [
		bind columns 'ProductCode
		vprobe reduce columns
		;ask "..."
		insert-sql 'product columns reduce columns
	]
]
;mysr/von
;von

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

