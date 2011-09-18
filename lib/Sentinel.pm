#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Sentinel;

use strict;
use warnings;

our $VERSION = '0.01_003';

use Exporter 'import';
our @EXPORT = qw( sentinel );

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Sentinel> - create lightweight SCALARs with get/set callbacks

=head1 SYNOPSIS

 package Some::Class;

 use Sentinel;

 sub attribute_name :lvalue
 {
    my $self = shift;
    sentinel get => sub { return $self->get_attribute_name },
             set => sub { $self->set_attribute_name( $_[0] ) };
 }

 sub another_attribute :lvalue
 {
    my $self = shift;
    sentinel value => $self->get_another_attribute,
             set   => sub { $self->set_attribute_name( $_[0] ) };
 }

 sub yet_another_attribute :lvalue
 {
    my $self = shift;
    sentinel obj => $self,
             get => \&get_another_attribute,
             set => \&set_another_attribute;
 }

=head1 DESCRIPTION

This module provides a single lvalue function, C<sentinel>, which yields a
scalar that invoke callbacks to get or set its value. Primarily this is useful
to create lvalue object accessors or other functions, to invoke actual code
when a new value is set, rather than simply updating a scalar variable.

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

=head3 Important note

The syntax used in the B<SYNOPSIS> only works on perl version 5.14 and above.
Before version 5.14, the lvalue context is not properly propagated through
nested lvalue functions and instead it dies at runtime with an exception

 Can't return a temporary from lvalue subroutine at ...

To be compatible with prior versions of perl, you must instead write a
slightly more awkward syntax, taking a C<SCALAR> ref to the sentinel return
value then immediately dereferencing it again:

 sub attribute_name :lvalue
 {
    my $self = shift;
    ${ \sentinel get => sub { return $self->get_attribute_name },
                 set => sub { $self->set_attribute_name( $_[0] ) } };
 }

This is purely a workaround for older perl behaviour; if you do not need
backward compatibility before perl 5.14, then you can yield C<sentinel>
directly from an C<:lvalue> function.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
