#
# ILS::Patron.pm
# 
# A Class for hiding the ILS's concept of the patron from the OpenSIP
# system
#

package ILS::Patron;

use strict;
use warnings;
use Exporter;
use Carp;

use Sys::Syslog qw(syslog);
use Data::Dumper;

use C4::Debug;
use C4::Context;
# use C4::Dates;
use C4::Koha;
use C4::Members;
use C4::Reserves;
use C4::Branch qw(GetBranchName);
use Digest::MD5 qw(md5_base64);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

BEGIN {
	$VERSION = 2.03;
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(invalid_patron);
}

our $kp;	# koha patron

sub new {
	my ($class, $patron_id) = @_;
    my $type = ref($class) || $class;
    my $self;
	$kp = GetMember(cardnumber=>$patron_id);
	$debug and warn "new Patron (GetMember): " . Dumper($kp);
    unless (defined $kp) {
		syslog("LOG_DEBUG", "new ILS::Patron(%s): no such patron", $patron_id);
		return undef;
	}
	$kp = GetMemberDetails(undef,$patron_id);
	$debug and warn "new Patron (GetMemberDetails): " . Dumper($kp);
	my $pw        = $kp->{password};  ### FIXME - md5hash -- deal with . 
	my $flags     = $kp->{flags};     # or warn "Warning: No flags from patron object for '$patron_id'"; 
	my $debarred  = $kp->{debarred};  # 1 if ($kp->{flags}->{DBARRED}->{noissues});
	$debug and warn sprintf("Debarred = %s : ", ($debarred||'undef')) . Dumper(%{$kp->{flags}});
    my ($day, $month, $year) = (localtime)[3,4,5];
    my $today    = sprintf '%04d-%02d-%02d', $year+1900, $month+1, $day;
    my $expired  = ($today gt $kp->{dateexpiry}) ? 1 : 0;
    if ($expired) {
        if ($kp->{opacnote} ) {
            $kp->{opacnote} .= q{ };
        }
        $kp->{opacnote} .= 'PATRON EXPIRED';
    }
	my %ilspatron;
	my $adr     = $kp->{streetnumber} || '';
	my $address = $kp->{address}      || ''; 
    my $dob     = $kp->{dateofbirth};
    $dob and $dob =~ s/-//g;    # YYYYMMDD
    my $dexpiry     = $kp->{dateexpiry};
    $dexpiry and $dexpiry =~ s/-//g;    # YYYYMMDD
	$adr .= ($adr && $address) ? " $address" : $address;
    my $fines_amount = $flags->{CHARGES}->{amount};
    $fines_amount = ($fines_amount and $fines_amount > 0) ? $fines_amount : 0;
    {
	no warnings;	# any of these $kp->{fields} being concat'd could be undef
    %ilspatron = (
        getmemberdetails_object => $kp,
        name => $kp->{firstname} . " " . $kp->{surname},
        id   => $kp->{cardnumber},    # to SIP, the id is the BARCODE, not userid
        password        => $pw,
        ptype           => $kp->{categorycode},     # 'A'dult.  Whatever.
        dateexpiry      => $dexpiry,
        dateexpiry_iso  => $kp->{dateexpiry},
        birthdate       => $dob,
        birthdate_iso   => $kp->{dateofbirth},
        branchcode      => $kp->{branchcode},
        library_name    => "",                      # only populated if needed, cached here
        borrowernumber  => $kp->{borrowernumber},
        address         => $adr,
        home_phone      => $kp->{phone},
        email_addr      => $kp->{email},
        charge_ok       => ( !$debarred && !$expired ),
        renew_ok        => ( !$debarred && !$expired ),
        recall_ok       => ( !$debarred && !$expired ),
        hold_ok         => ( !$debarred && !$expired ),
        card_lost       => ( $kp->{lost} || $kp->{gonenoaddress} || $flags->{LOST} ),
        claims_returned => 0,
        fines           => $fines_amount, # GetMemberAccountRecords($kp->{borrowernumber})
        fees            => 0,             # currently not distinct from fines
        recall_overdue  => 0,
        items_billed    => 0,
        screen_msg      => 'Greetings from Koha. ' . $kp->{opacnote},
        print_line      => '',
        items           => [],
        hold_items      => $flags->{WAITING}{itemlist},
        overdue_items   => $flags->{ODUES}{itemlist},
        fine_items      => [],
        recall_items    => [],
        unavail_holds   => [],
        inet            => ( !$debarred && !$expired ),
        expired         => $expired,
    );
    }
    $debug and warn "patron fines: $ilspatron{fines} ... amountoutstanding: $kp->{amountoutstanding} ... CHARGES->amount: $flags->{CHARGES}->{amount}";
	for (qw(EXPIRED CHARGES CREDITS GNA LOST DEBARRED NOTES)) {
		($flags->{$_}) or next;
        if ($_ ne 'NOTES' and $flags->{$_}->{message}) {
            $ilspatron{screen_msg} .= " -- " . $flags->{$_}->{message};  # show all but internal NOTES
        }
		if ($flags->{$_}->{noissues}) {
			foreach my $toggle (qw(charge_ok renew_ok recall_ok hold_ok inet)) {
				$ilspatron{$toggle} = 0;    # if we get noissues, disable everything
			}
		}
	}

    # FIXME: populate fine_items recall_items
#   $ilspatron{hold_items}    = (GetReservesFromBorrowernumber($kp->{borrowernumber},'F'));
	$ilspatron{unavail_holds} = [(GetReservesFromBorrowernumber($kp->{borrowernumber}))];
	$ilspatron{items} = GetPendingIssues($kp->{borrowernumber});
	$self = \%ilspatron;
	$debug and warn Dumper($self);
    syslog("LOG_DEBUG", "new ILS::Patron(%s): found patron '%s'", $patron_id,$self->{id});
    bless $self, $type;
    return $self;
}


