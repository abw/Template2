#==============================================================================
# 
# Template::Plugin::DBI
#
# DESCRIPTION
#   A Template Toolkit plugin to provide access to a DBI data source.
#
# AUTHOR
#   Simon Matthews <sam@knowledgepool.com>, with contributions from 
#   Andy Wardley <abw@kfs.org>.
#
# COPYRIGHT
#   Copyright (C) 1999-2000 Simon Matthews.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#------------------------------------------------------------------------------
#
# $Id$
# 
#==============================================================================

package Template::Plugin::DBI;

require 5.004;

use strict;
use Template::Plugin;
use Template::Exception;
use DBI;

use vars qw( $VERSION $DEBUG );
use base qw( Template::Plugin );

#$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/) - 1;
$VERSION = 1.03;
$DEBUG   = 0 unless defined $DEBUG;


#------------------------------------------------------------------------
# new($context, @params)
#
# Constructor which returns a reference to a new DBI plugin object. 
# A connection string (dsn), user name and password may be passed as
# positional arguments or a hash array of connection parameters can be
# passed to initialise a connection.  Otherwise, an unconnected DBI 
# plugin object is returned.
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $self    = ref $class ? $class : bless { 
	_CONTEXT => $context, 
    }, $class;

    $self->connect(@_) if @_;

    return $self;
}


#------------------------------------------------------------------------
# connect( $data_source, $username, $password, $attributes )
# connect( { data_source => 'dbi:driver:database' 
#	     username    => 'foo' 
#	     password    => 'bar' } )
#
# Opens a DBI connection for the plugin. 
#------------------------------------------------------------------------

sub connect {
    my $self   = shift;
    my $params = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my ($dbh, $dsn, $user, $pass);

    # set debug flag
    $DEBUG = $params->{ debug } if exists $params->{ debug };

    # fetch 'dbh' named paramater or use positional arguments or named 
    # parameters to specify 'dsn', 'user' and 'pass'

    if ($dbh = $params->{ dbh }) {
	# disconnect any existing database handle that we previously opened
	$self->{ _DBH }->disconnect()
	    if $self->{ _DBH } && $self->{ _DBH_CONNECT };

	# store new dbh but leave _DBH_CONNECT false to prevent us 
	# from automatically closing it in the future
	$self->{ _DBH } = $dbh;
	$self->{ _DBH_CONNECT } = 0;
    }
    else {
	$dsn = shift 
	     || $params->{ data_source } 
	     || $params->{ connect } 
	     || $params->{ dsn }
	     || return $self->_throw('data source not defined');
	$user = shift
	     || $params->{ username } 
	     || $params->{ user } 
	     || '';
	$pass = shift 
	     || $params->{ password } 
	     || $params->{ pass } 
	     || '';

	# reuse existing database handle if connection params match
	my $connect = join(':', $dsn, $user, $pass);
	return ''
	    if $self->{ _DBH } && $self->{ _DBH_CONNECT } eq $connect;
	
	# otherwise disconnect any existing database handle that we opened
	$self->{ _DBH }->disconnect()
	    if $self->{ _DBH } && $self->{ _DBH_CONNECT };
	    
	# open new connection
	$params->{ PrintError } = 0 
	    unless defined $params->{ PrintError };
	$self->{ _DBH } = DBI->connect( $dsn, $user, $pass, $params )
	    || return $self->_throw("DBI connect failed: $DBI::errstr");

	# store the connection parameters
	$self->{ _DBH_CONNECT } = $connect;
    }

    return '';
}

#------------------------------------------------------------------------
# _connect()
#
# An alias for connect, provided for backwards compatability
#------------------------------------------------------------------------

sub _connect {
    my $self = shift;
    unless (@_) {
	return $self->{ _DBH } || $self->_throw('no current dbh');
    }
    return $self->connect(@_);
}


#------------------------------------------------------------------------
# disconnect()
#
# Disconnects the current active database connection.
#------------------------------------------------------------------------

sub disconnect {
    my $self = shift;
    $self->{ _DBH }->disconnect() 
	if $self->{ _DBH };
    delete $self->{ _DBH };
    return '';
}


#------------------------------------------------------------------------
# prepare($sql)
#
# Prepare a query and store the live statement handle internally for
# subsequent execute() calls.
#------------------------------------------------------------------------

