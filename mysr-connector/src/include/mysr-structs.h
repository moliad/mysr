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
	//-     reconnect:
	//
	// stores the state of auto-reconnection.
	// when connecting we use a pointer to this value to the auto-reconnection mysql_option()
	//--------------------------
	int reconnect;
	

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



//--------------------------
//- MysrStmtData:
//
//
// a union of all the possible values, 
// to make sure we have enough space for any array of value types.
//
// some types may even include their own storage here.  
// this structure is wasteful, but we don't really care.  
// its better than having to deal with Rebol to C memory management.
//--------------------------
struct MysrStmtData {
	
	union {
		//--------------------------
		//-     text:
		//
		// also used for decimal!
		//--------------------------
		char *text;
		
		//--------------------------
		//-     byte:
		//
		//--------------------------
		signed   char i8;  // byte
		unsigned char u8;  // byte

		//--------------------------
		//-     short:
		//
		//--------------------------
		signed   short int i16;
		unsigned short int u16;
		
		//--------------------------
		//-     long:
		//
		//--------------------------
		signed   int i32;
		unsigned int u32;
		
		//--------------------------
		//-     float:
		//
		//--------------------------
		float  fp;
		double fp_double;
		
		//--------------------------
		//-     decimal:
		//
		// in mysql, decimals are stored like strings.
		// enough space for 10.4
		//--------------------------
		char decimal[16];
		
		
		//--------------------------
		//-     time:
		//
		//--------------------------
		MYSQL_TIME time;
	};
	//--------------------------
	//-     length
	//
	// some value types require a pointer to a length so store copied lenght.
	//--------------------------
	int unsigned long length; // we must use long because that is what mysql uses!;
	

	//--------------------------
	//-     type:
	// 
	// store the type to make sure any set operation is valid
	//--------------------------
	int type;
	
	
	//--------------------------
	//-     isnull:
	//
	// just set this to 1 to create a NULL in the db.
	//--------------------------
	my_bool isnull;
};
typedef struct MysrStmtData MysrStmtData;



//--------------------------
//-  MysrStatement: {...}
//
// stores all the data required for a repeatable statement.
//--------------------------
struct MysrStatement {
	//--------------------------
	//-     session:
	//
	//--------------------------
	MysrSession *session;
	
	//--------------------------
	//-     mysql_stmt:
	//
	//--------------------------
	MYSQL_STMT *mysql_stmt;

	//--------------------------
	//-     query:
	//
	//--------------------------
	char *query;
	
	//--------------------------
	//-     length:
	// length of query, in bytes.
	//--------------------------
	int length;
	
	//--------------------------
	//-     current_value:
	//
	// index of next value to set with any of the set value functions.
	// if current_value == values_count  then we are ok for executing the statement
	//--------------------------
	int current_value;
	
	//--------------------------
	//-     params:
	// array of values
	//--------------------------
	MYSQL_BIND *bound_values;
	
	//--------------------------
	//-     values_count:
	// how many values
	//--------------------------
	int values_count;
	
	//--------------------------
	//-     data:
	//
	// an array of values allocated when the statement is created.
	//--------------------------
	MysrStmtData *data;
};
typedef struct MysrStatement MysrStatement;



