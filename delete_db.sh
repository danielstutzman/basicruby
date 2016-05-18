#!/bin/bash -ex
PSQL=/Applications/Postgres.app/Contents/MacOS/bin/psql
echo "delete from completions; delete from exercises; delete from topics;" | $PSQL -U postgres -d basicruby
