package C4::Output;

#package to deal with marking up output
#You will need to edit parts of this pm
#set the value of path to be where your html lives

# Copyright 2000-2002 Katipo Communications
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


# NOTE: I'm pretty sure this module is deprecated in favor of
# templates.

use strict;
#use warnings; FIXME - Bug 2505

use C4::Context;
use C4::Dates qw(format_date);
use C4::Budgets qw(GetCurrency);
use C4::Templates;

#use HTML::Template::Pro;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
    # set the version for version checking
    $VERSION = 3.03;
    require Exporter;
    @ISA    = qw(Exporter);
	@EXPORT_OK = qw(&is_ajax ajax_fail); # More stuff should go here instead
	%EXPORT_TAGS = ( all =>[qw(&pagination_bar
							   &output_with_http_headers &output_html_with_http_headers)],
					ajax =>[qw(&output_with_http_headers is_ajax)],
					html =>[qw(&output_with_http_headers &output_html_with_http_headers)]
				);
    push @EXPORT, qw(
        &output_html_with_http_headers &output_with_http_headers FormatData FormatNumber pagination_bar
    );
}


=head1 NAME

C4::Output - Functions for managing output, is slowly being deprecated

=head1 FUNCTIONS

=over 2
=cut

=item FormatNumber
=cut
sub FormatNumber{
my $cur  =  GetCurrency;
my $cur_format = C4::Context->preference("CurrencyFormat");
my $num;

if ( $cur_format eq 'FR' ) {
    $num = new Number::Format(
        'decimal_fill'      => '2',
        'decimal_point'     => ',',
        'int_curr_symbol'   => $cur->{symbol},
        'mon_thousands_sep' => ' ',
        'thousands_sep'     => ' ',
        'mon_decimal_point' => ','
    );
} else {  # US by default..
    $num = new Number::Format(
        'int_curr_symbol'   => '',
        'mon_thousands_sep' => ',',
        'mon_decimal_point' => '.'
    );
}
return $num;
}

=item FormatData

FormatData($data_hashref)
C<$data_hashref> is a ref to data to format

Format dates of data those dates are assumed to contain date in their noun
Could be used in order to centralize all the formatting for HTML output
=cut

sub FormatData{
		my $data_hashref=shift;
        $$data_hashref{$_} = format_date( $$data_hashref{$_} ) for grep{/date/} keys (%$data_hashref);
}

=item pagination_bar

   pagination_bar($base_url, $nb_pages, $current_page, $startfrom_name)

Build an HTML pagination bar based on the number of page to display, the
current page and the url to give to each page link.

C<$base_url> is the URL for each page link. The
C<$startfrom_name>=page_number is added at the end of the each URL.

C<$nb_pages> is the total number of pages available.

C<$current_page> is the current page number. This page number won't become a
link.

This function returns HTML, without any language dependency.

=cut

