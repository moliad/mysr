//------------------------------------------------
// file:    mysr.c
// author:  (C) Maxim Olivier-Adlhoch
//
// date:    2020-02-14
// version: 1.0.1
//
// license: APACHE v2.0
//          https://www.apache.org/licenses/LICENSE-2.0
//
// purpose: core mysql connector code and rebol data interchange code.
//
// notes:   we rely on the common-c-libs repository. (you can find this here:  https://github.com/moliad/common-c-libs)
//------------------------------------------------
#include "dll-export.h"
#include "mysr.h"
#include "mold.h"

#define VERBOSE
#include "vprint.h"
#include "binary_log_types.h" // from mysql



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- DLL GLOBALS
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//-     resultbuffer:
//
// memory used for all rebol results
//
// set this up using mysr_init()
//--------------------------
char* resultbuffer=NULL;


//--------------------------
//-     resultbuffersize:
//
//--------------------------
int resultbuffersize = 0;


//--------------------------
//-     column_types:
//
// points to an array of int which stores types of each column.  this is pre-allocated to 256 columns wide, but will scale according to queries, run-time.
//--------------------------
int *column_types = 0;


//--------------------------
//-     column_types_array_size:
//
// size of currently allocated column_types array
//--------------------------
int column_types_array_size = 256;



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- INIT AND SETUP
//
//-----------------------------------------------------------------------------------------------------------
//--------------------------
//-     test_dll()
//--------------------------
// purpose:  simple function to test if the dll is properly linked when doing dev work.
//
// inputs:   expects null terminated string
//
// returns:
//
// notes:
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT int test_dll (char *text, int val){
	int i=0;
	for(i = 0; text[i] != 0; i++ ){}
	return i + val;
}



//--------------------------
//-     mysr_connect()
//--------------------------
// purpose:  creates a session in memory,  attempts a connection to db and returns the session
//
// inputs:
//
// returns:
//
// notes:    - the inner mysql connection will be null in the session, if connection is not successful.
//           - will also do some calls to mysql_options() to setup required options like charset to use.
//           - host and db arguments can be null (if host is null it will connect to localhost).
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT MysrSession *mysr_connect(char *host, char *db, char *usr, char *pwd ){
	MysrSession	*session = NULL;
	MYSQL 		*connection = NULL;
	void		*success = NULL;

	vin("mysr_connect()");

	if (host == NULL){
		host = "localhost";
	}

	session = calloc(1, sizeof(MysrSession));
	connection = calloc (1, sizeof(MYSQL));
	vprint("Attempting connection to DB: %s @ %s, with user: `%s` and password: `%s`", db, host, usr, pwd);

	if ((session == NULL) || (connection == NULL)) {
		vprint ("error !! not enough memory for MysrSession{...} object.");
	} else {
		//--------
		// intialise connection
		//--------
		success = mysql_init(connection);

		if (success == NULL){
			//error = build(mold_word,"error");
			//error -> next = build(mold_string, mysql_error());
			//vout;
			//return error;
			vprint("MySQL ERROR: %s", mysql_error(NULL));
		} else {
			//--------
			// setup connection options to make session compatible with Rebol
			//--------
			mysql_options(connection, MYSQL_SET_CHARSET_NAME, "latin1");

			//--------
			// attempt network connection.
			//--------
			success = mysql_real_connect(connection, host, usr, pwd, db, 0, NULL, CLIENT_REMEMBER_OPTIONS );
			if (success){
				vprint("Connected... YAY! Server info: %s", mysql_get_server_info(connection));
			}else{
				//error = build(mold_word,"error");
				//error -> next = build(mold_string, mysql_error(connection));
				//vout;
				//return error;
				vprint("Unable to connect, deallocating session...");
				vprint("MySQL ERROR: %s", mysql_error(connection));
			}
		}
	}

	if(success){
		session->connection = connection;
		session->host = host;
		session->db = db;
		session->usr = usr;
		session->pwd = pwd;
	}else{
		if (session){
			free(session);
		}
		if (connection){
			free(connection);
		}
		session = NULL;
		connection = NULL;
	}
	vout;
	return session;
}



