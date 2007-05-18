package Polebot::Plugin::Perldoc;
use strict;
use warnings;
use base 'Polebot::Plugin::Base';

my %perlfunc_valid = map { $_ => 1 } (
   'abs',              'accept',
   'alarm',            'atan2',
   'bind',             'binmode',
   'bless',            'caller',
   'chdir',            'chmod',
   'chomp',            'chop',
   'chown',            'chr',
   'chroot',           'close',
   'closedir',         'connect',
   'continue',         'cos',
   'crypt',            'dbmclose',
   'dbmopen',          'defined',
   'delete',           'die',
   'do',               'dump',
   'each',             'endgrent',
   'endhostent',       'endnetent',
   'endprotoent',      'endpwent',
   'endservent',       'eof',
   'eval',             'exec',
   'exists',           'exit',
   'exp',              'fcntl',
   'fileno',           'flock',
   'fork',             'format',
   'formline',         'getc',
   'getgrent',         'getgrgid',
   'getgrnam',         'gethostbyaddr',
   'gethostbyname',    'gethostent',
   'getlogin',         'getnetbyaddr',
   'getnetbyname',     'getnetent',
   'getpeername',      'getpgrp',
   'getppid',          'getpriority',
   'getprotobynumber', 'getprotoent',
   'getpwent',         'getpwnam',
   'getservbyname',    'getservbyport',
   'getservent',       'getsockname',
   'glob',             'gmtime',
   'goto',             'grep',
   'hex',              'import',
   'index',            'int',
   'ioctl',            'join',
   'keys',             'kill',
   'last',             'lc',
   'lcfirst',          'length',
   'link',             'listen',
   'local',            'localtime',
   'log',              'lstat',
   'm',                'map',
   'mkdir',            'msgctl',
   'msgget',           'msgrcv',
   'msgsnd',           'my',
   'next',             'no',
   'oct',              'open',
   'opendir',          'ord',
   'our',              'pack',
   'package',          'pipe',
   'pop',              'pos',
   'print',            'printf',
   'prototype',        'push',
   'qq',               'qr',
   'q',                'quotemeta',
   'qw',               'qx',
   'rand',             'read',
   'readdir',          'readline',
   'readlink',         'readpipe',
   'recv',             'redo',
   'ref',              'rename',
   'require',          'reset',
   'return',           'reverse',
   'rewinddir',        'rindex',
   'rmdir',            's',
   'scalar',           'seek',
   'seekdir',          'select',
   'semctl',           'semget',
   'semop',            'send',
   'setgrent',         'sethostent',
   'setnetent',        'setpgrp',
   'setpriority',      'setpwent',
   'setservent',       'setsockopt',
   'shift',            'shmctl',
   'shmget',           'shmread',
   'shmwrite',         'shutdown',
   'sin',              'sleep',
   'socket',           'socketpair',
   'getsockopt',       'sort',
   'splice',           'split',
   'sprintf',          'sqrt',
   'srand',            'stat',
   'study',            'sub',
   'substr',           'symlink',
   'syscall',          'sysopen',
   'sysread',          'sysseek',
   'system',           'syswrite',
   'tell',             'telldir',
   'tie',              'tied',
   'time',             'times',
   'getprotobyname',   'setprotoent',
   'tr',               'truncate',
   'uc',               'ucfirst',
   'umask',            'undef',
   'unlink',           'unpack',
   'unshift',          'untie',
   'use',              'utime',
   'values',           'vec',
   'wait',             'waitpid',
   'wantarray',        'warn',
   'write',            'getpwuid',
   '-X',               'y',
);

my %perldoc_valid = map { $_ => 1 } (
   'perl',          'perlintro',      'perltoc',       'perlreftut',
   'perldsc',       'perllol',        'perlrequick',   'perlretut',
   'perlboot',      'perltoot',       'perltooc',      'perlbot',
   'perlstyle',     'perlcheat',      'perltrap',      'perldebtut',
   'perlfaq',       'perlfaq1',       'perlfaq2',      'perlfaq3',
   'perlfaq4',      'perlfaq5',       'perlfaq6',      'perlfaq7',
   'perlfaq8',      'perlfaq9',       'perlsyn',       'perldata',
   'perlop',        'perlsub',        'perlfunc',      'perlopentut',
   'perlpacktut',   'perlpod',        'perlpodspec',   'perlrun',
   'perldiag',      'perllexwarn',    'perldebug',     'perlvar',
   'perlre',        'perlreref',      'perlref',       'perlform',
   'perlobj',       'perltie',        'perldbmfilter', 'perlipc',
   'perlfork',      'perlnumber',     'perlthrtut',    'perlothrtut',
   'perlport',      'perllocale',     'perluniintro',  'perlunicode',
   'perlebcdic',    'perlsec',        'perlmod',       'perlmodlib',
   'perlmodstyle',  'perlmodinstall', 'perlnewmod',    'perlutil',
   'perlcompile',   'perlfilter',     'perlembed',     'perldebguts',
   'perlxstut',     'perlxs',         'perlclib',      'perlguts',
   'perlcall',      'perlapi',        'perlintern',    'perliol',
   'perlapio',      'perlhack',       'perlbook',      'perltodo',
   'perldoc',       'perlhist',       'perldelta',     'perl586delta',
   'perl585delta',  'perl584delta',   'perl583delta',  'perl582delta',
   'perl581delta',  'perl58delta',    'perl573delta',  'perl572delta',
   'perl571delta',  'perl570delta',   'perl561delta',  'perl56delta',
   'perl5005delta', 'perl5004delta',  'perlartistic',  'perlgpl',
   'perlcn',        'perljp',         'perlko',        'perltw',
   'perlaix',       'perlamiga',      'perlapollo',    'perlbeos',
   'perlbs2000',    'perlce',         'perlcygwin',    'perldgux',
   'perldos',       'perlepoc',       'perlfreebsd',   'perlhpux',
   'perlhurd',      'perlirix',       'perlmachten',   'perlmacos',
   'perlmacosx',    'perlmint',       'perlmpeix',     'perlnetware',
   'perlopenbsd',   'perlos2',        'perlos390',     'perlos400',
   'perlplan9',     'perlqnx',        'perlsolaris',   'perltru64',
   'perluts',       'perlvmesa',      'perlvms',       'perlvos',
   'perlwin32',
);

sub description { 'tell links about perl documentation' }

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;

   my $channel = $where->[0];
   if (my ($function) = $msg =~ /perldoc\s+-f\s+(\w+)/mxs) {
      $self->say("prova "
           . "http://perldoc.perl.org/functions/$function.html "
           . "o http://www.perl.it/documenti/perlfunc/view.html?func=$function "
           . "(se esistono!)")
        if exists $perlfunc_valid{$function};
   } ## end if (my ($function) = $msg...
   elsif (my ($doc) = $msg =~ /perldoc\s+(\w+)/mxs) {
      $self->say(
             "prova "
           . "http://perldoc.perl.org/$doc.html "
           . "http://pod2it.sourceforge.net/pods/$doc.html "
           . "(se esistono!)"
      ) if exists $perldoc_valid{$doc};
   } ## end elsif (my ($doc) = $msg =~...
   return;
} ## end sub public

1;
