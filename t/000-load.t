#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

package main;
my $foo = Foo->new;
SKIP: {
    skip "MooseX::Role::Parameterized doesn't support does yet", 1;
    ok($foo->does('MooseX::Role::Matcher'),
       'role consumption works');
};
ok($foo->can('match'),
   'provided method exists');
