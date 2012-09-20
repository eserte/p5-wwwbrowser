#!/usr/bin/perl -w

use strict;
use Test::More;

use Cwd qw(cwd);
use Sys::Hostname qw(hostname);
use File::Spec;
use Getopt::Long;

plan tests => 2;

if (0) { # cease -w
    $WWWBrowser::VERBOSE = $WWWBrowser::VERBOSE;
    $WWWBrowser::available_browsers = $WWWBrowser::available_browsers;
}

$WWWBrowser::VERBOSE = 1;

use_ok("WWWBrowser");

my $all;

GetOptions("browser=s" => sub {
	       my $browser = $_[1];
	       @WWWBrowser::unix_browsers = $browser;
	   },
	   "all!" => \$all,
	   "v" => sub { $WWWBrowser::VERBOSE = 2 },
	  )
    or die "usage: $0 [-browser browser]";

my $local_html_url = "file:" . File::Spec->catfile(cwd, "test.html");

if ($all) {
    for my $browser (@WWWBrowser::available_browsers) {
	local @WWWBrowser::unix_browsers = $browser;
	print STDERR "*** Try $browser...\n";
	WWWBrowser::start_browser($local_html_url."?query=,)");
	print STDERR "*** Press RETURN to continue...\n";
	<STDIN>;
    }
} else {
    if (!$ENV{BATCH}) {
	WWWBrowser::start_browser($local_html_url);
	WWWBrowser::start_browser($local_html_url."?query=,)");
    }
}

pass("Did you see a simple page in a WWW browser?");
