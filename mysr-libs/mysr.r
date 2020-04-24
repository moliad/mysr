REBOL [
	; -- Core Header attributes --
	title: "MySQL Rebol connector"
	file: %mysr.r
	version: 0.6.0
	date: 2020-02-20
	author: "Maxim Olivier-Adlhoch"
	purpose: {Open source full featured mysql connector.}
	web: http://github/moliad/mysr
	source-encoding: "Windows-1252"
	note: {slim Library Manager is Required to use this module.}

	; -- slim - Library Manager --
	slim-name: 'mysr
	slim-version: 1.4.0
	slim-prefix: none

	; -- Licensing details  --
	copyright: "Copyright © 2020 Maxim Olivier-Adlhoch"
	license-type: "Apache License v2.0"
	license: {Copyright © 2020 Maxim Olivier-Adlhoch

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.}

	;-  / history
	history: {
	}
	;-  \ history

	;-  / documentation
	documentation: ""
	;-  \ documentation
]






;--------------------------------------
; unit testing setup
;--------------------------------------
;
; test-enter-slim 'mysr
;
;--------------------------------------

slim/register [

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
	debug?: all [
		value? 'USE-MYSR-DEBUG-DLL
		true? USE-MYSR-DEBUG-DLL
	]


	;--------------------------
	;-     default-session:
	;
	; connect will set this each time it is called, thus the last connection is always the default session.
	;--------------------------
	default-session: none


	;--------------------------
	;-     dlldir:
	; the dll is now setup to be used in the same folder as the mysr... remember to copy the mysql dll here.
	;--------------------------
	dlldir:  %./


	;--------------------------
	;-     dllname:
	;
	;--------------------------
	dllname: either debug? [ %mysr-debug.dll ] [ %mysr.dll ]


	;--------------------------
	;-     dllpath:
	;
	;--------------------------
	dllpath: join dlldir dllname
	;?? dlldir
	;?? dllpath


	;--------------------------
	;-     buffersize:
	;
	;--------------------------
	buffersize: any [
		all [
			value? 'MYSR-QUERY-BUFFERSIZE
			integer? MYSR-QUERY-BUFFERSIZE
			MYSR-QUERY-BUFFERSIZE
		]
		10'000'000
	]
	
	
	;--------------------------
	;-     quote-buffer:
	;
	; used (and reused) by function escape-sql()
	;--------------------------
	quote-buffer: ""
	
	


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- LIBS
	;
	;-----------------------------------------------------------------------------------------------------------
	slim/open/expose 'mysr-routines none [ 
		mysr.test  mysr.init  mysr.connect  mysr.tracelog
		mysr.list-dbs  mysr.query  mysr.escape-string-quote
		mysr.create-statement  mysr.release-statement  mysr.new-row  
		mysr.bind-string-value  mysr.bind-integer-value  mysr.bind-decimal-value
		mysr.set-null  mysr.set-string  mysr.set-integer mysr.set-decimal
		mysr.bind-statement  mysr.do-statement
	]


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- REBOL ERROR
	;
	;-----------------------------------------------------------------------------------------------------------
	system/error: make system/error [
		mysql: make object! [
			code: 1000 ; not guaranteed... real value is:  (index of object in system/error block) * 100
			type: "MySQL Error" 
			
			; error definitions start here:
			generic: [ rejoin [ "" :arg1 ] ]
			connector: [ rejoin [ "MySQL Connector ERROR: " :arg1 ] ]
			null: [  "MySQL NULL RESULT ERROR" ]
			invalid-result: [ "MySQL Invalid return" ]
		]
	]


