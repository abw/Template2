#============================================================= -*-perl-*-
#
# t/dbi.t
#
# Test script for the DBI plugin.
#
# The DBI plugin and test scripts were written by Simon Matthews 
# <sam@knowledgepool.com> with some minor modifications by Andy 
# Wardley <abw@kfs.org> for inclusion in the Template Toolkit from
# version 2.00 onwards.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( . ./t ../lib ./blib/lib ../blib/lib );
use vars qw( $DEBUG $run $dsn $user $pass );
use Template::Test;

$^W = 1;
$DEBUG = 0;
$Template::Test::PRESERVE = 1;

eval "use DBI";
if ($@) {
    exit(0);
}

# load the configuration file created by Makefile.PL which defines
# the $run, $dsn, $user and $pass variables.
require 'dbi_test.cfg';
unless ($run) {
    print "1..0\n";
    exit(0);
}

my $attr = { 
    PrintError => 0,
    ChopBlanks => 1,
};

my $dbh;
eval {
    $dbh = DBI->connect($dsn, $user, $pass, $attr);
};

if ($@ || ! $dbh) {
    warn <<EOF;
DBI connect() failed:
    $DBI::errstr

Please ensure that your database server is running and that you specified
the correct connection parameters.  If necessary, re-run the Makefile.PL
and specify new parameters, or answer 'n' when prompted: 

  - Do you want to run the DBI tests?

EOF
    ntests(1);
    ok(0);
    exit(0);
};

init_database($dbh);

my $vars = {
    dbh  => $dbh,
    dsn  => $dsn,
    user => $user,
    pass => $pass,
    attr => $attr,
};

test_expect(\*DATA, undef, $vars);

cleanup_database($dbh);

$dbh->disconnect();

#------------------------------------------------------------------------
# init_database($dsn, $user, $pass)
#------------------------------------------------------------------------

