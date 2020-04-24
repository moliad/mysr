//------------------------------------------------
// file:    mysr.h
// author:  (C) Maxim Olivier-Adlhoch
//
// date:    2020-02-14
// version: 1.0.1
//
// license: APACHE v2.0
//          https://www.apache.org/licenses/LICENSE-2.0
//
// purpose: main header for mysr, a mysql rebol connector using native C lib interface.
//
// notes:   we rely on the common-c-libs repository. (you can find this here:  https://github.com/moliad/common-c-libs)
//------------------------------------------------


#pragma once
#include <winsock2.h>
#include <windows.h>
#include "mysql.h"          // all mysql declarations.
#include "clibs-mold.h"
#include "mysr-structs.h"   // all mysql declarations.
#include "dll-export.h"     // DLL import/export switch handling


//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- INIT AND SETUP
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//-     test_dll()
//--------------------------
DLL_EXPORT int test_dll (char *text, int val);


//--------------------------
//-     mysr_connect()
//--------------------------
DLL_EXPORT MysrSession *mysr_connect( char *host, char *db, char *usr, char *pwd );


//--------------------------
//-     mysr_init()
//--------------------------
DLL_EXPORT int mysr_init();


//--------------------------
//-     mysr_tracelog()
//--------------------------
DLL_EXPORT int mysr_tracelog (char* filepath);


//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- REBOL RETURN DATA MANAGEMENT
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//-     mysr_prep_error()
//--------------------------
DLL_EXPORT MoldValue *mysr_prep_error(const char *type, const char *message );


//--------------------------
//-     mysr_rebol_result()
//--------------------------
DLL_EXPORT char *mysr_mold_result(MYSQL_RES *result);


//--------------------------
//-     mysr_free_data()
//--------------------------
DLL_EXPORT void mysr_free_data(void *data);


//--------------------------
//-     mysr_mold_row_count()
//--------------------------
DLL_EXPORT char *mysr_mold_row_count(int count);

//--------------------------
//-     mysr_mold_error()
//--------------------------
// purpose:  converts a string to a rebol error
//--------------------------
DLL_EXPORT char *mysr_mold_error(const char *error);



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- PREPARED STATEMENT MANAGEMENT
//
//-----------------------------------------------------------------------------------------------------------
//--------------------------
//-     mysr_create_statement()
//--------------------------
DLL_EXPORT MysrStatement *mysr_create_statement (
	MysrSession *session, 
	char *query, 
	int querylen
);


//--------------------------
//-     mysr_release_statement()
//--------------------------
DLL_EXPORT void mysr_release_statement(
	MysrStatement *statement
);


//--------------------------
//-     mysr_stmt_new_row()
//--------------------------
DLL_EXPORT void mysr_stmt_new_row(
	MysrStatement *statement
);


//--------------------------
//-     mysr_stmt_bind_string_value()
//--------------------------
DLL_EXPORT int mysr_stmt_bind_string_value(
	MysrStatement	*statement,
	char 			*buffer,
	int			 	 len        // length of buffer string,
);


//--------------------------
//-     mysr_stmt_bind_integer_value()
//--------------------------
DLL_EXPORT int mysr_stmt_bind_integer_value (
	MysrStatement *statement
);


//--------------------------
//-     mysr_stmt_bind_decimal_value()
//--------------------------
DLL_EXPORT int mysr_stmt_bind_decimal_value(
	MysrStatement	*statement
);


//--------------------------
//-     mysr_stmt_null_param()
//--------------------------
DLL_EXPORT int mysr_stmt_set_null_value (
	MysrStatement *statement
);


//--------------------------
//-     mysr_stmt_set_string_value()
//--------------------------
DLL_EXPORT int mysr_stmt_set_string_value(
	MysrStatement *statement,
	char *text,
	int len // number of characters without null termination, if any.
);


//--------------------------
//-     mysr_stmt_set_integer_value()
//--------------------------
DLL_EXPORT int mysr_stmt_set_integer_value (
	MysrStatement *statement,
	int value
);


//--------------------------
//-     mysr_bind_statement()
//--------------------------
// purpose:  transfer the bind call to the server.
//
// returns:  error number or 0 for success
//--------------------------
DLL_EXPORT int mysr_bind_statement(
	 MysrStatement *statement
);


//--------------------------
//-     mysr_run_statement()
//--------------------------
// purpose:  execute a mysql preparred statement once all values are set.
//
// returns:  number of rows affected.  returns -1 if an error occured.
//
// notes:    
//
// to do:    
//--------------------------
DLL_EXPORT int mysr_run_statement(
	MysrStatement *statement
);



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- DB QUERY FUNCTIONS
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//-     mysr_quote()
//--------------------------
DLL_EXPORT int mysr_quote(MysrSession *session, char* src, char* result, int srclen, char context);
	

//--------------------------
//-     mysr_server_info()
//--------------------------
DLL_EXPORT const char* mysr_server_info(MysrSession *session);


//--------------------------
//-     mysr_probe_result()
//--------------------------
void mysr_probe_result(MYSQL_RES *result);


//--------------------------
//-     mysr_list_db()
//--------------------------
// purpose:  list all the databases on the server
//--------------------------
DLL_EXPORT char *mysr_list_dbs(MysrSession *session, char *filter);


//--------------------------
//-     mysr_query()
//--------------------------
// purpose:  send query to current connection.
//--------------------------
DLL_EXPORT char *mysr_query(MysrSession *session, char *query_string);

