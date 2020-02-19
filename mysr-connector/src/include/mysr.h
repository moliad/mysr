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
#include "mold.h"
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
//-     mysr_init()
//--------------------------
DLL_EXPORT int mysr_init();


//--------------------------
//-     mysr_connect()
//--------------------------
DLL_EXPORT MysrSession *mysr_connect( char *host, char *db, char *usr, char *pwd );


//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- DB INTROSPECTION FUNCTIONS
//
//-----------------------------------------------------------------------------------------------------------
//--------------------------
//-     mysr_server_info()
//--------------------------
DLL_EXPORT const char* mysr_server_info(MysrSession *session);


//--------------------------
//-     mysr_list_db()
//--------------------------
// purpose:  list all the databases on the server
//
// inputs:
//
// returns:
//
// notes:    use mysr_free_data() on returned string.
//
// to do:
//
// tests:
//--------------------------
char *mysr_list_dbs(MysrSession *session, char *filter);


//--------------------------
//-     mysr_probe_result()
//--------------------------
void mysr_probe_result(MYSQL_RES *result);



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- REBOL RETURN DATA MANAGEMENT
//
//-----------------------------------------------------------------------------------------------------------

//--------------------------
//-     mysr_rebol_result()
//--------------------------
DLL_EXPORT char *mysr_mold_result(MYSQL_RES *result);


//--------------------------
//-     mysr_free_data()
//--------------------------
DLL_EXPORT void mysr_free_data(void *data);


