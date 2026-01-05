#!/bin/bash

BUCKET=$(terraform output -raw bucket_name) && \
WEBSITE=$(terraform output -raw website_url) && \
echo "=== S3 BUCKET: $BUCKET ===" && \
aws s3api get-bucket-versioning --bucket $BUCKET && \
echo "<h1>Test</h1>" > index.html && \
aws s3 cp index.html s3://$BUCKET/ && \
echo "=== WEBSITE TEST ===" && \
curl -s $WEBSITE | head -5 && \
echo "✅ SUCCESS!"
