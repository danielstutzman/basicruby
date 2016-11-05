#!/bin/bash -ex
DUMPFILE=`date -u +%Y%m%d%H%M%SZ.pgdump.sql`
fwknop -s -n basicruby.danstutzman.com
tugboat ssh -n basicruby -c "sudo -u postgres pg_dump -U postgres -v > /tmp/$DUMPFILE"
scp root@basicruby.danstutzman.com:/tmp/$DUMPFILE $DUMPFILE
tugboat ssh -n basicruby -c "rm /tmp/$DUMPFILE"
