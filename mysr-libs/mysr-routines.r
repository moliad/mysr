REBOL [
	; -- Core Header attributes --
	title: "mysr routines"
	file: %mysr-routines.r
	version: 1.0.0
	date: 2020-04-15
	author: "Maxim Olivier-Adlhoch"
	purpose: {All  routines required for mysr connection.}
	source-encoding: "Windows-1252"
	note: {slim Library Manager is Required to use this module.}

	; -- slim - Library Manager --
	slim-name: 'mysr-routines
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
; test-enter-slim 'mysr-routines
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
	;--------------------------
	;-     k32.dll:
	;--------------------------
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
	
	;--------------------------
	;-     dlldirpath:
	;--------------------------
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
	;--------------------------
	;-     mysr.dll:
	;--------------------------
	mysr.dll: load/library  dllpath
	setcurrentdir app-wd
	buffer: none

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
		

	
	;-                                                                                                       .
	;-----------------------------------------------------------------------------------------------------------
	;
	;-     STATEMENT ROUTINES
	;
	;-----------------------------------------------------------------------------------------------------------
	;--------------------------
	;-     mysr.create-statement()
	;--------------------------
	mysr.create-statement: make routine! [
		session [integer!]
		query [string!]
		query-length [integer!] "the length in bytes (without null) of given string"
		return: [integer!] "A pointer to the internal statement object."
	] mysr.dll "mysr_create_statement"


	;--------------------------
	;-     mysr.release-statement()
	;
	;--------------------------
	mysr.release-statement: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "error code"
	] mysr.dll "mysr_release_statement"
	
	
	;--------------------------
	;-     mysr.new-row()
	;
	;--------------------------
	mysr.new-row: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "error code"
	] mysr.dll "mysr_stmt_new_row"
	
	
	;--------------------------
	;-     mysr.bind-string-value()
	;
	;--------------------------
	mysr.bind-string-value: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		buffer		[string!] "a buffer used to send the result."
		length		[integer!] "max length of buffer."
		return: 	[integer!] "true/false"
	] mysr.dll "mysr_stmt_bind_string_value"
	
	
	;--------------------------
	;-     mysr.bind-integer-value()
	;
	;--------------------------
	mysr.bind-integer-value: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "true/false"
	] mysr.dll "mysr_stmt_bind_integer_value"
	
	
	;--------------------------
	;-     mysr.bind-decimal-value()
	;
	;--------------------------
	mysr.bind-decimal-value: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "true/false"
	] mysr.dll "mysr_stmt_bind_decimal_value"
	
	
	;--------------------------
	;-     mysr.set-null()
	;
	;--------------------------
	mysr.set-null: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "error code"
	] mysr.dll "mysr_stmt_set_null_value"
	
	
	;--------------------------
	;-     mysr.set-string()
	;
	;--------------------------
	mysr.set-string: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		text		[string!] "text to set"
		length		[integer!] "length of text"
		return: 	[integer!] "error code"
	] mysr.dll "mysr_stmt_set_string_value"
	
	
	;--------------------------
	;-     mysr.set-integer()
	;
	;--------------------------
	mysr.set-integer: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		value		[integer!] "value to set"
		return: 	[integer!] "error code"
	] mysr.dll "mysr_stmt_set_integer_value"
	
	
	;--------------------------
	;-     mysr.set-decimal()
	;
	;--------------------------
	mysr.set-decimal: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		text		[string!]  "decimal to set in string form"
		length		[integer!] "length of text"
		return: 	[integer!] "error code"
	] mysr.dll "mysr_stmt_set_decimal_value"
	

	;--------------------------
	;-     mysr.bind-statement()
	;
	;--------------------------
	mysr.bind-statement: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "error code"
	] mysr.dll "mysr_bind_statement"

	
	;--------------------------
	;-     mysr.do-statement()
	;
	;--------------------------
	mysr.do-statement: make routine! [
		statement	[integer!] "A pointer to the internal statement object."
		return: 	[integer!] "error code"
	] mysr.dll "mysr_run_statement"
	
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
