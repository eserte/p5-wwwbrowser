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

my $vran = hostname eq 'vran.herceg.de';
my $all;

GetOptions("browser=s" => sub {
	       my $browser = $_[1];
	       @WWWBrowser::unix_browsers = $browser;
	   },
	   "all!" => \$all,
	   "vran!" => \$vran,
	  )
    or die "usage: $0 [-browser browser]";

my $local_html_url = "file:" . File::Spec->catfile(cwd, "test.html");

if ($all) {
    for my $browser (@WWWBrowser::available_browsers) {
	local @WWWBrowser::unix_browsers = $browser;
	print STDERR "*** Try $browser...\n";
	WWWBrowser::start_browser($local_html_url);
	print STDERR "*** Press RETURN to continue...\n";
	<STDIN>;
    }
} else {
    if (!$ENV{BATCH}) {
	WWWBrowser::start_browser($local_html_url);
    }

    if ($vran) {
	WWWBrowser::start_browser("www.herceg.de", -expandurl => 1);
    }
}

pass("Did you see a simple page in a WWW browser?");
