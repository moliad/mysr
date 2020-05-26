rebol []

do %../slim-libs/slim/slim.r
slim/vexpose
slim/add-path clean-path %mysr-libs/

bulk-lib: slim/open/expose 'bulk none [ realign-bulk-rows csv-to-bulk make-bulk insert-objects bulk-to-csv select-bulk sort-bulk column-labels bulk-columns add-column]
mysr: slim/open/expose 'mysr none [
	connect  
	list-dbs 
	sql: mysql 
	query 
	query!  
	escape-sql  
	trace-sql 
	do-mysql 
	insert-sql
]


tracelog-path:  to-local-file clean-path %mysr-tracelog.txt




print "testing..."




connect "localhost" "" "root" "123456"
dbname: 'siemens

dbs: list-dbs
if find dbs "siemens" [
	sql "DROP database siemens;"
]

do-mysql [
	CREATE DATABASE :dbname

	CREATE TABLE 'discount [
		DiscountCode  100
		Discount    decimal!
	]
]


;it: dt compose/only [
;	foreach (columns) next discount-db [ ;contact-db [
;		bind columns 'DiscountCode
;		;vprobe reduce columns
;		;ask "..."
;		insert-sql 'discount columns reduce columns
;		if 0 = modulo counter 100 [
;			vprint counter
;		]
;		counter: counter + 1
;		;insert-sql 'product ["aaa" "111" "aaa-111" 1 "bbb" "222" "bbb-222" 10 ]
;	]
;]
von
mysr/von
print "insert"

trace-sql %debug-trace.log

insert-sql 'discount [DiscountCode Discount] ["6CL-PCK-2608-12" 10.1]

ask "..."

quit

print dt [
	loop 100 [
		insert-sql 'discount [DiscountCode Discount] ["6CL-PCK-2608-12" 10.1]
	]
]

print "select"
discount-query: {SELECT Discount FROM discount WHERE DiscountCode="6CL-PCK-2608-12";}
data: sql discount-query


ask "..."