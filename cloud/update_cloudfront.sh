#!/bin/bash -e

aws configure set preview.cloudfront true

cat > distconfig.json <<EOF
{
  "CallerReference": "basicruby.com",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "Custom-digitalocean.basicruby.com",
        "DomainName": "digitalocean.basicruby.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 3,
            "Items": ["TLSv1", "TLSv1.1", "TLSv1.2"]
          }
        },
        "CustomHeaders": {
          "Quantity": 0,
          "Items": []
        },
        "OriginPath": ""
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "Custom-digitalocean.basicruby.com",
    "ForwardedValues": {
      "QueryString": true,
      "Cookies": {
        "Forward": "all"
      },
      "Headers": {
        "Quantity": 0,
        "Items": []
      }
    },
    "ViewerProtocolPolicy": "allow-all",
    "MinTTL": 0,
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "SmoothStreaming": false,
    "DefaultTTL": 0,
    "MaxTTL": 31536000,
    "Compress": false,
    "AllowedMethods": {
      "Quantity": 7,
      "Items": ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    }
  },
  "Comment": "basicruby.com",
  "Enabled": true,

  "PriceClass": "PriceClass_All",
  "Aliases": {
    "Quantity": 1,
    "Items": ["basicruby.com"]
  },
  "Logging": {
    "Enabled": true,
    "IncludeCookies": false,
    "Bucket": "cloudfront-logs-danstutzman.s3.amazonaws.com",
    "Prefix": ""
  },
  "DefaultRootObject": "",
  "WebACLId": "",
  "CacheBehaviors": {
    "Quantity": 0,
    "Items": []
  },
  "CustomErrorResponses": {
    "Quantity": 0,
    "Items": []
  },
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "SSLv3",
    "CertificateSource": "cloudfront"
  },
  "Restrictions": {
    "GeoRestriction": {
      "RestrictionType": "none",
      "Quantity": 0,
      "Items": []
    }
  }
}
EOF

DISTRIBUTION_ID=`aws cloudfront list-distributions | python -c "import json,sys; distributions = json.load(sys.stdin); print '\n'.join([distribution['Id'] for distribution in distributions['DistributionList']['Items'] if distribution['Comment'] == 'basicruby.com'])"`

if [ "$DISTRIBUTION_ID" == "" ]; then
  aws cloudfront create-distribution --distribution-config file://distconfig.json
else
  DISTRIBUTION_ETAG=`aws cloudfront get-distribution --id "$DISTRIBUTION_ID" | python -c "import json,sys; response = json.load(sys.stdin); print response['ETag']"`
  aws cloudfront update-distribution --id "$DISTRIBUTION_ID" --distribution-config file://distconfig.json --if-match "$DISTRIBUTION_ETAG"
fi

rm -f distconfig.json
