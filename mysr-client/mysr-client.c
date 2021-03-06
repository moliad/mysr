//------------------------------------------------
// file:    mysr-client.c
// author:  (C) Maxim Olivier-Adlhoch
//
// date:    2020-02-14
// version: 1.0.1
//
// license: APACHE v2.0
//          https://www.apache.org/licenses/LICENSE-2.0
//
// purpose: compiled application to test out the mysr dll.  This allows us to test it without any possible rebol-based issues.
//
// notes:   properly copy and setup the mysr-userpwd.h file in your local repository.
//------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include "mysr.h"
#include "clibs-mold.h"

#define VERBOSE

#include "vprint.h"
//-----------
// this file doesn't exist in the repository and is part of the .gitignore.
// copy the mysr-usrpwd.h.template file and change the usr and pwd defines to those
// of your local DB install.
//-----------
#include "mysr-usrpwd.h"


int main(){
	int len=0;
	int bufsize = 1000;
	char buffer[bufsize];
	//MoldValue *dmv=NULL;
	MoldValue *mv=NULL;
	char *list=NULL;
	int success=0;
	
	int mysql_query_buffer_size = 10000000;

	von;
	vin ("MAIN()");
	MysrSession  *session = NULL;
	vprint("-----------------------------");
	vprint("   mysr client test v1.0.1");
	vprint("-----------------------------\n");
	len = test_dll("haha", 5);
	vprint("test: %i", len);
	success = mysr_init(mysql_query_buffer_size);  // 10MB
	
	if (success){
		session = mysr_connect(MYSR_HOST, MYSR_DB, MYSR_USR, MYSR_PWD);
		vprint ("connected to localhost mysql");
		list = mysr_list_dbs(session, NULL);
		
		list=mysr_query(session, "SHOW DATABASES;");
		vprint(list);
		
		list=mysr_query(session, "USE inmail;");
		vprint(list);
		
		list=mysr_query(session, "describe logs;");
		vprint(list);
	}else{
		printf("ERROR: unable to initialise a buffer of %i\n\n bytes", mysql_query_buffer_size );
	}
	mv = mysr_prep_error("generic", "Error test");
	//mv = build( MOLD_WORD, "error" );
	//mv->next = make ( MOLD_BLOCK );
	
	mold_list(mv, buffer, bufsize, 0);
	//;
	vprint(buffer);
	
	vout
	return 0;
}
