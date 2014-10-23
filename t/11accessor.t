#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

package TestObject;
use Sentinel;

sub new { return bless { foo => undef }, $_[0] }

sub get_foo { return $_[0]->{foo} }
sub set_foo { $_[0]->{foo} = $_[1] }

sub foo :lvalue
{
   my $self = shift;
   sentinel obj => $self, 
            get => \&get_foo,
            set => \&set_foo;
}

package main;

my $obj = TestObject->new;

is( $obj->get_foo, undef, '$obj->get_foo undef before set' );
is( $obj->foo,     undef, '$obj->foo undef before set' );

$obj->set_foo( "Hello" );

is( $obj->get_foo, "Hello", '$obj->get_foo after set via ->set' );
is( $obj->foo,     "Hello", '$obj->foo after set via ->set' );

$obj->foo = "Goodbye";

is( $obj->get_foo, "Goodbye", '$obj->get_foo after set via lvalue' );
is( $obj->foo,     "Goodbye", '$obj->foo after set via lvalue' );