sub prepare {
    my $self = shift;
    my $sql  = shift || return undef;

    my $dbh = $self->{ _DBH }
	|| return $self->_throw('no connection');

    my $sth = $dbh->prepare($sql) 
	|| return $self->_throw("DBI prepare failed: $DBI::errstr");
    
    # create wrapper object around handle to return to template client
    $self->{ _STH } = Template::Plugin::DBI::Query->new($sth);
}


#------------------------------------------------------------------------
# execute()
# 
# Calls execute() on the most recent statement created via prepare().
#------------------------------------------------------------------------

sub execute {
    my $self = shift;

    my $sth = $self->{ _STH } 
	|| return $self->_throw('no query prepared');

    $sth->execute(@_) 
}

    
#------------------------------------------------------------------------
# query($sql, @params)
#
# Prepares and executes a SQL query.
#------------------------------------------------------------------------

sub query {
    my $self = shift;
    my $sql  = shift;
    my $sth  = $self->prepare($sql);

    $sth->execute(@_);
}


#------------------------------------------------------------------------
# do($sql)
#
# Prepares and executes a SQL statement.
#------------------------------------------------------------------------

sub do {
    my $self = shift;
    my $sql  = shift || return '';

    # get a database connection
    my $dbh = $self->{ _DBH }
	|| return $self->_throw('no connection');

    return $dbh->do($sql) 
	|| $self->_throw("DBI do failed: $DBI::errstr");
}


#------------------------------------------------------------------------
# quote($value [, $data_type ])
#
# Returns a quoted string (correct for the connected database) from the 
# value passed in.
#------------------------------------------------------------------------

sub quote {
    my $self = shift;

    my $dbh = $self->{ _DBH }
	|| return $self->_throw('no connection');

    $dbh->quote(@_);
}


#------------------------------------------------------------------------
# DESTROY
#
# Called automatically when the plugin object goes out of scope to 
# disconnect the database handle cleanly
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;
    $self->{ _DBH }->disconnect() if $self->{ _DBH };
}


#------------------------------------------------------------------------
# _throw($error)
#
# Raise an error by throwing it via die() as a Template::Exception 
# object of type 'DBI'.
#------------------------------------------------------------------------

sub _throw {
    my $self  = shift;
    my $error = shift || die "DBI throw() called without an error string\n";

    # throw error as DBI exception
    die Template::Exception->new('DBI', $error);
}


#========================================================================
# Template::Plugin::DBI::Query
#========================================================================

package Template::Plugin::DBI::Query;
use vars qw( $DEBUG );

*DEBUG = \$Template::Plugin::DBI::DEBUG;


sub new {
    my ($class, $sth) = @_;
    bless \$sth, $class;
}

sub execute {
    my $self = shift;

    $$self->execute(@_) 
	|| return Template::Plugin::DBI->_throw("execute failed: $DBI::errstr");

    Template::Plugin::DBI::Iterator->new($$self);
}

sub DESTROY {
    my $self = shift;
    $$self->finish();
}


#========================================================================
# Template::Plugin::DBI::Iterator;
#========================================================================

package Template::Plugin::DBI::Iterator;

use Template::Iterator;
use base qw( Template::Iterator );
use vars qw( $DEBUG );

*DEBUG = \$Template::Plugin::DBI::DEBUG;


sub new {
    my ($class, $sth, $params) = @_;
    my $self = bless { 
	_STH => $sth,
    }, $class;
    
    return $self;
}


#------------------------------------------------------------------------
# get_first()
#
# Initialises iterator to read from statement handle.  We maintain a 
# one-record lookahead buffer to allow us to detect if the current 
# record is the last in the series.
#------------------------------------------------------------------------

sub get_first {
    my $self = shift;

    # set some status variables into $self
    @$self{ qw(  PREV   ITEM FIRST LAST COUNT INDEX ) } 
            = ( undef, undef,    2,   0,    0,   -1 );

    # support 'number' as an alias for 'count' for backwards compatability
    $self->{ NUMBER  } = 0;

    # NOTE: 'size' and 'max' should also be supported.  This should 
    # probably trigger a get_all() to determine the size of the result
    # set, but for now it's unsupported
    $self->{ SIZE   } = 'unknown';
    $self->{ MAX    } = 'unknown';

    print STDERR "get_first() called\n" if $DEBUG;

    # get the first row
    $self->_fetchrow();

    print STDERR "get_first() calling get_next()\n" if $DEBUG;

    return $self->get_next();
}


