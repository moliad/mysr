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
;-     column-set-count:
;
; how many sets of string:integer columns do you want per row?
;--------------------------
column-set-count: 1

;--------------------------
;-     cellsize:
;
; length of strings in cells
;--------------------------
cellsize: 5

;--------------------------
;- null-percentage:
;
; how many null values to insert in the result grid
;     - must be an integer
;     - 0 disables nulls
;--------------------------
null-percentage: 10


;--------------------------
;-     rows:
;
; how many total rows to setup
;--------------------------
rows: 100

;--------------------------
;-     insert-cluster:
;
; how -many sets of VALUES to insert per insert-sql call
;--------------------------
insert-cluster: 47

;--------------------------
;-     debug?:
;
; use debug lib?
;--------------------------
debug?: false

;--------------------------
;-     tracelog-path:
;--------------------------
tracelog:  %mysr-trace.log

;--------------------------
;-     stats-file:
;
;--------------------------
stats-file: %insert-speed-stats.rdata

;--------------------------
;-     mysr.buffersize:
;
; if this is set BEFORE importing mysr lib, then it uses this
; instead of its default when initializing itself.
;--------------------------
MYSR-QUERY-BUFFERSIZE: 12'000'000

;--------------------------
;-     dbname:
;--------------------------
dbname: 'MysrSpeedTest

;--------------------------
;-     session:
;
;--------------------------
session: none


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- ARGS
;
;-----------------------------------------------------------------------------------------------------------

ssa: system/script/args

either string? ssa [
	?? ssa
	if find ssa "-debug" [
		print "USE DEBUG LIB"
		USE-MYSR-DEBUG-DLL: true
	]
][
	print "No args"
]


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
;ask "!"

von

;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- BUILD DATASETS
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;-     col-types:
;
;--------------------------
col-types: []
repeat i column-set-count [
	append col-types [string! integer! decimal!]
]
v?? col-types

;--------------------------
;-     table-spec:
;
; table descript spec for create trable
;--------------------------
table-spec: []


;--------------------------
;-     columns:
;
;--------------------------
columns: []
i: 1
foreach column col-types [
	append columns to-word rejoin [to-word form get column "_" i]
	append table-spec to-word rejoin [to-word form get column "_" i]
	switch column [
		string!  [ append table-spec 30 ]
		integer! [ append table-spec 'integer!]
		decimal! [ append table-spec 'decimal!]
	]
	++ i
]
v?? columns
v?? table-spec

;--------------------------
;-     col-count:
;
;--------------------------
col-count: length? columns

;--------------------------
;-     cell-count:
;
;--------------------------
cell-count: col-count * rows

;--------------------------
;-     grid:
;
;--------------------------
grid: []
repeat i rows [
	foreach type col-types [
		all [
			null-percentage > 0
			(random 100) <= null-percentage
			type: 'none!
		]
	
		switch type [
			integer! [
				append grid i
			]
			string! [
				append grid  copy/part random "12345678901234567890" cellsize
			]
			decimal! [
				append grid  (random 1000'000'000) * 0.0001 
			]
			none! [
				append grid none
			]
		]
	]
]


new-line/skip grid true col-count
vprint ["size of grid: " length? grid]
v?? grid






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
vprint "testing mysr dll speed..."

connect "localhost" "" "root" "123456"

;------------
;-     - Traces
;------------
von
mysr/von
bulk-lib/von
;trace-sql tracelog

;------------
;-     - Create tables
;------------
vprint "============ TABLE CREATION ============="
dbs: list-dbs
v?? dbs

if find dbs to-string dbname [
	; we always drop it... we want new data at each time.
	query ["drop database " db] dbname
]	

do-mysql compose/deep [
	CREATE DATABASE :dbname
	CREATE TABLE 'test [
		id		autokey!
		(table-spec)
	]
]
bulk-lib/default-null: ""




;----------------------------
;-     - insert tests
;----------------------------
vprint "============ INSERTS ============="
trace-sql tracelog
cluster: insert-cluster
t: dt [success?: insert-sql/cluster/typed  'test  columns  grid  cluster  col-types]


if t = 0 [
	t = 0.001
]

secs: to-decimal t
vprint "============================="
vprint ["     inserts complete"]
vprint "============================="
v?? success?
vprint ["Time :    " t ]
vprint ["Seconds : " secs ]
vprint ["Rows :    " rows]
vprint ["Cells :   " cell-count]
vprint ["columns per row: " (col-count) ]
vprint ["rows  / insert : " cluster ]
vprint ["total inserts  : " (rows / cluster) ]
vprint ["cells / insert : " (cluster * col-count) ]
vprint ["rows  / sec    : " rows / secs ]
vprint ["cells / sec    : " cell-count / secs ]
vprint ["clusters / sec : " (rows / cluster) / secs ]


write/append stats-file mold reduce [ 
	t  
	secs  
	rows  
	cell-count
	col-count  
	cluster  
	(rows / cluster)
	(cluster * col-count)  
	(rows / secs)  
	cell-count / secs
	(rows / cluster ) / secs
]
write/append stats-file "^/"


ask "press enter to launch select..."




;ask ""

;----------------------------
;-     - select tests
;----------------------------



vprint "============ SELECTS ============="
result: none
t: dt [
	;result: sql "select * FROM test ;"
]

v?? result
;vprint ["select time: " t]
;v?? result


;probe sql "SHOW CHARACTER SET;"

;escaped: escape-sql {aaa";drop database}
;v?? escaped

ask "..." 

