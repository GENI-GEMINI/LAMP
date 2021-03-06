
#PASTOR: Code generated by XML::Pastor/1.0.3 at 'Wed Jul  1 15:32:04 2009'

use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

use XML::Pastor;



#================================================================

package OSCARS::Type::getTopologyResponseContent;

use OSCARS::ns002::Type::CtrlPlaneTopologyContent;
use OSCARS::ns002::topology;

our @ISA=qw(XML::Pastor::ComplexType);

OSCARS::Type::getTopologyResponseContent->mk_accessors( qw(topology));

OSCARS::Type::getTopologyResponseContent->XmlSchemaType( bless( {
                 'attributeInfo' => {},
                 'attributePrefix' => '_',
                 'attributes' => [],
                 'baseClasses' => [
                                    'XML::Pastor::ComplexType'
                                  ],
                 'class' => 'OSCARS::Type::getTopologyResponseContent',
                 'contentType' => 'complex',
                 'elementInfo' => {
                                  'topology' => bless( {
                                                       'class' => 'OSCARS::ns002::Type::CtrlPlaneTopologyContent',
                                                       'definition' => bless( {
                                                                                'baseClasses' => [
                                                                                                   'OSCARS::ns002::Type::CtrlPlaneTopologyContent',
                                                                                                   'XML::Pastor::Element'
                                                                                                 ],
                                                                                'class' => 'OSCARS::ns002::topology',
                                                                                'isRedefinable' => 1,
                                                                                'metaClass' => 'OSCARS::Pastor::Meta',
                                                                                'name' => 'topology',
                                                                                'scope' => 'global',
                                                                                'targetNamespace' => 'http://ogf.org/schema/network/topology/ctrlPlane/20080828/',
                                                                                'type' => 'CtrlPlaneTopologyContent|http://ogf.org/schema/network/topology/ctrlPlane/20080828/'
                                                                              }, 'XML::Pastor::Schema::Element' ),
                                                       'metaClass' => 'OSCARS::Pastor::Meta',
                                                       'minOccurs' => '1',
                                                       'name' => 'topology',
                                                       'nameIsAutoGenerated' => 1,
                                                       'ref' => 'topology|http://ogf.org/schema/network/topology/ctrlPlane/20080828/',
                                                       'scope' => 'local',
                                                       'targetNamespace' => 'http://ogf.org/schema/network/topology/ctrlPlane/20080828/'
                                                     }, 'XML::Pastor::Schema::Element' )
                                },
                 'elements' => [
                                 'topology'
                               ],
                 'isRedefinable' => 1,
                 'metaClass' => 'OSCARS::Pastor::Meta',
                 'name' => 'getTopologyResponseContent',
                 'scope' => 'global',
                 'targetNamespace' => 'http://oscars.es.net/OSCARS'
               }, 'XML::Pastor::Schema::ComplexType' ) );

1;


__END__



=head1 NAME

B<OSCARS::Type::getTopologyResponseContent>  -  A class generated by L<XML::Pastor> . 


=head1 ISA

This class descends from L<XML::Pastor::ComplexType>.


=head1 CODE GENERATION

This module was automatically generated by L<XML::Pastor> version 1.0.3 at 'Wed Jul  1 15:32:04 2009'


=head1 CHILD ELEMENT ACCESSORS

=over

=item B<topology>()      - See L<OSCARS::ns002::Type::CtrlPlaneTopologyContent>.

=back


=head1 SEE ALSO

L<XML::Pastor::ComplexType>, L<XML::Pastor>, L<XML::Pastor::Type>, L<XML::Pastor::ComplexType>, L<XML::Pastor::SimpleType>


=cut
