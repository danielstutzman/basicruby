#!/bin/bash -e

CREATE_ZONE_OUTPUT=`aws route53 create-hosted-zone --name basicruby.com --caller-reference basicruby.com 2>&1 || true`
if [[ "$CREATE_ZONE_OUTPUT" != *HostedZoneAlreadyExists* ]]; then
  echo "$CREATE_ZONE_OUTPUT" 1>&2
  exit 1
fi

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

HOSTED_ZONE_ID_FOR_ALL_CLOUDFRONT=Z2FDTNDATAQYW2
DOMAIN_NAME=`aws cloudfront list-distributions | python -c "import json,sys; distributions = json.load(sys.stdin); print '\n'.join([distribution['DomainName'] for distribution in distributions['DistributionList']['Items'] if distribution['Comment'] == 'basicruby.com'])"`

tee new_record_set.json <<EOF
{
  "Comment": "A new record set for the zone.",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "basicruby.com.",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "$DOMAIN_NAME",
          "HostedZoneId": "$HOSTED_ZONE_ID_FOR_ALL_CLOUDFRONT",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://$PWD/new_record_set.json
rm new_record_set.json

aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID
