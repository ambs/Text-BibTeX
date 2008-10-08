#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="btool"

echo "Checking source directory..."
(test -f $srcdir/configure.ac \
  && test -f $srcdir/autogen.sh \
  && test -f $srcdir/src/bibtex.c) || {
    echo -n "**Error**: Directory "\`$srcdir\'" does not look like the"
    echo " top-level $PKG_NAME directory"
    exit 1
}

echo "Running libtoolize"
libtoolize -f

echo "Running aclocal $ACLOCAL_FLAGS"
aclocal $ACLOCAL_FLAGS

echo "Running autoheader"
autoheader

echo "Running autoconf"
autoconf

echo "Running automake"
automake -a

echo "Configuring for debugging with extra flags: $*"
./configure --enable-maintainer-mode --with-cflags='-ggdb -Wall -Wimplicit-function-declaration' $*

