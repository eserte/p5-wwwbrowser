# -*- perl -*-

#
# $Id: WWWBrowser.pm,v 2.8 2001/08/20 14:04:55 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999,2000,2001 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package WWWBrowser;

use strict;
use vars qw(@unix_browsers $VERSION $initialized $os);

$VERSION = sprintf("%d.%02d", q$Revision: 2.8 $ =~ /(\d+)\.(\d+)/);

# XXX Hmmm, kfmclient lädt kfm, und das stellt gleich die KDE-Icons
# auf dem Desktop dar, auch wenn KDE gar nicht läuft. Trotzdem ist
# kfm wahrscheinlich billiger als netscape.
@unix_browsers = qw(netscape Netscape kfmclient
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
	$initialized++;
    }
}

sub start_browser {
    my $url = shift;

    if ($os eq 'win') {
	require Win32Util;
	if (!Win32Util::start_html_viewer($url)) {
	    status_message("Can't find HTML viewer.", "err");
	    return 0;
	} else {
	    return 1;
	}
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
	if ($browser =~ /^mosaic$/i &&
	    $url =~ /^file:/ && $url !~ m|file://|) {
	    $url =~ s|file:/|file://localhost/|;
	} elsif ($browser eq 'kfmclient') {
	    exec_bg("kfmclient", "openURL", $url);
	    return 1 if (!$?)
	} elsif ($browser eq 'netscape') {
	    if ($os eq 'unix') {
		if (-l "$ENV{HOME}/.netscape/lock") {
		    # XXX check whether netscape stills lives
		    # with kill -$$
# another argument to openURL: create new window
		    exec_bg("netscape", "-remote", "openURL($url)");
# further options: mailto(to-adresses)
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

    status_message("Can't find HTML viewer.", "err");

    return 0;
}

sub exec_bg {
    my(@cmd) = @_;
    if ($os eq 'unix') {
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
