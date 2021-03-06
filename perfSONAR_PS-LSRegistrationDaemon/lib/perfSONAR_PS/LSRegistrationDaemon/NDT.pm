package perfSONAR_PS::LSRegistrationDaemon::NDT;

=head1 NAME

perfSONAR_PS::LSRegistrationDaemon::NDT - The NDT class provides checks for
NDT services.

=head1 DESCRIPTION

This module provides the request functions to check an NDT service, and the
information necessary for the Base module to construct an NDT service
instance.

=cut

use strict;
use warnings;

our $VERSION = 3.1;

use base 'perfSONAR_PS::LSRegistrationDaemon::TCP_Service';

use constant DEFAULT_PORT => 7123;

=head2 init($self, $conf)

Since NDT doesn't have a configuration file like the others, this function
simply sets the default port values unless it has been set in the config file.

=cut

sub init {
    my ( $self, $conf ) = @_;

    my $port = $conf->{port};
    if ( not $port ) {
        $conf->{port} = DEFAULT_PORT;
    }

    return $self->SUPER::init( $conf );
}

=head2 get_service_addresses ($self)

This function returns the list of addresses for this service. This overrides
the TCP_Service get_service_addresses function so that NDT URLs are returned as
URLs.

=cut

sub get_service_addresses {
    my ( $self ) = @_;

    my @addresses = ();

    foreach my $addr ( @{ $self->{ADDRESSES} } ) {
        my $uri;

        $uri = "http://";
        if ( $addr =~ /:/ ) {
            $uri .= "[$addr]";
        }
        else {
            $uri .= "$addr";
        }

        $uri .= ":" . $self->{PORT};

        my %addr = ();
        $addr{"value"} = $uri;
        $addr{"type"}  = "url";

        push @addresses, \%addr;
    }

    return \@addresses;
}

=head2 type($self)

Returns the human readable description of the service "NDT Server".

=cut

sub type {
    my ( $self ) = @_;

    return "NDT Server";
}

=head2 service_type($self)

Returns the NDT service type.

=cut

sub service_type {
    my ( $self ) = @_;

    return "ndt";
}

=head2 event_type($self)

Returns the NDT event type.

=cut

sub event_type {
    my ( $self ) = @_;

    return "http://ggf.org/ns/nmwg/tools/ndt/1.0";
}

1;

__END__

=head1 SEE ALSO

L<perfSONAR_PS::LSRegistrationDaemon::TCP_Service>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: NDT.pm 2708 2009-04-03 13:39:02Z zurawski $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2007-2009, Internet2

All rights reserved.

=cut
