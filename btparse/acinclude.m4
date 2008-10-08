# -*- mode: autoconf; fill-column: 75; -*-

# BTPARSE_PROG_POD2MAN
# --------------------

AC_DEFUN(BTPARSE_PROG_POD2MAN,[
   AC_CHECK_PROG(POD2MAN,pod2man,pod2man,no)
   if test "$POD2MAN" = "no"; then
      AC_MSG_ERROR([
The pod2man program was not found in the default path.  pod2man is part of
Perl, which can be retrieved from:

    http://www.perl.com/

The latest version at this time is 5.6.1; it is available packaged as the
following archive:

    http://www.perl.com/CPAN/src/stable.tar.gz
])
   fi
])

# BTPARSE_CHECK_PCCTS_HEADERS
# ---------------------------

AC_DEFUN(BTPARSE_CHECK_PCCTS_HEADERS,[
   AC_MSG_CHECKING([for PCCTS header files])
   if test "x${btparse_pccts_includedir}" != "x"; then
      if test -f ${btparse_pccts_includedir}/pcctscfg.h; then
          PCCTS_INCLUDES=-I${btparse_pccts_includedir}
          AC_SUBST(PCCTS_INCLUDES)
          AC_MSG_RESULT([${btparse_pccts_includedir}])
      else
          AC_MSG_ERROR([
Could not find the PCCTS header files.  The directory you specified does
not seem to contain the PCCTS header files needed to compile btparse.
Please specify a valid directory.
])
      fi
   else
      PCCTS_INCLUDES=-I\$\(top_srcdir\)/pccts
      AC_SUBST(PCCTS_INCLUDES)
      AC_MSG_RESULT([yes])
   fi
])

# BTPARSE_CHECK_STRDUP
# --------------------

AC_DEFUN(BTPARSE_CHECK_STRDUP,[
   AC_MSG_CHECKING([for strdup declaration in <string.h>])
   AC_EGREP_HEADER([strdup *\(], string.h, btparse_tmp=yes, btparse_tmp=no)
   AC_MSG_RESULT($btparse_tmp)
   if test "$btparse_tmp" = "yes"; then
      AC_DEFINE([HAVE_STRDUP_DECL], [1],
                [set if strdup is declared in <string.h>])
   fi
])

# BTPARSE_CHECK_USE_PROTOS
# ------------------------

AC_DEFUN(BTPARSE_CHECK_USE_PROTOS,[
   AC_MSG_CHECKING(if __USE_PROTOS is defined by pccts/pcctscfg.h)
   AC_PROG_CPP
   AC_EGREP_CPP(yes,[
#include <pccts/pcctscfg.h>
#ifdef __USE_PROTOS
yes
#endif
], btparse_tmp=yes, btparse_tmp=no)
   AC_MSG_RESULT($btparse_use_protos)
   if test "$btparse_tmp" = "no"; then
      DEFINES="$DEFINES${DEFINES:+ }-D__USE_PROTOS"
   fi
   AC_SUBST(DEFINES)
])
