#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Getting S3 bucket name..."
BUCKET=$(cd terraform && terraform output -raw s3_bucket_name)

echo "Getting CloudFront distribution ID..."
DIST_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)

echo "Getting RUM configuration..."
RUM_APP_ID=$(cd terraform && terraform output -raw rum_app_monitor_id 2>/dev/null || echo "")
RUM_POOL_ID=$(cd terraform && terraform output -raw rum_identity_pool_id 2>/dev/null || echo "")

# Update index.html with RUM IDs if monitoring is enabled
if [ -n "$RUM_APP_ID" ] && [ "$RUM_APP_ID" != "null" ]; then
  echo "Injecting RUM configuration..."
  sed "s/RUM_APP_MONITOR_ID/$RUM_APP_ID/g; s/RUM_IDENTITY_POOL_ID/$RUM_POOL_ID/g" index.html > /tmp/index.html
  INDEX_FILE="/tmp/index.html"
else
  INDEX_FILE="index.html"
fi

echo "Uploading files to S3..."
aws s3 cp "$INDEX_FILE" "s3://${BUCKET}/" --content-type "text/html"
aws s3 cp style.css "s3://${BUCKET}/" --content-type "text/css"
aws s3 cp game.js "s3://${BUCKET}/" --content-type "application/javascript"
aws s3 cp engine.js "s3://${BUCKET}/" --content-type "application/javascript"
aws s3 cp state.js "s3://${BUCKET}/" --content-type "application/javascript"
aws s3 cp ui.js "s3://${BUCKET}/" --content-type "application/javascript"

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation --distribution-id "${DIST_ID}" --paths "/*" --no-cli-pager

echo "Deployment complete!"
echo "Website URL: https://$(cd terraform && terraform output -raw cloudfront_domain_name)"

if [ -n "$RUM_APP_ID" ] && [ "$RUM_APP_ID" != "null" ]; then
  echo "CloudWatch Dashboard: $(cd terraform && terraform output -raw cloudwatch_dashboard_url)"
fi
