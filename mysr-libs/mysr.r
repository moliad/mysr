REBOL [
	; -- Core Header attributes --
	title: "Generic block! handling functions"
	file: %mysr.r
	version: 0.5.0
	date: 2020-02-20
	author: "Maxim Olivier-Adlhoch"
	purpose: {Open source full featured mysql connector.}
	web: http://github/moliad/mysr
	source-encoding: "Windows-1252"
	note: {slim Library Manager is Required to use this module.}

	; -- slim - Library Manager --
	slim-name: 'mysr
	slim-version: 1.0.1
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
; test-enter-slim 'utils-blocks
;
;--------------------------------------

slim/register [
	setcurrentdir to-local-file what-dir

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
	;-----
	; here we must play with the OS current directory for mysr.dll to find libmysql.dll in the same folder.
	;
	; the problem is that Rebol's current-dir function doesn't change the system current dir... just 
	; the default used by Rebol mezz code  :-(
	;-----
	k32.dll: load/library %kernel32.dll
	setcurrentdir: make routine! [
		path [string!]
		return: [integer!]
	] k32.dll "SetCurrentDirectoryA"
	getcurrentdir: make routine! [
		len [integer!] ; size of memory buffer
		path [string!] ; memory buffer to use
		return: [integer!]
	] k32.dll "GetCurrentDirectoryA"
	dlldirpath: to-local-file clean-path dlldir

	;---
	; remember path of app wd so we can restore it.
	buflen: 300
	buffer: head insert/dup "" "^@" buflen
	pathlen: getcurrentdir buflen buffer
	app-wd: copy/part buffer pathlen
	;?? app-wd
	
	vprint "loading mysql library..."
	;print [ dllpath " : "  exists? dllpath ]
	setcurrentdir dlldirpath
	mysr.dll: load/library  dllpath
	setcurrentdir app-wd

	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- ROUTINES
	;
	;-----------------------------------------------------------------------------------------------------------

	;--------------------------
	;-     mysr.test()
	;
	;--------------------------
	mysr.test: make routine! [
		text   [string!]
		val    [integer!]
		return: [integer!]
	] mysr.dll "test_dll"

	;--------------------------
	;-     mysr.init()
	;
	;--------------------------
	mysr.init: make routine! [
		buffersize [integer!]
		return: [integer!]
	] mysr.dll "mysr_init"


	;--------------------------
	;-     mysr.connect()
	;
	;--------------------------
	mysr.connect: make routine! [
		host [string!]
		db [string!]
		user [string!]
		pwd [string!]
		return: [integer!] ; pointer to a mysr session object.
	] mysr.dll "mysr_connect"


	;--------------------------
	;-     mysr.tracelog()
	;
	;--------------------------
	mysr.tracelog: make routine! [
		path [string!]
		return: [integer!]
	] mysr.dll "mysr_tracelog"


	;--------------------------
	;-     mysr.list-dbs()
	;
	;--------------------------
	mysr.list-dbs: make routine! [
		session [integer!]
		filter  [string!]
		return: [string!]
	] mysr.dll "mysr_list_dbs"


	;--------------------------
	;-     mysr.query()
	;
	;--------------------------
	mysr.query: make routine! [
		session [integer!]
		query [string!]
		return: [string!]
	] mysr.dll "mysr_query"
	
	
	
	;--------------------------
	;-     mysr.escape-string-quote()
	;
	; doc url : https://dev.mysql.com/doc/refman/5.7/en/mysql-real-escape-string-quote.html
	;--------------------------
	mysr.escape-string-quote: make routine! [
		session   [integer!]  ; mysr connection session.
		src-text  [string!]   ; text to quote
		dest-text [string!]   ; result is copied here ( buffer must be ((src-len * 2) +1 bytes long )
		src-len   [integer!]  ; length of text
		context   [char!]     ; string wrapping character to ignore within given text.  ("), ('), or (`) 
		return:   [integer!]  ; length of result string.
	] mysr.dll "mysr_quote"
		
;		to-buffer [string!]    ; destination buffer ... NOTE: the length of this buffer must be:  
;		                       ; ((from-length * 2) +1 bytes long )  
;		                       ; In the worst case, each character may need to be encoded as using 
;		                       ; two bytes, and there must be room for the terminating null byte.
;		from-buffer [string!]  ; source buffer (string to fix) 
;		from-length [integer!] ; length of source text (excluding null termination) 
;		quote-context [char!]  ; within what string context is the text to be replaced within the query...
;		                       ;    ex:  { "this" }  vs { 'this' }  
;		                       ; in mysr we should only support the " string quote context.
;		
;		return: [integer!]     ; length of the to-buffer without null termination.
	




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
		vin "reduce-query()"
		throw-on-error [
			parse blk [
				some [
					.here: 
					
					;-------------------------
					; standard value, bound, quoted and escaped.
					set word word! (
						value: get word
						
						switch/all type?/word :value [
							function! object! native! op! paren! port! [
								to-error rejoin ["invalid type in query spec: " type?/word :value " here: " mold/all pick .here 2 "..." ]
							]
						]
						
						v?? word
						v?? value
						embedded-value: rejoin ["`" escape-sql/backtick form value "`"]
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
		vout
		
		blk
	]


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
	;- SHIM FUNCTIONS
	;
	;-----------------------------------------------------------------------------------------------------------

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
		vin "escape-sql()"

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
		
		v?? text
		v?? [length? text]
		newlength: mysr.escape-string-quote session text quote-buffer length? text wrap-char
		
		v?? quote-buffer
		v?? newlength
		v?? [ length? quote-buffer ]
		
		clear text
		append text copy/part quote-buffer newlength
	
		vout
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
		/extern default-session
	][
		vin "list-dbs()"
		session: any [session default-session]
		filter: any [filter ""]
		
		v?? filter
		;vprobe session
		
		unless session [
			throw-on-error [
				to-error "list-dbs() must connect to server first"
				none
			]
		]
		data: mysr.list-dbs session filter
		result: load data
		vout
		first reduce [result result: data: none]
	]


	;--------------------------
	;-     mysql()
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
	mysql: funcl [
		query [string! block!]
	][
		vin "mysql()"
		session: any [ session default-session ]
		unless session [
			throw-on-error [
				to-error "list-dbs() must connect to server first"
				none
			]
		]
		if block? query [
			query: rejoin query
		]
		
		data: mysr.query session query
		result: load data
		vout
		
		first reduce [result result: data: none]
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
		query   [object! block! string!]
		values  [object! string! block! none!]
	][
		vin "query()"
		word: none
		result: none
		v?? query
		v?? values
		
		if string? query [
			query: reduce [query]
		]
		
		if block? query [
			; I guess the following is a query  ;-D
			query: make query! compose/only [query: (query)]
			v?? query
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
				vprint "got block variables"
				; when given a block of values, we assume these are given in numerical order,
				;
				; the first value is set to the first variable (any word!) in the query
				words: copy []
				variables: copy []
				ctx-words: words-of query/variables
				v?? query/query
				
				parse query/query [
					some [
						set word word! (
							vprint ["FOUND variable: " word]
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
				v?? words
				v?? variables
				
				unless empty? words [
					append words none
					query/variables: make query/variables words 
				]
				
				i: 1
				foreach word variables [
					value: pick values i
					if none? value [
						to-error ["mysr/query() missing values for given query : " mold query/query]
					]
					set (in query/variables word) pick values i
					++ i
				]
			]
		]
		
		
		;--------
		; at this point we have properly constructed query! instance ready to perform
		;--------
		v?? query
		query-blk: copy/deep query/query 
		bind query-blk query/variables

		v?? query-blk
		query-blk: reduce-query query-blk
		
		v?? query-blk
		replace/all query-blk #[none] "NULL"
		
		vprint "============================"
		v?? query-blk
		vprint "============================"
		query-str: form query-blk
		
		unless #";" = last query-str [
			append query-str ";"
		]
		
		v?? query-str
		
		
		result: sql query-str
				
		vout
		
		result
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
