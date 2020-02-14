//------------------------------------------------
// file:    dll-exports.h
// author:  (C) Maxim Olivier-Adlhoch
//
// date:    2020-02-14
// version: 1.0.1
//
// license: APACHE v2.0 
//          https://www.apache.org/licenses/LICENSE-2.0
//
// purpose: used on windows to declare export or import of shared library functions.
//
// notes:   - You MUST define BUILD_DLL in project which compiles the DLL (do this in project setup in IDE or in make file). 
//          - NEVER set BUILD_DLL in projects which USE the DLL.
//------------------------------------------------
#ifdef BUILD_DLL
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT __declspec(dllimport)
#endif

