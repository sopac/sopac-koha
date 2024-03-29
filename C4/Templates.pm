package C4::Templates;

use strict;
use warnings;
use Carp;
use CGI;
use List::Util qw/first/;

# Copyright 2009 Chris Cormack and The Koha Dev Team
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

=head1 NAME 

    Koha::Templates - Object for manipulating templates for use with Koha

=cut

use base qw(Class::Accessor);
use Template;
use Template::Constants qw( :debug );
use C4::Languages qw(getTranslatedLanguages get_bidi regex_lang_subtags language_get_description accept_language );

use C4::Context;

__PACKAGE__->mk_accessors(qw( theme lang filename htdocs interface vars));



sub new {
    my $class     = shift;
    my $interface = shift;
    my $filename  = shift;
    my $tmplbase  = shift;
    my $query     = @_? shift: undef;
    my $htdocs;
    if ( $interface ne "intranet" ) {
        $htdocs = C4::Context->config('opachtdocs');
    }
    else {
        $htdocs = C4::Context->config('intrahtdocs');
    }

    my ($theme, $lang)= themelanguage( $htdocs, $tmplbase, $interface, $query);
    my $template = Template->new(
        {   EVAL_PERL    => 1,
            ABSOLUTE     => 1,
            INCLUDE_PATH => [
                "$htdocs/$theme/$lang/includes",
                "$htdocs/$theme/en/includes"
            ],
            FILTERS => {},
        }
    ) or die Template->error();
    my $self = {
        TEMPLATE => $template,
        VARS     => {},
    };
    bless $self, $class;
    $self->theme($theme);
    $self->lang($lang);
    $self->filename($filename);
    $self->htdocs($htdocs);
    $self->interface($interface);
    $self->{VARS}->{"test"} = "value";
    return $self;

}

sub output {
    my $self = shift;
    my $vars = shift;

#    my $file = $self->htdocs . '/' . $self->theme .'/'.$self->lang.'/'.$self->filename;
    my $template = $self->{TEMPLATE};
    if ( $self->interface eq 'intranet' ) {
        $vars->{themelang} = '/intranet-tmpl';
    }
    else {
        $vars->{themelang} = '/opac-tmpl';
    }
    $vars->{lang} = $self->lang;
    $vars->{themelang} .= '/' . $self->theme . '/' . $self->lang;
    $vars->{yuipath} =
      ( C4::Context->preference("yuipath") eq "local"
        ? $vars->{themelang} . "/lib/yui"
        : C4::Context->preference("yuipath") );
    $vars->{interface} =
      ( $self->{interface} ne 'intranet' ? '/opac-tmpl' : '/intranet-tmpl' );
    $vars->{theme} = $self->theme;
    $vars->{opaccolorstylesheet} =
      C4::Context->preference('opaccolorstylesheet');
    $vars->{opacsmallimage} = C4::Context->preference('opacsmallimage');
    $vars->{opacstylesheet} = C4::Context->preference('opacstylesheet');

    # add variables set via param to $vars for processing
    # and clean any utf8 mess
    for my $k ( keys %{ $self->{VARS} } ) {
        $vars->{$k} = $self->{VARS}->{$k};
        if (ref($vars->{$k}) eq 'ARRAY'){
            utf8_arrayref($vars->{$k});
        }
        elsif (ref($vars->{$k}) eq 'HASH'){
            utf8_hashref($vars->{$k});
        }
        else {
            utf8::encode($vars->{$k}) if utf8::is_utf8($vars->{$k});
        }
    }
    my $data;
#    binmode( STDOUT, ":utf8" );
    $template->process( $self->filename, $vars, \$data )
      || die "Template process failed: ", $template->error();
    return $data;
}

sub utf8_arrayref {
    my $arrayref = shift;
    foreach my $element (@$arrayref){
        if (ref($element) eq 'ARRAY'){
            utf8_arrayref($element);
            next;
        }
        if (ref($element) eq 'HASH'){
            utf8_hashref($element);
            next;
        }
        utf8::encode($element) if utf8::is_utf8($element);
    }        
}         

sub utf8_hashref {
    my $hashref = shift;
    for my $key (keys %{$hashref}){
        if (ref($hashref->{$key}) eq 'ARRAY'){
            utf8_arrayref($hashref->{$key});
            next;
        }
        if (ref($hashref->{$key}) eq 'HASH'){
            utf8_hashref($hashref->{$key});
            next;
        }
        utf8::encode($hashref->{$key}) if utf8::is_utf8($hashref->{$key});
    }
}
        
        
# FIXME - this is a horrible hack to cache
# the current known-good language, temporarily
# put in place to resolve bug 4403.  It is
# used only by C4::XSLT::XSLTParse4Display;
# the language is set via the usual call
# to themelanguage.
my $_current_language = 'en';

sub _current_language {
    return $_current_language;
}


# wrapper method to allow easier transition from HTML template pro to Template Toolkit
sub param {
    my $self = shift;
    while (@_) {
        my $key = shift;
        my $val = shift;
        if    ( ref($val) eq 'ARRAY' && !scalar @$val ) { $val = undef; }
        elsif ( ref($val) eq 'HASH'  && !scalar %$val ) { $val = undef; }
        if ( $key ) {
            $self->{VARS}->{$key} = $val;
        } else {
            warn "Problem = a value of $val has been passed to param without key";
        }
    }
}


