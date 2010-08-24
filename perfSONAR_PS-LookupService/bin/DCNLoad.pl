#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

DCNLoad.pl - Load an hLS with DCN content.

=head1 DESCRIPTION

Loads an hLS (specified in URL) with the contents of the file (specified in 
FILENAME).

=head1 SYNOPSIS

./DCNLoad.pl FILENAME URL

=cut

use Carp;

use FindBin qw($RealBin);
my $basedir = "$RealBin/";
use lib "$RealBin/../lib";

use perfSONAR_PS::Client::DCN;

my $file = shift;
my $url = shift;

croak "Provide intput file and LS url.\n" unless $file and $url;

my $dcn = new perfSONAR_PS::Client::DCN( { instance => $url, myAddress => "https://dcn-ls.internet2.edu/dcnAdmin.cgi", myName => "DCN Registration CGI", myType => "dcnmap" } );

open( IN, "<" . $file );
my $counter = 0;
while ( <IN> ) {
    if ( $counter ) {
        my @fields = split( /,/, $_ );

        my @temp = ();
        for( my $x = 5; $x <= $#fields; $x++ ) {
            push @temp, $fields[$x];
        }

        my $code = $dcn->insert( { name => $fields[0], id => $fields[1], institution => $fields[2], longitude => $fields[3], latitude => $fields[4], keywords => \@temp } );
        unless ( $code == 0 ) {
            print "FAIL: " , $_ , "\n";
        }

    }
    $counter++;
}
my @content = <IN>;
close(IN);

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

$Id: DCNLoad.pl 3629 2009-08-25 14:06:00Z zurawski $

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