sub init_database {
    my $dbh = shift;

    # ensure tables don't already exist (in case previous test run failed).
    sql_query($dbh, 'DROP TABLE usr', 1);
    sql_query($dbh, 'DROP TABLE grp', 1);

    # create some tables
    sql_query($dbh, 'CREATE TABLE grp ( 
                         id Char(16), 
                         name Char(32) 
                     )');

    sql_query($dbh, 'CREATE TABLE usr  ( 
                         id Char(16), 
                         name Char(32),
                         grp Char(16)
                     )');

    # add some records to the 'grp' table
    sql_query($dbh, "INSERT INTO grp 
                     VALUES ('foo', 'The Foo Group')");
    sql_query($dbh, "INSERT INTO grp 
                     VALUES ('bar', 'The Bar Group')");

    # add some records to the 'usr' table
    sql_query($dbh, "INSERT INTO usr 
		     VALUES ('abw', 'Andy Wardley', 'foo')");
    sql_query($dbh, "INSERT INTO usr 
		     VALUES ('sam', 'Simon Matthews', 'foo')");
    sql_query($dbh, "INSERT INTO usr 
		     VALUES ('hans', 'Hans von Lengerke', 'bar')");
    sql_query($dbh, "INSERT INTO usr 
		     VALUES ('mrp', 'Martin Portman', 'bar')");
}


#------------------------------------------------------------------------
# sql_query($dbh, $sql, $quiet)
#------------------------------------------------------------------------

sub sql_query {
    my ($dbh, $sql, $quiet) = @_;

    my $sth = $dbh->prepare($sql) 
	|| warn "prepare() failed: $DBI::errstr\n";

    $sth->execute() 
	|| $quiet || warn "execute() failed: $DBI::errstr\n";
    
    $sth->finish();
}


#------------------------------------------------------------------------
# cleanup_database($dsn, $user, $pass)
#------------------------------------------------------------------------

sub cleanup_database {
    my $dbh = shift;

    sql_query($dbh, 'DROP TABLE usr');
    sql_query($dbh, 'DROP TABLE grp');
};


#========================================================================

__END__

#------------------------------------------------------------------------
# test plugin loading with implicit and explicit connect() method
#------------------------------------------------------------------------

-- test --
[% USE DBI -%]
[% DBI.connect(dsn, user, pass, ChopBlanks => 1) -%]
[% FOREACH user = DBI.query("SELECT name FROM usr WHERE id='abw'") -%]
* [% user.name %]
[% END %]

-- expect --
* Andy Wardley

-- test --
[% USE dbi -%]
[% dbi.connect(dsn, user, pass, ChopBlanks => 1) -%]
[% FOREACH user = dbi.query("SELECT name FROM usr WHERE id='sam'") -%]
* [% user.name %]
[% END %]

-- expect --
* Simon Matthews

-- test --
[% USE db = DBI -%]
[% db.connect(dsn, user, pass, ChopBlanks => 1) -%]
[% FOREACH user = db.query("SELECT name FROM usr WHERE id='hans'") -%]
* [% user.name %]
[% END %]

-- expect --
* Hans von Lengerke

-- test --
[% USE db = DBI(data_source => dsn, 
		username    => user, 
		password    => pass,
		ChopBlanks  => 1)  -%]
[% FOREACH user = db.query("SELECT name FROM usr WHERE id='mrp'") -%]
* [% user.name %]
[% END %]

-- expect --
* Martin Portman

-- test --
[% USE dbi -%]
[% dbi.connect(dsn=dsn, user=user, pass=pass ChopBlanks=1) -%]
[% FOREACH user = dbi.query("SELECT name FROM usr WHERE id='abw'") -%]
* [% user.name %]
[% END %]

-- expect --
* Andy Wardley

-- test --
[% USE DBI -%]
[% TRY;
     DBI.query('blah blah'); 
   CATCH; 
     error; 
   END 
%]
-- expect --
DBI error - data source not defined


#------------------------------------------------------------------------
# disconnect() and subsequent connect()
#------------------------------------------------------------------------

-- test --
[% USE DBI(dsn, user, pass, attr) -%]
[% DBI.disconnect -%]
[% TRY;
     DBI.query('blah blah'); 
   CATCH; 
     error; 
   END 
%]
-- expect --
DBI error - data source not defined

-- test --
[% USE DBI(dsn, user, pass, attr) -%]
[% DBI.disconnect -%]
[% DBI.connect(dsn, user, pass, attr) -%] 
[% FOREACH user = DBI.query("SELECT name FROM usr WHERE id='abw'") -%]
* [% user.name %]
[% END %]

-- expect --
* Andy Wardley


#------------------------------------------------------------------------
# validate 'loop' reference to iterator
#------------------------------------------------------------------------

-- test --
[% USE dbi(dsn, user, pass, attr) -%]
[% FOREACH user = dbi.query('SELECT * FROM usr ORDER BY id') -%]
[% loop.number %]: [% user.id %] - [% user.name %]
[% END %]
-- expect --
1: abw - Andy Wardley
2: hans - Hans von Lengerke
3: mrp - Martin Portman
4: sam - Simon Matthews

-- test --
# DBI plugin before TT 2.00 used 'count' instead of 'number'
[% USE dbi(dsn, user, pass, attr) -%]
[% FOREACH user = dbi.query('SELECT * FROM usr ORDER BY id') -%]
[% loop.count %]: [% user.id %] - [% user.name %]
[% END %]
-- expect --
1: abw - Andy Wardley
2: hans - Hans von Lengerke
3: mrp - Martin Portman
4: sam - Simon Matthews


#------------------------------------------------------------------------
# test 'loop' reference to iterator in nested queries
#------------------------------------------------------------------------

-- test --
[% USE dbi(dsn, user, pass, attr) -%]
[% FOREACH group = dbi.query('SELECT * FROM grp
                              ORDER BY id')      -%]
Group [% loop.number %]: [% group.name %] ([% group.id %])
[% FOREACH user = dbi.query("SELECT * FROM usr 
                              WHERE grp='$group.id'
                              ORDER BY id")       -%]
  #[% loop.number %]: [% user.name %] ([% user.id %])
[% END -%]
[% END -%]

-- expect --
Group 1: The Bar Group (bar)
  #1: Hans von Lengerke (hans)
  #2: Martin Portman (mrp)
Group 2: The Foo Group (foo)
  #1: Andy Wardley (abw)
  #2: Simon Matthews (sam)


#------------------------------------------------------------------------
# test prev and next iterator methods
#------------------------------------------------------------------------

-- test --
[% USE dbi(dsn, user, pass, attr) -%]
[% FOREACH user = dbi.query('SELECT * FROM usr ORDER BY id') -%]
[% loop.prev ? "[$loop.prev.id] " : "[no prev] " -%]
[% user.id %] - [% user.name -%]
[% loop.next ? " [$loop.next.id]" : " [no next]" %]
[% END %]
-- expect --
[no prev] abw - Andy Wardley [hans]
[abw] hans - Hans von Lengerke [mrp]
[hans] mrp - Martin Portman [sam]
[mrp] sam - Simon Matthews [no next]


#------------------------------------------------------------------------
# test do() to perform SQL queries without returning results
#------------------------------------------------------------------------

-- test --
[% USE DBI(dsn, user, pass, attr) -%]
[% CALL DBI.do("INSERT INTO usr VALUES ('numb', 'Numb Nuts', 'bar')") -%]
[% FOREACH user = DBI.query("SELECT * FROM usr 
                             WHERE grp = 'bar'
                             ORDER BY id") -%]
* [% user.name %] ([% user.id %])
[% END %]

-- expect --
* Hans von Lengerke (hans)
* Martin Portman (mrp)
* Numb Nuts (numb)

-- test --
[% USE dbi(dsn, user, pass, attr) -%]
[% IF dbi.do("DELETE FROM usr WHERE id = 'numb'") -%]
deleted the user
[% ELSE -%]
failed to delete the user 
[% END -%]
[% FOREACH user = dbi.query("SELECT * FROM usr 
                             WHERE grp = 'bar'
                             ORDER BY id") -%]
* [% user.name %] ([% user.id %])
[% END %]
-- expect --
deleted the user
* Hans von Lengerke (hans)
* Martin Portman (mrp)


#------------------------------------------------------------------------
# prepare()
#------------------------------------------------------------------------

-- test --
[% USE dbi(dsn=dsn, user=user, pass=pass, ChopBlanks=1) -%]
[% user_query  = dbi.prepare('SELECT * FROM usr 
                              WHERE grp = ?
			      ORDER BY id') -%]
Foo:
[% users = user_query.execute('foo') -%]
[% FOREACH user = users -%]
  #[% users.index %]: [% user.name %] ([% user.id %])
[% END -%]

Bar:
[% users = user_query.execute('bar') -%]
[% FOREACH user = users -%]
  #[% users.index %]: [% user.name %] ([% user.id %])
[% END -%]
-- expect --
Foo:
  #0: Andy Wardley (abw)
  #1: Simon Matthews (sam)

Bar:
  #0: Hans von Lengerke (hans)
  #1: Martin Portman (mrp)


-- test --
[% USE dbi(dsn, user, pass, attr) -%]
[% group_query = dbi.prepare('SELECT * FROM grp
                              ORDER BY id') -%]
[% user_query  = dbi.prepare('SELECT * FROM usr 
                              WHERE grp = ?
			      ORDER BY id') -%]
[% groups = group_query.execute -%]
[% FOREACH group = groups -%]
Group [% groups.count %] : [% group.name %]
[% users = user_query.execute(group.id) -%]
[% FOREACH user = users -%]
  User [% users.index %] : [% user.name %] ([% user.id %])
[% END -%]
[% END %]
-- expect --
Group 1 : The Bar Group
  User 0 : Hans von Lengerke (hans)
  User 1 : Martin Portman (mrp)
Group 2 : The Foo Group
  User 0 : Andy Wardley (abw)
  User 1 : Simon Matthews (sam)


-- test --
[% USE dbi(dsn, user, pass, attr) -%]
[% CALL dbi.prepare('SELECT * FROM usr WHERE id = ?') -%]
[% FOREACH uid = [ 'abw', 'sam' ] -%]
===
[% FOREACH user = dbi.execute(uid) -%]
  * [% user.name %] ([% user.id %])
[% END -%]
===
[% END %]

-- expect --
===
  * Andy Wardley (abw)
===
===
  * Simon Matthews (sam)
===


#------------------------------------------------------------------------
# test that dbh can be passed as a named parameter and remains open
#------------------------------------------------------------------------

-- test --
[% USE dbi(dbh => dbh) -%]
[% FOREACH dbi.query("SELECT * FROM usr WHERE id = 'abw'") -%]
* [% name %]
[% END -%]
[% dbi.connect(dsn, user, pass, ChopBlanks=1) -%]
[% FOREACH user = dbi.query("SELECT * FROM usr WHERE id = 'abw'") -%]
* [% user.name %]
[% END -%]
-- expect --
* Andy Wardley
* Andy Wardley