# 0 means read-only
# 1 means read/write

my %fields = (
    id                      => 0,
    name                    => 0,
    address                 => 0,
    email_addr              => 0,
    home_phone              => 0,
    birthdate               => 0,
    birthdate_iso           => 0,
    dateexpiry              => 0,
    dateexpiry_iso          => 0,
    ptype                   => 0,
    charge_ok               => 0,   # for patron_status[0] (inverted)
    renew_ok                => 0,   # for patron_status[1] (inverted)
    recall_ok               => 0,   # for patron_status[2] (inverted)
    hold_ok                 => 0,   # for patron_status[3] (inverted)
    card_lost               => 0,   # for patron_status[4]
    recall_overdue          => 0,
    currency                => 1,
#   fee_limit               => 0,
    screen_msg              => 1,
    print_line              => 1,
    too_many_charged        => 0,   # for patron_status[5]
    too_many_overdue        => 0,   # for patron_status[6]
    too_many_renewal        => 0,   # for patron_status[7]
    too_many_claim_return   => 0,   # for patron_status[8]
    too_many_lost           => 0,   # for patron_status[9]
#   excessive_fines         => 0,   # for patron_status[10]
#   excessive_fees          => 0,   # for patron_status[11]
    recall_overdue          => 0,   # for patron_status[12]
    too_many_billed         => 0,   # for patron_status[13]
    inet                    => 0,   # EnvisionWare extension
    getmemberdetails_object => 0,
);

our $AUTOLOAD;

sub DESTROY {
    # be cool.  needed for AUTOLOAD(?)
}

sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) or croak "$self is not an object";
    my $name = $AUTOLOAD;

    $name =~ s/.*://;

    unless (exists $fields{$name}) {
		croak "Cannot access '$name' field of class '$class'";
    }

	if (@_) {
        $fields{$name} or croak "Field '$name' of class '$class' is READ ONLY.";
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}
}

sub check_password {
    my ($self, $pwd) = @_;
	my $md5pwd = $self->{password};
	# warn sprintf "check_password for %s: '%s' vs. '%s'",($self->{name}||''),($self->{password}||''),($pwd||'');
	(defined $pwd   ) or return 0;		# you gotta give me something (at least ''), or no deal
	(defined $md5pwd) or return($pwd eq '');	# if the record has a NULL password, accept '' as match
	return (md5_base64($pwd) eq $md5pwd);
}

# A few special cases, not in AUTOLOADed %fields
sub fee_amount {
    my $self = shift;
    return $self->{fines} || undef;
}

sub fines_amount {
    my $self = shift;
    return $self->fee_amount;
}

sub language {
    my $self = shift;
    return $self->{language} || '000'; # Unspecified
}

sub expired {
    my $self = shift;
    return $self->{expired};
}

#
# remove the hold on item item_id from my hold queue.
# return true if I was holding the item, false otherwise.
# 
sub drop_hold {
    my ($self, $item_id) = @_;
	$item_id or return undef;
	my $result = 0;
	foreach (qw(hold_items unavail_holds)) {
		$self->{$_} or next;
		for (my $i = 0; $i < scalar @{$self->{$_}}; $i++) {
			my $held_item = $self->{$_}[$i]->{item_id} or next;
			if ($held_item eq $item_id) {
				splice @{$self->{$_}}, $i, 1;
				$result++;
			}
		}
	}
    return $result;
}