//--------------------------
//-     mysr_init()
//--------------------------
// purpose:
//
// inputs:
//
// returns:
//
// notes:
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT int mysr_init(int buffersize){
	int success = 1;
	von;
	vin("mysr_init()");

	resultbuffer = calloc(1, buffersize);

	if (resultbuffer){
		resultbuffersize = buffersize;
	}

	column_types = calloc(1, column_types_array_size * sizeof(int));
	if (column_types == NULL){
		// make sure the actual array size is reflected.
		column_types_array_size =0;
	}


	vprint("MySQL client info: %s", mysql_get_client_info())

	vnum(success);
	vout;
	return success;
}



//--------------------------
//-     mysr_tracelog()
//--------------------------
// purpose:  generates a trace log on disk, given an absolute filepath.
//
// inputs:
//
// returns:  0 or 1 depending on if we where able to open filepath.
//
// notes:    - folder of given path must exist.
//           - automatically activates vloging.
//           - CAN BE CALLED BEFORE mysr_init() !!!
//           - if called from REBOL, BE SURE not to reset the word holding the path to another value or it will be recycled and OUR pointer will be corrupted.
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT int mysr_tracelog (char* filepath){

	vlogpath = filepath;
	vlogreset;
	vlogon;
	vin("mysr_tracelog()");
	vstr(filepath);
	vout;
	return (vlogfile != NULL);
}



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- DB QUERY FUNCTIONS
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//-     mysr_quote()
//--------------------------
// purpose:  quote a string to prevent sql injection.
//
// inputs:
//
// returns:
//
// notes:    - be careful, we swapped argument order of src & result strings, compared to the mysql dll function.
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT int mysr_quote(MysrSession *session, char* src, char* result, int srclen, char context){
	int result_len=0;

	vin("mysr_quote()");
	vstr(src);
	vchar(context);
	result_len = mysql_real_escape_string_quote(session->connection, result, src, srclen, context);
	vstr(result);
	vnum(srclen);
	vnum(result_len);
	vout;
	return result_len;
}




//--------------------------
//-     mysr_server_info()
//--------------------------
// purpose:  get version string from server
//
// inputs:
//
// returns:
//
// notes:
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT const char* mysr_server_info(MysrSession *session){
	vin("mysr_server_info()");
	const char *ver=NULL;
	if (session){
		ver = mysql_get_server_info((MYSQL*)session);
	}
	vout;
	return ver;
}



//--------------------------
//-     mysr_list_dbs()
//--------------------------
// purpose:  list all the databases on the server
//
// inputs:
//
// returns:
//
// notes:
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT char *mysr_list_dbs(MysrSession *session, char *filter){
	MYSQL_RES *mysql_result=NULL;
	char *molded_str=NULL;

	vin("mysr_list_dbs()");

	if (session && session->connection){
		if ((filter) && (filter[0] == 0)){
			filter = NULL;
		}
		mysql_result = mysql_list_dbs(session->connection, filter);

		if (mysql_result){
			//--------------
			// convert result to a REBOL-Loadable dataset
			//--------------
			//mysr_probe_result(mysql_result);
			molded_str = mysr_mold_result(mysql_result);
			vprint("%s", molded_str);

			mysql_free_result(mysql_result);
		}
	}

	vout;
	return molded_str;
}


//--------------------------
//-     mysr_query()
//--------------------------
// purpose:  send query to current connection.
//--------------------------
DLL_EXPORT char *mysr_query(MysrSession *session, char *query_string){
	vin("mysr_query()");
	MYSQL_RES *result;
	//unsigned int num_fields;
	unsigned int num_rows;
	char *molded_str=NULL;

	vprint(query_string);

	if (mysql_query(session->connection, query_string)){
		//------
		// error
		//------
		//error = build(mold_word,"error");
		//error -> next = build(mold_string, mysql_error(session->connection));
		vprint ("MySQL Query ERROR! %s", mysql_error(session->connection));
		//vout;
		//return error;
	} else {
		 // query succeeded, process any data returned by it
		result = mysql_store_result(session->connection);
		if (result) {
			// there are rows

			molded_str = mysr_mold_result(result);
		} else {
			// mysql_store_result() returned nothing; should it have?
			if(mysql_field_count(session->connection) == 0) {
				// query does not return data
				// (it was not a SELECT)
				num_rows = mysql_affected_rows(session->connection);
				vprint("Query affected %i rows", num_rows);
			} else {
				// mysql_store_result() should have returned data
				//error = build(mold_word,"error");
				//error -> next = build(mold_string, mysql_error(session->connection));
				vprint ("MySQL Query ERROR! %s", mysql_error(session->connection));
				//vout;
				//return error;
			}
		}
	}
	vout;
	return molded_str;
}





