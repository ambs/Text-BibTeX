## Process this file with automake to produce Makefile.in

DEFINES = @DEFINES@
INCLUDES = @INCLUDES@ @PCCTS_INCLUDES@

ANTLR = @ANTLR@

ANTLR_FE = err.c
ANTLR_FH = stdpccts.h
ANTLR_FL = parser.dlg
ANTLR_FT = tokens.h
PARSER = bibtex.c

ANTLR_FLAGS = -gt -fe $(ANTLR_FE) -fh $(ANTLR_FH) -fl $(ANTLR_FL) -ft $(ANTLR_FT)
ANTLR_SPAWN = $(ANTLR_FE) $(ANTLR_FH) $(ANTLR_FL) $(ANTLR_FT) $(PARSER)

DLG = @DLG@

DLG_FM = mode.h
SCANNER = scan.c

DLG_FLAGS = -C2 -i -m $(DLG_FM)
DLG_SPAWN = $(DLG_FM) $(SCANNER)

## delete antlr/dlg spawn at maintainer-clean
BUILT_SOURCES = $(ANTLR_SPAWN) $(DLG_SPAWN)

EXTRA_DIST = bibtex.g $(ANTLR_SPAWN) $(DLG_SPAWN) $(wildcard *.h)

$(ANTLR_SPAWN): bibtex.g
	@if [ "$(ANTLR)" = "not found" ]; then \
	  echo "configure script could not find antlr -- cannot build $@" 2>&1 ;\
	  exit 1; \
	fi
	$(ANTLR) $(ANTLR_FLAGS) bibtex.g

$(DLG_SPAWN): $(ANTLR_FL)
	@if [ "$(DLG)" = "not found" ]; then \
	  echo "configure script could not find dlg -- cannot build $@" 2>&1 ;\
	  exit 1; \
	fi
	$(DLG) $(DLG_FLAGS) $(ANTLR_FL) $(SCANNER)

lib_LTLIBRARIES = libbtparse.la
libbtparse_la_SOURCES = init.c input.c $(PARSER) $(ANTLR_FE) $(SCANNER) \
	error.c lex_auxiliary.c parse_auxiliary.c bibtex_ast.c sym.c util.c \
	postprocess.c macros.c traversal.c modify.c names.c tex_tree.c \
	string_util.c format_name.c
#libbtparse_la_LIBADD = @LIBADD_DMALLOC@
#	$(patsubst %.c,%.lo,$(PARSER) $(ANTLR_FE) $(SCANNER))

# libtool versioning system (see libtool manual, section 6.2)
#
#   - If no interfaces changed, only implementations, increment REVISION.
#   - If new interfaces were added, but none was removed, increment CURRENT,
#     increment AGE, and set REVISION to 0.
#   - If interfaces were removed (bad, as it breaks upward compatibility),
#     increment CURRENT, set AGE and REVISION to 0.

LT_CURRENT = 0
LT_REVISION = 0
LT_AGE = 0

libbtparse_la_LDFLAGS = -version-info $(LT_CURRENT):$(LT_REVISION):$(LT_AGE)

include_HEADERS = btparse.h
