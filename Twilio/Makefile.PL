use 5.008001;
use ExtUtils::MakeMaker;

## look for previously installed version
COMPAT: {
    eval 'require Twilio::API';
    last COMPAT if $@;

    eval 'die "flatulence" if $Twilio::API::VERSION < 0.15';
    last COMPAT unless $@;

    sleep 1;
    warn <<'_COMPAT_';
======================================================================

        *** WARNING *** ACHTUNG *** CUIDADO ***

It looks like you have previously installed a version of
Twilio::API which is incompatible with this current release.

You have two options:

1) don't upgrade unless you need a new feature (note that 0.15
   contains no code changes other than the default API).

2) upgrade using one of the two methods found in the documentation
   under "COMPATIBILITY NOTICE".

Thanks for using Twilio::API!

======================================================================
_COMPAT_
}

WriteMakefile(
    NAME              => 'Twilio::API',
    VERSION_FROM      => 'lib/Twilio/API.pm',
    PREREQ_PM         => { LWP::Protocol::https => 6.06,
                           LWP::UserAgent => 6.13,
                           URI::Escape    => 3.31, },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Twilio/API.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);
