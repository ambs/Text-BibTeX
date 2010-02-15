# -*- cperl -*-
use strict;
use warnings;
use vars qw($DEBUG);
use IO::Handle;
use Test::More tests => 51;

BEGIN {
    use_ok("Text::BibTeX");
    require "t/common.pl";
}

$DEBUG = 0;

#setup_stderr;

sub test_name {
    my ($name, $parts) = @_;
    my $ok = 1;
    my @partnames = qw(first von last jr);
    my $i;

    for $i (0 .. $#partnames)  {
        if (defined $parts->[$i]) {
            $ok &= ($name->part ($partnames[$i]))
              && slist_equal ($parts->[$i], [$name->part ($partnames[$i])]);
        }
        else {
            $ok &= ! $name->part ($partnames[$i]);
        }
    }
    ok(keys %$name <= 4 && $ok);
}


# ----------------------------------------------------------------------
# processing of author names

my (@names, %names, @orig_namelist, $namelist, @namelist);
my ($text, $entry);

# first just a big ol' list of names, not attached to any entry
%names =
 ('van der Graaf'          => '|van+der|Graaf|',
  'Jones'                  => '||Jones|',
  'van'                    => '||van|',
  'John Smith'             => 'John||Smith|',
  'John van Smith'         => 'John|van|Smith|',
  'John van Smith Jr.'     => 'John|van|Smith+Jr.|',
  'John Smith Jr.'         => 'John+Smith||Jr.|',
  'John van'               => 'John||van|',
  'John van der'           => 'John|van|der|',
  'John van der Graaf'     => 'John|van+der|Graaf|',
  'John van der Graaf foo' => 'John|van+der|Graaf+foo|',
  'foo Foo foo'            => '|foo|Foo+foo|',
  'Foo foo'                => 'Foo||foo|',
  'foo Foo'                => '|foo|Foo|'
 );

@orig_namelist = keys %names;
$namelist = join (' and ', @orig_namelist);
@namelist = Text::BibTeX::split_list
   ($namelist, 'and', 'test', 0, 'name');
is_deeply(\@orig_namelist, \@namelist);

my $i;
foreach $i (0 .. $#namelist)
{
   is($namelist[$i], $orig_namelist[$i]);
   my %parts;
   Text::BibTeX::Name::_split (\%parts, $namelist[$i], 'test', 0, $i, 0);
   ok (keys %parts <= 4);

   my @name = map { join ('+', ref $_ ? @$_ : ()) }
     @parts{'first','von','last','jr'};
   is (join ('|', @name), $names{$orig_namelist[$i]});
}

# now an entry with some names in it

$text = <<'TEXT';
@article{homer97,
  author = {  Homer  Simpson    and
              Flanders, Jr.,    Ned Q. and
              {Foo  Bar and Co.}},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT

ok ($entry = new Text::BibTeX::Entry $text);
my $author = $entry->get ('author');
is ($author, 'Homer Simpson and Flanders, Jr., Ned Q. and {Foo Bar and Co.}');
@names = $entry->split ('author');
ok (@names == 3 &&
    $names[0] eq 'Homer Simpson' &&
    $names[1] eq 'Flanders, Jr., Ned Q.' &&
    $names[2] eq '{Foo Bar and Co.}');
@names = $entry->names ('author');
ok (@names == 3);
test_name ($names[0], [['Homer'], undef, ['Simpson'], undef]);
test_name ($names[1], [['Ned', 'Q.'], undef, ['Flanders'], ['Jr.']]);
test_name ($names[2], [undef, undef, ['{Foo Bar and Co.}']]);
