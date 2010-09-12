#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Log::Log4perl qw(get_logger :easy :levels);
use Template;
use POSIX;
use Config::General;

use FindBin qw($RealBin);

my $basedir = "$RealBin/";

use lib "$RealBin/../../../../lib";

use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;
use perfSONAR_PS::NPToolkit::Config::Services;

my $config_file = $basedir . '/etc/web_admin.conf';
my $conf_obj = Config::General->new( -ConfigFile => $config_file );
our %conf = $conf_obj->getall;

$conf{template_directory} = "templates" unless ( $conf{template_directory} );
$conf{template_directory} = $basedir . "/" . $conf{template_directory} unless ( $conf{template_directory} =~ /^\// );

if ( $conf{logger_conf} ) {
    unless ( $conf{logger_conf} =~ /^\// ) {
        $conf{logger_conf} = $basedir . "/etc/" . $conf{logger_conf};
    }

    Log::Log4perl->init( $conf{logger_conf} );
}
else {

    # If they've not specified a logger, send it all to /dev/null
    Log::Log4perl->easy_init( { level => $DEBUG, file => "/dev/null" } );
}

our $logger = get_logger( "perfSONAR_PS::WebGUI::ServiceStatus" );
if ( $conf{debug} ) {
    $logger->level( $DEBUG );
}

my $services_conf = perfSONAR_PS::NPToolkit::Config::Services->new();
# TODO: Load this from node.info
$services_conf->init( { unis_instance => "https://127.0.0.1:8012/perfSONAR_PS/services/unis" } );

my $administrative_info_conf = perfSONAR_PS::NPToolkit::Config::AdministrativeInfo->new();
$administrative_info_conf->init( { administrative_info_file => $conf{administrative_info_file} } );

my $tt = Template->new( INCLUDE_PATH => $conf{template_directory} ) or die( "Couldn't initialize template toolkit" );

my $html;

my %vars = ();
$vars{site_name}       = $administrative_info_conf->get_organization_name();
$vars{site_location}   = $administrative_info_conf->get_location();
$vars{nodes}           = $services_conf->get_nodes();

$tt->process( "status.tmpl", \%vars, \$html ) or die $tt->error();

my $cgi = CGI->new();
print $cgi->header;
print $html;

exit 0;

# vim: expandtab shiftwidth=4 tabstop=4
