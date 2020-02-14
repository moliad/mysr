//------------------------------------------------
// file:    mysr-structs.h
// author:  (C) Maxim Olivier-Adlhoch
//
// date:    2020-02-14
// version: 1.0.1
//
// license: APACHE v2.0 
//          https://www.apache.org/licenses/LICENSE-2.0
//
// purpose: stores the structs used by mysr.
//
// notes:   In any C file using this header, mysql.h must be included before this one.
//------------------------------------------------


#pragma once


//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- STRUCTS
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//- MysrSession: {...}
//
// note that the session can be used like a MYSQL struct since it's the first
// item of the struct.
//--------------------------
struct MysrSession {

	//--------------------------
	//-     connection:
	// current connection. may be NULL.
	//--------------------------
	MYSQL *connection;

	//--------------------------
	//-     host:
	//
	//--------------------------
	char *host;
	
	//--------------------------
	//-     db:
	//
	//--------------------------
	char *db;

	//--------------------------
	//-     usr:
	//
	// user name used for connection (if set, allows auto reconnection attempts).
	//--------------------------
	char *usr;

	//--------------------------
	//-     pwd:
	//
	// password used for connection (if set, allows auto reconnection attempts).
	//--------------------------
	char *pwd;
};

typedef struct MysrSession MysrSession;

