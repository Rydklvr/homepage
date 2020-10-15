#!/usr/bin/env bash
echo "Removing existing public directory..."
rm -rf public
echo "Generating new minified public directory..."
hugo --minify
echo "Optimising images..."
find static/img -name '*.png' -exec convert {} png8:{} \;
echo "Deploying to CloudFront..."
hugo deploy
echo "Invalidating CloudFront cache..."
invalidation_id=$(aws cloudfront create-invalidation --distribution-id E2S0LJUNOTR5CD --paths "/*" | jq --raw-output '.Invalidation | .Id')
printf "Waiting for invalidation: %s to be complete\n" "$invalidation_id"
COUNTER=0
while :; do
    status=$(aws cloudfront get-invalidation --id "$invalidation_id" --distribution-id E2S0LJUNOTR5CD | jq --raw-output '.Invalidation | .Status')
    printf "=%.0s" $(seq 1 $COUNTER)
    COUNTER=$((COUNTER + 1))
    if [[ "$status" = "Completed" ]]; then
        break
    fi

done
printf "\nMinified.\nDeployed to S3.\nCloudFront cache invalidated.\nComplete!\n"
