#============================================================= -*-Perl-*-
# 
# Template::Stash::XS
# 
# DESCRIPTION
#
#   Perl bootstrap for XS module. Inherits methods from 
#   Template::Stash when not implemented in the XS module.
#
#========================================================================

package Template::Stash::XS;

use Template;
use Template::Stash;

BEGIN {
  require DynaLoader;
  @Template::Stash::XS::ISA = qw( DynaLoader Template::Stash );

  eval {
    bootstrap Template::Stash::XS $Template::VERSION;
  };
  if ($@) {
    die "Couldn't load Template::Stash::XS $Template::VERSION:\n\n$@\n";
  }
}


sub DESTROY {
  # no op
  1;
}


# catch missing method calls here so perl doesn't barf 
# trying to load *.al files 
sub AUTOLOAD {
  my ($self, @args) = @_;
  my @c             = caller(0);
  my $auto	    = $AUTOLOAD;

  $auto =~ s/.*:://;
  $self =~ s/=.*//;

  die "Can't locate object method \"$auto\"" .
      " via package \"$self\" at $c[1] line $c[2]\n";
}

1;

__END__

=head1 NAME

Template::Stash::XS - Experimental high-speed stash

=head1 SYNOPSIS

 use Template::Stash;
 use Template::Stash::XS;

 my $stash = Template::Stash::XS->new();
 my $tt    = Template->new({ STASH => $stash });

=head1 DESCRIPTION

This module loads the XS version of Template::Stash::XS. It should 
behave very much like the old one, but run about twice as fast. 
See the synopsis above for usage information.

Only a few methods (such as get and set) have been implemented in XS. 
The others are inherited from Template::Stash.

=head1 NOTE

To always use the XS version of Stash, modify the Template/Config.pm 
module near line 45:

 $STASH    = 'Template::Stash::XS';

If you make this change, then there is no need to explicitly create 
an instance of Template::Stash::XS as seen in the SYNOPSIS above. Just
use Template as normal.

Alternatively, in your code add this line before creating a Template
object:

 $Template::Config::STASH = 'Template::Stash::XS';


To use the original, pure-perl version restore this line in 
Template/Config.pm:

 $STASH    = 'Template::Stash';

Or in your code:

 $Template::Config::STASH = 'Template::Stash';


=head1 BUGS

Please report bugs to the Template Toolkit mailing list
templates@template-toolkit.org

=head1 VERSION

$Id$

=head1 SEE ALSO

L<Template::Stash|Template::Stash>