#------------------------------------------------------------------------
# get_next()
#
# Called to read remaining result records from statement handle.
#------------------------------------------------------------------------

sub get_next {
    my $self = shift;
    my ($data, $fixup);

    # increment the 'index' and 'count' counts
    $self->{ INDEX  }++;
    $self->{ COUNT  }++;
    $self->{ NUMBER }++;   # 'number' is old name for 'count'

    # decrement the 'first-record' flag
    $self->{ FIRST }-- if $self->{ FIRST };

    # we should have a row already cache in NEXT
    return (undef, Template::Constants::STATUS_DONE)
	unless $data = $self->{ NEXT };

    # set PREV to be current ITEM from last iteration
    $self->{ PREV } = $self->{ ITEM };

    # look ahead to the next row so that the rowcache is refilled
    $self->_fetchrow();

    # NOTE: this needs fixing, flushing or documenting...
    # process any fixup handlers on the data
    if (defined($fixup = $self->{ _FIXUP })) {
	foreach (keys %$fixup) {
	    $data->{ $_ } = &{ $fixup->{$_} }($data->{ $_ })
		if exists $data->{ $_ };
	}
    }

    $self->{ ITEM } = $data;
    return ($data, Template::Constants::STATUS_OK);
}



#------------------------------------------------------------------------
# _fetchrow()
#
# Retrieve a record from the statement handle and store in row cache.
#------------------------------------------------------------------------

sub _fetchrow {
    my $self = shift;
    my $sth  = $self->{ _STH };

    my $data = $sth->fetchrow_hashref() || do {
	$self->{ LAST } = 1;
	$self->{ NEXT } = undef;
	$sth->finish();
	return;
    };
    $self->{ NEXT } = $data;
    return;
}

1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Plugin::DBI - Interface to the DBI module

=head1 SYNOPSIS

    # use positional arguments...
    [% USE DBI('dbi:driver:database', 'username', 'password') %]

    # ...or named parameters...
    [% USE DBI(data_source = 'dbi:driver:database',
               username    = 'username', 
               password    = 'password') %]

    # ...or call connect() explicitly
    [% USE DBI %]
    [% DBI.connect(dsn, user, pass) %]

    [% FOREACH item = DBI.query( 'SELECT rows FROM table' ) %]
       Here's some row data: [% item.field %]
    [% END %]

    [% query = DBI.prepare('SELECT * FROM user WHERE manager = ?') %]
    [% FOREACH user = query.execute('sam') %]
       ...
    [% FOREACH user = query.execute('abw') %]
       ...

    [% IF DBI.do("DELETE FROM users WHERE uid = 'sam'") %]
       Oh No!  The user was deleted!
    [% END %]

=head1 DESCRIPTION

This Template Toolkit plugin module provides an interface to the Perl
DBI/DBD modules, allowing you to integrate SQL queries into your template
documents.

A DBI plugin object can be created as follows:

    [% USE DBI %]

This creates an uninitialised DBI object.  You can then open a connection
to a database using the connect() method.

    [% DBI.connect('dbi:driver:database', 'username', 'password') %]

The DBI connection can be opened when the plugin is created by passing
arguments to the constructor, called from the USE directive.

    [% USE DBI('dbi:driver:database', 'username', 'password') %]

You can also use named parameters to provide the data source connection 
string, user name and password.

    [% USE DBI(data_source => 'dbi:driver:database',
               username    => 'username',
               password    => 'password')  %]

Lazy Template hackers may prefer to use 'dsn' or 'connect' as a shorthand
form of the 'data_source' parameter, and 'user' and 'pass' as shorthand
forms of 'username' and 'password', respectively.

    [% USE DBI(connect => 'dbi:driver:database',
               user    => 'username',
               pass    => 'password')  %]

Any additional DBI attributes can be specified as named parameters.
The 'PrintError' attribute defaults to 0 unless explicitly set true.

    [% USE DBI(dsn, user, pass, ChopBlanks=1) %]

