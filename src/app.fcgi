#!/bin/sh

cd $(dirname $0)
if [ "$ENV" = "devel" ]; then
    EXTRA_WATCH_DIRS="-R $DOCROOT"
fi

set -x

export PERL_HASH_SEED=0
exec plackup -s FCGI -r $EXTRA_WATCH_DIRS --access-log=/dev/null
