use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $prereq = {};
if ($^O eq 'MSWin32') {
    $prereq->{'Win32Util'} = 0;
}

WriteMakefile(
    'NAME'		=> 'WWWBrowser',
    'VERSION_FROM'	=> 'WWWBrowser.pm',
    'PREREQ_PM'		=> $prereq,
    'EXE_FILES'         => ['anybrowser'],
);
