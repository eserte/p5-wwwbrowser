use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $prereq = {};
if ($^O eq 'MSWin32') {
    $prereq->{'Win32Util'} = undef;
}

WriteMakefile(
    'NAME'		=> 'WWWBrowser',
    'VERSION_FROM'	=> 'WWWBrowser.pm', # finds $VERSION
    'PREREQ_PM'		=> $prereq, # e.g., Module::Name => 1.1
);