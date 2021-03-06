
#PASTOR: Code generated by XML::Pastor/1.0.3 at 'Wed Jul  1 15:32:04 2009'

use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

use XML::Pastor;



#================================================================

package OSCARS::ns002::Type::CtrlPlaneNextHopContent;


our @ISA=qw(XML::Pastor::Builtin::string);

OSCARS::ns002::Type::CtrlPlaneNextHopContent->mk_accessors( qw(_weight _optional));

# Attribute accessor aliases

sub weight { &_weight; }
sub optional { &_optional; }

OSCARS::ns002::Type::CtrlPlaneNextHopContent->XmlSchemaType( bless( {
                 'attributeInfo' => {
                                    'optional' => bless( {
                                                         'class' => 'XML::Pastor::Builtin::boolean',
                                                         'metaClass' => 'OSCARS::Pastor::Meta',
                                                         'name' => 'optional',
                                                         'scope' => 'local',
                                                         'targetNamespace' => 'http://ogf.org/schema/network/topology/ctrlPlane/20080828/',
                                                         'type' => 'boolean|http://www.w3.org/2001/XMLSchema',
                                                         'use' => 'optional'
                                                       }, 'XML::Pastor::Schema::Attribute' ),
                                    'weight' => bless( {
                                                       'class' => 'XML::Pastor::Builtin::int',
                                                       'metaClass' => 'OSCARS::Pastor::Meta',
                                                       'name' => 'weight',
                                                       'scope' => 'local',
                                                       'targetNamespace' => 'http://ogf.org/schema/network/topology/ctrlPlane/20080828/',
                                                       'type' => 'int|http://www.w3.org/2001/XMLSchema',
                                                       'use' => 'optional'
                                                     }, 'XML::Pastor::Schema::Attribute' )
                                  },
                 'attributePrefix' => '_',
                 'attributes' => [
                                   'weight',
                                   'optional'
                                 ],
                 'base' => 'string|http://www.w3.org/2001/XMLSchema',
                 'baseClasses' => [
                                    'XML::Pastor::Builtin::string'
                                  ],
                 'class' => 'OSCARS::ns002::Type::CtrlPlaneNextHopContent',
                 'contentType' => 'complex',
                 'derivedBy' => 'extension',
                 'elementInfo' => {},
                 'elements' => [],
                 'isRedefinable' => 1,
                 'isSimpleContent' => 1,
                 'metaClass' => 'OSCARS::Pastor::Meta',
                 'name' => 'CtrlPlaneNextHopContent',
                 'scope' => 'global',
                 'targetNamespace' => 'http://ogf.org/schema/network/topology/ctrlPlane/20080828/'
               }, 'XML::Pastor::Schema::ComplexType' ) );

1;


__END__



=head1 NAME

B<OSCARS::ns002::Type::CtrlPlaneNextHopContent>  -  A class generated by L<XML::Pastor> . 


=head1 ISA

This class descends from L<XML::Pastor::Builtin::string>.


=head1 CODE GENERATION

This module was automatically generated by L<XML::Pastor> version 1.0.3 at 'Wed Jul  1 15:32:04 2009'


=head1 ATTRIBUTE ACCESSORS

=over

=item B<_optional>(), B<optional>()      - See L<XML::Pastor::Builtin::boolean>.

=item B<_weight>(), B<weight>()      - See L<XML::Pastor::Builtin::int>.

=back


=head1 SEE ALSO

L<XML::Pastor::Builtin::string>, L<XML::Pastor>, L<XML::Pastor::Type>, L<XML::Pastor::ComplexType>, L<XML::Pastor::SimpleType>


=cut
