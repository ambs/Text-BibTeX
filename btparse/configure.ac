dnl Process this file with autoconf to produce a configure script.

AC_INIT(btparse, 0.34)dnl
AC_CONFIG_SRCDIR(src/bibtex.g)dnl
AC_PREREQ(2.57)dnl
AM_INIT_AUTOMAKE

AC_SUBST(PACKAGE_VERSION)
AC_SUBST(RELEASE_DATE,2003-10-25)

# additional options to configure

AC_MSG_CHECKING(if external PCCTS include files are wanted)
AC_ARG_WITH(pccts-includedir,
   AC_HELP_STRING([--with-pccts-includedir=DIR],
                  [directory with PCCTS parser generator header files]),
   [AC_MSG_RESULT(yes); btparse_pccts_includedir=$withval],
   [AC_MSG_RESULT(no)])

AM_WITH_DMALLOC

# checks for programs

AC_PROG_CC
AC_PROG_CC_STDC
AC_PROG_INSTALL
AC_PROG_LIBTOOL
AC_PROG_MAKE_SET

AC_CHECK_PROG(ANTLR,antlr,antlr,not found)
AC_CHECK_PROG(DLG,dlg,dlg,not found)

BTPARSE_PROG_POD2MAN

# checks for header files

AC_HEADER_STDC
AC_CHECK_HEADERS(limits.h)
BTPARSE_CHECK_PCCTS_HEADERS

# checks for types

AC_CHECK_TYPES([ushort, boolean])

# checks for compiler characteristics

AC_C_CONST

# checks for library functions

AC_FUNC_ALLOCA
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(strdup strlwr strupr vsnprintf)
BTPARSE_CHECK_STRDUP
#BTPARSE_CHECK_USE_PROTOS

# finishing up

AC_SUBST(INCLUDES)

AM_CONFIG_HEADER(src/bt_config.h src/btparse.h)
AC_CONFIG_FILES(Makefile doc/Makefile progs/Makefile src/Makefile tests/Makefile)
AC_OUTPUT
