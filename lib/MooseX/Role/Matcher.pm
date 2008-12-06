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

sub _apply_to_matches {
    my $on_match = shift;
    my $code = shift;
    my $matcher = shift;

    # pass in a coderef? return the first for which the coderef is true
    if (ref($matcher) eq 'CODE') {
        return $on_match->(sub { $code->($_) }, (grep { $matcher->($_) } @_));
    }

    # pass in a regex? return the first item for which the regex matches ID
    if (ref($matcher) eq 'Regexp') {
        return $on_match->(sub { $code->($_) }, (grep { $_->match($default => $matcher) } @_));
    }

    my $value = shift;
    if (!defined($value)) {
        # they passed in only one argument. assume they are checking identity
        ($matcher, $value) = ($default, $matcher);
    }

    return $on_match->(sub { $code->($_) }, (grep { $_->match($matcher => $value) } @_));
}

sub first_match {
    _apply_to_matches(\&first, @_);
}

sub each_match {
    _apply_to_matches(\&apply, @_);
}

sub grep_matches {
    # XXX: can you use grep like this?
    _apply_to_matches(\&grep, @_);
}

sub any_match {
    _apply_to_matches(\&any, @_);
}

sub _match {
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
}

sub match {
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
}

};

no MooseX::Role::Parameterized;

1;
