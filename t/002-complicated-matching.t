#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

package main;
my $foo = Foo->new(a => 'foo', b => 'bar', c => 'baz');
ok($foo->match(a => [qr/o/, sub { length(shift) == 4 }]),
   'arrayref matching works');
ok($foo->match(a => [qr/b/, sub { length(shift) == 3 }]),
   'arrayref matching works');
ok(!$foo->match(a => [qr/b/, sub { length(shift) == 4 }]),
   'arrayref matching works');
ok($foo->match('!a' => 'bar', b => 'bar', '!c' => 'bar'),
   'negated matching works');
