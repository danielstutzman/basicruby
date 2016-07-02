#!/bin/bash -ex

if [ "$1" == "" ]; then
  echo 1>&2 "First arg: .pgdump.sql file to pg_restore"
  exit 1
fi
DUMPFILE=$1

INSTANCE_IP=`tugboat droplets | grep 'basicruby ' | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+"`
echo INSTANCE_IP=$INSTANCE_IP

scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -p 2222 $DUMPFILE root@$INSTANCE_IP:/tmp/$DUMPFILE

ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -p 2222 root@$INSTANCE_IP <<EOF
set -e
cd /tmp # eliminate warning
for TABLE_NAME in \`sudo -u postgres psql -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"\`; do sudo -u postgres psql -c "drop table \$TABLE_NAME cascade"; done
cat /tmp/$DUMPFILE | sudo -u postgres psql -U postgres -d postgres
EOF
