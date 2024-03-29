package C4::Context;
# Copyright 2002 Katipo Communications
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD $context @context_stack);

BEGIN {
	if ($ENV{'HTTP_USER_AGENT'})	{
		require CGI::Carp;
        # FIXME for future reference, CGI::Carp doc says
        #  "Note that fatalsToBrowser does not work with mod_perl version 2.0 and higher."
		import CGI::Carp qw(fatalsToBrowser);
			sub handle_errors {
			    my $msg = shift;
			    my $debug_level;
			    eval {C4::Context->dbh();};
			    if ($@){
				$debug_level = 1;
			    } 
			    else {
				$debug_level =  C4::Context->preference("DebugLevel");
			    }

                print q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
                            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
                       <html lang="en" xml:lang="en"  xmlns="http://www.w3.org/1999/xhtml">
                       <head><title>Koha Error</title></head>
                       <body>
                );
				if ($debug_level eq "2"){
					# debug 2 , print extra info too.
					my %versions = get_versions();

		# a little example table with various version info";
					print "
						<h1>Koha error</h1>
						<p>The following fatal error has occurred:</p> 
                        <pre><code>$msg</code></pre>
						<table>
						<tr><th>Apache</th><td>  $versions{apacheVersion}</td></tr>
						<tr><th>Koha</th><td>    $versions{kohaVersion}</td></tr>
						<tr><th>Koha DB</th><td> $versions{kohaDbVersion}</td></tr>
						<tr><th>MySQL</th><td>   $versions{mysqlVersion}</td></tr>
						<tr><th>OS</th><td>      $versions{osVersion}</td></tr>
						<tr><th>Perl</th><td>    $versions{perlVersion}</td></tr>
						</table>";

				} elsif ($debug_level eq "1"){
					print "
						<h1>Koha error</h1>
						<p>The following fatal error has occurred:</p> 
                        <pre><code>$msg</code></pre>";
				} else {
					print "<p>production mode - trapped fatal error</p>";
				}       
                print "</body></html>";
			}
		#CGI::Carp::set_message(\&handle_errors);
		## give a stack backtrace if KOHA_BACKTRACES is set
		## can't rely on DebugLevel for this, as we're not yet connected
		if ($ENV{KOHA_BACKTRACES}) {
			$main::SIG{__DIE__} = \&CGI::Carp::confess;
		}
    }  	# else there is no browser to send fatals to!
	$VERSION = '3.00.00.036';
}

use DBI;
use ZOOM;
use XML::Simple;
use C4::Boolean;
use C4::Debug;
use POSIX ();

=head1 NAME

C4::Context - Maintain and manipulate the context of a Koha script

=head1 SYNOPSIS

  use C4::Context;

  use C4::Context("/path/to/koha-conf.xml");

  $config_value = C4::Context->config("config_variable");

  $koha_preference = C4::Context->preference("preference");

  $db_handle = C4::Context->dbh;

  $Zconn = C4::Context->Zconn;

  $stopwordhash = C4::Context->stopwords;

=head1 DESCRIPTION

When a Koha script runs, it makes use of a certain number of things:
configuration settings in F</etc/koha/koha-conf.xml>, a connection to the Koha
databases, and so forth. These things make up the I<context> in which
the script runs.

This module takes care of setting up the context for a script:
figuring out which configuration file to load, and loading it, opening
a connection to the right database, and so forth.

Most scripts will only use one context. They can simply have

  use C4::Context;

at the top.

Other scripts may need to use several contexts. For instance, if a
library has two databases, one for a certain collection, and the other
for everything else, it might be necessary for a script to use two
different contexts to search both databases. Such scripts should use
the C<&set_context> and C<&restore_context> functions, below.

By default, C4::Context reads the configuration from
F</etc/koha/koha-conf.xml>. This may be overridden by setting the C<$KOHA_CONF>
environment variable to the pathname of a configuration file to use.

=head1 METHODS

=cut

