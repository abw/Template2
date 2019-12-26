# Template::Plugin::CGI
requires "CGI" => ">= 4.44";

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on "test" => sub {
        requires "File::Temp"                => 0;
        requires "Test2::Bundle::Extended"   => 0;
        requires "Test2::Plugin::NoWarnings" => 0;
        requires "Test2::Suite"              => 0;
        requires "Test2::Tools::Explain"     => 0;
        requires "Test::Builder"             => 0;
        requires "Test::CPAN::Meta"          => 0;
        requires "Test::More"                => 0;
};