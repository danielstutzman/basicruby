#!/bin/bash -ex

if [ "$1" == "" ]; then
  echo 1>&2 "First arg: .pgdump.sql file to pg_restore"
  exit 1
fi
DUMPFILE=$1

fwknop -s -n basicruby.danstutzman.com
scp $DUMPFILE root@basicruby.danstutzman.com:/tmp/$DUMPFILE

ssh root@basicruby.danstutzman.com <<EOF
set -e
cd /tmp # eliminate warning
for TABLE_NAME in \`sudo -u postgres psql -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"\`; do sudo -u postgres psql -c "drop table \$TABLE_NAME cascade"; done
cat /tmp/$DUMPFILE | sudo -u postgres psql -U postgres -d postgres
EOF