#'
# In addition to what is said in the POD above, a Context object is a
# reference-to-hash with the following fields:
#
# config
#    A reference-to-hash whose keys and values are the
#    configuration variables and values specified in the config
#    file (/etc/koha/koha-conf.xml).
# dbh
#    A handle to the appropriate database for this context.
# dbh_stack
#    Used by &set_dbh and &restore_dbh to hold other database
#    handles for this context.
# Zconn
#     A connection object for the Zebra server

# Koha's main configuration file koha-conf.xml
# is searched for according to this priority list:
#
# 1. Path supplied via use C4::Context '/path/to/koha-conf.xml'
# 2. Path supplied in KOHA_CONF environment variable.
# 3. Path supplied in INSTALLED_CONFIG_FNAME, as long
#    as value has changed from its default of 
#    '__KOHA_CONF_DIR__/koha-conf.xml', as happens
#    when Koha is installed in 'standard' or 'single'
#    mode.
# 4. Path supplied in CONFIG_FNAME.
#
# The first entry that refers to a readable file is used.

use constant CONFIG_FNAME => "/etc/koha/koha-conf.xml";
                # Default config file, if none is specified
                
my $INSTALLED_CONFIG_FNAME = '__KOHA_CONF_DIR__/koha-conf.xml';
                # path to config file set by installer
                # __KOHA_CONF_DIR__ is set by rewrite-confg.PL
                # when Koha is installed in 'standard' or 'single'
                # mode.  If Koha was installed in 'dev' mode, 
                # __KOHA_CONF_DIR__ is *not* rewritten; instead
                # developers should set the KOHA_CONF environment variable 

$context = undef;        # Initially, no context is set
@context_stack = ();        # Initially, no saved contexts


=head2 KOHAVERSION

returns the kohaversion stored in kohaversion.pl file

=cut

sub KOHAVERSION {
    my $cgidir = C4::Context->intranetdir;

    # Apparently the GIT code does not run out of a CGI-BIN subdirectory
    # but distribution code does?  (Stan, 1jan08)
    if(-d $cgidir . "/cgi-bin"){
        my $cgidir .= "/cgi-bin";
    }
    
    do $cgidir."/kohaversion.pl" || die "NO $cgidir/kohaversion.pl";
    return kohaversion();
}
=head2 read_config_file

Reads the specified Koha config file. 

Returns an object containing the configuration variables. The object's
structure is a bit complex to the uninitiated ... take a look at the
koha-conf.xml file as well as the XML::Simple documentation for details. Or,
here are a few examples that may give you what you need:

The simple elements nested within the <config> element:

    my $pass = $koha->{'config'}->{'pass'};

The <listen> elements:

    my $listen = $koha->{'listen'}->{'biblioserver'}->{'content'};

The elements nested within the <server> element:

    my $ccl2rpn = $koha->{'server'}->{'biblioserver'}->{'cql2rpn'};

Returns undef in case of error.

=cut

sub read_config_file {		# Pass argument naming config file to read
    my $koha = XMLin(shift, keyattr => ['id'], forcearray => ['listen', 'server', 'serverinfo'], suppressempty => '');
    return $koha;			# Return value: ref-to-hash holding the configuration
}

# db_scheme2dbi
# Translates the full text name of a database into de appropiate dbi name
# 
sub db_scheme2dbi {
    my $name = shift;
    # for instance, we support only mysql, so don't care checking
    return "mysql";
    for ($name) {
# FIXME - Should have other databases. 
        if (/mysql/) { return("mysql"); }
        if (/Postgres|Pg|PostgresSQL/) { return("Pg"); }
        if (/oracle/) { return("Oracle"); }
    }
    return undef;         # Just in case
}

sub import {
    # Create the default context ($C4::Context::Context)
    # the first time the module is called
    # (a config file can be optionaly passed)

    # default context allready exists? 
    return if $context;

    # no ? so load it!
    my ($pkg,$config_file) = @_ ;
    my $new_ctx = __PACKAGE__->new($config_file);
    return unless $new_ctx;

    # if successfully loaded, use it by default
    $new_ctx->set_context;
    1;
}

