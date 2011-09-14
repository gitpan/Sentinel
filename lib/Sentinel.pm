#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Sentinel;

use strict;
use warnings;

our $VERSION = '0.01_001';

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
    ${ \sentinel get => sub { return $self->get_attribute_name },
                 set => sub { $self->set_attribute_name( $_[0] ) } };
 }

 sub another_attribute :lvalue
 {
    my $self = shift;
    ${ \sentinel value => $self->get_another_attribute,
                 set   => sub { $self->set_attribute_name( $_[0] ) } };
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

=back

The slightly awkward reference/dereference syntax of C<${ \sentinel ... }>
works around an as-yet-unresolved issue that, without it, an error is raised
at runtime. See the C<TODO> section below.

=cut

=head1 TODO

=over 4

=item *

See if the awkward reference/dereference construct can be removed, yielding a
neater syntax of

 sub foo :lvalue { sentinel get => ..., set => ...; }

Currently this fails with the error

 Can't return a temporary from lvalue subroutine at ...

=item *

Add an C<obj> argument passed as the first argument to a C<get> or C<set>
callback, so that plain function references can be stored, further reducing
the overhead to avoid creating temporary closures.

 sentinel obj => $self, get => \&get_foo, set => \&set_foo;

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;