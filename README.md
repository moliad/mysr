# mysr - mysql rebol connector

An effort to provide full access to all features of mysql for Rebol and derivative languages.

The interface is setup using a shim dll which integrates an easy to use Rebol compatibility layer to send queries and load the results.

We currently build the connector against v5.7.29 of the mysql libc sdk.

There are very few steps and external dependencies, most of them required by mysql itself.

# Setup

### You will need these things to BUILD your own version of the library:

* download and install the visual studio 2013 redistributables (from microsoft.com !!).

* download and install the visual studio 2019 redistributables (from microsoft.com !!).

* download this repository

* download and install mysql v5.7.25+, including the C connector SDK

* clone master branch of  [common-c-libs repository](git@github.com:moliad/common-c-libs.git)

* have a version of Rebol which supports dll support (/view or /command)

* get slim for rebol and all library packages [here] 

#### building with Visual Studio

* have a copy of Visual Studio 2017 or more recent

* open the mysrConnector.sln in the root of the project

* that's it  :-)

#### building with GCC

* download and install code blocks with mingw

* copy the `\include\` and `\lib\` folder from the standard mysql installation (`C:\Program Files (x86)\MySQL\MySQL Server 5.7\ `) to your local dev setup (follow directory tree below).  We need to do this so you can write to it because Windows doesn't allow applications to write within `program files` folders, the actual path is aliased to another path.

* download lib2a so you can easily convert the .lib format to a compatible .a linking lib for GCC. You can find it here: https://code.google.com/archive/p/lib2a/downloads

* run lib2a on the mysql\lib\libmysql.lib file in order to get a libmysql.a file.

* rename the libmysql.lib from your copy of the mysql lib dir...  it confuses GCC.

### You will need these to USE the library

* download and setup a version of rebol which supports dll support on windows.

* download the latest rebol slim libraries from github (especially the misc-libs, which is required for bulk support)

* mysql v5.7.29+ installed and running


### Final Directory Tree

Once you have everything, if you place all the packages and files in the following directory tree, the code blocks project will be usable as-is!  It uses only relative paths for its setups.

```
git/
    common-c-libs/
        include/
    mysr/
        LIB2A/
        mysql/
            include/
            lib/
        mysr-client/
        mysr-connector/
            src/
                include/
```


## Setup Client test

The mysr_client requires you to setup your mysql server instance used.  this includes setting up the host, user and passwd.

Copy the `mysr\mysr-client\myser-usrpwd.template.h` file as `myser-usrpwd.h` and change the information within to suit your setup.

Note that we include no values in the template to make sure no one uses a default and it becomes a security flaw.  You ***must*** put your values.