//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- REBOL RETURN DATA MANAGEMENT
//
//-----------------------------------------------------------------------------------------------------------


//--------------------------
//-     map_sql_type()
//--------------------------
// purpose:
//
// inputs:
//
// returns:  a MOLD type
//
// notes:
//
// to do:
//
// tests:
//--------------------------
int map_sql_type(int sqltype){
	int mold_type = 0;
	vin("map_sql_type()");
	switch (sqltype){
		//---
		// floating point
		case MYSQL_TYPE_FLOAT:
		case MYSQL_TYPE_DOUBLE:
		case MYSQL_TYPE_NEWDECIMAL:
		case MYSQL_TYPE_DECIMAL:
			mold_type = MOLD_DECIMAL;
			break;

		//---
		// integers
		case MYSQL_TYPE_TINY:
		case MYSQL_TYPE_SHORT:
		case MYSQL_TYPE_LONG:
		case MYSQL_TYPE_INT24:
			mold_type = MOLD_INT;
			break;

		//---
		// URL (we store the whole 64bit value as a url, using the scheme as the type)
		//
		// ex:  longlong:2137823465834587456
		case MYSQL_TYPE_LONGLONG:
			mold_type = MOLD_LITERAL;
			break;

		//---
		// boolean
		case MYSQL_TYPE_NULL:
			mold_type = MOLD_NONE;
			break;

		//---
		// dates
		case MYSQL_TYPE_DATE:
		case MYSQL_TYPE_DATETIME:
		case MYSQL_TYPE_NEWDATE:
		case MYSQL_TYPE_DATETIME2:

		case MYSQL_TYPE_YEAR:		// this may need to be returned as int... not sure.
		case MYSQL_TYPE_TIMESTAMP:  // this may need to be returned as 64 bit int... not sure.
		case MYSQL_TYPE_TIMESTAMP2: // this may need to be returned as 64 bit int... not sure.
			mold_type = MOLD_DATE;
			break;

		case MYSQL_TYPE_TIME:
		case MYSQL_TYPE_TIME2:
			mold_type = MOLD_TIME;
			break;

		//---
		// string
		case MYSQL_TYPE_VARCHAR:
		case MYSQL_TYPE_JSON:
		case MYSQL_TYPE_VAR_STRING:
		case MYSQL_TYPE_STRING:
			mold_type = MOLD_TEXT;
			break;

		//---
		// charset
		case MYSQL_TYPE_BIT:
			mold_type = MOLD_LITERAL;
			break;

		//---
		// issue
		case MYSQL_TYPE_ENUM:
			mold_type = MOLD_TEXT;
			break;

		//---
		// binary
		case MYSQL_TYPE_TINY_BLOB:
		case MYSQL_TYPE_MEDIUM_BLOB:
		case MYSQL_TYPE_LONG_BLOB:
		case MYSQL_TYPE_BLOB:
			mold_type = MOLD_BINARY;
			break;

		//---
		// block
		case MYSQL_TYPE_SET:         //(list of tokens)
		case MYSQL_TYPE_GEOMETRY:
			mold_type = MOLD_BLOCK;
			break;
	}
	vout;
	return mold_type;
}


//--------------------------
//-     mysr_mold_sql_value()
//--------------------------
// purpose:  returns a mold object based on equivalent sql type
//
// inputs:
//
// returns:
//
// notes:
//
// to do:
//
// tests:
//--------------------------
MoldValue *mysr_mold_sql_value(char *data, int column_type){
	int type=0;
	MoldValue *mv=NULL;
	vin("mysr_mold_sql_value()");

	if (data){
		type = map_sql_type(column_type);

		mv = build(MOLD_TEXT, data);
		vnum(type != MOLD_TEXT);
		vnum(type);
		if (type != MOLD_TEXT){ // do nothing if output is a string.
			switch (type) {
				case MOLD_LITERAL:
					vprint("will be using MOLD_LITTERAL");
					// this type requires a specific conversion based on source type.
					break;

				// semi-types can only be used for cast purposes (they become MOLD_LITERAL values pre
				case MOLD_DATE:
				case MOLD_TIME:
				case MOLD_BINARY:
					break;

				default:
					// the type can be converted directly using cast()
					mv = cast(mv, type, CFALSE);
					break;
			}
		}
	}else{
		mv = make(MOLD_NONE);
	}

	vout;
	return mv;
}






