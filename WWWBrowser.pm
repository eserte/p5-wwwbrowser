# -*- perl -*-

#
# $Id: WWWBrowser.pm,v 2.3 2000/07/22 20:00:00 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999, 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package WWWBrowser;

# In main sollte folgendes definiert sein:
#   $os: Betriebssystem (win, mac oder unix)
#   &status_message: Fehlermeldungsroutine
# @INC muss für das Laden von Win32Util erweitert sein (nur Win32)

use strict;
use vars qw(@unix_browsers);

# XXX Hmmm, kfmclient lädt kfm, und das stellt gleich die KDE-Icons
# auf dem Desktop dar, auch wenn KDE gar nicht läuft. Trotzdem ist
# kfm wahrscheinlich billiger als netscape.
@unix_browsers = qw(netscape Netscape kfmclient
		    w3m lynx
		    mosaic Mosaic
		    chimera arena tkweb) if !@unix_browsers;

$main::os = ($^O eq 'MSWin32' ? 'win' : 'unix') unless defined $main::os;
if (!defined &main::status_message) {
    eval 'sub status_message { warn $_[0] }';
}

sub start_browser {
    my $url = shift;

    if ($main::os eq 'win') {
	require Win32Util;
	if (!Win32Util::start_html_viewer($url)) {
	    status_message("Es wurde kein HTML-Viewer gefunden.",
			   "err");
	    return 0;
	} else {
	    return 1;
	}
    }

    foreach my $browser (@unix_browsers) {
	next if (!is_in_path($browser));
	if ($browser =~ /^(lynx|w3m)$/) { # text-orientierte Browser
	    foreach my $term (qw(xterm kvt gnome-terminal)) {
		if (is_in_path($term)) {
		    exec_bg($term, ($term eq 'gnome_terminal' ? '-x' : '-e'),
			    $browser, $url);
		    return 1;
		}
	    }
	    next;
	}
	my $url = $url;
	if ($browser =~ /^mosaic$/i &&
	    $url =~ /^file:/ && $url !~ m|file://|) {
	    $url =~ s|file:/|file://localhost/|;
	} elsif ($browser eq 'kfmclient') {
	    exec_bg("kfmclient", "openURL", $url);
	    return 1 if (!$?)
	} elsif ($browser eq 'netscape') {
	    if ($main::os eq 'unix') {
		if (-l "$ENV{HOME}/.netscape/lock") {
		    # XXX check whether netscape stills lives
		    # with kill -$$
		    exec_bg("netscape", "-remote", "openURL($url)");
		    # XXX check return code?
		    return 1;
		} else {
		    exec_bg("netscape", $url);
		    return 1;
		}
	    }
	} else {
	    exec_bg($browser, $url);
	    return 1;
	}
    }

    status_message("Es wurde kein HTML-Viewer gefunden.", "err");

    return 0;
}

sub exec_bg {
    my(@cmd) = @_;
    if ($main::os eq 'unix') {
	eval {
	    if (fork == 0) {
		exec @cmd;
		die "Can't exec @cmd: $!";
	    }
	};
    } else {
	# XXX use Spawn
	system(join(" ", @cmd) . "&");
    }
}

# REPO BEGIN
# REPO NAME is_in_path
# REPO MD5 3beca578b54468d079bd465a90ebb198
=head2 is_in_path($prog)

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

=cut

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
if (!Getopt::Long::GetOptions("-browser=s" => \$browser)) { die "usage!" }
if ($browser) { unshift @WWWBrowser::unix_browsers, $browser }

WWWBrowser::start_browser $ARGV[0];

__END__
