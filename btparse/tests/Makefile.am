## Process this file with automake to produce Makefile.in

AM_CFLAGS = -DDATA_DIR=\"$(srcdir)/data\"
INCLUDES = @INCLUDES@ -I@abs_top_srcdir@/src
LDADD = ../src/libbtparse.la

# The first three are real test programs, ie. they run non-interactively
# and it's fairly obvious whether the tests passed or not.  The others
# (macro_test etc.) are interactive and require a good understanding
# of BibTeX and btparse to understand what's going on -- which is why
# they're not listed in TESTS below.
check_PROGRAMS = simple_test \
                 read_test \
                 postprocess_test \
                 macro_test \
                 case_test \
                 name_test \
                 purify_test

simple_test_SOURCES = simple_test.c testlib.c
read_test_SOURCES = read_test.c testlib.c
postprocess_test_SOURCES = postprocess_test.c
macro_test_SOURCES = macro_test.c
case_test_SOURCES = case_test.c
name_test_SOURCES = name_test.c
purify_test_SOURCES = purify_test.c

TESTS = read_test simple_test postprocess_test

EXTRA_DIST = testlib.h $(wildcard data/*.bib) data/TESTS