;	;--------------------------
;	;-     make-error()
;	;--------------------------
;	; purpose:  
;	;
;	; inputs:   
;	;
;	; returns:  
;	;
;	; notes:    
;	;
;	; to do:    
;	;
;	; tests:    
;	;--------------------------
;	make-error: funcl [
;		[catch]
;		type [word!]
;		msg [string!]
;	][
;		;vin "make-error()"
;		;vout
;		;throw-on-error [
;			throw make error! compose [ mysql (type) (msg) ]
;		]
;	]
	
	
	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- CLASSES
	;
	;-----------------------------------------------------------------------------------------------------------
	;--------------------------
	;-     query!: [...]
	;
	; helper class to build and send safe (injection-proof queries)
	;--------------------------
	query!: context [
		;--------------------------
		;-         query:
		;
		; query to send to DB, in block format.
		;
		; words are replaced by their equivalents in variables.
		;
		; variables are injection-proofed before building the final query.
		;
		; we also detect if the query is missing a semi-colon at end and add it.
		;--------------------------
		query: ["show databases"]
		
		;--------------------------
		;-         variables:
		;
		;--------------------------
		variables: context [
		]
	]
	


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- GENERIC FUNCTIONS
	;
	;-----------------------------------------------------------------------------------------------------------


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- INTIALISE DLL
	;
	;-----------------------------------------------------------------------------------------------------------
	vprint "initialising mysr for 10MB max query buffer"
	;?? buffersize
	success: mysr.init buffersize
	;?? success
	if success = 0 [
		to-error "mysr.init() UNABLE TO INITIALISE MYSQL CONNECTOR"
	]




	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;-     DIALECTS
	;
	;-----------------------------------------------------------------------------------------------------------
	;--------------------------
	;-     parse-mysql-ctx: [...]
	;
	; all the rules used by do-mysql
	;--------------------------
	parse-mysql-ctx: context [
		;--------------------------
		;-         .name:
		; generic variable which must be used in the same rule (must not allow a sub-rule after (since .name may be replaced by it.)
		;--------------------------
		.name: none
		
		;--------------------------
		;-         mysql-script:
		;
		; reused container to store sql script to execute after =mysql= rule is done.
		;--------------------------
		mysql-script: []
		
		
		;--------------------------
		;-         =mysql=:
		;
		;--------------------------
		=mysql=: [
			(clear mysql-script)
			any [
				[
					;---
					; db creation
					'CREATE [ 'DATABASE | 'DB ] 
						set .name [get-word! | lit-word! | word! ] 
						(vprint "!")
						(
							if get-word? :.name [
								;v?? .name
								.name: get .name
							]
							;v?? .name
							append mysql-script compose/deep [
								query [ "create database " db ] [(to-word .name)]
								query [ "use " db ] [(to-word .name)]
							]
						)
					
					;---
					; db loading
					| 'USE 
						set .name [word! | string!] 
						(
							append mysql-script compose [
								query [ "use " db ] [(to-string .name)]
							]
						)
					
					;---
					; TABLE creation
					| 'CREATE 'TABLE 
					set .name [ get-word! | lit-word! | word! ]
					set .spec block!
					(
						if get-word? :.name [
							.name: get .name
						]
						repend mysql-script [
							'create-table to-lit-word .name .spec
						]
					)
				]
				
				| skip
			]
		]
	]



	;--------------------------
	;-     trace-sql()
	;--------------------------
	; purpose:  given a path, set the tracelog-file and activate it.
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
	trace-sql: funcl [
		path [string! file!] "if given string!, we expect a system path."
	][
		vin "trace-sql()"
		if file? path [
			path: to-local-file clean-path path
		]
		mysr.tracelog path
		vout
	]
	

	;--------------------------
	;-     escape-sql()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    performs change "in-place"
	;
	; to do:    
	;
	; tests:    
	;--------------------------
	escape-sql: funcl [
		text [string!]
		/tick
		/backtick
		/using session [integer!]
		/extern quote-buffer
	][
		;vin "escape-sql()"

		session: any [session default-session]
		required-buffer-size: ((length? text) * 2 + 1 )
	
		if (length? quote-buffer) < required-buffer-size  [
			quote-buffer: head insert/dup (copy "") "^@" required-buffer-size + 10
		]
	
		wrap-char: case [
			tick [#"'"]
			backtick [#"`"]
			'default [#"^""]
		]
		
		;v?? text
		;v?? [length? text]
		newlength: mysr.escape-string-quote session text quote-buffer length? text wrap-char
		
		;v?? quote-buffer
		;v?? newlength
		;v?? [ length? quote-buffer ]
		
		clear text
		append text copy/part quote-buffer newlength
	
		;vout
		text
	]


	;--------------------------
	;-     connect()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    
	;
	; to do:    get and return mysql error
	;
	; tests:    
	;--------------------------
	connect: funcl [
		[catch]
		host [string! tuple!]
		db [string! word!]
		usr [string! word!]
		passwd [string! binary!]
		/extern default-session
	][
		vin "mysr.connect()"
		
		host: to-string host
		db: to-string db
		usr: to-string usr
		passwd: to-string passwd
		session: mysr.connect host db usr passwd
		
		throw-on-error [
			if session = 0 [
				session: none
				to-error "mysr.connect(): unable to connect to DB"
			]
			none
		]
		default-session: session
		
		vout
		session
	]



	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- QUERY MANAGEMENT
	;
	;-----------------------------------------------------------------------------------------------------------



	;--------------------------
	;-     sql-options()
	;--------------------------
	; purpose:  return MySQL options based on our options dialect
	;--------------------------
	sql-options: funcl [
		options [block! none!]
	][
		vin "sql-options()"
		str: clear ""
		;v?? options
		if options [
			;---
			; we must deal with the size first, since it must immediately follow the type name.
			;---
			if size: find/last options integer! [
				vprint "found size!"
				size: take size
				append str rejoin [ "(" size ")" ]
			]
			if spec: find/last options pair! [
				vprint "found spec!"
				spec: take spec
				append str rejoin [ "(" spec/x "," spec/y ")" ]
			]
			parse options [
				any [
					'auto-increment (
						vprint "found auto-increment"
						append str " AUTO_INCREMENT" 
					)
					| 'index (
						; this column can be searched, it must be indexed
						vprint "found index"	
						append str " INDEX"
					)
					| 'unique (
						; this column cannot have two rows with same data
						vprint "found unique"	
						append str " UNIQUE"
					)
					| 'primary (
						; this column cannot have two rows with same data
						vprint "found unique"	
						append str " PRIMARY KEY"
					)
					| skip
				]
			]
		]
		vout
		copy str
	]


	;--------------------------
	;-     sql-type()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    the contents of the options block! MAY BE modified as a result of this function!!!
	;
	; to do:    
	;
	; tests:    
	;--------------------------
	sql-type: funcl [
		type [word!] ; use this pseudo-type
		options [block!] ; also set these options!
	][
		;vin "sql-type()"
		
		sql-type: none
		
		switch type [
			string! [
				; by default we use a varchar with a max size of 255 bytes.
				sql-type: "VARCHAR" 
				unless find options integer! [
					append options 255 ; integers are used as the max size
				]
			]
			text! [
				; by default we use a longtext
				sql-type: "LONGTEXT"
			]
			
			binary! [
				; by default we use a generic blob type
				sql-type: "LONGBLOB"
			]
			integer! [
				; by default we use a 32 bit signed integer value (like rebol)
				sql-type: "INTEGER"
			]
			autokey! [
				; simply an integer! with the auto-increment value set to true.
				sql-type: "INTEGER"
				unless find options 'auto-increment [
					append options 'auto-increment
				]
				unless find options 'unique [
					append options 'unique
				]
			]
			literal! [
				sql-type: "VARCHAR"
				append options 255
			]
			
			decimal! [
				; Use sql decimal type  
				;
				; note that rebol actually uses double internaly. For currency, this should be ok.
				;
				; we may decide to use an alternate data mechanism to exchange decimal values and cast them when needed.
				; this would be useful when we don't do arithmetic and require the data to remain unchanged textually.
				; 
				sql-type: "DECIMAL"
				unless find options pair! [
					append options 10x4
				]
					
			]
			
			json! [
				; use optimised JSON storage
				sql-type: "JSON"
			]
		]

		;vout
		sql-type
	]



	;--------------------------
	;-     reduce-query()
	;--------------------------
	; purpose:  just like reduce, but will convert all string-based values to string!
	;           and escape the string to mysql specs.  this prevents sql injection, even
	;           on values which are not bound to the query/variables context
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    - We escape using back-tick by default as these are MUCH less used in the wild.
	;           - as with reduce, the operation is "in-place"
	;           - we do not support unbound words in blk on purpose
	;
	; to do:    
	;
	; tests:    
	;--------------------------
	reduce-query: funcl [
		[catch]
		blk [block!]
		/tick
		/quotes
		/allow-unquoted "Allows unsafe query! blocks to be reduced."
	][
		;vin "reduce-query()"
		throw-on-error [
			parse blk [
				some [
					.here: 
					
					;-------------------------
					; standard value, bound, quoted and escaped.
					set word word! (
						value: get word
						
						switch/default type?/word :value [
							function! object! native! op! paren! port! [
								to-error rejoin ["invalid type in query spec: " type?/word :value " here: " mold/all pick .here 2 "..." ]
							]
							word! [
								embedded-value: rejoin ["`" escape-sql/backtick form value "`"]
							]
							integer! decimal! [
								embedded-value: form :value
							]
							none! [
								embedded-value: "NULL"
							]
						][
							embedded-value: rejoin [ {"} escape-sql form value {"} ]
						]
						;v?? word
						;v?? value
						;v?? embedded-value
						change .here embedded-value
					)
					
					;-------------------------
					; unsafe value, not allowed by default... must use /allow-unquoted
					;
					; get words are not quoted nor escaped.  they are dangerous and should be used ONLY with data
					; which isn't originated from a client (untrusted) source.  These CAN EASILY ALLOW SQL INJECTION.
					| set word get-word! (
						unless allow-unquoted [
							to-error ["Unsafe value spec found in query spec. : " word " use /allow-unquoted to force query."]
						]
						word: to-word word ; we got a get-word!, just make things simpler.
						value: form get word
						value:  form value
						; we do not quote or escape value!
						change .here value
					)
					| set value [function! | object! | native! | op! | paren! | port!] (
						to-error rejoin ["invalid type in query spec: " type?/word :value " here: " mold/all pick .here 2 "..." ]
					)
										
					| skip
				]
			]
			;----- 
			; all good, no reason to throw an error
			;----- 
			true
		]
		;vout
		
		blk
	]


	;--------------------------
	;-     mysql()
	;--------------------------
	; purpose:  lowest level function which sends a textual query and receives a textual response.
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    this function usually isn`t called directly within 
	;
	; to do:    
	;
	; tests:    
	;--------------------------
	mysql: funcl [
		[catch]
		query [string! block!]
		/raw "returns the raw result string from mysr"
	][
		;vin "mysql()"
		session: any [ session default-session ]
		unless session [
			throw-on-error [
				to-error "list-dbs() must connect to server first"
				none
			]
		]
		;vprint query
		if block? query [
			query: rejoin query
		]
		
		throw-on-error [
			data: mysr.query session query
			unless raw [
				data: load-mysr data
			]
		]
		;vout
		
		first reduce [data data: none]
	]
	
	
	;--------------------------
	;-     query()
	;--------------------------
	; purpose:  
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
	query: funcl [
		[catch]
		query   [object! block! string!]
		values  [object! string! block! none! word!]
		/check "Do not actually run the query, just print out what it would look like in sql."
		/allow-unquoted "get-word! values are allowed in given query"
	][
		vin "query()"
		throw-on-error [
		;0 / 0
			word: none
			result: none
			;v?? query
			;v?? values
			if any [
				string? values
				word? values
			] [
				values: reduce [values]
			]
			
			if string? query [
				query: reduce [query]
			]
			
			if block? query [
				; I guess the following is a query  ;-D
				query: make query! compose/only [query: (query)]
				;v?? query
			]
			
			if string? values [
				; a string is a block of 1 argument
				values: reduce [values]
			]
			
			switch type?/word values [
				object! [
					query/variables: make query/variables values 
				]
			
				block! [
					;vprint "got block variables"
					; when given a block of values, we assume these are given in numerical order,
					;
					; the first value is set to the first variable (any word!) in the query
					words: copy []
					variables: copy []
					ctx-words: words-of query/variables
					;v?? query/query
					
					parse query/query [
						some [
							set word word! (
								;vprint ["FOUND variable: " word]
								unless find variables word [
									append variables word
								]
								unless find ctx-words word [
									append words to-set-word word
									append ctx-words word ; we don't want to add the same word twice.
								]
							)
							| skip
						]
					]
					;v?? words
					;v?? variables
					
					unless empty? words [
						append words none
						query/variables: make query/variables words 
					]
					
					; add a refinement for missing values as null?
					if (length? values) < (length? variables) [
						to-error ["mysr/query() missing values for given query : " mold query/query]
					]
					
					i: 1
					foreach word variables [
						value: any [
							pick values i 
							;"NULL"
						]
						set (in query/variables word) value
						++ i
					]
				]
			]
			
			;--------
			; at this point we have properly constructed query! instance ready to perform
			;--------
			;v?? query
			query-blk: copy/deep query/query 
			bind query-blk query/variables

			;v?? query-blk
			either allow-unquoted [
				query-blk: reduce-query/allow-unquoted query-blk
			][
				query-blk: reduce-query query-blk
			]
			
			;v?? query-blk
			replace/all query-blk #[none] "NULL"
			
			;vprint "============================"
			;v?? query-blk
			;vprint "============================"
			query-str: form query-blk
			
			unless #";" = last query-str [
				append query-str ";"
			]
			v?? query-str
			
			either check [
				; user just wants a trace of what the query would be in final SQL
				print "=========================================="
				print query-str
				print "=========================================="
				result: none
			][
				mysql-result: mysql/raw query-str
				v?? [length? mysql-result]
				;v?? mysql-result
				result: load-mysr mysql-result
				;v?? result
			]
			vout
		]
		;-----
		; clean GC result
		first reduce [result result: mysql-result: query-str: query-blk: values: query: words: ctx-words: none]
	]
	
	
	;--------------------------
	;-     load-mysr()
	;--------------------------
	; purpose:  
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
	load-mysr: funcl [
		[catch]
		data [string!]
	][
		vin "load-mysr()"
	
		throw-on-error [
			result: load data
			
			;v?? result
			
			either block? :result [
				type: first result
				;v?? type
				;v?? [word? type]
				either word? :type [
					v?? type
					switch type [
						grid [
							result: pick result 2
						]
						
						error [
							do next result
						]
						
						rows [
							result: pick result 2
						]
					]
				][
					make error! [mysql invalid-result]
				]
			][
				make error! [mysql null]
			]
		]
		vout
		result
	]


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- TRANSACTION MANAGEMENT
	;
	;-----------------------------------------------------------------------------------------------------------
	;--------------------------
	;-     start()
	;--------------------------
	; purpose:  starts a new transaction
	;--------------------------
	start: funcl [
	][
		vin "start()"
		result: sql "START TRANSACTION;"
		vout
		result
	]
	
	
	;--------------------------
	;-     commit()
	;--------------------------
	; purpose:  Commit current transaction;
	;--------------------------
	commit: funcl [
	][
		vin "commit()"
		result: sql "COMMIT;"
		vout
		result
	]
	
	
	;--------------------------
	;-     rollback()
	;--------------------------
	; purpose:  rollback current transaction
	;--------------------------
	rollback: funcl [
	][
		vin "rollback()"
		result: sql "ROLLBACK;"
		vout
		result
	]


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- HIGH-LEVEL FUNCTIONS
	;
	; all of these functions MUST pass through load-mysr()
	;-----------------------------------------------------------------------------------------------------------


	;--------------------------
	;-     list-dbs()
	;--------------------------
	; purpose:  
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
	list-dbs: funcl [
		[catch]
		/like filter [string!]
		/using session [integer!]
		/system "also include mysql system tables"
		/extern default-session
	][
		vin "list-dbs()"
		session: any [session default-session]
		filter: any [filter ""]
		
		;v?? filter
		;vprobe session
		
		unless session [
			throw-on-error [
				to-error "list-dbs() must connect to server first"
				none
			]
		]
		data: mysr.list-dbs session filter
		
		
		throw-on-error [
			result: load-mysr data
			if all [
				block? result 
				block? pick result 1
				integer? select result/1 first [columns:]
			][
				remove result  ; just remove bulk header
				unless system [
					result: exclude result ["information_schema" "performance_schema" "sys" "mysql"]
				]
				;v?? result
			]
		]
		v?? [length? result]
		
		;result: load data
		vout
		first reduce [result result: data: none]
	]

	
	;--------------------------
	;-     create-table()
	;--------------------------
	; purpose:  
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
	create-table: funcl [
		[catch]
		name [word!]
		columns [block!]
	][
		vin "create-table()"
		
		qry: copy ["CREATE TABLE " name "(^/" ] 
		params: reduce [name ]
		
		; column options
		.nulls?: false ; does this column allow NULLS.  it will become the default value if not set explicitely with .default.
		.default: none ; none becomes NULL and will be type according to column datatype if not null.
		.unique?: false ; does this column only store unique items
		.primary?: none ; what is the primary key to this table.
		.foreign: [] ; setup a reference to an external, existing table column of appropriate type.
		
		parse columns [
			some [
				set .name word!  (v?? .name .name: to-string .name)
				(
					.type: 'string!
					.current-options: copy []
					.sql-type: none
				)
				
				;----
				; remember, even though these look like datatypes they are just words in a block.
				opt [
					set .type [
						  'string! 
						| 'autokey! 
						| 'binary! 
						| 'integer! 
						| 'decimal! 
						| 'text!
						| 'literal!
						| 'json!
					]
				]
				(
					;v?? .type
					.sql-type: sql-type .type .current-options
				)
				any [
					set .options block! ( .options append .current-options .options) ;v?? .options
					
					| set .option [
						  'PRIMARY 
						| 'UNIQUE
						| 'INDEX
						| 'AUTO-INCREMENT 
						| 'AUTO_INCREMENT
					] ( 
						;v?? .current-options
						;v?? .option
						if .option = 'AUTO_INCREMENT [ .option: 'AUTO-INCREMENT]
						unless find .current-options .option [
							append .current-options .option
						]
					)
					| set .size integer! (
						v?? .size 
						append .current-options .size 
					)
					| set .spec pair! (
						v?? .spec 
						append .current-options .spec 
					)
				]
				(
					append qry reduce [ "^-" .name .sql-type (sql-options .current-options)]
					append qry ",^/"
				)
			]
		]
		remove back tail qry ; just remove last comma
		; end statement
		append qry "^/);"
		;v?? qry
		
		throw-on-error [
			result: query qry none
		]
		
	;	qry: reduce-query/allow-unquoted qry
	;	v?? qry
	;	
	;	qry-str: form qry
	;	v?? qry-str
	;	
	;	result: sql qry-str
	;	
		vout
		
		result
		
	]
	
	
	
	
	;--------------------------
	;-     insert-sql()
	;--------------------------
	; purpose:  
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
;	insert-sql: funcl [
;		table [word!]
;		columns [block!]
;		data [block!]
;	][
;		;vin "insert-sql()"
;		
;		;v?? columns
;		;v?? data
;		;ask "..."
;		
;		qry: clear []
;		qry-values: clear []
;		
;		data: copy data
;		word-name: 'w
;		counter: 1
;		
;		qry: clear []
;		append qry reduce [ "INSERT INTO" to-string table "(" ]
;		
;		foreach word columns [
;			append qry to-lit-word word
;			append qry ","
;		]
;		remove back tail qry 
;		append qry ") VALUES "
;		
;		len: length? columns
;		
;		until [
;			set: take/part data len
;			qryset: copy ["("]
;			foreach item set [
;				append qryset to-word rejoin [word-name counter]
;				append qry-values item
;				append qryset "," 
;				++ counter
;			]
;			remove back tail  qryset
;			append qryset ")"
;			append qry qryset
;			append qry ","
;		
;			empty? data 
;		]
;		take/last qry
;		
;		;v?? qry
;		;v?? qry-values
;		query qry qry-values
;		
;		;vout
;	]
	
	

	;--------------------------
	;-     insert-sql()
	;--------------------------
	; purpose:  use prepared statements to insert data. supports string! integer! and decimal!
	;
	; inputs:   
	;
	; returns:  columns affected.
	;
	; notes:    - builds its own transaction
	;           -  ** ATTENTION ** we use an APPLY within, update it with any change to the spec.
	;--------------------------
	insert-sql: funcl [
		table	[word!]		"Table to insert into.  must have a current db, connection must have permissions as usual."
		columns	[block!]	"Columns to use on insert, default values used as normal for unspecified columns."
		rows	[block!]	"Data to store, types MUST match data"
		/using session [integer!]	"insert into an alternate session, must still be connected and have permissions for this DB."
		/typed types [block!]   "a list of datatypes, if types are not given, we will attempt to insert everything as strings."
		/atomic "Do not run inside of a transaction (it may already be within one)"
		/cluster records "how many records to insert for each call to sql. MUST be more than 0."
	][
		vin "insert-sql()"
		success: true
		col-count: length? columns
		session: any [session default-session]
		records: any [records 1]
		cols: clear ""
		vals: clear ""

		;-----------
		; make sure given rows are an exact multiple of columns.
		;-----------
		if 0 <> modulo length? rows col-count [
			vprint ["Given row data is not an appropriate count of " col-count " columns"]
			vout
			false
		]
		
		;-----------
		; we keep a last slice to call insert-sql() with a cluster of 1
		; this is for when the given rows are not a perfect multiple of
		; cluster records.
		;-----------
		v?? length? rows
		if 0 <> extra: modulo length? rows (records * col-count) [
			;v?? [length? rows]
			;v?? records
			v?? extra
			
			extra-rows: take/last/part rows extra
			;v?? extra-rows
			
			;ask "!!!!"
		]
		
		;-----------
		; we only handle exceptions when we're not atomic
		; they are used for transaction control
		;-----------
		either atomic [
			exec: :do
		][
			exec: :try
		]

		
		
		foreach column columns [
			;v?? column
			append cols column 
			append cols ","
			append vals "?,"
		]
		take/last vals
		
		vals: rejoin ["(" vals ")"]
		
		record-sets: copy vals
		loop (records - 1) [
			append record-sets ","
			append record-sets vals
		]
		
		take/last cols 
		take/last vals
		
		
		err: EXEC [
			unless atomic [START]
			
			query: rejoin [ "INSERT INTO `" table "` (" cols ") VALUES " record-sets  ]
			statement: mysr.create-statement session query length? query
			
			either types [
				if (length? columns) <> (length? types)[
					to-error "insert-sql() types and columns must be of the same length"
				]
			][
				types: head insert/dup copy [] 'string! col-count
			]
			v?? statement
			
			;types: reduce types ; in case
			;vprint "reduced types"
			;v?? types
			query-buffers:  copy [  ]
			
			column-count: records * ( length? columns)
			v?? column-count
			;v?? query
			v?? types
			
			loop records [
				foreach type types [
					;vprint type
					switch/default type [
						string! [
							;vprint "string >"
							buffer: head insert/dup copy "" "^@" power 2 16 ; enough for 16k of text.
							append query-buffers buffer
							mysr.bind-string-value statement buffer length? buffer
							;vprint "< string"
						]
						decimal! [
							;vprint "decimal >"
							mysr.bind-decimal-value statement 
							;vprint "< decimal"
						]
						integer! [
							;vprint "> integer"
							mysr.bind-integer-value statement 
							;vprint "< integer"
						]
					][
						to-error "insert-sql() invalid type given, choose from  [ string! integer! decimal! ]"
					]
				]
				
			]
			v?? statement
			;ask "..."
			mysr.bind-statement statement
			vprint "statement bound"
			;ask "-->"
			
			; send data and execute statements.
			vin "inserting data loop"
			while[not empty? rows] [
				;vprint "=================================="
				mysr.new-row statement
				;copy/part rows col-count
				;v?? label
				;vprobe copy/part columns 2
				;vprobe rows
				loop records [
					repeat i col-count [
						;v?? rows
						item: pick rows i
						type: pick types i
						
						;v?? i
						;v?? item
						;v?? type
						;v?? item
						;v?? i
						if none? item [
							type: 'none!
						]
						switch type [
							string! [
								;vprint "inserting string"
								str: form item
								mysr.set-string statement str  (length? str)
							]
							decimal! [
								;vprint "inserting decimal"
								item: round/to item 0.0001
								str: form item
								mysr.set-decimal statement  str (length? str)
							]
							integer! [
								;vprint "inserting integer"
								mysr.set-integer statement to-integer item
							]
							none! [
								mysr.set-null statement
							]
						]
					]
					rows: skip rows col-count
					;vprint "row done"
				]
				lines-changed: mysr.do-statement statement
				if lines-changed < 1 [
					vprint "ERROR Executing the statement, breaking loop"
					success: false
					break
				]
				;tail? rows
			]
			vout
			rows
		] 
		if statement <> 0 [
			; in all cases, ok or error...
			mysr.release-statement statement
		]
		
		
		;-----------
		; if we have a few extra rows of data which don`t fit within the last cluster
		;-----------
		if extra-rows [
			; we run an insert-sql with the same setup except 
			success: apply :insert-sql [table columns extra-rows using session typed types true true 1]
		]
		
		
		
		unless atomic [
			either error? err [
				success: false
				disarm err
				ROLLBACK
			][
				COMMIT
			]
		]
		
		vout
		success
	]
	
	
	
	
	;--------------------------
	;-     do-mysql()
	;--------------------------
	; purpose: 	takes a block, and replaces known sql patterns into function calls, 
	;           leaves the rest as-is.
	;
	;           it then binds the resulting block and calls 'DO on it.
	;--------------------------
	do-mysql: funcl [
		[catch]
		instructions [block!]
	][
		vin "do-mysql()"
		throw-on-error [
			parse instructions parse-mysql-ctx/=mysql= 
			script: parse-mysql-ctx/mysql-script
			;v?? script
			do script
		]
		vout
	]

	;-                                                                                                       .
	;-     END OF LIB
]





;------------------------------------
; We are done testing this library.
;------------------------------------
;
; test-exit-slim
;
;------------------------------------
