#!/usr/bin/perl
package MooseX::Role::Matcher;
use MooseX::Role::Parameterized;
use List::Util qw/first/;
use List::MoreUtils qw/any apply/;

parameter default_match => (
    is  => 'ro',
    isa => 'Str',
);

role {
my $p = shift;
my $default = $p->default_match;

method _apply_to_matches => sub {
    my $class = shift;
    my $on_match = shift;
    my $matcher = shift;
    my @list = @{ shift() };
    unshift @_, $default if (@_ % 2 == 1);
    $on_match->(sub { $matcher->(@_) }, @list);
};

method first_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&first, sub { $_->match(@_) }, @_);
};

method each_match => sub {
    my $class = shift;
    my $code = shift;
    $class->_apply_to_matches(\&apply, $code, @_);
};

method grep_matches => sub {
    my $class = shift;
    # XXX: can you use grep like this?
    $class->_apply_to_matches(\&grep, sub { $_->match(@_) }, @_);
};

method any_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&any, sub { $_->match(@_) }, @_);
};

method _match => sub {
    my $self = shift;
    my $value = shift;
    my $seek = shift;

    return !defined $value if !defined $seek;
    return 0 if !defined $value;
    return $value =~ $seek if ref($seek) eq 'Regexp';
    return $seek->($value) if ref($seek) eq 'CODE';
    if (ref($seek) eq 'ARRAY') {
        for (@$seek) {
            return 1 if $self->_match($value => $_);
        }
    }
    return $value eq $seek;
};

method match => sub {
    my $self = shift;
    my %args = @_;

    # All the conditions must be true for true to be returned. Return
    # immediately if a false condition is found.
    for my $matcher (keys %args) {
        my ($invert, $name) = $matcher =~ /^(not_)?(.*)$/;
        my $value = $self->can($name) ? $self->$name : undef;
        my $seek = $args{$matcher};

        my $matched = $self->_match($value => $seek) ? 1 : 0;

        if ($invert) {
            return 0 if $matched;
        }
        else {
            return 0 unless $matched;
        }
    }

    return 1;
};

};

no MooseX::Role::Parameterized;

1;
