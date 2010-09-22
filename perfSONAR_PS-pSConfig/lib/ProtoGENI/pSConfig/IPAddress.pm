package ProtoGENI::pSConfig::IPAddress;

use base 'perfSONAR_PS::Services::pSConfig::Handlers::Base';

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

TODO:

=head1 DESCRIPTION

TODO:

=cut

use Log::Log4perl qw(get_logger);

=head1 API

The offered API is not meant for external use as many of the functions are
relied upon by internal aspects of the perfSONAR-PS framework.

=head2 apply($self, $node)

TODO:

=cut

sub apply {
    my ( $self, $node ) = @_;
    return 0;
}

1;

__END__

=head1 SEE ALSO

L<perfSONAR_PS::Services::pSConfig::Handlers::Base>

=cut
