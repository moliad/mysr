REBOL [
	; -- Core Header attributes --
	title: "Generic block! handling functions"
	file: %mysr.r
	version: 1.0.2
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
	print "============"
	probe what-dir
	print "============"

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
	?? dlldir
	?? dllpath


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
	?? app-wd
	
	print "loading mysql library..."
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
	;- mysr.test()
	;
	;--------------------------
	mysr.test: make routine! [
		text   [string!]
		val    [integer!]
		return: [integer!]
	] mysr.dll "test_dll"

	;--------------------------
	;- mysr.init()
	;
	;--------------------------
	mysr.init: make routine! [
		buffersize [integer!]
		return: [integer!]
	] mysr.dll "mysr_init"


	;--------------------------
	;- mysr.connect()
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
	;- mysr.tracelog()
	;
	;--------------------------
	mysr.tracelog: make routine! [
		path [string!]
		return: [integer!]
	] mysr.dll "mysr_tracelog"


	;--------------------------
	;- mysr.list-dbs()
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


	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- INTIALISE DLL
	;
	;-----------------------------------------------------------------------------------------------------------

	vprint "initialising mysr for 10MB max query buffer"
	?? buffersize
	success: mysr.init buffersize
	?? success
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
		vprobe session
		
		unless session [
			throw-on-error [
				to-error "list-dbs() must connect to server first"
				none
			]
		]
		data: mysr.list-dbs session filter
		probe data
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

]


;------------------------------------
; We are done testing this library.
;------------------------------------
;
; test-exit-slim
;
;------------------------------------
