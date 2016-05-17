#!/bin/bash -e

CREATE_ZONE_OUTPUT=`aws route53 create-hosted-zone --name basicruby.com --caller-reference basicruby.com 2>&1 || true`
if [[ "$CREATE_ZONE_OUTPUT" != *HostedZoneAlreadyExists* ]]; then
  echo "$CREATE_ZONE_OUTPUT" 1>&2
  exit 1
fi

INSTANCE_IP=`tugboat droplets | grep basicruby | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || true`
echo INSTANCE_IP=$INSTANCE_IP

ZONE_ID=`aws route53 list-hosted-zones | python -c '
import json, sys
j=json.load(sys.stdin)
for zone in j["HostedZones"]:
  if zone["Name"] == "basicruby.com.":
    print zone["Id"]
'`
if [ "$ZONE_ID" == "" ]; then
  echo 1>&2 "Can't find basicruby.com. in 'aws route53 list-hosted-zones'"
  exit 1
fi

tee new_record_set.json <<EOF
{
  "Comment": "A new record set for the zone.",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "digitalocean.basicruby.com.",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "$INSTANCE_IP"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://$PWD/new_record_set.json
rm new_record_set.json

aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID
