package perfSONAR_PS::NPToolkit::Config::Services;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::NPToolkit::Config::Services

=head1 DESCRIPTION

Module for configuring the set of services for the toolkit. Currently, this is
only used to enable/disable services. Longer term, it'd be good to think about
how the enable/disable configuration integrates with the configuration for each
service.

=cut

use Data::Dumper;

use base 'perfSONAR_PS::NPToolkit::Config::Base';

use fields 'UNIS_CLIENT', 'NODES', 'CONFIG_FILE', 'LAST_PULL_DATE', 'LAST_MODIFIED_DATE';

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger :nowarn);
use Storable qw(store retrieve freeze thaw dclone);

use perfSONAR_PS::Common qw(extract parseToDOM);
use perfSONAR_PS::Client::Topology;
use perfSONAR_PS::Topology::ID qw(idBaseLevel);

# XXX: Namespaces should be kept in a single module?
use constant UNIS_NS     => 'http://ogf.org/schema/network/topology/unis/20100528/';
use constant PSCONFIG_NS => 'http://ogf.org/schema/network/topology/psconfig/20100716/';


my %defaults = (
    config_file => "/home/fernandes/sandbox/XXX",
);

my %known_services = (
    "unis" => {
        description => "Unified Network Information Service (UNIS)",
    },

    "hls"  => {
        description => "Lookup Service",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },

    "ls_registration_daemon" => {
        description => "LS Registration Daemon",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },

    "snmp_ma" => {
        description => "SNMP Measurement Archive",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },

    "ndt" => {
        description => "Network Diagnostic Tester (NDT)",
        url         => "http://www.internet2.edu/performance/ndt/",
    },

    "npad" => {
        description => "Network Path and Application Diagnosis (NPAD)",
        url         => "http://www.psc.edu/networking/projects/pathdiag/",
    },

    "pinger" => {
        description => "PingER Measurement Archive and Regular Tester",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
        module      => "",
    },

    "owamp" => {
        description => "One-Way Ping Service (OWAMP)",
        url         => "http://www.internet2.edu/performance/owamp/index.html",
    },

    "bwctl" => {
        description => "Bandwidth Test Controller (BWCTL)",
        url         => "http://www.internet2.edu/performance/bwctl/index.html",
    },

    "ssh" => {
        description => "SSH Server",
    },

    "perfsonarbuoy_ma" => {
        description => "perfSONAR-BUOY Measurement Archive",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },

    "perfsonarbuoy_owamp" => {
        description => "perfSONAR-BUOY Regular Testing (One-Way Latency)",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },

    "perfsonarbuoy_bwctl" => {
        description => "perfSONAR-BUOY Regular Testing (Throughput)",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },

    "ntp" => {
        description => "NTP Server",
        url         => "http://www.ntp.org/",
    },

    "ganglia_gmetad" => {
        description => "Host Monitoring Daemon (Ganglia Monitoring Daemon)",
        url         => "http://ganglia.info/",
    },

    "ganglia_gmond" => {
        description => "Host Monitoring Collector (Ganglia Meta Daemon)",
        url         => "http://ganglia.info/",
    },

    "ganglia_ma" => {
        description => "Ganglia Measurement Archive",
        url         => "http://ganglia.info/",
    },

    "periscope" => {
        description => "Periscope Visualization Tool",
    },

    "perfadmin" => {
        description => "perfAdmin Visualization Tool",
        url         => "http://www.internet2.edu/performance/pS-PS/index.html",
    },
);

=head2 init({ enabled_services_file => 0 })

Initializes the client. Returns 0 on success and -1 on failure. The
enabled_services_file parameter can be specified to set which file the module
should use for reading/writing the configuration.

=cut

sub init {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { unis_instance => 1, config_file => 0 } );

    # Initialize the defaults
    $self->{CONFIG_FILE} = $defaults{config_file};

    # Override any
    $self->{CONFIG_FILE} = $parameters->{config_file} if ( $parameters->{config_file} );
    
    # XXX: This could be determined through the hints file, especially 
    #   as there might be the need for querying multiple UNIS instances 
    $self->{UNIS_CLIENT} = perfSONAR_PS::Client::Topology->new( $parameters->{unis_instance} );
    
    my $res = $self->reset_state();
    if ( $res != 0 ) {
        return $res;
    }

    return 0;
}

=head2 save({ restart_services => 0 })
    Saves the configuration to disk. The dependent services can be restarted by
    specifying the "restart_services" parameter as 1. 
=cut

