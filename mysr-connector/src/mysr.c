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
#include "clibs-mold.h"

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
//- ACCESSORY ROUTINES
//
//-----------------------------------------------------------------------------------------------------------

//--------------------------
//-     mold_mysql_type()
//--------------------------
// purpose:  returns the string name of an sql type for various error reports and messages.
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
const char *mold_mysql_type(int type){
	char *rval = NULL;
	vin("mold_mysql_type()");
	switch(type){
		//---
		// floating point
		case MYSQL_TYPE_FLOAT:
			rval = "MYSQL_TYPE_FLOAT" ;
			break;
			
		case MYSQL_TYPE_DOUBLE:
			rval = "MYSQL_TYPE_DOUBLE" ;
			break;
			
		case MYSQL_TYPE_NEWDECIMAL:
			rval = "MYSQL_TYPE_NEWDECIMAL" ;
			break;
			
		case MYSQL_TYPE_DECIMAL:
			rval = "MYSQL_TYPE_DECIMAL" ;
			break;

		//---
		// integers
		case MYSQL_TYPE_TINY:
			rval = "MYSQL_TYPE_TINY" ;
			break;
			
		case MYSQL_TYPE_SHORT:
			rval = "MYSQL_TYPE_SHORT" ;
			break;
			
		case MYSQL_TYPE_LONG:
			rval = "MYSQL_TYPE_LONG" ;
			break;
			
		case MYSQL_TYPE_INT24:
			rval = "MYSQL_TYPE_INT24" ;
			break;

		//---
		// URL (we store the whole 64bit value as a url, using the scheme as the type)
		//
		// ex:  longlong:2137823465834587456
		case MYSQL_TYPE_LONGLONG:
			rval = "MYSQL_TYPE_LONGLONG" ;
			break;

		//---
		// boolean
		case MYSQL_TYPE_NULL:
			rval = "MYSQL_TYPE_NULL" ;
			break;
			
		//---
		// dates
		case MYSQL_TYPE_DATE:
			rval = "MYSQL_TYPE_DATE" ;
			break;
			
		case MYSQL_TYPE_DATETIME:
			rval = "MYSQL_TYPE_DATETIME" ;
			break;
			
		case MYSQL_TYPE_NEWDATE:
			rval = "MYSQL_TYPE_NEWDATE" ;
			break;
			
		case MYSQL_TYPE_DATETIME2:
			rval = "MYSQL_TYPE_DATETIME2" ;
			break;

		case MYSQL_TYPE_YEAR:		
			rval = "MYSQL_TYPE_YEAR" ;
			break;
			
		case MYSQL_TYPE_TIMESTAMP:  
			rval = "MYSQL_TYPE_TIMESTAMP" ;
			break;
			
		case MYSQL_TYPE_TIMESTAMP2: 
			rval = "MYSQL_TYPE_TIMESTAMP2" ;
			break;
			
		case MYSQL_TYPE_TIME:
			rval = "MYSQL_TYPE_TIME" ;
			break;
			
		case MYSQL_TYPE_TIME2:
			rval = "MYSQL_TYPE_TIME2" ;
			break;
			
		//---
		// string
		case MYSQL_TYPE_VARCHAR:
			rval = "MYSQL_TYPE_VARCHAR" ;
			break;
			
		case MYSQL_TYPE_JSON:
			rval = "MYSQL_TYPE_JSON" ;
			break;
			
		case MYSQL_TYPE_VAR_STRING:
			rval = "MYSQL_TYPE_VAR_STRING" ;
			break;
			
		case MYSQL_TYPE_STRING:
			rval = "MYSQL_TYPE_STRING" ;
			break;
			
		//---
		// charset
		case MYSQL_TYPE_BIT:
			rval = "MYSQL_TYPE_BIT" ;
			break;
			
		//---
		// issue
		case MYSQL_TYPE_ENUM:
			rval = "MYSQL_TYPE_ENUM" ;
			break;
			
		//---
		// binary
		case MYSQL_TYPE_TINY_BLOB:
			rval = "MYSQL_TYPE_TINY_BLOB" ;
			break;
			
		case MYSQL_TYPE_MEDIUM_BLOB:
			rval = "MYSQL_TYPE_MEDIUM_BLOB" ;
			break;
			
		case MYSQL_TYPE_LONG_BLOB:
			rval = "MYSQL_TYPE_LONG_BLOB" ;
			break;
			
		case MYSQL_TYPE_BLOB:
			rval = "MYSQL_TYPE_BLOB" ;
			break;
			
		//---
		// block
		case MYSQL_TYPE_SET:         
			rval = "MYSQL_TYPE_SET" ;
			break;
			
		case MYSQL_TYPE_GEOMETRY:
			rval = "MYSQL_TYPE_GEOMETRY" ;
			break;
			
		default:
			rval = "UNKNOWN_TYPE";
			break;	
	}
	vout;
	
	return rval;
}



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- REBOL RETURN DATA MANAGEMENT
//
//-----------------------------------------------------------------------------------------------------------

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
//-     mysr_prep_error()
//--------------------------
// purpose:  prepare a rebol piece of code which will generate a rebol ERROR! 
//--------------------------
DLL_EXPORT MoldValue *mysr_prep_error(const char *type, const char *message ){
	MoldValue *mv=NULL;
	MoldValue *errmv = NULL;
	
	vin("mysr_prep_error()");
	// we cheat by using the literal type which will just concatenate the strings.
	mv = build(MOLD_LITERAL, "error make error! [ mysql ");
	mv->next = build(MOLD_WORD, (char *)type); // we know build word satisfies const
	errmv = mv; // remember first item for return value.
	mv = mv->next;
	mv->next = build(MOLD_TEXT, (char *) message); // we know build word satisfies const
	mv = mv->next;
	mv->next = build(MOLD_LITERAL, " ]");
	vout;
	
	return errmv;
}


