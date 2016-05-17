#!/bin/bash -ex
INSTANCE_IP=`tugboat droplets | grep 'basicruby ' | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || true`
echo INSTANCE_IP=$INSTANCE_IP
DUMPFILE=`date -u +%Y%m%d%H%M%SZ.pgdump.sql`
tugboat ssh -n basicruby -c "sudo -u postgres pg_dump -U postgres -v > /tmp/$DUMPFILE"
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@$INSTANCE_IP:/tmp/$DUMPFILE $DUMPFILE
tugboat ssh -n basicruby -c "rm /tmp/$DUMPFILE"
