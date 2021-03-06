#!/bin/bash -ex

# Set to true to renew certificate
if false; then
  gem install aws-sdk
  pushd letsencrypt.sh
  AWS_ACCESS_KEY_ID=`grep aws_access_key_id ~/.aws/config | awk '{print $3}'`
  AWS_SECRET_ACCESS_KEY=`grep aws_secret_access_key ~/.aws/config | awk '{print $3}'`
  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    ./letsencrypt.sh \
    --config ./config.sh \
    --cron --hook ./hook.rb --challenge dns-01 --domain basicruby.com
  pushd

  aws iam delete-server-certificate --server-certificate-name basicruby.com || true
  aws iam upload-server-certificate \
    --server-certificate-name basicruby.com \
    --certificate-body file://letsencrypt.sh/certs/basicruby.com/cert.pem \
    --private-key file://letsencrypt.sh/certs/basicruby.com/privkey.pem \
    --certificate-chain file://letsencrypt.sh/certs/basicruby.com/chain.pem \
    --path /cloudfront/ \
    | tee upload-server-certificate.json
fi
SERVER_CERTIFICATE_ID=`cat upload-server-certificate.json | python -c "import json,sys; response = json.load(sys.stdin); print response['ServerCertificateMetadata']['ServerCertificateId']"`

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
    "ViewerProtocolPolicy": "redirect-to-https",
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
    "CloudFrontDefaultCertificate": false,
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1",
    "Certificate": "$SERVER_CERTIFICATE_ID",
    "IAMCertificateId": "$SERVER_CERTIFICATE_ID",
    "CertificateSource": "iam"
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