sub pagination_bar {
	my $base_url = (@_ ? shift : $ENV{SCRIPT_NAME} . $ENV{QUERY_STRING}) or return undef;
    my $nb_pages       = (@_) ? shift : 1;
    my $current_page   = (@_) ? shift : undef;	# delay default until later
    my $startfrom_name = (@_) ? shift : 'page';

    # how many pages to show before and after the current page?
    my $pages_around = 2;

	my $delim = qr/\&(?:amp;)?|;/;		# "non memory" cluster: no backreference
	$base_url =~ s/$delim*\b$startfrom_name=(\d+)//g; # remove previous pagination var
    unless (defined $current_page and $current_page > 0 and $current_page <= $nb_pages) {
        $current_page = ($1) ? $1 : 1;	# pull current page from param in URL, else default to 1
		# $debug and	# FIXME: use C4::Debug;
		# warn "with QUERY_STRING:" .$ENV{QUERY_STRING}. "\ncurrent_page:$current_page\n1:$1  2:$2  3:$3";
    }
	$base_url =~ s/($delim)+/$1/g;	# compress duplicate delims
	$base_url =~ s/$delim;//g;		# remove empties
	$base_url =~ s/$delim$//;		# remove trailing delim

    my $url = $base_url . (($base_url =~ m/$delim/ or $base_url =~ m/\?/) ? '&amp;' : '?' ) . $startfrom_name . '=';
    my $pagination_bar = '';

    # navigation bar useful only if more than one page to display !
    if ( $nb_pages > 1 ) {

        # link to first page?
        if ( $current_page > 1 ) {
            $pagination_bar .=
                "\n" . '&nbsp;'
              . '<a href="'
              . $url
              . '1" rel="start">'
              . '&lt;&lt;' . '</a>';
        }
        else {
            $pagination_bar .=
              "\n" . '&nbsp;<span class="inactive">&lt;&lt;</span>';
        }

        # link on previous page ?
        if ( $current_page > 1 ) {
            my $previous = $current_page - 1;

            $pagination_bar .=
                "\n" . '&nbsp;'
              . '<a href="'
              . $url
              . $previous
              . '" rel="prev">' . '&lt;' . '</a>';
        }
        else {
            $pagination_bar .=
              "\n" . '&nbsp;<span class="inactive">&lt;</span>';
        }

        my $min_to_display      = $current_page - $pages_around;
        my $max_to_display      = $current_page + $pages_around;
        my $last_displayed_page = undef;

        for my $page_number ( 1 .. $nb_pages ) {
            if (
                   $page_number == 1
                or $page_number == $nb_pages
                or (    $page_number >= $min_to_display
                    and $page_number <= $max_to_display )
              )
            {
                if ( defined $last_displayed_page
                    and $last_displayed_page != $page_number - 1 )
                {
                    $pagination_bar .=
                      "\n" . '&nbsp;<span class="inactive">...</span>';
                }

                if ( $page_number == $current_page ) {
                    $pagination_bar .=
                        "\n" . '&nbsp;'
                      . '<span class="currentPage">'
                      . $page_number
                      . '</span>';
                }
                else {
                    $pagination_bar .=
                        "\n" . '&nbsp;'
                      . '<a href="'
                      . $url
                      . $page_number . '">'
                      . $page_number . '</a>';
                }
                $last_displayed_page = $page_number;
            }
        }

        # link on next page?
        if ( $current_page < $nb_pages ) {
            my $next = $current_page + 1;

            $pagination_bar .= "\n"
              . '&nbsp;<a href="'
              . $url
              . $next
              . '" rel="next">' . '&gt;' . '</a>';
        }
        else {
            $pagination_bar .=
              "\n" . '&nbsp;<span class="inactive">&gt;</span>';
        }

        # link to last page?
        if ( $current_page != $nb_pages ) {
            $pagination_bar .= "\n"
              . '&nbsp;<a href="'
              . $url
              . $nb_pages
              . '" rel="last">'
              . '&gt;&gt;' . '</a>';
        }
        else {
            $pagination_bar .=
              "\n" . '&nbsp;<span class="inactive">&gt;&gt;</span>';
        }
    }

    return $pagination_bar;
}

=item output_with_http_headers

   &output_with_http_headers($query, $cookie, $data, $content_type[, $status])

Outputs $data with the appropriate HTTP headers,
the authentication cookie $cookie and a Content-Type specified in
$content_type.

If applicable, $cookie can be undef, and it will not be sent.

$content_type is one of the following: 'html', 'js', 'json', 'xml', 'rss', or 'atom'.

$status is an HTTP status message, like '403 Authentication Required'. It defaults to '200 OK'.

=cut

sub output_with_http_headers($$$$;$) {
    my ( $query, $cookie, $data, $content_type, $status ) = @_;
    $status ||= '200 OK';

    my %content_type_map = (
        'html' => 'text/html',
        'js'   => 'text/javascript',
        'json' => 'application/json',
        'xml'  => 'text/xml',
        # NOTE: not using application/atom+xml or application/rss+xml because of
        # Internet Explorer 6; see bug 2078.
        'rss'  => 'text/xml',
        'atom' => 'text/xml'
    );

    die "Unknown content type '$content_type'" if ( !defined( $content_type_map{$content_type} ) );
    my $options = {
        type    => $content_type_map{$content_type},
        status  => $status,
        charset => 'UTF-8',
        Pragma          => 'no-cache',
        'Cache-Control' => 'no-cache',
    };
    $options->{cookie} = $cookie if $cookie;
    if ($content_type eq 'html') {  # guaranteed to be one of the content_type_map keys, else we'd have died
        $options->{'Content-Style-Type' } = 'text/css';
        $options->{'Content-Script-Type'} = 'text/javascript';
    }
    # remove SUDOC specific NSB NSE
    $data =~ s/\x{C2}\x{98}|\x{C2}\x{9C}/ /g;
    $data =~ s/\x{C2}\x{88}|\x{C2}\x{89}/ /g;
      
# We can't encode here, that will double encode our templates, and xslt
# We need to fix the encoding as it comes out of the database, or when we pass the variables to templates
 
#    utf8::encode($data) if utf8::is_utf8($data);

    print $query->header($options), $data;
}

sub output_html_with_http_headers ($$$;$) {
    my ( $query, $cookie, $data, $status ) = @_;
    $data =~ s/\&amp\;amp\; /\&amp\; /g;
    output_with_http_headers( $query, $cookie, $data, 'html', $status );
}

sub is_ajax () {
    my $x_req = $ENV{HTTP_X_REQUESTED_WITH};
    return ( $x_req and $x_req =~ /XMLHttpRequest/i ) ? 1 : 0;
}

END { }    # module clean-up code here (global destructor)

1;
__END__

=back

=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=cut
