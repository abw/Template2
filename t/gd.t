#============================================================= -*-perl-*-
#
# t/gd.t
#
# Test the GD plugin.  Tests are based on the GD module tests.
#
# Written by Craig Barratt <craig@arraycomm.com>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
$^W = 1;

eval "use GD;";

if ( $@ || $GD::VERSION < 1.20 ) {
    skip_all('GD module(s) not installed');
}

test_expect(\*DATA, { 
    FILTERS => {
        hex => \&hex_filter,
    }
});

#
# write text out in hex format.
#
sub hex_filter {
    my $text = shift;
    $text =~ s/(.)/sprintf("%02x", ord($1))/esg;
    $text =~ s/(.{70})/$1\n/g;
    return $text;
}

__END__

-- test --
[% FILTER replace('.');
    #
    # This is test2 from GD-1.xx/t/GD.t
    #
    USE gd_c = GD.Constants;
    USE im = GD.Image(300,300);
    white = im.colorAllocate(255, 255, 255);
    black = im.colorAllocate(0, 0, 0);
    red = im.colorAllocate(255, 0, 0);
    blue = im.colorAllocate(0,0,255);
    yellow = im.colorAllocate(255,250,205);
    USE brush = GD.Image(10,10);
    brush.colorAllocate(255,255,255); # white
    brush.colorAllocate(0,0,0);       # black
    brush.transparent(white);        # white is transparent
    brush.filledRectangle(0,0,5,2,black); # a black rectangle
    im.setBrush(brush);
    im.arc(100,100,100,150,0,360,gd_c.gdBrushed);
    USE poly = GD::Polygon;
    poly.addPt(30,30);
    poly.addPt(100,10);
    poly.addPt(190,290);
    poly.addPt(30,290);
    im.polygon(poly,gd_c.gdBrushed);
    im.fill(132,62,blue);
    im.fill(100,70,red);
    im.fill(40,40,yellow);
    im.interlaced(1);
    im.copy(im,150,150,20,20,50,50);
    im.copyResized(im,10,200,20,20,100,100,50,50);
   END; 
   out = im.png | hex;
   out.length > 6500 ? 'ok' : 'not ok'
-%]
-- expect --
ok

