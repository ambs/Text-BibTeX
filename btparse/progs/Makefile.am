## Process this file with automake to produce Makefile.in

INCLUDES = @INCLUDES@ -I@abs_top_srcdir@/src @PCCTS_INCLUDES@
LDADD = ../src/libbtparse.la

bin_PROGRAMS = bibparse
noinst_PROGRAMS = biblex dumpnames

bibparse_SOURCES = bibparse.c args.c getopt.c getopt1.c

biblex_SOURCES = biblex.c

dumpnames_SOURCES = dumpnames.c

noinst_HEADERS = args.h getopt.h
