# -*- perl -*-

#
# $Id: WWWBrowser.pm,v 1.4 1999/06/29 00:10:29 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package WWWBrowser;

# in main muss folgendes definiert sein:
# $os: Betriebssystem (win, mac oder unix)
# &status_message: Fehlermeldungsroutine
# @INC muss für das Laden von BBBikeUtil und Win32Util erweitert sein

use strict;
use BBBikeUtil;

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

    # XXX Hmmm, kfmclient lädt kfm, und das stellt gleich die KDE-Icons
    # auf dem Desktop dar, auch wenn KDE gar nicht läuft. Trotzdem ist
    # kfm wahrscheinlich billiger als netscape.
    # XXX Vielleicht auch einen Lieblingsbrowser angeben lassen (Optionen).
    foreach my $browser (qw(netscape Netscape kfmclient lynx mosaic Mosaic
			    chimera arena tkweb)) {
	next if (!is_in_path($browser));
	if ($browser eq 'lynx') { # text-orientierte Browser
	    if (is_in_path('xterm')) {
		exec_bg('xterm', '-e', $browser, $url);
		return 1;
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

1;

__END__
