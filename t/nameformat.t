# -*- cperl -*-
use strict;
use vars qw($DEBUG);
use IO::Handle;
use Test::More tests=>11;

require "t/common.pl";

use Text::BibTeX qw(:nameparts :joinmethods);
use Text::BibTeX::Name;
use Text::BibTeX::NameFormat;

$DEBUG = 1;

#setup_stderr;

# Get a name to work with (and just a quick check that the Name class
# is in working order)
my $name = new Text::BibTeX::Name
        "Charles Louis Xavier Joseph de la Vall{\'e}e Poussin";
my @first = $name->part ('first');
my @von = $name->part ('von');
my @last = $name->part ('last');
is_deeply(\@first, [qw(Charles Louis Xavier Joseph)]);
is_deeply(\@von, [qw(de la)]);
is_deeply(\@last, ['Vall{\'e}e', 'Poussin']);


# Start with a basic "von last, jr, first" formatter
my $format = new Text::BibTeX::NameFormat ('vljf', 1);
is ($format->apply ($name), "de~la Vall{\'e}e~Poussin, C.~L. X.~J.");
is ($format->apply ($name), $name->format ($format));

# Tweak options: force ties between tokens of the first name
$format->set_options (BTN_FIRST, 1, BTJ_FORCETIE, BTJ_NOTHING);
is ($format->apply ($name), "de~la Vall{\'e}e~Poussin, C.~L.~X.~J.");

# And no ties in the "von" part
$format->set_options (BTN_VON, 0, BTJ_SPACE, BTJ_SPACE);
is ($format->apply ($name), "de la Vall{\'e}e~Poussin, C.~L.~X.~J.");

# No punctuation in the first name
$format->set_text (BTN_FIRST, undef, undef, undef, '');
is ($format->apply ($name), "de la Vall{\'e}e~Poussin, C~L~X~J");

# And drop the first name inter-token separation entirely
$format->set_options (BTN_FIRST, 1, BTJ_NOTHING, BTJ_NOTHING);
is ($format->apply ($name), "de la Vall{\'e}e~Poussin, CLXJ");

# Now we get silly: keep the first name tokens jammed together, but
# don't abbreviate them any more
$format->set_options (BTN_FIRST, 0, BTJ_NOTHING, BTJ_NOTHING);
is ($format->apply ($name),
    "de la Vall{\'e}e~Poussin, CharlesLouisXavierJoseph");

# OK, but spaces back in to the first name
$format->set_options (BTN_FIRST, 0, BTJ_SPACE, BTJ_NOTHING);
is ($format->apply ($name),
    "de la Vall{\'e}e~Poussin, Charles Louis Xavier Joseph");
