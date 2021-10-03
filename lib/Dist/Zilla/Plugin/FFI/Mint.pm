use strict;
use warnings;
use 5.026;

package Dist::Zilla::Plugin::FFI::Mint {

  use Moose;
  with 'Dist::Zilla::Role::FileMunger', 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::ModuleMaker';
  use experimental qw( signatures postderef );
  use Dist::Zilla::File::InMemory;
  use namespace::autoclean;

  # ABSTRACT: Generate module and modify dist.ini for use with FFI

  has lib_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      $self->zilla->chrome->prompt_str("Library name (for libfoo.so or foo.dll enter 'foo')");
    },
  );

  has alien_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      $self->zilla->chrome->prompt_str("Fallback Alien name");
    },
  );

  has module_package => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
  );

  has module_filename => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
  );

  has lib_package => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub ($self) {
      $self->module_package . "::Lib";
    },
  );

  has lib_filename => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub ($self) {
      $self->module_filename =~ s/\.pm$/\/Lib.pm/r;
    },
  );

  has test_filename => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub ($self) {
      't/' . lc($self->module_package =~ s/::/_/gr) . ".t";
    },
  );

  sub munge_files ($self)
  {
    my($dist_ini) = grep { $_->name eq 'dist.ini' } @{ $self->zilla->files };
    $self->log_fatal("unable to find dist.ini") unless defined $dist_ini;

    $self->log("Munge: @{[ $dist_ini->name ]}");

    my $code = $dist_ini->code;

    # this is hilariously stupid but this is what we are doing.
    $dist_ini->code(sub {
      my $content = $code->();
      $content =~ s/##LIB_FILENAME##/$self->lib_filename/eg;
      $content =~ s/##LIB_MODULENAME##/$self->lib_package/eg;
      $content =~ s/##ALIEN_NAME##/$self->alien_name/eg;
      $content;
    });
  }

  sub gather_files ($self)
  {
    $self->log("Generate: @{[ $self->lib_filename ]}");
    $self->add_file(
      Dist::Zilla::File::InMemory->new({
        name    => $self->lib_filename,
        content => <<~"END",
          package @{[ $self->lib_package ]};

          use strict;
          use warnings;
          use FFI::CheckLib 0.28 qw( find_lib );

          sub lib {
            find_lib lib => '@{[ $self->lib_name ]}', alien => '@{[ $self->alien_name ]}';
          }

          1;

          =head1 NAME

          @{[ $self->lib_package ]} - Private class for @{[ $self->module_package ]}

          =head1 SYNOPSIS

           perldoc @{[ $self->module_package ]}

          =head1 DESCRIPTION

          This class is private.

          =head1 SEE ALSO

          =over 4

          =item @{[ $self->module_package ]}

          =back

          =cut
          END
      })
    );

    $self->log("Generate: @{[ $self->test_filename ]}");
    $self->add_file(
      Dist::Zilla::File::InMemory->new({
        name    => $self->test_filename,
        content => <<~"END",
          use Test2::V0;
          use @{[ $self->module_package ]};

          ok 1;

          done_testing;
          END
      }),
    );
  }

  sub make_module ($self, $arg)
  {
    $self->module_package($arg->{name});
    $self->module_filename("lib/" . ($arg->{name} =~ s/::/\//gr) . ".pm");
    $self->log("Creating main module: @{[ $self->module_filename ]}");

    my $file = Dist::Zilla::File::InMemory->new({
      name => $self->module_filename,
      content => <<~"END",
        package @{[ $self->module_package ]};

        use strict;
        use warnings;
        use FFI::Platypus 1.00;
        use @{[ $self->module_package ]}::Lib;

        my \$ffi = FFI::Platypus->new(
          api => 1,
          lib => [@{[ $self->module_package ]}::Lib->lib],
        );

        #\$ffi->attach( ... );

        1;

        =head1 NAME

        @{[ $self->module_package ]} - Bindings for ...

        =head1 SYNOPSIS

         ...

        =head1 DESCRIPTION

        ...

        =cut
        END
    });
    $self->add_file($file);
  }

  __PACKAGE__->meta->make_immutable;
}

1;

=head1 SYNOPSIS

 dzil new -P FFI Foo::FFI

=head1 DESCRIPTION

This plugin will prompt you for a library which will be used by your
FFI module.  Its intended use if by the FFI minting profile, but may
be useful in your own FFI related profiles.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<Dist::Zilla::MintingProfile::FFI>

=item L<Dist::Zilla>

=back

=cut

