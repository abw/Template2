#============================================================= -*-Perl-*-
#
# Template::Test
#
# DESCRIPTION
#   Module defining a test harness which processes template input and
#   then compares the output against pre-define expected output.
#   Generates test output compatible with Test::Harness.  This was 
#   originally the t/texpect.pl script.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Test;

require 5.004;

use strict;
use vars qw( @ISA @EXPORT $VERSION $DEBUG $EXTRA $PRESERVE $loaded %callsign);
use Template qw( :template );
use Exporter;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;
@ISA     = qw( Exporter );
@EXPORT  = qw( ntests ok match flush test_expect callsign banner );
$| = 1;

$EXTRA    = 0;   # any extra tests to come after test_expect()
$PRESERVE = 0	 # don't mangle newlines in output/expect
    unless defined $PRESERVE;

my @results = ();
my ($ntests, $ok_count);

sub END {
    # ensure flush() is called to print any cached results 
    flush();
}


#------------------------------------------------------------------------
# ntests($n)
#
# Declare how many (more) tests are expected to come.  If ok() is called 
# before ntests() then the results are cached instead of being printed
# to STDOUT.  When ntests() is called, the total number of tests 
# (including any cached) is known and the "1..$ntests" line can be
# printed along with the cached results.  After that, calls to ok() 
# generated printed output immediately.
#------------------------------------------------------------------------

sub ntests {
    $ntests = shift;
    # add any pre-declared extra tests, or pre-stored test @results, to 
    # the grand total of tests
    $ntests += $EXTRA + scalar @results;	 
    $ok_count = 1;
    print "1..$ntests\n";
    foreach my $pre_test (@results) {
	ok($pre_test);
    }
}


#------------------------------------------------------------------------
# ok($truth)
#
# Tests the value passed for truth and generates an "ok $n" or "not ok $n"
# line accordingly.  If ntests() hasn't been called then we cached 
# results for later, instead.
#------------------------------------------------------------------------

sub ok {
    my $result = shift;

    if ($ok_count) {
	print "not " unless $result;
	print "ok $ok_count\n";
	++$ok_count;
    }
    else {
	# haven't started counting tests yet, so buffer it for later
	push(@results, $result);
    }
    return $result;
}


#------------------------------------------------------------------------
# match( $result, $expect )
#------------------------------------------------------------------------

sub match {
    my ($result, $expect) = @_;
    my $count = $ok_count ? $ok_count : scalar @results + 1;

    # force stringification of $result to avoid 'no eq method' overload errors
    $result = "$result" if ref $result;	   

    if ($result eq $expect) {
	return ok(1);
    }
    else {
	print STDERR "FAILED $count:\n  expect: [$expect]\n  result: [$result]\n";
	return ok(0);
    }
}


#------------------------------------------------------------------------
# flush()
#
# Flush any tests results.
#------------------------------------------------------------------------

sub flush {
    ntests(0)
	unless ($ok_count);
}


#------------------------------------------------------------------------
# test_expect($input, $template, \%replace)
#
# This is the main testing sub-routine.  The $input parameter should be a 
# text string or a filehandle reference (e.g. GLOB or IO::Handle) from
# which the input text can be read.  The input should contain a number 
# of tests which are split up and processed individually, comparing the 
# generated output against the expected output.  Tests should be defined
# as follows:
#
#   -- test --
#   test input
#   -- expect --
#   expected output
# 
#   -- test --
#    etc...
#
# The number of tests is determined and ntests() is called to generate 
# the "0..$n" line compatible with Test::Harness.  Each test input is
# then processed by the Template object passed as the second parameter,
# $template.  This may also be a hash reference containing configuration
# which are used to instantiate a Template object, or may be left 
# undefined in which case a default Template object will be instantiated.
# The third parameter, also optional, may be a reference to a hash array
# defining template variables.  This is passed to the template process()
# method.
#------------------------------------------------------------------------

