#!/bin/bash
set -e

# Set default region if not set
AWS_REGION=${AWS_REGION:-"us-west-2"}

echo "Creating psycopg2 Lambda layer..."

# Use the existing zip file
ZIP_FILE="$(dirname $(dirname $0))/psycopg2-layer.zip"

# Check if the zip file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: psycopg2-layer.zip not found"
    exit 1
fi

echo "Using existing psycopg2-layer.zip file"

# Create Lambda layer
LAYER_VERSION=$(aws lambda publish-layer-version \
  --layer-name psycopg2-layer \
  --description "psycopg2 PostgreSQL driver" \
  --license-info "MIT" \
  --compatible-runtimes python3.9 \
  --zip-file fileb://$ZIP_FILE \
  --region $AWS_REGION)

LAYER_ARN=$(echo $LAYER_VERSION | jq -r '.LayerVersionArn')

# Create config directory if it doesn't exist
mkdir -p ../config

# Save layer ARN to config file
echo "export PSYCOPG2_LAYER_ARN=$LAYER_ARN" > ../config/layer_config.env

echo "psycopg2 Lambda layer created with ARN: $LAYER_ARN"

echo "Layer creation completed"