//--------------------------
//-     mysr_prep_sql_value()
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
MoldValue *mysr_prep_sql_value(char *data, int column_type){
	int type=0;
	MoldValue *mv=NULL;
	vin("mysr_prep_sql_value()");

	if (data){
		type = map_sql_type(column_type);

		mv = build(MOLD_TEXT, data);
		vnum(type != MOLD_TEXT);
		vnum(type);
		if (type != MOLD_TEXT){ // do nothing if output is a string.
			switch (type) {
				case MOLD_DECIMAL:
				case MOLD_INT:
				case MOLD_LITERAL:
					vprint("will be using MOLD_LITTERAL");
					//-----
					// this type can use the source text directly for its output...
					// no point in converting to-from. use the given text directly.
					// text to literal is EXTREMELY FAST...
					// its practically a no-op.
					//-----
					mv = cast(mv, MOLD_LITERAL, FALSE);
					break;

				// semi-types can only be used for cast purposes (they become MOLD_LITERAL values pre
				case MOLD_DATE:
				case MOLD_TIME:
				case MOLD_BINARY:
					break;

				default:
					// the type can be converted directly using cast()
					mv = cast(mv, type, FALSE);
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
//-     mysr_mold_error()
//--------------------------
// purpose:  converts a string to a rebol error
//--------------------------
DLL_EXPORT char *mysr_mold_error(const char *error){
	MoldValue	*mv = NULL;
	int			 len = 0;
	char		*rval = NULL;
	
	vin("mysr_mold_error()");
	mv  = mysr_prep_error("generic", error);
	len = mold_list(mv, resultbuffer, resultbuffersize, 0);
	if(len){
		rval = resultbuffer;
	}
	vout;
	
	return rval;
}


//--------------------------
//-     mysr_mold_row_count()
//--------------------------
// purpose:  prepare a row count result for rebol.
//--------------------------
DLL_EXPORT char *mysr_mold_row_count(int count){
	MoldValue	*mv = NULL;
	int			 len = 0;
	char		*rval = NULL;
	
	vin("mysr_mold_row_count()");
	mv = build(MOLD_WORD, "rows");
	mv->next = build(MOLD_INT, &count);
	len = mold_list(mv, resultbuffer, resultbuffersize, 0);
	if(len){
		rval = resultbuffer;
	}
	vout;
	
	return rval;
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
	MoldValue	*resultmv=NULL;
	MoldValue	*header=NULL;
	MoldValue	*column_names=NULL;
	MoldValue	*column_count=NULL;
	MoldValue   *mv=NULL;
	MoldValue	*db=NULL;
	int			 len=0;
	int			 field_cnt=0;
	int			 i;
	MYSQL_ROW 	row=0;

	vin("mysr_mold_result()");
	resultmv = build(MOLD_WORD, "grid");
	db = make(MOLD_BLOCK);
	resultmv->next = db;
	header = make (MOLD_BLOCK);
	column_names = make (MOLD_BLOCK);
	column_count = make (MOLD_INT);
	append(header, build( MOLD_SET_WORD, "columns" ));
	append(header, column_count);
	append(header, build( MOLD_SET_WORD, "labels" ));
	append(header, column_names);
	column_count->newline = TRUE;
	// add bulk header
	append(db, header);

	if (result == NULL){
		vprint ("ERROR: NULL result given as argument");
		dismantle(resultmv);
		resultmv = mysr_prep_error("generic", "NULL result in MySQL");
		resultmv = make(MOLD_NONE);
	} else {
		field_cnt = mysql_num_fields(result);
		vprint("Number of columns: %d\n", field_cnt);

		if (field_cnt >  column_types_array_size){
			// TODO: we should grow list on the fly!
			vprint ("ERROR! Too many columns in result set");
			dismantle(resultmv);
			resultmv = mysr_prep_error("generic", "Too many columns in result set");
		}else{
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
				int breakfetch = FALSE;
				for(i = 0; i < field_cnt; i++) {
					mv = mysr_prep_sql_value(row[i], column_types[i]);  // if row[i] is NULL, we receive a MOLD_NONE value
					vprint("%s , " , (row[i] ? row[i] : "NULL"));
					if (mv == NULL){
						vprint("mv is NULL!");
						dismantle(resultmv);
						vprint("INPUT TYPE: %s", mold_mysql_type(column_types[i]));
						resultmv = mysr_prep_error("generic", "problem casting mysql value to mysr");
						breakfetch = TRUE;
						break;
					}else{
						append(db, mv);
					}
				}
				if (breakfetch){
					vprint("BREAKFETCH DETECTED!");
					//----
					// an error occured, stop loop right away.
					break;
				}
				mv->newline = TRUE;
				vprint("\n---------------------\n");
			}
		}
	}
	len=mold_list(resultmv, resultbuffer, resultbuffersize, 0);

	// in theory, len cannot be larger than resultbuffersize
	// make absolutely sure that the string is null terminated.
	resultbuffer[len] = 0;

	//-------------
	// deallocate the whole data-tree
	//-------------
	dismantle(resultmv);

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




//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- DB QUERY FUNCTIONS
//
//-----------------------------------------------------------------------------------------------------------

//--------------------------
//-     mysr_stmt_create()
//--------------------------
// purpose:  
//
// inputs:   
//
// returns:  
//
// notes:    - params must match the actual number of params within the query.
//           - we will want to add some form of error reporting
//
// to do:    
//
// tests:    
//--------------------------
DLL_EXPORT MYSQL_STMT *mysr_stmt_create(
	MysrSession *session, 
	char *query, 
	int querylen, 
	int count
){
	MYSQL_STMT    *stmt=NULL;

	vin("mysr_stmt_create()");
	
	stmt = mysql_stmt_init(session->connection);
	
	if (stmt){
		if (mysql_stmt_prepare(stmt, query, querylen)){
			// error, quit
			mysql_stmt_close(stmt);
			stmt = NULL;
		}
	}
	if (stmt){
		int param_count = 0;
		param_count= mysql_stmt_param_count(stmt);
		if (count==param_count){
			// ready to get params setup
			//return stmt;
			
		}else{
			// error wrong number of params.
			mysql_stmt_close(stmt);
			stmt=NULL;
			
		}
	}
	vout;
	
	return stmt;
}





//--------------------------
//-     mysr_build_params()
//--------------------------
// purpose:  allocates an array of params.
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
DLL_EXPORT MYSQL_BIND *mysr_build_params(int count){
	MYSQL_BIND *params = NULL;
	vin("mysr_build_params()");
	params = calloc(count, sizeof(MYSQL_BIND));
	vout;
	return params;
}


//--------------------------
//-     mysr_set_param()
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
void mysr_set_param(
	MYSQL_BIND *params, 
	int idx,
	enum enum_field_types type
){
	vin("mysr_set_param()");
	
	vout;
}







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
	char *error=NULL;

	vprint(query_string);

	if (mysql_query(session->connection, query_string)){
		//------
		// error
		//------
		//error = build(mold_word,"error");
		//error -> next = build(mold_string, mysql_error(session->connection));
		error = (char *) mysql_error(session->connection);
		vprint ("MySQL Query ERROR! %s", error);
		molded_str = mysr_mold_error(error); // we cannot set type...it's blocked to generic.
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
				molded_str = mysr_mold_row_count(num_rows);
			} else {
				// mysql_store_result() should have returned data
				//error = build(mold_word,"error");
				//error -> next = build(mold_string, mysql_error(session->connection));
				error = (char *) mysql_error(session->connection);
				if (error){
					vprint ("MySQL Query ERROR! %s", error);
					//vout;
					//return error;
					molded_str = mysr_mold_error(error) ; // we cannot set type...it's blocked to generic.
				}
			}
		}
	}
	vout;
	return molded_str;
}


