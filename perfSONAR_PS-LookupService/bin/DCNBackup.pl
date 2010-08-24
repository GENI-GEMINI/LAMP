#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

DCNBackup.pl - export DCN content from an hLS

=head1 DESCRIPTION

Exports the DCN specific contents (e.g. node to friendly name mapping) of an hLS

=head1 SYNOPSIS

./DCNBackup.pl OUTPUTFILE
 
=cut

use Carp;

use FindBin qw($RealBin);
my $basedir = "$RealBin/";
use lib "$RealBin/../lib";

use perfSONAR_PS::Client::DCN;

my $file = shift;
croak "Provide output file.\n" unless $file;
open( OUT, ">" . $file );

my $source = new perfSONAR_PS::Client::DCN( { instance => "http://dcn-ls.internet2.edu:8005/perfSONAR_PS/services/hLS" } );

print OUT "name,id,institution,longitude,latitude,keywords\n";

my $map = $source->getMappings;
foreach my $m ( @$map ) {
    print OUT $m->[0] if exists $m->[0] and $m->[0];
    print OUT ",";
    print OUT $m->[1] if exists $m->[0] and $m->[1];
    print OUT ",";
    if ( exists $m->[2] and $m->[2] ) {

       print OUT $m->[2]->{institution} if exists $m->[2]->{institution} and $m->[2]->{institution};
       print OUT ",";
       print OUT $m->[2]->{longitude} if exists $m->[2]->{longitude} and $m->[2]->{longitude};
       print OUT ",";
       print OUT $m->[2]->{latitude} if exists $m->[2]->{latitude} and $m->[2]->{latitude};
       print OUT ",";

        if ( $m->[2]->{keywords} ) {
            my $kwc = 0;
            foreach my $kw ( @{ $m->[2]->{keywords} } ) {
                print OUT ", " if $kwc;
                print OUT $kw;
                $kwc++;
            }
        }
    }
    else {
        print OUT ",,,";
    }
    print OUT "\n";
}

close(OUT);

__END__

=head1 SEE ALSO

L<Carp>, L<perfSONAR_PS::Client::DCN>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: DCNBackup.pl 3629 2009-08-25 14:06:00Z zurawski $

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2007-2009, Internet2

All rights reserved.

=cut


