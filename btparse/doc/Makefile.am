## Process this file with automake to produce Makefile.in

POD2MAN = @POD2MAN@

man_MANS = btparse.3 \
	   bt_language.3 \
	   bt_input.3 \
	   bt_traversal.3 \
	   bt_postprocess.3 \
	   bt_macros.3 \
	   bt_split_names.3 \
	   bt_format_names.3 \
	   bt_misc.3

PODS = $(subst .3,.pod,$(man_MANS))

EXTRA_DIST = $(man_MANS) $(PODS)

## delete man pages at maintainer-clean
BUILT_SOURCES = $(man_MANS)

%.3: %.pod
	$(POD2MAN) \
		--section=3 \
		--release="btparse, version @PACKAGE_VERSION@" \
		--center="btparse" \
		--date="@RELEASE_DATE@" \
		$< > $@
