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

#define VERBOSE
#include "vprint.h"



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
//- resultbuffersize:
//
//--------------------------
int resultbuffersize = 0;




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
// purpose:  creates a session in memory, attempts a connection to db and returns the session
//
// inputs:
//
// returns:
//
// notes:    - the inner mysql connection will be null in the session, if connection is not successful.
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
		success = mysql_init(connection);
		if (success == NULL){
			vprint("MySQL ERROR: %s", mysql_error(NULL));
		} else {
			success = mysql_real_connect(connection, host, usr, pwd, db, 0, NULL, 0 );
			if (success){
				vprint("Connected... YAY! Server info: %s", mysql_get_server_info(connection));
			}else{
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
	

	vprint("MySQL client info: %s", mysql_get_client_info())

	vnum(success);
	vout;
	return success;
}



//-                                                                                                       .
//-----------------------------------------------------------------------------------------------------------
//
//- DB INTROSPECTION FUNCTIONS
//
//-----------------------------------------------------------------------------------------------------------
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
// notes:    use mysr_free_data() on returned string.
//
// to do:
//
// tests:
//--------------------------
DLL_EXPORT char *mysr_list_dbs(MysrSession *session, char *filter){
	char *result=NULL;
	MYSQL_RES *mysql_result=NULL;
	char *rebstr=NULL;

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

			rebstr = mysr_mold_result(mysql_result);
			printf("%s", rebstr);

			mysql_free_result(mysql_result);
		}
	}

	vout;
	return result;
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
	int			 len=0;
	int			 field_cnt=0;
	int			 i;
	MYSQL_ROW 	row=0;
	int			*col_types=NULL;  // will be allocated to an array or integers which represent the mold.c types of each column, by index.
	                              // we will use this to properly type any results in the rebol molded values.  any unknown type, just gets returned as a string.
	
	vin("mysr_mold_result()");
	blk = make(MOLD_BLOCK);
	header = make (MOLD_BLOCK);
	column_names = make (MOLD_BLOCK);
	append(header, build( MOLD_SET_WORD, "columns" ));
	append (header, column_names);
	
	// add bulk header
	append(blk, header);
	vprint("result is %i chars long", len );

	if (result == NULL){
		vprint ("ERROR: NULL result given as argument");
	} else {
		field_cnt = mysql_num_fields(result);
		vprint("Number of columns: %d\n", field_cnt);
		for (i=0; i < field_cnt; ++i){
			/* col describes i-th column of the table */
			MYSQL_FIELD *col = mysql_fetch_field_direct(result, i);
			vprint ("Column %d: %s\n", i, col->name);
			append ( column_names, build(MOLD_WORD, col->name) );
		}
		
		//----------
		// fetch the row data
		while ((row = mysql_fetch_row(result))) {
			for(i = 0; i < field_cnt; i++) 
			{ 
				append(blk, build(MOLD_TEXT, row[i]));
				printf("%s ", row[i] ? row[i] : "NULL"); 
			} 
			printf("\n"); 
		}		
	}
	mold(blk, resultbuffer, resultbuffersize, 0);
	

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
