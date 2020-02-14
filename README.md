# mysr - mysql rebol connector

An effort to provide full access to all features of mysql for Rebol and derivative languages.

The interface is setup using a shim dll which integrates an easy to use Rebol compatibility layer to send queries and load the results.

We currently build the connector against v5.7.25 of the mysql libc sdk.

There are very few steps and external dependencies, most of them required by mysql itself.

# Setup

### You will need these things to BUILD your own version of the library:

* download and install code blocks with mingw

* download this repository

* download common-c-libs repository

* download and install the visual studio 2013 redistributables (from microsoft.com !!).

* download and install the visual studio 2019 redistributables (from microsoft.com !!).

* download and install mysql v5.7.25+ 

* copy the `\include\` and `\lib\` folder from the standard mysql installation (`C:\Program Files (x86)\MySQL\MySQL Server 5.7\ `) to your local dev setup (follow directory tree below).  We need to do this so you can write to it because Windows doesn't allow applications to write within `program files` folders, the actual path is aliased to another path.

* delete the libmysql.lib from your copy of the mysql lib dir...  it confuses GCC.

* download lib2a so you can easily convert the .lib format to a compatible .a linking lib for GCC. You can find it here: https://code.google.com/archive/p/lib2a/downloads


### You will need these to USE the library

* download and setup a version of rebol which supports dll support on windows.

* download the latest rebol slim libraries from github (especially the misc-libs, which is required for bulk support)

* mysql v5.7.25+ installed and running



once you have everything, if you place all the packages and files in the following directory tree, the code blocks project will be usable as-is!  It uses only relative paths for its setups.