sub test_expect {
    my ($src, $tproc, $params) = @_;
    my ($input, @tests);
    my ($output, $expect, $match);
    my $ttprocs;
    local $/ = undef;

    # read input text
    eval {
	$input = ref $src ? <$src> : $src;
    };
    if ($@) {
	ntests(1); ok(0);
	warn "Cannot read input text from $src\n";
	return undef;
    }

    # remove any comment lines
    $input =~ s/^#.*?\n//gm;

    # remove anything before '-- start --' and/or after '-- stop --'
    $input = $' if $input =~ /\s*--\s*start\s*--\s*/;
    $input = $` if $input =~ /\s*--\s*stop\s*--\s*/;

    @tests = split(/^\s*--\s*test\s*--\s*\n/im, $input);

    # if the first line of the file was '--test--' (optional) then the 
    # first test will be empty and can be discarded
    shift(@tests) if $tests[0] =~ /^\s*$/;

    ntests(3 + scalar(@tests) * 2);

    # first test is that Template loaded OK, which it did
    ok(1);

    # optional second param may contain a Template reference or a HASH ref
    # of constructor options, or may be undefined
    if (ref($tproc) eq 'HASH') {
	# create Template object using hash of config items
	$tproc = Template->new($tproc)
	    || die Template->error(), "\n";
    }
    elsif (ref($tproc) eq 'ARRAY') {
	# list of [ name => $tproc, name => $tproc ], use first $tproc
	$ttprocs = { @$tproc };
	$tproc   = $tproc->[1];
    }
    elsif (! ref $tproc) {
	$tproc = Template->new()
	    || die Template->error(), "\n";
    }
    # otherwise, we assume it's a Template reference

    # test: template processor created OK
    ok($tproc);

    # third test is that the input read ok, which it did
    ok(1);

    # the remaining tests are defined in @tests...
    foreach $input (@tests) {
	# split input by a line like "-- expect --"
	($input, $expect) = 
	    split(/^\s*--\s*expect\s*--\s*\n/im, $input);
	$expect = '' 
	    unless defined $expect;

	$output = '';

	# input text may be prefixed with "-- use name --" to indicate a
	# Template object in the $ttproc hash which we should use
	if ($input =~ s/^\s*--\s*use\s+(\S+)\s*--\s*\n//im) {
	    my $ttname = $1;
	    my $ttlookup;
	    if ($ttlookup = $ttprocs->{ $ttname }) {
		$tproc = $ttlookup;
	    }
	    else {
		warn "no such template object to use: $ttname\n";
	    }
	}

	# process input text
	$tproc->process(\$input, $params, \$output) || do {
	    warn "Template process failed: ", $tproc->error(), "\n";
	    # report failure and automatically fail the expect match
	    ok(0); ok(0);
	    next;
	};

	# processed OK
	ok(1);

	# another hack: if the '-- expect --' section starts with 
	# '-- process --' then we process the expected output 
	# before comparing it with the generated output.  This is
	# slightly twisted but it makes it possible to run tests 
	# where the expected output isn't static.  See t/date.t for
	# an example.

	if ($expect =~ s/^\s*--+\s*process\s*--+\s*\n//im) {
	    my $out;
	    $tproc->process(\$expect, $params, \$out) || do {
		warn("Template process failed (expect): ", 
		     $tproc->error(), "\n");
		# report failure and automatically fail the expect match
		ok(0);
		next;
	    };
	    $expect = $out;
	};		

	# strip any trailing blank lines from expected and real output
	foreach ($expect, $output) {
	    s/\n*\Z//mg;
	}

	$match = ($expect eq $output) ? 1 : 0;
	if (! $match || $DEBUG) {
	    print "MATCH FAILED\n"
		unless $match;

	    my ($copyi, $copye, $copyo) = ($input, $expect, $output);
	    unless ($PRESERVE) {
		foreach ($copyi, $copye, $copyo) {
		    s/\n/\\n/g;
		}
	    }
	    printf(" input: [%s]\nexpect: [%s]\noutput: [%s]\n", 
		   $copyi, $copye, $copyo);
	}

	ok($match);
    };
}

#------------------------------------------------------------------------
# callsign()
#
# Returns a hash array mapping lower a..z to their phonetic alphabet 
# equivalent.
#------------------------------------------------------------------------

sub callsign {
    my %callsign;
    @callsign{ 'a'..'z' } = qw( 
	    alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );
    return \%callsign;
}


#------------------------------------------------------------------------
# banner($text)
# 
# Prints a banner with the specified text if $DEBUG is set.
#------------------------------------------------------------------------

sub banner {
    return unless $DEBUG;
    my $text = join('', @_);
    my $count = $ok_count ? $ok_count - 1 : scalar @results;
    print "-" x 72, "\n$text ($count tests completed)\n", "-" x 72, "\n";
}




1;