sub save {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { restart_services => 0, } );

    my $enabled_services_file_output = $self->generate_enabled_services_file();

    my $res;

    $res = save_file( { file => $self->{ENABLED_SERVICES_FILE}, content => $enabled_services_file_output } );
    if ( $res == -1 ) {
        return (-1, "Problem saving set of enabled services");
    }

    if ( $parameters->{restart_services} ) {
        foreach my $key ( keys %{ $self->{SERVICES} } ) {
            my $service = $self->{SERVICES}->{$key};

            next if ($service->{name} eq "http"); # XXX it restarts the apache daemon while it is running.

            if ( $service->{enabled} ) {
                $self->{LOGGER}->debug( "Starting " . $service->{name} );
                start_service( { name => $service->{name} } );
            }
            else {
                $self->{LOGGER}->debug( "Stopping " . $service->{name} );
                stop_service( { name => $service->{name} } );
            }
        }
    }

    return 0;
}

=head2 reset_state()
    Resets the state of the module to the state immediately after having run "init()".
    Pulls the current configuration from UNIS if there's no local copy.
=cut

sub reset_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my $must_pull = 1;
    if ( -e $self->{CONFIG_FILE} ) {
        $must_pull = 0;
        eval {
            my $fd = new IO::File( $self->{CONFIG_FILE} ) or die " Failed to open config file.";
            
            # First line should be the last pull date.
            # We make sure it's a valid date, but keep it in string format.
            my $last_pull = <$fd>;
            timegm( strptime( $last_pull ) ) or die " Failed to parse last pull date.";
            $self->{LAST_PULL_DATE} = $last_pull;
            
            # Second line should be the last modified (and not pushed) date.
            # 0 means the configuration hasn't been modified locally.
            my $last_modified = <$fd>;
            if ( $last_modified != 0 ) {
                timegm( strptime( $last_modified ) ) or die " Failed to parse last pull date.";
            }
            $self->{LAST_MODIFIED_DATE} = $last_modified;
            
            # Rest of file should be the topology data of all psconfig-enabled nodes.
            # Slurp the rest of the file as a string and parse it.
            local ( $/ );
            my $topology = <$fd>;
            my $res = $self->parse_configuration( $topology );
            die $res if $res;
            
            $fd->close();            
        } or do {
            my $msg = " Failed to load the configuration file: $@";
            $self->{LOGGER}->error( $msg );
            $must_pull = 1;
        };
    }
    
    # We pull the current configuratoin from UNIS if there was a problem
    # reading the configuration file or if there was none (i.e. first run).
    $self->pull_configuration() if ( $must_pull == 1 );
    
    return 0;
}

=head2 pull_configuration ({ })
    TODO:
=cut

# GFR: There's a bug in the current UNIS implementation for the TS side
#   that xQuery's won't work, only xPath 1.0 queries.
use constant NODE_XPATH => "
//*[local-name()='node' and 
    namespace-uri()='" . UNIS_NS . "' and 
    ./*[local-name()='nodePropertiesBag' and 
        namespace-uri()='" . UNIS_NS . "']/*[local-name()='nodeProperties' and 
                                             namespace-uri()='" . PSCONFIG_NS . "']]
";

sub pull_configuration {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    my ( $status, $res ) = $self->{UNIS_CLIENT}->xQuery( NODE_XPATH );
   
    if ( $status != 0 ) {
        my $msg = "Couldn't query UNIS: $res";
        $self->{LOGGER}->error( $msg );
        return -1;
    }
    
    return $self->parse_configuration( { node_list => $res } );
}

=head2 parse_configuration ({ node_list => 1 })
    TODO:
=cut

sub parse_configuration {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { node_list => 1 } );
    
    my $node_list = $parameters->{node_list};
    
    unless ( ref $node_list eq "XML::LibXML::Element" ) {
        my $node_list_dom = parseToDOM( $node_list );
        
        return -1 if $node_list_dom == -1;
         
        $node_list = $node_list_dom->documentElement();
    }
    
    $self->{NODES} = {};
    foreach my $node ( $node_list->getChildrenByTagNameNS( UNIS_NS, "node" )->get_nodelist ) {
        my $node_id = $node->getAttribute( "id" );
        
        # For the name of the node we either use one of the node's <unis:name>
        # elements if any, otherwise we use the node value of the id.
        my @node_names = $node->getChildrenByTagNameNS( UNIS_NS, "name" );
        if ( scalar @node_names > 0 ) {
            foreach my $name ( @node_names ) {
                my $name_val = extract( $name, 0 );
                # Trim it
                $name_val =~ s/^\s*//;
                $name_val =~ s/\s*$//;
                
                # Make sure it's not empty
                if ( $name_val ) {
                    $self->{NODES}->{ $node_id }->{name} = $name_val;
                }
            }
        }
        
        unless ( exists $self->{NODES}->{ $node_id }->{name} ) {
            $self->{NODES}->{ $node_id }->{name} = idBaseLevel( $node_id );
        }
        
        $self->{NODES}->{ $node_id }->{SERVICES} = {};
        
        my @node_properties = $node->getElementsByTagNameNS( PSCONFIG_NS, "nodeProperties" );
        unless ( scalar @node_properties == 1 ) { 
            $self->{LOGGER}->error( " Invalid number of psconfig:nodeProperties for $node_id." );
            next;
        }
        
        for my $service ( $node_properties[0]->getElementsByTagNameNS( PSCONFIG_NS, "service" ) ) {
            my $service_type = $service->getAttribute( "type" );
            
            # For now we only care about services we know about.
            next unless exists $known_services{ $service_type };
            
            $self->{NODES}->{ $node_id }->{SERVICES}->{ $service_type } = {};
            
            my $service_ref = $self->{NODES}->{ $node_id }->{SERVICES}->{ $service_type };
            $service_ref->{enabled} = $service->getAttribute( "enable" );
            
            # Append all we know about this service.
            @$service_ref{ keys %{ $known_services{ $service_type } } }  = values %{ $known_services{ $service_type } };
            
            # For further processing by the service-specific config module.
            $service_ref->{ ELEMENT } = $service->cloneNode( 1 );
        }
    }

    return 0;
}