# Accessor method for array_ref values, designed to get the "start" and "end" values
# from the SIP request.  Note those incoming values are 1-indexed, not 0-indexed.
#
sub x_items {
    my $self      = shift or return;
    my $array_var = shift or return;
    my ($start, $end) = @_;
	$self->{$array_var} or return [];
    $start = 1 unless defined($start);
    $end   = scalar @{$self->{$array_var}} unless defined($end);
    # syslog("LOG_DEBUG", "$array_var: start = %d, end = %d; items(%s)", $start, $end, join(', ', @{$self->{items}}));

    return [@{$self->{$array_var}}[$start-1 .. $end-1]];
}

#
# List of outstanding holds placed
#
sub hold_items {
    my $self = shift or return;
    return $self->x_items('hold_items', @_);
}

sub overdue_items {
    my $self = shift or return;
    return $self->x_items('overdue_items', @_);
}
sub charged_items {
    my $self = shift or return;
    return $self->x_items('items', @_);
}
sub fine_items {
    my $self = shift or return;
    return $self->x_items('fine_items', @_);
}
sub recall_items {
    my $self = shift or return;
    return $self->x_items('recall_items', @_);
}
sub unavail_holds {
    my $self = shift or return;
    return $self->x_items('unavail_holds', @_);
}

sub block {
    my ($self, $card_retained, $blocked_card_msg) = @_;
    foreach my $field ('charge_ok', 'renew_ok', 'recall_ok', 'hold_ok', 'inet') {
		$self->{$field} = 0;
    }
    $self->{screen_msg} = "Block feature not implemented";  # $blocked_card_msg || "Card Blocked.  Please contact library staff";
    # TODO: not really affecting patron record
    return $self;
}

sub enable {
    my $self = shift;
    foreach my $field ('charge_ok', 'renew_ok', 'recall_ok', 'hold_ok', 'inet') {
		$self->{$field} = 1;
    }
    syslog("LOG_DEBUG", "Patron(%s)->enable: charge: %s, renew:%s, recall:%s, hold:%s",
	   $self->{id}, $self->{charge_ok}, $self->{renew_ok},
	   $self->{recall_ok}, $self->{hold_ok});
    $self->{screen_msg} = "Enable feature not implemented."; # "All privileges restored.";   # TODO: not really affecting patron record
    return $self;
}

sub inet_privileges {
    my $self = shift;
    return $self->{inet} ? 'Y' : 'N';
}

sub fee_limit {
    # my $self = shift;
    return C4::Context->preference("noissuescharge") || 5;
}

sub excessive_fees {
    my $self = shift or return;
    return ($self->fee_amount and $self->fee_amount > $self->fee_limit);
}
sub excessive_fines {
    my $self = shift or return;
    return $self->excessive_fees;   # excessive_fines is the same thing as excessive_fees for Koha
}
    
sub library_name {
    my $self = shift;
    unless ($self->{library_name}) {
        $self->{library_name} = GetBranchName($self->{branchcode});
    }
    return $self->{library_name};
}
#
# Messages
#

sub invalid_patron {
    return "Please contact library staff";
}

sub charge_denied {
    return "Please contact library staff";
}

1;
__END__

=head1 EXAMPLES

  our %patron_example = (
		  djfiander => {
		      name => "David J. Fiander",
		      id => 'djfiander',
		      password => '6789',
		      ptype => 'A', # 'A'dult.  Whatever.
		      birthdate => '19640925',
		      address => '2 Meadowvale Dr. St Thomas, ON',
		      home_phone => '(519) 555 1234',
		      email_addr => 'djfiander@hotmail.com',
		      charge_ok => 1,
		      renew_ok => 1,
		      recall_ok => 0,
		      hold_ok => 1,
		      card_lost => 0,
		      claims_returned => 0,
		      fines => 100,
		      fees => 0,
		      recall_overdue => 0,
		      items_billed => 0,
		      screen_msg => '',
		      print_line => '',
		      items => [],
		      hold_items => [],
		      overdue_items => [],
		      fine_items => ['Computer Time'],
		      recall_items => [],
		      unavail_holds => [],
		      inet => 1,
		  },
  );

 From borrowers table:
+---------------------+--------------+------+-----+---------+----------------+
| Field               | Type         | Null | Key | Default | Extra          |
+---------------------+--------------+------+-----+---------+----------------+
| borrowernumber      | int(11)      | NO   | PRI | NULL    | auto_increment |
| cardnumber          | varchar(16)  | YES  | UNI | NULL    |                |
| surname             | mediumtext   | NO   |     | NULL    |                |
| firstname           | text         | YES  |     | NULL    |                |
| title               | mediumtext   | YES  |     | NULL    |                |
| othernames          | mediumtext   | YES  |     | NULL    |                |
| initials            | text         | YES  |     | NULL    |                |
| streetnumber        | varchar(10)  | YES  |     | NULL    |                |
| streettype          | varchar(50)  | YES  |     | NULL    |                |
| address             | mediumtext   | NO   |     | NULL    |                |
| address2            | text         | YES  |     | NULL    |                |
| city                | mediumtext   | NO   |     | NULL    |                |
| state               | mediumtext   | YES  |     | NULL    |                |
| zipcode             | varchar(25)  | YES  |     | NULL    |                |
| country             | text         | YES  |     | NULL    |                |
| email               | mediumtext   | YES  |     | NULL    |                |
| phone               | text         | YES  |     | NULL    |                |
| mobile              | varchar(50)  | YES  |     | NULL    |                |
| fax                 | mediumtext   | YES  |     | NULL    |                |
| emailpro            | text         | YES  |     | NULL    |                |
| phonepro            | text         | YES  |     | NULL    |                |
| B_streetnumber      | varchar(10)  | YES  |     | NULL    |                |
| B_streettype        | varchar(50)  | YES  |     | NULL    |                |
| B_address           | varchar(100) | YES  |     | NULL    |                |
| B_address2          | text         | YES  |     | NULL    |                |
| B_city              | mediumtext   | YES  |     | NULL    |                |
| B_state             | mediumtext   | YES  |     | NULL    |                |
| B_zipcode           | varchar(25)  | YES  |     | NULL    |                |
| B_country           | text         | YES  |     | NULL    |                |
| B_email             | text         | YES  |     | NULL    |                |
| B_phone             | mediumtext   | YES  |     | NULL    |                |
| dateofbirth         | date         | YES  |     | NULL    |                |
| branchcode          | varchar(10)  | NO   | MUL |         |                |
| categorycode        | varchar(10)  | NO   | MUL |         |                |
| dateenrolled        | date         | YES  |     | NULL    |                |
| dateexpiry          | date         | YES  |     | NULL    |                |
| gonenoaddress       | tinyint(1)   | YES  |     | NULL    |                |
| lost                | tinyint(1)   | YES  |     | NULL    |                |
| debarred            | tinyint(1)   | YES  |     | NULL    |                |
| contactname         | mediumtext   | YES  |     | NULL    |                |
| contactfirstname    | text         | YES  |     | NULL    |                |
| contacttitle        | text         | YES  |     | NULL    |                |
| guarantorid         | int(11)      | YES  | MUL | NULL    |                |
| borrowernotes       | mediumtext   | YES  |     | NULL    |                |
| relationship        | varchar(100) | YES  |     | NULL    |                |
| ethnicity           | varchar(50)  | YES  |     | NULL    |                |
| ethnotes            | varchar(255) | YES  |     | NULL    |                |
| sex                 | varchar(1)   | YES  |     | NULL    |                |
| password            | varchar(30)  | YES  |     | NULL    |                |
| flags               | int(11)      | YES  |     | NULL    |                |
| userid              | varchar(30)  | YES  | MUL | NULL    |                |
| opacnote            | mediumtext   | YES  |     | NULL    |                |
| contactnote         | varchar(255) | YES  |     | NULL    |                |
| sort1               | varchar(80)  | YES  |     | NULL    |                |
| sort2               | varchar(80)  | YES  |     | NULL    |                |
| altcontactfirstname | varchar(255) | YES  |     | NULL    |                |
| altcontactsurname   | varchar(255) | YES  |     | NULL    |                |
| altcontactaddress1  | varchar(255) | YES  |     | NULL    |                |
| altcontactaddress2  | varchar(255) | YES  |     | NULL    |                |
| altcontactaddress3  | varchar(255) | YES  |     | NULL    |                |
| altcontactstate     | mediumtext   | YES  |     | NULL    |                |
| altcontactzipcode   | varchar(50)  | YES  |     | NULL    |                |
| altcontactcountry   | text         | YES  |     | NULL    |                |
| altcontactphone     | varchar(50)  | YES  |     | NULL    |                |
| smsalertnumber      | varchar(50)  | YES  |     | NULL    |                |
| privacy             | int(11)      | NO   |     | 1       |                |
+---------------------+--------------+------+-----+---------+----------------+


 From C4::Members

 $flags->{KEY}
 {CHARGES}
	{message}     Message showing patron's credit or debt
	{noissues}    Set if patron owes >$5.00
 {GNA}         	Set if patron gone w/o address
	{message}     "Borrower has no valid address"
	{noissues}    Set.
 {LOST}        	Set if patron's card reported lost
	{message}     Message to this effect
	{noissues}    Set.
 {DBARRED}     	Set if patron is debarred
	{message}     Message to this effect
	{noissues}    Set.
 {NOTES}       	Set if patron has notes
	{message}     Notes about patron
 {ODUES}       	Set if patron has overdue books
	{message}     "Yes"
	{itemlist}    ref-to-array: list of overdue books
	{itemlisttext}    Text list of overdue items
 {WAITING}     	Set if there are items available that the patron reserved
	{message}     Message to this effect
	{itemlist}    ref-to-array: list of available items

=cut