=head2 new

  $context = new C4::Context;
  $context = new C4::Context("/path/to/koha-conf.xml");

Allocates a new context. Initializes the context from the specified
file, which defaults to either the file given by the C<$KOHA_CONF>
environment variable, or F</etc/koha/koha-conf.xml>.

C<&new> does not set this context as the new default context; for
that, use C<&set_context>.

=cut

#'
# Revision History:
# 2004-08-10 A. Tarallo: Added check if the conf file is not empty
sub new {
    my $class = shift;
    my $conf_fname = shift;        # Config file to load
    my $self = {};

    # check that the specified config file exists and is not empty
    undef $conf_fname unless 
        (defined $conf_fname && -s $conf_fname);
    # Figure out a good config file to load if none was specified.
    if (!defined($conf_fname))
    {
        # If the $KOHA_CONF environment variable is set, use
        # that. Otherwise, use the built-in default.
        if (exists $ENV{"KOHA_CONF"} and $ENV{'KOHA_CONF'} and -s  $ENV{"KOHA_CONF"}) {
            $conf_fname = $ENV{"KOHA_CONF"};
        } elsif ($INSTALLED_CONFIG_FNAME !~ /__KOHA_CONF_DIR/ and -s $INSTALLED_CONFIG_FNAME) {
            # NOTE: be careful -- don't change __KOHA_CONF_DIR in the above
            # regex to anything else -- don't want installer to rewrite it
            $conf_fname = $INSTALLED_CONFIG_FNAME;
        } elsif (-s CONFIG_FNAME) {
            $conf_fname = CONFIG_FNAME;
        } else {
            warn "unable to locate Koha configuration file koha-conf.xml";
            return undef;
        }
    }
        # Load the desired config file.
    $self = read_config_file($conf_fname);
    $self->{"config_file"} = $conf_fname;
    
    warn "read_config_file($conf_fname) returned undef" if !defined($self->{"config"});
    return undef if !defined($self->{"config"});

    $self->{"dbh"} = undef;        # Database handle
    $self->{"Zconn"} = undef;    # Zebra Connections
    $self->{"stopwords"} = undef; # stopwords list
    $self->{"marcfromkohafield"} = undef; # the hash with relations between koha table fields and MARC field/subfield
    $self->{"userenv"} = undef;        # User env
    $self->{"activeuser"} = undef;        # current active user
    $self->{"shelves"} = undef;

    bless $self, $class;
    return $self;
}

=head2 set_context

  $context = new C4::Context;
  $context->set_context();
or
  set_context C4::Context $context;

  ...
  restore_context C4::Context;

In some cases, it might be necessary for a script to use multiple
contexts. C<&set_context> saves the current context on a stack, then
sets the context to C<$context>, which will be used in future
operations. To restore the previous context, use C<&restore_context>.

=cut

#'
sub set_context
{
    my $self = shift;
    my $new_context;    # The context to set

    # Figure out whether this is a class or instance method call.
    #
    # We're going to make the assumption that control got here
    # through valid means, i.e., that the caller used an instance
    # or class method call, and that control got here through the
    # usual inheritance mechanisms. The caller can, of course,
    # break this assumption by playing silly buggers, but that's
    # harder to do than doing it properly, and harder to check
    # for.
    if (ref($self) eq "")
    {
        # Class method. The new context is the next argument.
        $new_context = shift;
    } else {
        # Instance method. The new context is $self.
        $new_context = $self;
    }

    # Save the old context, if any, on the stack
    push @context_stack, $context if defined($context);

    # Set the new context
    $context = $new_context;
}

=head2 restore_context

  &restore_context;

Restores the context set by C<&set_context>.

=cut

