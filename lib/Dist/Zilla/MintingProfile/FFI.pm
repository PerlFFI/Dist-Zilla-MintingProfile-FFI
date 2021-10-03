use strict;
use warnings;
use 5.020;
use experimental qw( postderef );

package Dist::Zilla::MintingProfile::FFI {

  use Moose;
  with 'Dist::Zilla::Role::MintingProfile::ShareDir';
  use namespace::autoclean;

  # ABSTRACT: A minimal Dist::Zilla minting profile for FFI

  __PACKAGE__->meta->make_immutable;
}

1;

=head1 SYNOPSIS

 dzil new -P FFI Foo::FFI

=head1 DESCRIPTION

This is a L<Dist::Zilla> minting profile for creating L<FFI::Platypus> bindings.
It uses a reasonable template and the L<[@Starter]|Dist::Zilla::PluginBundle::Starter>
or L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> bundle plus some
FFI specific plugins.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<[@Starter]|Dist::Zilla::PluginBundle::Starter>

=item L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git>

=back

=cut
