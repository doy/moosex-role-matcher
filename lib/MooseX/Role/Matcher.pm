#!/usr/bin/perl
package MooseX::Role::Matcher;
use MooseX::Role::Parameterized;
use List::Util qw/first/;
use List::MoreUtils qw/any all/;

# ABSTRACT: generic object matching based on attributes and methods

=head1 SYNOPSIS

  package Person;
  use Moose;
  with 'MooseX::Role::Matcher' => { default_match => 'name' };

  has name  => (is => 'ro', isa => 'Str');
  has age   => (is => 'ro', isa => 'Num');
  has phone => (is => 'ro', isa => 'Str');

  package main;
  my @people = (Person->new(name => 'James', age => 22, phone => '555-1914'),
                Person->new(name => 'Jesse', age => 22, phone => '555-6287'),
                Person->new(name => 'Eric',  age => 21, phone => '555-7634'));

  # is James 22?
  $people[0]->match(age => 22);

  # which people are not 22?
  my @not_twenty_two = Person->grep_matches([@people], '!age' => 22);

  # do any of the 22-year-olds have a phone number ending in 4?
  Person->any_match([@people], age => 22, number => qr/4$/);

  # does everyone's name start with either J or E?
  Person->all_match([@people], name => [qr/^J/, qr/^E/]);

  # find the first person whose name is 4 characters long (using the default)
  my $four = Person->first_match([@people], sub { length == 4 });

=head1 DESCRIPTION

This role adds flexible matching and searching capabilities to your Moose
class. It provides a match method, which tests attributes and methods of your
object against strings, regexes, or coderefs, and also provides several class
methods for using match on lists of objects.

=head2 PARAMETERS

MooseX::Role::Matcher is a parameterized role (see
L<MooseX::Role::Parameterized>). The parameters it takes are:

=over

=item default_match

Which attribute/method to test against by default, if none are specified
explicitly. Setting default_match to 'foo' allows using $obj->match('bar')
rather than $obj->match(foo => 'bar').

=back

=cut

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

=method first_match

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns the first object for which match returns true.

=cut

method first_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&first, @_);
};

=method grep_matches

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns the each object for which match returns true.

=cut

method grep_matches => sub {
    my $class = shift;
    my $grep = sub { my $code = shift; grep { $code->() } @_ };
    $class->_apply_to_matches($grep, @_);
};

=method any_match

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns true if any C<match> calls return true,
otherwise returns false.

=cut

method any_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&any, @_);
};

=method all_match

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns false if any C<match> calls return false,
otherwise returns true.

=cut

method all_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&all, @_);
};

method _match => sub {
    my $self = shift;
    my $value = shift;
    my $seek = shift;

    return !defined $value if !defined $seek;
    return 0 if !defined $value;
    return $value =~ $seek if ref($seek) eq 'Regexp';
    if (ref($seek) eq 'CODE') {
        local $_ = $value;
        return $seek->();
    }
    if (ref($seek) eq 'ARRAY') {
        for (@$seek) {
            return 1 if $self->_match($value => $_);
        }
    }
    return $value eq $seek;
};

=method match

=cut

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

=head1 TODO

=head1 SEE ALSO

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-moosex-role-matcher at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Role-Matcher>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Role::Matcher

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Role-Matcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Matcher>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Role-Matcher>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Role-Matcher>

=back

=cut

1;
