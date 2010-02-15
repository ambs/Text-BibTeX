# -*- cperl -*-
use strict;
use warnings;

use Test::More tests => 57;

use vars ('$DEBUG');

BEGIN {
    use_ok('Text::BibTeX', qw(:macrosubs));
    require "t/common.pl";
}
$DEBUG = 1;

# setup_stderr;

# ----------------------------------------------------------------------
# test macro parsing and expansion

my ($macrodef, $regular, $entry, @warnings);

$macrodef = <<'TEXT';
@string ( foo = "  The Foo
  Journal",  
        sons  = " \& Sons",
    bar 
=    {Bar   } # sons,

)
TEXT

$regular = <<'TEXT';
@article { my_article, 
            author = { Us and Them },
            journal = foo,
            publisher = "Fu" # bar 
          }
TEXT

# Direct access to macro table, part 1: make sure the macros we're going to
# defined aren't defined

print "testing that none of our macros are defined yet\n" if $DEBUG;

is(macro_length('foo') , 0 );
is(macro_length('sons'), 0 );
is(macro_length('bar') , 0 );

err_like( sub{ ok(! defined macro_text('foo') ); }, qr/undefined macro "foo"/);
err_like( sub{ ok(! defined macro_text('sons')); }, qr/undefined macro "sons"/);
err_like( sub{ ok(! defined macro_text('bar') ); }, qr/undefined macro "bar"/);

# Now parse the macro-definition entry; this should put the three 
# macros we're interested in into the macro table so we can
# successfully parse the regular entry
print "parsing macro-definition entry to define 3 macros\n" if $DEBUG;
$entry = new Text::BibTeX::Entry;

no_err( sub{ $entry->parse_s($macrodef); } );

test_entry($entry, 'string', undef,
           [qw(foo sons bar)],
           ['  The Foo   Journal', ' \& Sons', 'Bar    \& Sons']);

# Direct access to macro table, part 2: make sure the macros we've just
# defined now have the correct values
print "checking macro table to ensure that the macros were properly defined\n"
   if $DEBUG;

no_err( sub {
            is(macro_length('foo') ,19);
            is(macro_length('sons'), 8);
            is(macro_length('bar') ,14);

            is(macro_text('foo') , '  The Foo   Journal');
            is(macro_text('sons'), ' \& Sons');
            is(macro_text('bar') , 'Bar    \& Sons');
         } );

# Parse the regular entry -- there should be no warnings, because
# we've just defined the 'foo' and 'bar' macros on which it depends

# calling a parse or read method on an existing object isn't documented
# as an "ok thing to do", but it is (at least as the XS code currently
# is!) -- hence I can leave the "new" uncommented
# $entry = new Text::BibTeX::Entry;
print "parsing the regular entry which uses those 2 of those macros\n"
   if $DEBUG;

no_err( sub { $entry->parse_s ($regular); });

test_entry ($entry, 'article', 'my_article',
            [qw(author journal publisher)],
            ['Us and Them', 'The Foo Journal', 'FuBar \& Sons']);


# Delete the 'bar' macro and change 'foo' -- this should result in
# one warning about the macro value being overridden

delete_macro ('bar');
is(macro_length ('bar'), 0);

err_like( sub { ok(! defined macro_text ('bar')); }, qr/undefined macro "bar"/);

err_like ( sub { add_macro_text ('foo', 'The Journal of Fooology'); },
           qr/overriding existing definition of macro "foo"/);

# Now re-parse our regular entry; we should get a warning about the deleted
# "bar" macro, and the "journal" field (which relies on "foo") should have
# a different value

err_like( sub { $entry->parse_s ($regular); }, qr/undefined macro "bar"/);

test_entry ($entry, 'article', 'my_article',
            [qw(author journal publisher)],
            ['Us and Them', 'The Journal of Fooology', 'Fu']);
