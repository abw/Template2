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
use Template::Plugin;
use File::Spec;
use base qw( Template::Plugin );

use vars qw( $VERSION $AUTOLOAD );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

BEGIN {
    if (eval { require Image::Info; }) {
        *img_info = \&Image::Info::image_info;
    }
    elsif (eval { require Image::Size; }) {
        *img_info = sub {
            my $file = shift;
            my @stuff = Image::Size::imgsize($file);
            return { "width"  => $stuff[0],
                     "height" => $stuff[1],
                     "error"  => $stuff[2]
                   };
        }
    }
    else {
        die(Template::Exception->new("image",
            "Couldn't load Image::Info or Image::Size: $@"));
    }

}

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
# init()
#
# Calls image_info on $self->{ file }
#------------------------------------------------------------------------

sub init {
    my $self = shift;
    return $self if $self->{ size };

    my $image = img_info($self->{ file });
    return $self->throw($image->{ error }) if defined $image->{ error };

    @$self{ keys %$image } = values %$image;
    $self->{ size } = [ $image->{ width }, $image->{ height } ];

    $self->{ modtime } = (stat $self->{ file })[10];

    return $self;
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
# modtime()
#
# Return last modification time as a time_t:
#
#   [% date.format(image.modtime, "%Y/%m/%d") %]
#------------------------------------------------------------------------

sub modtime {
    my $self = shift;
    $self->init;
    return $self->{ modtime };
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

sub AUTOLOAD {
    my $self = shift;
   (my $a = $AUTOLOAD) =~ s/.*:://;

    $self->init;
    return $self->{ $a };
}

1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Plugin::Image - Plugin access to image sizes

=head1 SYNOPSIS

    [% USE Image(filename) %]
    [% Image.width %]
    [% Image.height %]
    [% Image.size.join(', ') %]
    [% Image.attr %]
    [% Image.tag %]

=head1 DESCRIPTION

This plugin provides an interface to the Image::Size module for 
determining the size of image files.

You can specify the plugin name as either 'Image' or 'image'.  The
plugin object created will then have the same name.  The file name of
the image should be specified as a positional or named argument.

    [% # all these are valid, take your pick %]
    [% USE Image('foo.gif') %]
    [% USE image('bar.gif') %]
    [% USE Image 'ping.gif' %]
    [% USE image(name='baz.gif') %]
    [% USE Image name='pong.gif' %]

You can also provide an alternate name for an Image plugin object.

    [% USE img1 = image 'foo.gif' %]
    [% USE img2 = image 'bar.gif' %]

The 'width' and 'height' methods return the width and height of the
image, respectively.  The 'size' method returns a reference to a 2
element list containing the width and height.

    [% USE image 'foo.gif' %]
    width: [% image.width %]
    height: [% image.height %]
    size: [% image.size.join(', ') %]

The 'attr' method returns the height and width as HTML/XML attributes.

    [% USE image 'foo.gif' %]
    [% image.attr %]

Typical output:

    width="60" height="20"

The 'tag' method returns a complete XHTML tag referencing the image.

    [% USE image 'foo.gif' %]
    [% image.tag %]

Typical output:

    <img src="foo.gif" width="60" height="20" />

You can provide any additional attributes that should be added to the 
XHTML tag.


    [% USE image 'foo.gif' %]
    [% image.tag(border=0, class="logo") %]

Typical output:

    <img src="foo.gif" width="60" height="20" border="0" class="logo" />

=head1 CATCHING ERRORS

If the image file cannot be found then the above methods will throw an
'Image' error.  You can enclose calls to these methods in a
TRY...CATCH block to catch any potential errors.

    [% TRY;
         image.width;
       CATCH;
         error;      # print error
       END
    %]

=head1 AUTHOR

Andy Wardley E<lt>abw@andywardley.comE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

1.01, distributed as part of the
Template Toolkit version 2.08c, released on 04 November 2002.

=head1 COPYRIGHT

  Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>
