#!/usr/bin/env perl
# -*- perl -*-

#
# $Id: WWWBrowser.pm,v 2.13 2001/11/17 12:09:54 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999,2000,2001 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven.rezic@berlin.de
# WWW:  http://www.rezic.de/eserte/
#

package WWWBrowser;

use strict;
use vars qw(@unix_browsers $VERSION $initialized $os $fork);

$VERSION = sprintf("%d.%02d", q$Revision: 2.13 $ =~ /(\d+)\.(\d+)/);

@unix_browsers = qw(konqueror netscape Netscape kfmclient
		    dillo w3m lynx
		    mosaic Mosaic
		    chimera arena tkweb) if !@unix_browsers;

init();

sub init {
    if (!$initialized) {
	if (!defined $main::os) {
	    $os = ($^O eq 'MSWin32' ? 'win' : 'unix');
	} else {
	    $os = $main::os;
	}
	if (!defined &main::status_message) {
	    eval 'sub status_message { warn $_[0] }';
	} else {
	    eval 'sub status_message { main::status_message(@_) }';
	}
	$fork = 1;
	$initialized++;
    }
}

sub start_browser {
    my $url = shift;

    if ($os eq 'win') {
	if (!eval 'require Win32Util;
	           Win32Util::start_html_viewer($url)') {
	    # if this fails, just try to start a default viewer
	    system($url);
	    # otherwise croak
	    if ($?/256 != 0) {
		status_message("Can't find HTML viewer.", "err");
		return 0;
	    }
	}
	return 1;
    }

    foreach my $browser (@unix_browsers) {
	next if (!is_in_path($browser));
	if ($browser =~ /^(lynx|w3m)$/) { # text-orientierte Browser
	    if (defined $ENV{DISPLAY} && $ENV{DISPLAY} ne "") {
		foreach my $term (qw(xterm kvt gnome-terminal)) {
		    if (is_in_path($term)) {
			exec_bg($term,
				($term eq 'gnome_terminal' ? '-x' : '-e'),
				$browser, $url);
			return 1;
		    }
		}
	    } else {
		# without X11: not in background!
		system($browser, $url);
		return 1;
	    }
	    next;
	}

	next if !defined $ENV{DISPLAY} || $ENV{DISPLAY} eq '';
	# after this point only X11 browsers

	my $url = $url;
	if ($browser eq 'konqueror') {
	    return 1 if open_in_konqueror($url);
	} elsif ($browser =~ /^mosaic$/i &&
	    $url =~ /^file:/ && $url !~ m|file://|) {
	    $url =~ s|file:/|file://localhost/|;
	} elsif ($browser eq 'kfmclient') {
	    # kfmclient loads kfm, which loads and displays all KDE icons
	    # on the desktop, even if KDE is not running at all.
	    exec_bg("kfmclient", "openURL", $url);
	    return 1 if (!$?)
	} elsif ($browser eq 'netscape') {
	    if ($os eq 'unix') {
		my $lockfile = "$ENV{HOME}/.netscape/lock";
		if (-l $lockfile) {
		    my($host,$pid) = readlink($lockfile) =~ /^(.*):(\d+)$/;
		    # XXX check $host
		    # Check whether Netscape stills lives:
		    if (defined $pid && kill 0 => $pid) {
			# XXX another argument to openURL: create new window
			exec_bg("netscape", "-remote", "openURL($url)");
		        # XXX further options: mailto(to-adresses)
			# XXX check return code?
			return 1;
		    }
		}
		exec_bg("netscape", $url);
		return 1;
	    }
	} else {
	    exec_bg($browser, $url);
	    return 1;
	}
    }

    status_message("Can't find HTML viewer.", "err");

    return 0;
}

sub open_in_konqueror {
    my $url = shift;
    if (is_in_path("dcop") && is_in_path("konqueror")) {
	# try first to send to running konqueror process:
	system(qw/dcop konqueror KonquerorIface openBrowserWindow/, $url);
	return 1 if ($?/256 == 0);
	# otherwise start a new konqueror
	exec_bg("konqueror", $url);
	return 1; # if ($?/256 == 0);
    }
    0;
}

sub exec_bg {
    my(@cmd) = @_;
    if ($os eq 'unix') {
	eval {
	    if (!$fork || fork == 0) {
		exec @cmd;
		die "Can't exec @cmd: $!";
	    }
	};
    } else {
	# XXX use Spawn
	system(join(" ", @cmd) . ($fork ? "&" : ""));
    }
}

# REPO BEGIN
# REPO NAME is_in_path
# REPO MD5 3beca578b54468d079bd465a90ebb198
sub is_in_path {
    my($prog) = @_;
    require Config;
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	return $_ if -x "$_/$prog";
    }
    undef;
}
# REPO END

return 1 if caller();

package main;

require Getopt::Long;
my $browser;
if (!Getopt::Long::GetOptions("-browser=s" => \$browser,
			      "-fork!" => \$WWWBrowser::fork,
			     )) { die "usage!" }
if ($browser) { unshift @WWWBrowser::unix_browsers, $browser }

WWWBrowser::start_browser $ARGV[0];

__END__

=head1 NAME

WWWBrowser - platform independent mean to start a WWW browser

=head1 SYNOPSIS

    use WWWBrowser;
    WWWBrowser::start_browser($url);

=head1 DESCRIPTION

=head2 start_browser($url)

Start a web browser with the specified URL. The process is started in
background.

=head1 CONFIGURATION

For unix, the global variable C<@WWWBrowser::unix_browsers> can be set
to a list of preferred web browsers. The following browsers are
handled specially:

=over 4

=item lynx, w3m

Text oriented browsers, which are opened in an C<xterm>, C<kvt> or
C<gnome-terminal> (if running under X11). If not running under X11,
then no background process is started.

=item kfmclient

Use C<openURL> method of kfm.

=item netscape

Use C<-remote> option to re-use a running netscape process, if
possible.

=back

The following variables can be defined globally in the B<main>
package:

=over 4

=item C<$os>

Short name of operating system (C<win>, C<mac> or C<unix>).

=item C<&status_messages>

Error handling function (instead of default C<warn>).

=back

=head1 REQUIREMENTS

For Windows, the L<Win32Util|Win32Util> module should be installed in
the path.

=head1 AUTHOR

Slaven Rezic <eserte@cs.tu-berlin.de>

=head1 COPYRIGHT

Copyright (c) 1999,2000,2001 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Win32Util|Win32Util>.
