#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Sentinel;

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT = qw( sentinel );

eval {
   require XSLoader;
   XSLoader::load( __PACKAGE__, $VERSION );
} or do {
   # pureperl fallback
   no warnings 'redefine';
   *sentinel = \&Sentinel::PP::sentinel;
};

=head1 NAME

C<Sentinel> - create lightweight SCALARs with get/set callbacks

=head1 SYNOPSIS

 package Some::Class;

 use Sentinel;

 sub foo :lvalue
 {
    my $self = shift;
    sentinel get => sub { return $self->get_foo },
             set => sub { $self->set_foo( $_[0] ) };
 }

 sub bar :lvalue
 {
    my $self = shift;
    sentinel value => $self->get_bar,
             set   => sub { $self->set_bar( $_[0] ) };
 }

 sub splot :lvalue
 {
    sentinel obj => shift, get => \&get_splot, set => \&set_splot;
 }

=head1 DESCRIPTION

This module provides a single lvalue function, C<sentinel>, which yields a
scalar that invoke callbacks to get or set its value. Primarily this is useful
to create lvalue object accessors or other functions, to invoke actual code
when a new value is set, rather than simply updating a scalar variable.

If an XS compiler is available at build time, this module is implemented using
XS. If not, it falls back on an implementation using a C<tie>d scalar.

=cut

=head1 FUNCTIONS

=head2 $scalar = sentinel %args

Returns (as an lvalue) a scalar with magic attached to it. This magic is used
to get the value of the scalar, or to inform of a new value being set, by
invoking callback functions supplied to the sentinel. Takes the following
named arguments:

=over 8

=item get => CODE

A C<CODE> reference to invoke when the value of the scalar is read, to obtain
its value. The value returned from this code will appear as the value of the
scalar.

=item set => CODE

A C<CODE> reference to invoke when a new value for the scalar is written. The
code will be passed the new value as its only argument.

=item value => SCALAR

If no C<get> callback is provided, this value is given as the initial value of
the scalar. If the scalar manages to survive longer than a single assignment,
its value on read will retain the last value set to it.

=item obj => SCALAR

Optional value to pass as the first argument into the C<get> and C<set>
callbacks. If this value is provided, then the C<get> and C<set> callbacks may
be given as direct sub references to object methods, rather than closures that
capture the referent object. This avoids the runtime overhead of creating lots
of small one-use closures around the object.

=back

=head1 ACKNOWLEDGEMENTS

With thanks to C<leont>, C<Zefram>, and others from C<irc.perl.org/#p5p> for
assisting with trickier bits of XS logic. Thanks to C<mst> for suggesting a
pureperl implementation for XS-challenged systems.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

package # Hide from CPAN
   Sentinel::PP;

sub sentinel :lvalue
{
   my %args = @_;
   tie my $scalar, "Sentinel::PP", $args{value}, $args{get}, $args{set}, $args{obj};
   $scalar;
}

use constant { VALUE => 0, GET => 1, SET => 2, OBJ => 3 };
sub TIESCALAR
{
   my $class = shift;
   bless [ @_ ], $class;
}

sub FETCH
{
   my $self = shift;
   return $self->[GET]->( $self->[OBJ] ? ( $self->[OBJ] ) : () ) if $self->[GET];
   return $self->[VALUE];
}

sub STORE
{
   my $self = shift;
   my ( $value ) = @_;
   $self->[SET]->( $self->[OBJ] ? ( $self->[OBJ] ) : (), $value ) if $self->[SET];
   $self->[VALUE] = $value;
}

0x55AA;
