#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
);

package main;
my $foo = Foo->new(a => 'foo', b => 'bar', c => 'baz');
ok($foo->match(a => 'foo', b => 'bar', c => 'baz'),
   'string matching works');
ok($foo->match(a => qr/o/),
   'regex matching works');
ok($foo->match(b => sub { length(shift) == 3 }),
   'subroutine matching works');
ok($foo->match(a => 'foo', b => qr/a/, c => sub { substr(shift, 2) eq 'z' }),
   'combined matching works');
$foo = Foo->new(a => 'foo');
ok($foo->match(a => 'foo', b => undef),
   'matching against undef works');