=head1 NAME

C4::Templates - Functions for managing templates

=head1 FUNCTIONS

=cut

# FIXME: this is a quick fix to stop rc1 installing broken
# Still trying to figure out the correct fix.
my $path = C4::Context->config('intrahtdocs') . "/prog/en/includes/";

#---------------------------------------------------------------------------------------------------------
# FIXME - POD

sub _get_template_file {
    my ($tmplbase, $interface, $query) = @_;

    my $is_intranet = $interface eq 'intranet';
    my $htdocs = C4::Context->config($is_intranet ? 'intrahtdocs' : 'opachtdocs');
    my ($theme, $lang) = themelanguage($htdocs, $tmplbase, $interface, $query);
    my $opacstylesheet = C4::Context->preference('opacstylesheet');

    # if the template doesn't exist, load the English one as a last resort
    my $filename = "$htdocs/$theme/$lang/modules/$tmplbase";
    unless (-f $filename) {
        $lang = 'en';
        $filename = "$htdocs/$theme/$lang/modules/$tmplbase";
    }
    return ($htdocs, $theme, $lang, $filename);
}


sub gettemplate {
    my ( $tmplbase, $interface, $query ) = @_;
    ($query) or warn "no query in gettemplate";
    my $path = C4::Context->preference('intranet_includes') || 'includes';
    my $opacstylesheet = C4::Context->preference('opacstylesheet');
    $tmplbase =~ s/\.tmpl$/.tt/;
    my ($htdocs, $theme, $lang, $filename)
       =  _get_template_file($tmplbase, $interface, $query);
    my $template = C4::Templates->new($interface, $filename, $tmplbase, $query);
    my $is_intranet = $interface eq 'intranet';
    my $themelang =
        ($is_intranet ? '/intranet-tmpl' : '/opac-tmpl') .
        "/$theme/$lang";
    $template->param(
        themelang => $themelang,
        yuipath   => C4::Context->preference("yuipath") eq "local"
                     ? "$themelang/lib/yui"
                     : C4::Context->preference("yuipath"),
        interface => $is_intranet ? '/intranet-tmpl' : '/opac-tmpl',
        theme     => $theme,
        lang      => $lang
    );

    # Bidirectionality
    my $current_lang = regex_lang_subtags($lang);
    my $bidi;
    $bidi = get_bidi($current_lang->{script}) if $current_lang->{script};
    # Languages
    my $languages_loop = getTranslatedLanguages($interface,$theme,$lang);
    my $num_languages_enabled = 0;
    foreach my $lang (@$languages_loop) {
        foreach my $sublang (@{ $lang->{'sublanguages_loop'} }) {
            $num_languages_enabled++ if $sublang->{enabled};
         }
    }
    $template->param(
            languages_loop       => $languages_loop,
            bidi                 => $bidi,
            one_language_enabled => ($num_languages_enabled <= 1) ? 1 : 0, # deal with zero enabled langs as well
    ) unless @$languages_loop<2;

    return $template;
}


#---------------------------------------------------------------------------------------------------------
# FIXME - POD
sub themelanguage {
    my ($htdocs, $tmpl, $interface, $query) = @_;
    ($query) or warn "no query in themelanguage";

    # Select a language based on cookie, syspref available languages & browser
    my $is_intranet = $interface eq 'intranet';
    my @languages = split(",", C4::Context->preference(
        $is_intranet ? 'language' : 'opaclanguages'));
    my $lang;
    $lang = $query->cookie('KohaOpacLanguage')
        if defined $query and $query->cookie('KohaOpacLanguage');
    unless ($lang) {
        my $http_accept_language = $ENV{ HTTP_ACCEPT_LANGUAGE };
        $lang = accept_language( $http_accept_language, 
            getTranslatedLanguages($interface,'prog') );
    }
    # Ignore a lang not selected in sysprefs
    $lang = undef  unless first { $_ eq $lang } @languages;
    # Fall back to English if necessary
    $lang = 'en' unless $lang;

    my @themes = split(" ", C4::Context->preference(
        $is_intranet ? "template" : "opacthemes" ));
    push @themes, 'prog';

    # Try to find first theme for the selected language
    for my $theme (@themes) {
        if ( -e "$htdocs/$theme/$lang/modules/$tmpl" ) {
            $_current_language = $lang;
            return ($theme, $lang)
        }
    }
    # Otherwise, return prog theme in English 'en'
    return ('prog', 'en');
}


sub setlanguagecookie {
    my ( $query, $language, $uri ) = @_;
    my $cookie = $query->cookie(
        -name    => 'KohaOpacLanguage',
        -value   => $language,
        -expires => ''
    );
    print $query->redirect(
        -uri    => $uri,
        -cookie => $cookie
    );
}

sub getlanguagecookie {
    my ($query) = @_;
    my $lang;
    if ($query->cookie('KohaOpacLanguage')){
        $lang = $query->cookie('KohaOpacLanguage') ;
    }else{
        $lang = $ENV{HTTP_ACCEPT_LANGUAGE};
        
    }
    $lang = substr($lang, 0, 2);

    return $lang;
}

1;

