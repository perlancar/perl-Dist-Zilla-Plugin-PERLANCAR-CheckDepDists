package Dist::Zilla::Plugin::PERLANCAR::CheckDepDists;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::AfterBuild',
);

use App::lcpan::Call qw(call_lcpan_script);
use Module::List qw(list_modules);
use Sub::NoRepeat qw(norepeat);
use Term::ANSIColor;

use namespace::autoclean;

sub after_build {
    use experimental 'smartmatch';
    no strict 'refs';

    my $self = shift;

    norepeat(
        key => __PACKAGE__ . ' ' . $self->zilla->name,
        period => '8h',
        code => sub {
            $self->log_debug(["Listing all ::Lumped & ::Fattened modules ..."]);
            my $mods = list_modules("", {list_modules=>1, recurse=>1});
            for my $mod (sort keys %$mods) {
                next unless $mod =~ /.+::(Lumped|Fattened)$/;
                my $lump = $1 eq 'Lumped';
                $self->log_debug(["Checking against %s", $mod]);
                my $mod_pm = do { local $_ = $mod; s!::!/!g; "$_.pm" };
                require $mod_pm;
                my $dists = \@{"$mod\::" . ($lump ? "LUMPED_DISTS" : "FATTENED_DISTS")};
                if ($self->zilla->name ~~ @$dists) {
                    my $dist = $mod; $dist =~ s/::/-/g;
                    say colored(["bold cyan"], "This distribution also needs to be rebuilt: $dist");
                }
            }
        },
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Check for dists that depend on the dist you're building

=for Pod::Coverage .+

=head1 SYNOPSIS

In C<dist.ini>:

 [PERLANCAR::CheckDepDists]


=head1 DESCRIPTION

This plugin checks for dists that depend on the dist you're building. Currently
what it does:

=over

=item *

In the after_build phase, search your local installation for all lump dists (via
searching all modules whose name ends with C<::Lumped>). Inside each of these
modules, there is a C<@LUMPED_DISTS> array which lists all the dists that the
lump dist includes. When the current dist you're building is listed in
C<@LUMPED_DISTS>, the plugin will issue a notification that you will also need
to rebuild the associated lump dist.

=item *

In the after_build phase, search your local installation for all fattened dists
(via searching all modules whose name ends with C<::Fattened>). Inside each of
these modules, there is a C<@FATTENED_DISTS> array which lists all the dists
that the fattened dist includes. When the current dist you're building is listed
in C<@FATTENED_DISTS>, the plugin will issue a notification that you will also
need to rebuild the associated fattened dist.

=back


=head1 SEE ALSO

For more information about lump dists: L<Dist::Zilla::Plugin::Lump>

For more information about fattened dists: L<Dist::Zilla::Plugin::Fatten>