#'
sub restore_context
{
    my $self = shift;

    if ($#context_stack < 0)
    {
        # Stack underflow.
        die "Context stack underflow";
    }

    # Pop the old context and set it.
    $context = pop @context_stack;

    # FIXME - Should this return something, like maybe the context
    # that was current when this was called?
}

=head2 config

  $value = C4::Context->config("config_variable");

  $value = C4::Context->config_variable;

Returns the value of a variable specified in the configuration file
from which the current context was created.

The second form is more compact, but of course may conflict with
method names. If there is a configuration variable called "new", then
C<C4::Config-E<gt>new> will not return it.

=cut

sub _common_config ($$) {
	my $var = shift;
	my $term = shift;
    return undef if !defined($context->{$term});
       # Presumably $self->{$term} might be
       # undefined if the config file given to &new
       # didn't exist, and the caller didn't bother
       # to check the return value.

    # Return the value of the requested config variable
    return $context->{$term}->{$var};
}

sub config {
	return _common_config($_[1],'config');
}
sub zebraconfig {
	return _common_config($_[1],'server');
}
sub ModZebrations {
	return _common_config($_[1],'serverinfo');
}

=head2 preference

  $sys_preference = C4::Context->preference('some_variable');

Looks up the value of the given system preference in the
systempreferences table of the Koha database, and returns it. If the
variable is not set or does not exist, undef is returned.

In case of an error, this may return 0.

Note: It is impossible to tell the difference between system
preferences which do not exist, and those whose values are set to NULL
with this method.

=cut

# FIXME: running this under mod_perl will require a means of
# flushing the caching mechanism.

my %sysprefs;

sub preference {
    my $self = shift;
    my $var  = shift;                          # The system preference to return

    if (exists $sysprefs{$var}) {
        return $sysprefs{$var};
    }

    my $dbh  = C4::Context->dbh or return 0;

    # Look up systempreferences.variable==$var
    my $sql = <<'END_SQL';
        SELECT    value
        FROM    systempreferences
        WHERE    variable=?
        LIMIT    1
END_SQL
    $sysprefs{$var} = $dbh->selectrow_array( $sql, {}, $var );
    return $sysprefs{$var};
}

sub boolean_preference ($) {
    my $self = shift;
    my $var = shift;        # The system preference to return
    my $it = preference($self, $var);
    return defined($it)? C4::Boolean::true_p($it): undef;
}

=head2 clear_syspref_cache

  C4::Context->clear_syspref_cache();

cleans the internal cache of sysprefs. Please call this method if
you update the systempreferences table. Otherwise, your new changes
will not be seen by this process.

=cut

sub clear_syspref_cache {
    %sysprefs = ();
}

=head2 set_preference

  C4::Context->set_preference( $variable, $value );

This updates a preference's value both in the systempreferences table and in
the sysprefs cache.

=cut

sub set_preference {
    my $self = shift;
    my $var = shift;
    my $value = shift;

    my $dbh = C4::Context->dbh or return 0;

    my $type = $dbh->selectrow_array( "SELECT type FROM systempreferences WHERE variable = ?", {}, $var );

    $value = 0 if ( $type && $type eq 'YesNo' && $value eq '' );

    my $sth = $dbh->prepare( "
      INSERT INTO systempreferences
        ( variable, value )
        VALUES( ?, ? )
        ON DUPLICATE KEY UPDATE value = VALUES(value)
    " );

    $sth->execute( $var, $value );
    $sth->finish;
}

# AUTOLOAD
# This implements C4::Config->foo, and simply returns
# C4::Context->config("foo"), as described in the documentation for
# &config, above.

# FIXME - Perhaps this should be extended to check &config first, and
# then &preference if that fails. OTOH, AUTOLOAD could lead to crappy
# code, so it'd probably be best to delete it altogether so as not to
# encourage people to use it.
sub AUTOLOAD
{
    my $self = shift;

    $AUTOLOAD =~ s/.*:://;        # Chop off the package name,
                    # leaving only the function name.
    return $self->config($AUTOLOAD);
}

=head2 Zconn

  $Zconn = C4::Context->Zconn

Returns a connection to the Zebra database for the current
context. If no connection has yet been made, this method 
creates one and connects.

C<$self> 

C<$server> one of the servers defined in the koha-conf.xml file

C<$async> whether this is a asynchronous connection

C<$auth> whether this connection has rw access (1) or just r access (0 or NULL)


=cut

sub Zconn {
    my $self=shift;
    my $server=shift;
    my $async=shift;
    my $auth=shift;
    my $piggyback=shift;
    my $syntax=shift;
    if ( defined($context->{"Zconn"}->{$server}) && (0 == $context->{"Zconn"}->{$server}->errcode()) ) {
        return $context->{"Zconn"}->{$server};
    # No connection object or it died. Create one.
    }else {
        # release resources if we're closing a connection and making a new one
        # FIXME: this needs to be smarter -- an error due to a malformed query or
        # a missing index does not necessarily require us to close the connection
        # and make a new one, particularly for a batch job.  However, at
        # first glance it does not look like there's a way to easily check
        # the basic health of a ZOOM::Connection
        $context->{"Zconn"}->{$server}->destroy() if defined($context->{"Zconn"}->{$server});

        $context->{"Zconn"}->{$server} = &_new_Zconn($server,$async,$auth,$piggyback,$syntax);
        return $context->{"Zconn"}->{$server};
    }
}

=head2 _new_Zconn

$context->{"Zconn"} = &_new_Zconn($server,$async);

Internal function. Creates a new database connection from the data given in the current context and returns it.

C<$server> one of the servers defined in the koha-conf.xml file

C<$async> whether this is a asynchronous connection

C<$auth> whether this connection has rw access (1) or just r access (0 or NULL)

=cut

sub _new_Zconn {
    my ($server,$async,$auth,$piggyback,$syntax) = @_;

    my $tried=0; # first attempt
    my $Zconn; # connection object
    $server = "biblioserver" unless $server;
    $syntax = "usmarc" unless $syntax;

    my $host = $context->{'listen'}->{$server}->{'content'};
    my $servername = $context->{"config"}->{$server};
    my $user = $context->{"serverinfo"}->{$server}->{"user"};
    my $password = $context->{"serverinfo"}->{$server}->{"password"};
 $auth = 1 if($user && $password);   
    retry:
    eval {
        # set options
        my $o = new ZOOM::Options();
        $o->option(user=>$user) if $auth;
        $o->option(password=>$password) if $auth;
        $o->option(async => 1) if $async;
        $o->option(count => $piggyback) if $piggyback;
        $o->option(cqlfile=> $context->{"server"}->{$server}->{"cql2rpn"});
        $o->option(cclfile=> $context->{"serverinfo"}->{$server}->{"ccl2rpn"});
        $o->option(preferredRecordSyntax => $syntax);
        $o->option(elementSetName => "F"); # F for 'full' as opposed to B for 'brief'
        $o->option(databaseName => ($servername?$servername:"biblios"));

        # create a new connection object
        $Zconn= create ZOOM::Connection($o);

        # forge to server
        $Zconn->connect($host, 0);

        # check for errors and warn
        if ($Zconn->errcode() !=0) {
            warn "something wrong with the connection: ". $Zconn->errmsg();
        }

    };
#     if ($@) {
#         # Koha manages the Zebra server -- this doesn't work currently for me because of permissions issues
#         # Also, I'm skeptical about whether it's the best approach
#         warn "problem with Zebra";
#         if ( C4::Context->preference("ManageZebra") ) {
#             if ($@->code==10000 && $tried==0) { ##No connection try restarting Zebra
#                 $tried=1;
#                 warn "trying to restart Zebra";
#                 my $res=system("zebrasrv -f $ENV{'KOHA_CONF'} >/koha/log/zebra-error.log");
#                 goto "retry";
#             } else {
#                 warn "Error ", $@->code(), ": ", $@->message(), "\n";
#                 $Zconn="error";
#                 return $Zconn;
#             }
#         }
#     }
    return $Zconn;
}

# _new_dbh
# Internal helper function (not a method!). This creates a new
# database connection from the data given in the current context, and
# returns it.
sub _new_dbh
{

    ## $context
    ## correct name for db_schme        
    my $db_driver;
    if ($context->config("db_scheme")){
        $db_driver=db_scheme2dbi($context->config("db_scheme"));
    }else{
        $db_driver="mysql";
    }

    my $db_name   = $context->config("database");
    my $db_host   = $context->config("hostname");
    my $db_port   = $context->config("port") || '';
    my $db_user   = $context->config("user");
    my $db_passwd = $context->config("pass");
    # MJR added or die here, as we can't work without dbh
    my $dbh= DBI->connect("DBI:$db_driver:dbname=$db_name;host=$db_host;port=$db_port",
    $db_user, $db_passwd, {'RaiseError' => $ENV{DEBUG}?1:0 }) or die $DBI::errstr;
	my $tz = $ENV{TZ};
    if ( $db_driver eq 'mysql' ) { 
        # Koha 3.0 is utf-8, so force utf8 communication between mySQL and koha, whatever the mysql default config.
        # this is better than modifying my.cnf (and forcing all communications to be in utf8)
        $dbh->{'mysql_enable_utf8'}=1; #enable
        $dbh->do("set NAMES 'utf8'");
        ($tz) and $dbh->do(qq(SET time_zone = "$tz"));
    }
    elsif ( $db_driver eq 'Pg' ) {
	    $dbh->do( "set client_encoding = 'UTF8';" );
        ($tz) and $dbh->do(qq(SET TIME ZONE = "$tz"));
    }
    return $dbh;
}

=head2 dbh

  $dbh = C4::Context->dbh;

Returns a database handle connected to the Koha database for the
current context. If no connection has yet been made, this method
creates one, and connects to the database.

This database handle is cached for future use: if you call
C<C4::Context-E<gt>dbh> twice, you will get the same handle both
times. If you need a second database handle, use C<&new_dbh> and
possibly C<&set_dbh>.

=cut

#'
sub dbh
{
    my $self = shift;
    my $sth;

    if (defined($context->{"dbh"}) && $context->{"dbh"}->ping()) {
	return $context->{"dbh"};
    }

    # No database handle or it died . Create one.
    $context->{"dbh"} = &_new_dbh();

    return $context->{"dbh"};
}

=head2 new_dbh

  $dbh = C4::Context->new_dbh;

Creates a new connection to the Koha database for the current context,
and returns the database handle (a C<DBI::db> object).

The handle is not saved anywhere: this method is strictly a
convenience function; the point is that it knows which database to
connect to so that the caller doesn't have to know.

=cut

#'
sub new_dbh
{
    my $self = shift;

    return &_new_dbh();
}

=head2 set_dbh

  $my_dbh = C4::Connect->new_dbh;
  C4::Connect->set_dbh($my_dbh);
  ...
  C4::Connect->restore_dbh;

C<&set_dbh> and C<&restore_dbh> work in a manner analogous to
C<&set_context> and C<&restore_context>.

C<&set_dbh> saves the current database handle on a stack, then sets
the current database handle to C<$my_dbh>.

C<$my_dbh> is assumed to be a good database handle.

=cut

#'
sub set_dbh
{
    my $self = shift;
    my $new_dbh = shift;

    # Save the current database handle on the handle stack.
    # We assume that $new_dbh is all good: if the caller wants to
    # screw himself by passing an invalid handle, that's fine by
    # us.
    push @{$context->{"dbh_stack"}}, $context->{"dbh"};
    $context->{"dbh"} = $new_dbh;
}

=head2 restore_dbh

  C4::Context->restore_dbh;

Restores the database handle saved by an earlier call to
C<C4::Context-E<gt>set_dbh>.

=cut

#'
sub restore_dbh
{
    my $self = shift;

    if ($#{$context->{"dbh_stack"}} < 0)
    {
        # Stack underflow
        die "DBH stack underflow";
    }

    # Pop the old database handle and set it.
    $context->{"dbh"} = pop @{$context->{"dbh_stack"}};

    # FIXME - If it is determined that restore_context should
    # return something, then this function should, too.
}

=head2 marcfromkohafield

  $dbh = C4::Context->marcfromkohafield;

Returns a hash with marcfromkohafield.

This hash is cached for future use: if you call
C<C4::Context-E<gt>marcfromkohafield> twice, you will get the same hash without real DB access

=cut

#'
sub marcfromkohafield
{
    my $retval = {};

    # If the hash already exists, return it.
    return $context->{"marcfromkohafield"} if defined($context->{"marcfromkohafield"});

    # No hash. Create one.
    $context->{"marcfromkohafield"} = &_new_marcfromkohafield();

    return $context->{"marcfromkohafield"};
}

# _new_marcfromkohafield
# Internal helper function (not a method!). This creates a new
# hash with stopwords
sub _new_marcfromkohafield
{
    my $dbh = C4::Context->dbh;
    my $marcfromkohafield;
    my $sth = $dbh->prepare("select frameworkcode,kohafield,tagfield,tagsubfield from marc_subfield_structure where kohafield > ''");
    $sth->execute;
    while (my ($frameworkcode,$kohafield,$tagfield,$tagsubfield) = $sth->fetchrow) {
        my $retval = {};
        $marcfromkohafield->{$frameworkcode}->{$kohafield} = [$tagfield,$tagsubfield];
    }
    return $marcfromkohafield;
}

=head2 stopwords

  $dbh = C4::Context->stopwords;

Returns a hash with stopwords.

This hash is cached for future use: if you call
C<C4::Context-E<gt>stopwords> twice, you will get the same hash without real DB access

=cut

#'
sub stopwords
{
    my $retval = {};

    # If the hash already exists, return it.
    return $context->{"stopwords"} if defined($context->{"stopwords"});

    # No hash. Create one.
    $context->{"stopwords"} = &_new_stopwords();

    return $context->{"stopwords"};
}

# _new_stopwords
# Internal helper function (not a method!). This creates a new
# hash with stopwords
sub _new_stopwords
{
    my $dbh = C4::Context->dbh;
    my $stopwordlist;
    my $sth = $dbh->prepare("select word from stopwords");
    $sth->execute;
    while (my $stopword = $sth->fetchrow_array) {
        $stopwordlist->{$stopword} = uc($stopword);
    }
    $stopwordlist->{A} = "A" unless $stopwordlist;
    return $stopwordlist;
}

=head2 userenv

  C4::Context->userenv;

Retrieves a hash for user environment variables.

This hash shall be cached for future use: if you call
C<C4::Context-E<gt>userenv> twice, you will get the same hash without real DB access

=cut

#'
sub userenv {
    my $var = $context->{"activeuser"};
    return $context->{"userenv"}->{$var} if (defined $var and defined $context->{"userenv"}->{$var});
    # insecure=1 management
    if ($context->{"dbh"} && $context->preference('insecure') eq 'yes') {
        my %insecure;
        $insecure{flags} = '16382';
        $insecure{branchname} ='Insecure';
        $insecure{number} ='0';
        $insecure{cardnumber} ='0';
        $insecure{id} = 'insecure';
        $insecure{branch} = 'INS';
        $insecure{emailaddress} = 'test@mode.insecure.com';
        return \%insecure;
    } else {
        return;
    }
}

=head2 set_userenv

  C4::Context->set_userenv($usernum, $userid, $usercnum, $userfirstname, 
                  $usersurname, $userbranch, $userflags, $emailaddress);

Establish a hash of user environment variables.

set_userenv is called in Auth.pm

=cut

#'
sub set_userenv {
    my ($usernum, $userid, $usercnum, $userfirstname, $usersurname, $userbranch, $branchname, $userflags, $emailaddress, $branchprinter)= @_;
    my $var=$context->{"activeuser"};
    my $cell = {
        "number"     => $usernum,
        "id"         => $userid,
        "cardnumber" => $usercnum,
        "firstname"  => $userfirstname,
        "surname"    => $usersurname,
        #possibly a law problem
        "branch"     => $userbranch,
        "branchname" => $branchname,
        "flags"      => $userflags,
        "emailaddress"     => $emailaddress,
        "branchprinter"    => $branchprinter
    };
    $context->{userenv}->{$var} = $cell;
    return $cell;
}

sub set_shelves_userenv ($$) {
	my ($type, $shelves) = @_ or return undef;
	my $activeuser = $context->{activeuser} or return undef;
	$context->{userenv}->{$activeuser}->{barshelves} = $shelves if $type eq 'bar';
	$context->{userenv}->{$activeuser}->{pubshelves} = $shelves if $type eq 'pub';
	$context->{userenv}->{$activeuser}->{totshelves} = $shelves if $type eq 'tot';
}

sub get_shelves_userenv () {
	my $active;
	unless ($active = $context->{userenv}->{$context->{activeuser}}) {
		$debug and warn "get_shelves_userenv cannot retrieve context->{userenv}->{context->{activeuser}}";
		return undef;
	}
	my $totshelves = $active->{totshelves} or undef;
	my $pubshelves = $active->{pubshelves} or undef;
	my $barshelves = $active->{barshelves} or undef;
	return ($totshelves, $pubshelves, $barshelves);
}

=head2 _new_userenv

  C4::Context->_new_userenv($session);  # FIXME: This calling style is wrong for what looks like an _internal function

Builds a hash for user environment variables.

This hash shall be cached for future use: if you call
C<C4::Context-E<gt>userenv> twice, you will get the same hash without real DB access

_new_userenv is called in Auth.pm

=cut

#'
sub _new_userenv
{
    shift;  # Useless except it compensates for bad calling style
    my ($sessionID)= @_;
     $context->{"activeuser"}=$sessionID;
}

=head2 _unset_userenv

  C4::Context->_unset_userenv;

Destroys the hash for activeuser user environment variables.

=cut

#'

sub _unset_userenv
{
    my ($sessionID)= @_;
    undef $context->{"activeuser"} if ($context->{"activeuser"} eq $sessionID);
}


=head2 get_versions

  C4::Context->get_versions

Gets various version info, for core Koha packages, Currently called from carp handle_errors() sub, to send to browser if 'DebugLevel' syspref is set to '2'.

=cut

#'

# A little example sub to show more debugging info for CGI::Carp
sub get_versions {
    my %versions;
    $versions{kohaVersion}  = KOHAVERSION();
    $versions{kohaDbVersion} = C4::Context->preference('version');
    $versions{osVersion} = join(" ", POSIX::uname());
    $versions{perlVersion} = $];
    {
        no warnings qw(exec); # suppress warnings if unable to find a program in $PATH
        $versions{mysqlVersion}  = `mysql -V`;
        $versions{apacheVersion} = `httpd -v`;
        $versions{apacheVersion} = `httpd2 -v`            unless  $versions{apacheVersion} ;
        $versions{apacheVersion} = `apache2 -v`           unless  $versions{apacheVersion} ;
        $versions{apacheVersion} = `/usr/sbin/apache2 -v` unless  $versions{apacheVersion} ;
    }
    return %versions;
}


1;
__END__

=head1 ENVIRONMENT

=head2 C<KOHA_CONF>

Specifies the configuration file to read.

=head1 SEE ALSO

XML::Simple

=head1 AUTHORS

Andrew Arensburger <arensb at ooblick dot com>

Joshua Ferraro <jmf at liblime dot com>

=cut
