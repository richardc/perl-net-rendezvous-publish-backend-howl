package Net::Rendezvous::Publish::Backend::Howl;
use strict;
use warnings;
use XSLoader;
use base qw( Net::Rendezvous::Publish::Backend Class::Accessor::Lvalue::Fast );
__PACKAGE__->mk_accessors(qw( _handle _salt ));
our $VERSION = 0.01;

XSLoader::load __PACKAGE__;

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    $self->_handle = init_rendezvous();
    $self->_salt   = get_salt( $self->_handle );
    return $self;
}

sub DESTROY {
    my $self = shift;
    sw_rendezvous_fina( $self->_handle );
}

sub publish {
    my $self = shift;
    my %args = @_;
    return xs_publish( $self->_handle, map {
        $_ || ''
    } @args{qw( object name type domain host port txt )} );
}

sub publish_stop {
    my $self = shift;
    my $id   = shift;
    return sw_rendezvous_stop_publish( $self->_handle, $id );
}

sub step {
    my $self = shift;
    my $howlong = @_ ? shift : 0.5;
    $howlong *= 1000; # millisecs
    run_step( $self->_salt, $howlong );
}

1;
