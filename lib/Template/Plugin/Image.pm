#============================================================= -*-Perl-*-
#
# Template::Plugin::Image
#
# DESCRIPTION
#  Plugin for encapsulating information about an image.
#
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
# COPYRIGHT
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Plugin::Image;

require 5.004;

use strict;
use Image::Size;
use Template::Plugin;
use File::Spec;
use base qw( Template::Plugin );

use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);



#------------------------------------------------------------------------
# new($context, $name, \%config)
#
# Create a new Image object.  Takes the pathname of the file as
# the argument following the context and an optional 
# hash reference of configuration parameters.
#------------------------------------------------------------------------

sub new {
    my $config = ref($_[-1]) eq 'HASH' ? pop(@_) : { };
    my ($class, $context, $name) = @_;
    my ($root, $file);

    # name can be a positional or named argument
    $name = $config->{ name } unless defined $name;

    return $class->throw('no image file specified')
	unless defined $name and length $name;

    # name can be specified as an absolute path or relative
    # to a root directory 

    if ($root = $config->{ root }) {
        $file = File::Spec->catfile($root, $name);
    }
    else {
        $file = $name;
    }
        
    # do we want to check to see if file exists?

    bless { 
	name => $name,
        file => $file,
        root => $root,
    }, $class;
}


#------------------------------------------------------------------------
# size()
#
# Return the width and height of the image as a 2 element list.
#------------------------------------------------------------------------

sub size {
    my $self = shift;

    # return cached size
    return $self->{ size } if $self->{ size };

    my ($width, $height, $error ) = imgsize($self->{ file });
    return $self->throw($error) unless defined $width;
    $self->{ width  } = $width;
    $self->{ height } = $height;
    return ($self->{ size } = [ $width, $height ]);
}


#------------------------------------------------------------------------
# width()
#
# Return the width of the image.
#------------------------------------------------------------------------

sub width {
    my $self = shift;
    $self->size() unless $self->{ size };
    return $self->{ width };
}


#------------------------------------------------------------------------
# height()
#
# Return the height of the image.
#------------------------------------------------------------------------

sub height {
    my $self = shift;
    $self->size() unless $self->{ size };
    return $self->{ height };
}


#------------------------------------------------------------------------
# attr()
#
# Return the width and height as HTML/XML attributes.
#------------------------------------------------------------------------

sub attr {
    my $self = shift;
    my $size = $self->size();
    return "width=\"$size->[0]\" height=\"$size->[1]\"";
}


#------------------------------------------------------------------------
# tag(\%options)
#
# Return an XHTML img tag.
#------------------------------------------------------------------------

sub tag {
    my $self = shift;
    my $options = ref $_[0] eq 'HASH' ? shift : { @_ };

    my $tag = "<img src=\"$self->{ name }\" " . $self->attr();

    if (%$options) {
        while (my ($key, $val) = each %$options) {
            $tag .= " $key=\"$val\"";
        }
    }

    $tag .= ' />';

    return $tag;
}


sub throw {
    my ($self, $error) = @_;
    die (Template::Exception->new('Image', $error));
}

1;

__END__