-- test --
[% FILTER replace('.');
    #
    # This is test3 from GD-1.xx/t/GD.t
    #
    USE im = GD.Image(100,50);
    black = im.colorAllocate(0, 0, 0);
    white = im.colorAllocate(255, 255, 255);
    red   = im.colorAllocate(255, 0, 0);
    blue  = im.colorAllocate(0,0,255);
    im.arc(50, 25, 98, 48, 0, 360, white);
    im.fill(50, 21, red);
END; -%][% im.png | hex -%]
-- expect --
89504e470d0a1a0a0000000d4948445200000064000000320203000000d75b962d0000
000c504c5445000000ffffffff00000000ff011d334a000000bc49444154789cad94c1
0d83300c451309ba01cc93117a203d3002d3f4403680037fca8a448526f1b710ea3fe6
c9f9b163db984b6ae4e3ce4755e7d64f88f2cf82787c151c0105eaf0ab708276ca0886
83bc7280d5919033a80c39826c1502a4a4fa1a608d6414c8e6c865e9ba560298894d32
926c9291680338636580b742e4a7ed8f7b10b2dc2272a27baafff5e1f9dca90eafb5f2
3ffc4f791ff0dee1fda6f428ef6b3e0bcafcf09953e694cfb6b20f941da2ec1dbeaba2
b2fdf60111b64d2854ccf25e0000000049454e44ae426082
-- test --
[% FILTER replace('.');
    #
    # This is test4 from GD-1.xx/t/GD.t
    #
    USE im = GD.Image(225,180);
    black   = im.colorAllocate(0, 0, 0);
    white   = im.colorAllocate(255, 255, 255);
    red     = im.colorAllocate(255, 0, 0);
    blue    = im.colorAllocate(0,0,255);
    yellow  = im.colorAllocate(255,250,205);
    USE poly = GD.Polygon;
    poly.addPt(0,50);
    poly.addPt(25,25);
    poly.addPt(50,50);
    im.filledPolygon(poly,blue);
    poly.offset(100,100);
    im.filledPolygon(poly,red);
    poly.map(50,50,100,100,10,10,110,60);
    im.filledPolygon(poly,yellow);
    b = poly.bounds; b0 = b.0; b1 = b.1; b2 = b.2; b3 = b.3;
    poly.map(b0,b1,b2,b3,50,20,80,160);
    im.filledPolygon(poly,white);
END; -%][% im.png | hex -%]
-- expect --
89504e470d0a1a0a0000000d49484452000000e1000000b4040300000090de560d0000
000f504c5445000000ffffffff00000000fffffacda03f5b3b0000022349444154789c
eddad96d84500c85e1591a081d4454108906f2e0fe6bca2c2c77b70df615d19cd3c0a7
ff010b242e170cc3300cc3b00fdd15224476f7eee2f4d359bc4f5367719a0a919ee223
b110e9293ec13c72f872035f8979a4a3f806b3483f714ecc22fdc4054c23ddc435318d
7413373089f41283c424d24b0cc138d2498c12a3c8eb30b8883118463a89496218e924
a66010e923668941a48f98835ba48b5848dc225dc412b8467a88c5c435d2432c834be4
30981f9d4ae212e920d6c039d24164061122c4ca1e47cee9b503224488e7179f60dfa3
031122c4d388af93d3f5e8408408f15f8bbfc7c437a8397344c748b5487490d48a4447
49a5487498d48944c749954864406a44220b52211299907231057792f3c9111c9d1cdc
478ac512b88b948a65700f29146be00e5226d6413d29125ba09a94886d504b0a440e54
92bcc8833a7201ab474702aa484e94811a9211a5a0826c8b72504e36450d28265ba20e
94920d510b0a49f6e930df0788eb91ebf675051122c4f3881bd8ebe89c52bc7517c7ef
cee26d1c3b8be3681bc98a8f44db48567c82a6919cf84ab48c0c4e4ef9e8bc41c3484e
9c130d23397101ed2219714db48b64c40d348b6c8b41a259645b0c41abc8a618255a45
36c518348a6c8949a2516408a6672e056d221b62966813d91073d024b22e16124d22eb
6209b488ac8ac5448bc8aa58060d226b6225d120b226d6c0c391d1c9e9f2ad031122c4
f38831d8fbaf720cc3300cc3b0a3fb03d69b699bd4e71fcb0000000049454e44ae4260
82
-- test --
[% FILTER replace('.');
    #
    # This is test5 from GD-1.xx/t/GD.t
    #
    USE gd_c = GD.Constants;
    USE im = GD.Image(300,300);
    white   = im.colorAllocate(255, 255, 255);
    black   = im.colorAllocate(0, 0, 0);
    red     = im.colorAllocate(255, 0, 0);
    blue    = im.colorAllocate(0,0,255);
    yellow  = im.colorAllocate(255,250,205);
    im.transparent(white);
    im.interlaced(1);
    USE brush = GD.Image(10,10);
    brush.colorAllocate(255,255,255);
    brush.colorAllocate(0,0,0);
    brush.transparent(white);
    brush.filledRectangle(0,0,5,2,black);
    im.string(gd_c.gdLargeFont,150,10,"Hello world!",red);
    im.string(gd_c.gdSmallFont,150,28,"Goodbye cruel world!",blue);
    im.stringUp(gd_c.gdTinyFont,280,250,"I'm climbing the wall!",black);
    im.charUp(gd_c.gdMediumBoldFont,280,280,"Q",black);
    im.setBrush(brush);
    im.arc(100,100,100,150,0,360,gd_c.gdBrushed);
    USE poly = GD.Polygon;
    poly.addPt(30,30);
    poly.addPt(100,10);
    poly.addPt(190,290);
    poly.addPt(30,290);
    im.polygon(poly,gd_c.gdBrushed);
    im.fill(132,62,blue);
    im.fill(100,70,red);
    im.fill(40,40,yellow);
  END;
  out = im.png | hex;
  out.length > 6500 ? 'ok' : 'not ok'
-%]
-- expect --
ok