//--------------------------
//-     mysr_probe_result()
//--------------------------
// purpose:  debug result table within stdout.
//--------------------------
void mysr_probe_result(MYSQL_RES *result){
	unsigned int field_cnt = 0;
	int i=0;

	vin("mysr_probe_result()");
	if (result == NULL){
		vprint ("ERROR: NULL result given as argument");
	} else {
		field_cnt = mysql_num_fields(result);
		vprint("Number of columns: %d\n", field_cnt);
		for (i=0; i < field_cnt; ++i){
			/* col describes i-th column of the table */
			MYSQL_FIELD *col = mysql_fetch_field_direct(result, i);
			vprint ("Column %d: %s\n", i, col->name);
		}
	}
	vout;
}





//--------------------------
//-     mysr_mold_result()
//--------------------------
// purpose:  converts a MYSQL_RES to a Rebol Bulk table.
//
// inputs:   any result from a function returning a MYSQL_RES *
//
// returns:
//
// notes:    if the result is NULL we return we will return a REBOL loadable error.
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT char *mysr_mold_result(MYSQL_RES *result){
	MoldValue	*blk=NULL;
	MoldValue	*header=NULL;
	MoldValue	*column_names=NULL;
	MoldValue	*column_count=NULL;
	MoldValue   *mv=NULL;
	int			 len=0;
	int			 field_cnt=0;
	int			 i;
	MYSQL_ROW 	row=0;

	vin("mysr_mold_result()");
	blk = make(MOLD_BLOCK);
	header = make (MOLD_BLOCK);
	column_names = make (MOLD_BLOCK);
	column_count = make (MOLD_INT);
	append(header, build( MOLD_SET_WORD, "columns" ));
	append(header, column_count);
	append(header, build( MOLD_SET_WORD, "labels" ));
	append(header, column_names);
	column_count->newline = TRUE;
	// add bulk header
	append(blk, header);
	//vprint("result is %i chars long", len );

	if (result == NULL){
		vprint ("ERROR: NULL result given as argument");
	} else {
		field_cnt = mysql_num_fields(result);
		vprint("Number of columns: %d\n", field_cnt);

		if (field_cnt >  column_types_array_size){
			vprint ("ERROR! Too many columns in result set");
			vout;
			return NULL;
		}
		column_count->value = field_cnt;

		for (i=0; i < field_cnt; ++i){
			/* col describes i-th column of the table */
			MYSQL_FIELD *col = mysql_fetch_field_direct(result, i);
			vprint ("Column %d: %s\n", i, col->name);
			append ( column_names, build(MOLD_WORD, col->name) );

			vprint ("Column type %i\n", col->type);
			column_types[i] = col->type;
		}

		//----------
		// fetch the row data
		vprint ("FETCHING DATA")
		while ((row = mysql_fetch_row(result))) {
			for(i = 0; i < field_cnt; i++)
			{
				mv = mysr_mold_sql_value(row[i], column_types[i]);  // if row[i] is NULL, we receive a MOLD_NONE value
				append(blk, mv);
				printf("%s , " , (row[i] ? row[i] : "NULL"));
			}
			mv->newline = TRUE;
			printf("\n---------------------\n");
		}
	}
	len=mold_list(blk, resultbuffer, resultbuffersize, 0);

	// in theory, len cannot be larger than resultbuffersize
	// make absolutely sure that the string is null terminated.
	resultbuffer[len] = 0;

	dismantle(blk);


	//-------------
	// deallocate the whole data-tree
	//-------------
	// destroy(blk);

	vout;
	return resultbuffer;
}


//--------------------------
//-     mysr_free_data()
//--------------------------
// purpose: free data allocated within mysr which was sent to client as a result.
//
// possibly deprecated since we use a reusable buffer for mold()
//--------------------------
DLL_EXPORT void mysr_free_data(void *data){
	vin("mysr_free_data()");
	free(data);
	vout;
}
