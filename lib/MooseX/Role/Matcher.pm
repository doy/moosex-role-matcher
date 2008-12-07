#!/usr/bin/perl
package MooseX::Role::Matcher;
use MooseX::Role::Parameterized;
use List::Util qw/first/;
use List::MoreUtils qw/any/;

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
    my @list = @{ shift() };
    my @matchers = @_;
    unshift @matchers, $default if (@_ % 2 == 1);
    $on_match->(sub { $_->match(@matchers) }, @list);
};

method first_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&first, @_);
};

method grep_matches => sub {
    my $class = shift;
    my $grep = sub { my $code = shift; grep { $code->() } @_ };
    $class->_apply_to_matches($grep, @_);
};

method any_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&any, @_);
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
        my ($invert, $name) = $matcher =~ /^(!)?(.*)$/;
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