=head2 get_nodes ({})
    Returns the list of nodes as a hash indexed by UNIS id. The hash values are
    hashes containing the node's properties (including a services hash).
=cut

sub get_nodes {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{NODES};
}

=head2 get_services ({ node_id => 1 })
    Returns the list of services as a hash indexed by name. The hash values are
    hashes containing the service's properties.
=cut

sub get_services {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { node_id => 1, } );

    return $self->{NODES}->{ $parameters->{node_id} }->{SERVICES};
}

=head2 lookup_service ({ name => 1 })
    Returns the properties of the specified service as a hash. Returns
    undefined if the service request does not exist.
=cut

sub lookup_service {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { name => 1, } );

    my $name = $parameters->{name};

    return $self->{SERVICES}->{$name};
}

=head2 enable_service ({ name => 1})
    Enables the specified service. Returns 0 if successful and -1 if the
    service does not exist.
=cut

sub enable_service {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { name => 1, } );

    my $name = $parameters->{name};

    return -1 unless ( $self->{SERVICES}->{$name} );

    $self->{SERVICES}->{$name}->{enabled} = 1;

    return 0;
}

=head2 disable_service ({ name => 1})
    Disables the specified service. Returns 0 if successful and -1 if the
    service does not exist.
=cut

sub disable_service {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { name => 1, } );

    my $name = $parameters->{name};

    return -1 unless ( $self->{SERVICES}->{$name} );

    $self->{SERVICES}->{$name}->{enabled} = 0;

    return 0;
}

=head2 last_modified()
    Returns when the site information was last saved.
=cut

sub last_modified {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my ($mtime) = (stat ( $self->{ENABLED_SERVICES_FILE} ) )[9];

    return $mtime;
}

=head2 read_enabled_services_file({ file => 1 })
    Reads the specified "enabled_services.info" file. This file consists of
    key/value pairs specifying whether services should be enabled or not.
=cut

sub read_enabled_services_file {
    my $parameters = validate( @_, { file => 1, } );

    # If the file doesn't exist, that means no interfaces are configured
    unless ( open( FILE, $parameters->{file} ) ) {
        my %retval = ();
        return ( 0, \%retval );
    }

    my %enabled = ();

    while ( <FILE> ) {
        chomp;

        if ( /=/ ) {
            my ( $variable, $value ) = split( '=' );

            # clear out whitespace
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;

            $enabled{$variable} = $value;
        }
    }

    close( FILE );

    return ( 0, \%enabled );
}

=head2 generate_enabled_services_file ({})
    Generates a string representation of the contents of an
    "enabled_services.info" file from the internal set of services.
=cut

sub generate_enabled_services_file {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my $output = "";

    foreach my $key ( sort keys %{ $self->{SERVICES} } ) {
        my $service = $self->{SERVICES}->{$key};

        next unless ( $service->{enabled_services_variable} );

        if ( $service->{enabled} ) {
            $output .= $service->{enabled_services_variable} . "=enabled\n";
        }
        else {
            $output .= $service->{enabled_services_variable} . "=disabled\n";
        }
    }

    return $output;
}

=head2 save_state()
    Saves the current state of the module as a string. This state allows the
    module to be recreated later.
=cut

sub save_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my %state = (
        services              => $self->{SERVICES},
        enabled_services_file => $self->{ENABLED_SERVICES_FILE},
    );

    my $str = freeze( \%state );

    return $str;
}

=head2 restore_state({ state => \$state })
    Restores the modules state based on a string provided by the "save_state"
    function above.
=cut

sub restore_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { state => 1, } );

    my $state = thaw( $parameters->{state} );

    $self->{SERVICES}              = $state->{services};
    $self->{ENABLED_SERVICES_FILE} = $state->{enabled_services_file};

    return;
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