Methods can then be called on the plugin object using the familiar dotted
notation:

    [% FOREACH item = DBI.query( 'SELECT rows FROM table' ) %]
       Here's some row data: [% item.field %]
    [% END %]

See L<OBJECT METHODS> below for further details of the methods available.

An alternate variable name can be provided for the plugin as per regular
Template Toolkit syntax:

    [% USE mydb = DBI('dbi:driver:database','username','password') %]

    [% FOREACH item = mydb.query( 'SELECT rows FROM table' ) %]
       ...

You can also specify the DBI plugin name in lower case if you prefer:

    [% USE dbi(dsn, user, pass) %]
    [% FOREACH item = dbi.query( 'SELECT rows FROM table' ) %]
       ...

The disconnect() method can be called to explicitly disconnect the
current database, but this generally shouldn't be necessary as it is
called automatically when the plugin goes out of scope.  You can call
connect() at any time to open a connection to another database.  The
previous connection will be closed automatically.

=head1 OBJECT METHODS

=head2 connect($data_source, $username, $password)

Establishes a database connection.  This method accepts both positional 
and named parameter syntax.  e.g. 

    [% DBI.connect(data_source, username, password) %]
    [% DBI.connect(data_source = 'dbi:driver:database'
                   username    = 'foo' 
                   password    = 'bar' ) %]

The connect method allows you to connect to a data source explicitly.
It can also be used to reconnect an exisiting object to a different
data source.

=head2 query($sql)

This method submits an SQL query to the database and creates an iterator 
object to return the results.  This may be used directly in a FOREACH 
directive as shown below.  Data is automatically fetched a row at a time
from the query result set as required for memory efficiency.

    [% FOREACH row = DBI.query('select * from users') %]
       Each [% row.whatever %] can be processed here
    [% END %]

=head2 prepare($sql)

Prepare a query for later execution.  This returns a compiled query
object (of the Template::Plugin::DBI::Query class) on which the
execute() method can subsequently be called.

    [% query = DBI.prepare('SELECT * FROM users WHERE id = ?') %]

=head2 execute(@args)

Execute a previously prepared query.  This method should be called on
the query object returned by the prepare() method.  Returns an
iterator object which can be used directly in a FOREACH directive.

    [% query = DBI.prepare('SELECT * FROM users WHERE manager = ?') %]

    [% FOREACH user = query.execute('sam') %]
       [% user.name %]
    [% END %]

    [% FOREACH user = query.execute('sam') %]
       [% user.name %]
    [% END %]

=head2 do($sql)

The do() method executes a sql statement from which no records are
returned.  It will return true if the statement was successful

    [% IF DBI.do("DELETE FROM users WHERE uid = 'sam'") %]
       The user was successfully deleted.
    [% END %]

=head2 quote($value, $type)

Calls the quote() method on the underlying DBI handle to quote the value
specified in the appropriate manner for its type.

=head2 disconnect()

Disconnects the current database.

=head1 PRE-REQUISITES

Perl 5.005, Template-Toolkit 2.00, DBI 1.02

=head1 AUTHORS

The DBI plugin was written by Simon A Matthews,
E<lt>sam@knowledgepool.comE<gt>, with contributions from Andy Wardley
E<lt>abw@kfs.orgE<gt>.

=head1 HISTORY

=over 4

=item 1.01  2000/11/03  abw

Modified connect method to pass all named arguments to DBI.  e.g.

    [% USE DBI(dsn, user, pass, ChopBlanks=1) %]

=item 1.02  2000/11/14  abw

Added prev() and next() methods to Template::Plugin::DBI:Iterator to
return the previous and next items in the iteration set or undef if
not available.

=item 1.03  2000/11/31  sam

Added _connect method to Plugin::DBI for backwards compatability with code 
from version 1 of Template that subclassed the plugin

Changed the new method on the DBI plugin so that it checks to see if it is
being called by a subclassed object.  

Fixed the return value in the DBI plugin when connect is called more than
once in the lifetime of the plugin.

=back

=head1 COPYRIGHT

Copyright (C) 1999-2000 Simon Matthews.  All Rights Reserved

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<CPAN::DBI|CPAN::DBI>

