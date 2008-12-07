#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

package FooCollection;
use Moose;

has foos => (
    is      => 'rw',
    isa     => 'ArrayRef[Foo]',
    default => sub { [] },
);

sub each_match {
    my $self = shift;
    Foo->each_match($self->foos, @_);
}

sub first_match {
    my $self = shift;
    Foo->first_match($self->foos, @_);
}

package main;
my $foos = FooCollection->new;
my $foo1 = Foo->new(a => 'foo',  b => 'bar', c => 'baz');
my $foo2 = Foo->new(a => '',     b => '3',   c => 'foobar');
my $foo3 = Foo->new(a => 'blah', b => 'abc', c => 'foo');
push @{ $foos->foos }, $foo1;
push @{ $foos->foos }, $foo2;
push @{ $foos->foos }, $foo3;
is($foos->first_match(a => ''), $foo2,
   'first_match works');
