
#PASTOR: Code generated by XML::Pastor/1.0.3 at 'Wed Jul  1 15:32:04 2009'

use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

use XML::Pastor;



#================================================================

package OSCARS::Type::listRequest;

use OSCARS::Type::vlanTag;

our @ISA=qw(XML::Pastor::ComplexType);

OSCARS::Type::listRequest->mk_accessors( qw(resStatus startTime endTime description linkId vlanTag resRequested resOffset));

OSCARS::Type::listRequest->XmlSchemaType( bless( {
                 'attributeInfo' => {},
                 'attributePrefix' => '_',
                 'attributes' => [],
                 'baseClasses' => [
                                    'XML::Pastor::ComplexType'
                                  ],
                 'class' => 'OSCARS::Type::listRequest',
                 'contentType' => 'complex',
                 'elementInfo' => {
                                  'description' => bless( {
                                                          'class' => 'XML::Pastor::Builtin::string',
                                                          'maxOccurs' => '1',
                                                          'metaClass' => 'OSCARS::Pastor::Meta',
                                                          'minOccurs' => '0',
                                                          'name' => 'description',
                                                          'scope' => 'local',
                                                          'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                          'type' => 'string|http://www.w3.org/2001/XMLSchema'
                                                        }, 'XML::Pastor::Schema::Element' ),
                                  'endTime' => bless( {
                                                      'class' => 'XML::Pastor::Builtin::long',
                                                      'metaClass' => 'OSCARS::Pastor::Meta',
                                                      'name' => 'endTime',
                                                      'scope' => 'local',
                                                      'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                      'type' => 'long|http://www.w3.org/2001/XMLSchema'
                                                    }, 'XML::Pastor::Schema::Element' ),
                                  'linkId' => bless( {
                                                     'class' => 'XML::Pastor::Builtin::string',
                                                     'maxOccurs' => 'unbounded',
                                                     'metaClass' => 'OSCARS::Pastor::Meta',
                                                     'minOccurs' => '0',
                                                     'name' => 'linkId',
                                                     'scope' => 'local',
                                                     'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                     'type' => 'string|http://www.w3.org/2001/XMLSchema'
                                                   }, 'XML::Pastor::Schema::Element' ),
                                  'resOffset' => bless( {
                                                        'class' => 'XML::Pastor::Builtin::int',
                                                        'metaClass' => 'OSCARS::Pastor::Meta',
                                                        'minOccurs' => '0',
                                                        'name' => 'resOffset',
                                                        'scope' => 'local',
                                                        'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                        'type' => 'int|http://www.w3.org/2001/XMLSchema'
                                                      }, 'XML::Pastor::Schema::Element' ),
                                  'resRequested' => bless( {
                                                           'class' => 'XML::Pastor::Builtin::int',
                                                           'metaClass' => 'OSCARS::Pastor::Meta',
                                                           'minOccurs' => '0',
                                                           'name' => 'resRequested',
                                                           'scope' => 'local',
                                                           'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                           'type' => 'int|http://www.w3.org/2001/XMLSchema'
                                                         }, 'XML::Pastor::Schema::Element' ),
                                  'resStatus' => bless( {
                                                        'class' => 'XML::Pastor::Builtin::string',
                                                        'maxOccurs' => '5',
                                                        'metaClass' => 'OSCARS::Pastor::Meta',
                                                        'minOccurs' => '0',
                                                        'name' => 'resStatus',
                                                        'scope' => 'local',
                                                        'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                        'type' => 'string|http://www.w3.org/2001/XMLSchema'
                                                      }, 'XML::Pastor::Schema::Element' ),
                                  'startTime' => bless( {
                                                        'class' => 'XML::Pastor::Builtin::long',
                                                        'metaClass' => 'OSCARS::Pastor::Meta',
                                                        'name' => 'startTime',
                                                        'scope' => 'local',
                                                        'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                        'type' => 'long|http://www.w3.org/2001/XMLSchema'
                                                      }, 'XML::Pastor::Schema::Element' ),
                                  'vlanTag' => bless( {
                                                      'class' => 'OSCARS::Type::vlanTag',
                                                      'maxOccurs' => 'unbounded',
                                                      'metaClass' => 'OSCARS::Pastor::Meta',
                                                      'minOccurs' => '0',
                                                      'name' => 'vlanTag',
                                                      'scope' => 'local',
                                                      'targetNamespace' => 'http://oscars.es.net/OSCARS',
                                                      'type' => 'vlanTag|http://oscars.es.net/OSCARS'
                                                    }, 'XML::Pastor::Schema::Element' )
                                },
                 'elements' => [
                                 'resStatus',
                                 'startTime',
                                 'endTime',
                                 'description',
                                 'linkId',
                                 'vlanTag',
                                 'resRequested',
                                 'resOffset'
                               ],
                 'isRedefinable' => 1,
                 'metaClass' => 'OSCARS::Pastor::Meta',
                 'name' => 'listRequest',
                 'scope' => 'global',
                 'targetNamespace' => 'http://oscars.es.net/OSCARS'
               }, 'XML::Pastor::Schema::ComplexType' ) );

1;


__END__



=head1 NAME

B<OSCARS::Type::listRequest>  -  A class generated by L<XML::Pastor> . 


=head1 ISA

This class descends from L<XML::Pastor::ComplexType>.


=head1 CODE GENERATION

This module was automatically generated by L<XML::Pastor> version 1.0.3 at 'Wed Jul  1 15:32:04 2009'


=head1 CHILD ELEMENT ACCESSORS

=over

=item B<description>()      - See L<XML::Pastor::Builtin::string>.

=item B<endTime>()      - See L<XML::Pastor::Builtin::long>.

=item B<linkId>()      - See L<XML::Pastor::Builtin::string>.

=item B<resOffset>()      - See L<XML::Pastor::Builtin::int>.

=item B<resRequested>()      - See L<XML::Pastor::Builtin::int>.

=item B<resStatus>()      - See L<XML::Pastor::Builtin::string>.

=item B<startTime>()      - See L<XML::Pastor::Builtin::long>.

=item B<vlanTag>()      - See L<OSCARS::Type::vlanTag>.

=back


=head1 SEE ALSO

L<XML::Pastor::ComplexType>, L<XML::Pastor>, L<XML::Pastor::Type>, L<XML::Pastor::ComplexType>, L<XML::Pastor::SimpleType>


=cut
