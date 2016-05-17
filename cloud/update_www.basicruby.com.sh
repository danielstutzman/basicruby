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

aws s3 mb s3://www.basicruby.com
touch redirect-to-apex.html
aws s3 cp redirect-to-apex.html s3://www.basicruby.com/redirect-to-apex.html \
  --website-redirect https://basicruby.com/
aws s3 website s3://www.basicruby.com --index-document redirect-to-apex.html
cat >policy.json <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadForGetBucketObjects",
    "Effect":"Allow",
    "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::www.basicruby.com/*"
      ]
    }
  ]
}
EOF
aws s3api put-bucket-policy --bucket www.basicruby.com --policy file://policy.json
rm redirect-to-apex.html policy.json

tee new_record_set.json <<EOF
{
  "Comment": "A new record set for the zone.",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.basicruby.com.",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "s3-website-us-east-1.amazonaws.com.",
          "HostedZoneId": "Z3AQBSTGFYJSTF",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF
#                          "HostedZoneId": "Z3AQBSTGFYJSTF",

aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://$PWD/new_record_set.json
rm new_record_set.json

aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID
