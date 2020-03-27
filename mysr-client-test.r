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
dbname: 'siemens


;--------------------------
;-     session:
;
;--------------------------
session: none

;--------------------------
;-     only-rebuild-db:
;
; in production, this is none.
;
; while developping, you can choose one or more DBs to rebuild.
;--------------------------
;only-rebuild-db: [
;	contact-db
;	product-db
;]
;only-rebuild-db: [product-db sap-db] 
only-rebuild-db: [discount-db] 
;only-rebuild-db: none
;only-rebuild-db: [client-db contact-db domain-equiv-db sap-db products-db client-domain-db discount-db]

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
;v?? dbs


;trace-sql %mysr-trace.log


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------
;--------------------------

;-     get-discount-code()
;--------------------------
; purpose: Get a discount code using CustomerLevel_ID-MaterialLevel-MaterialLevel_ID-Channel
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
get-discount-code: funcl [
	CustomerLevel_ID [string!]
	MaterialLevel [string!]
	MaterialLevel_ID [string!]
	Channel [string! integer!]
][
	rejoin [CustomerLevel_ID "-" MaterialLevel "-" MaterialLevel_ID "-" Channel]
]

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
	
	CREATE TABLE 'discount [
		DiscountCode	100
		Discount		decimal!
	]
	
	CREATE TABLE 'contact [
		Email				100
		Surname				40
		FirstName			40
		CompanyNumber		100
		Name1				120
		Name2				120
		PL					2
		Grp2				30
		CustomerGroup2		30
	]
]

bulk-lib/default-null: ""



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;-     CLIENT-DB
;
;-----------------------------------------------------------------------------------------------------------
if any [
	not only-rebuild-db
	find only-rebuild-db 'client-db
][
	print "PROCESSING CLIENT DB"
	client-db: csv-to-bulk/select  join dir %data/siemens-client-db.csv [Customer Name1 Name2 PL Grp2 CustomerGroup2]
	rebuild-client-rule?: true
	client-db: to-hash next client-db
	;v?? CLIENT-DB
	;ask "..."
	print "PROCESSING CLIENT DB DONE"
]




;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;-     CONTACT-DB
;
;-----------------------------------------------------------------------------------------------------------
if any [
	not only-rebuild-db
	all [
		find only-rebuild-db 'client-db
		find only-rebuild-db 'contact-db
	]
][
	vprint "PROCESSING CONTACT DB"	
	contact-db: csv-to-bulk/utf8/select join dir %data/siemens-contact-db.csv  [ Email Surname FirstName CompanyNumber]
	;==============
	; generating ambiguous client 
	pure-columns: exclude column-labels contact-db [Surname FirstName]
	;probe contact-db-bulk
	;probe pure-columns
	;probe next contact-db-bulk
	pure-contact-bulk: select-bulk/select contact-db pure-columns
	column-count: bulk-columns pure-contact-bulk
	record: next pure-contact-bulk
	
	;ask "YEEEEEEEES"
	ambiguous-contacts: make hash![]
	classify-blk: make hash![]
	potential-blk: make hash![] 
	repetetive-blk: make hash![]

	forskip record column-count [
		key: first record
		;v?? key
		unless blk: select classify-blk key [
			repend classify-blk [ key blk: copy[]]
			;if (length? blk ) > 1 [ repend potential-blk [ key blk: copy[]] ]
		]
		append blk copy/part next record column-count - 1
		;if (length? blk ) > 1 [ repend potential-blk [key blk]]
		
		new-line/skip blk true column-count - 1
	]
	;print classify-blk

	;ask "BEFORE FILTERING"

	foreach [email blk] classify-blk [
		clients: unique blk
		either ( length? clients ) > 1  [
			repend  ambiguous-contacts  [email clients]
			;?? ambiguous-contacts
		][
			; clean up the list so its unique
			clear blk
			append blk clients
		]
	]
	
	;print "ambiguous-contacts"
	;v?? ambiguous-contacts
	new-line/skip ambiguous-contacts: to-block ambiguous-contacts true 2
	;print classify-blk
	;ask "ambiguous-contacts"
	
	;ask "Ambiguity Found"
	
	;----finishing generating the ambiguous-contacts 
	;=============

	rebuild-client-rule?: true


	table: next contact-db
	
	email: Surname: FirstName: CompanyNumber: Name1: Name2: PL: Grp2: CustomerGroup2: none ;Grp2: CustomerGroup2: none
	
	;---
	;add columns to contact-db
	;---
	delay: dt [add-column contact-db [ Name1 Name2 PL Grp2 CustomerGroup2 ]]
	v?? delay
	vprint "JOINING CLIENT-DB DATA TO CONTACT-DB"
	until [
		;vprint "^/======================================================="
		set [Email Surname FirstName CompanyNumber   Name1 Name2 PL Grp2 CustomerGroup2] table
		client: find client-db CompanyNumber
		
		either client [
			set [CompanyNumber Name1 Name2 PL Grp2 CustomerGroup2] client
		][
			Name1: ""
			Name2: ""
			PL: "Unknown"
			Grp2: ""
			CustomerGroup2: ""
			; <TODO>   remove comments... in production.
		]
		
		next-row: change table reduce [ Email Surname FirstName CompanyNumber Name1 Name2 PL Grp2 CustomerGroup2] ; CHANGE returns block After its change, (after last column, so the first column of next row)
		
		table: next-row

		tail? table
	]

	;new-line/skip next contact-db true 9
	realign-bulk-rows contact-db
	
	columns: next next next contact-db/1
	;v?? columns
	;ask "..."
	counter: 0
	;voff
	;mysr/voff
	it: dt compose/only [
		foreach (columns) next contact-db[ ;contact-db [
			bind columns 'Email
			;vprobe reduce columns
			;ask "..."
			insert-sql 'contact columns reduce columns
			if 0 = modulo counter 100 [
				vprint counter
			]
			counter: counter + 1
			;insert-sql 'product ["aaa" "111" "aaa-111" 1 "bbb" "222" "bbb-222" 10 ]
		]
	]
	
	vprint "PROCESSING CONTACT DB DONE"
]


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;-     DOMAIN-EQUIV-DB
;
;-----------------------------------------------------------------------------------------------------------
if any [
	not only-rebuild-db
	find only-rebuild-db 'domain-equiv-db
][
	vprint "PROCESSING DOMAIN-EQUIV DB"
	domain-equiv-db: csv-to-bulk/utf8/select dir/data/siemens-domain-equiv-db.csv [Domain ClientID]
	v?? domain-equiv-db
	domain-equiv-db: to-hash copy next domain-equiv-db
	
	vprint "PROCESSING DOMAIN-EQUIV DB DONE"
]

;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;-     SAP-DB
;
;-----------------------------------------------------------------------------------------------------------
if any [
	not only-rebuild-db
	find only-rebuild-db 'sap-db
][
	print "PROCESSING SAP DB"
	sap-db: csv-to-bulk/select/every join dir %data/siemens-sap-products-db.csv [ProductCode Material] [ProductCode: make-product-code ProductNumberPrint Options] 
	sap-db: to-hash next sap-db

	print "PROCESSING SAP DB DONE"
;vprint ["LOADING SAP DB DONE (" delay ")" ]
]
;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;-     PRODUCT-DB
;
;-----------------------------------------------------------------------------------------------------------
if any [
	not only-rebuild-db
	all [
		find only-rebuild-db 'sap-db
		find only-rebuild-db 'product-db
	]
][
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


	;v?? products-db

	;dataset: []
	;
	;repeat i 1000 [
	;	repend dataset [ to-string i rejoin [to-string i to-string i to-string i ] rejoin [to-string i "-options"] i ]
	;]


	columns: products-db/1/4
	;v?? columns
	;ask "..."
	;v?? products-db
	;ask "..."
	counter: 0
	;voff
	;mysr/voff
	it: dt compose/only [
		foreach (columns) next products-db[ ;products-db [
			bind columns 'ProductCode
			;vprobe reduce columns
			;ask "..."
			insert-sql 'product columns reduce columns
			if 0 = modulo counter 100 [
				vprint counter
			]
			counter: counter + 1
			;insert-sql 'product ["aaa" "111" "aaa-111" 1 "bbb" "222" "bbb-222" 10 ]
		]
	]
	vprint "PROCESSING PRODUCT DB DONE"
	;mysr/von
	;von

	;vprint ["insert time: " it]
	;v?? it


	t: dt [
		result: sql "select * FROM product ;"
	]
]

;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;-     DISCOUNT-DB
;
;-----------------------------------------------------------------------------------------------------------
if any [
	not only-rebuild-db
	all [
		find only-rebuild-db 'discount-db
	]
][
	vprint "PROCESSING DISCOUNT DB"
	discount.csv: as-string read/binary join dir %data/siemens-discount-db.csv

	discount-db: csv-to-bulk/select/each discount.csv [DiscountCode Discount] [
		DiscountCode: get-discount-code CustomerLevel_ID MaterialLevel MaterialLevel_ID Channel 
		Discount: either DiscountUnit = "EUR" [
			to-money Net_or_Discount_Value
		][
			to-decimal Net_or_Discount_Value
		]
	]
	columns: discount-db/1/4
	v?? columns
	;v?? columns
	;ask "..."
	counter: 0
	;voff
	;mysr/voff
	it: dt compose/only [
		foreach (columns) next discount-db[ ;contact-db [
			bind columns 'DiscountCode
			;vprobe reduce columns
			;ask "..."
			insert-sql 'discount columns reduce columns
			if 0 = modulo counter 100 [
				vprint counter
			]
			counter: counter + 1
			;insert-sql 'product ["aaa" "111" "aaa-111" 1 "bbb" "222" "bbb-222" 10 ]
		]
	]
	discount.csv: none ; clear from GC
	vprint "PROCESSING DISCOUNT DB DONE"
]

;vprint ["select time: " t]
;v?? result


;probe sql "SHOW CHARACTER SET;"

;escaped: escape-sql {aaa";drop database}
;v?? escaped

;ask "..." 

