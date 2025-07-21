#!/bin/bash
set -e

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Load configurations
source "$PROJECT_DIR/config/iam_config.env"
source "$PROJECT_DIR/config/cognito_config.env"

echo "Creating Lambda functions for DB Performance Analyzer..."

# Create simple Lambda function for testing
LAMBDA_CODE=$(cat <<'EOF'
def lambda_handler(event, context):
    print("Received event:", event)
    
    action_type = event.get('action_type', '')
    environment = event.get('environment', '')
    
    if action_type == 'explain_query':
        query = event.get('query', '')
        return {
            'explanation': f"Query execution plan for '{query}' in environment '{environment}'",
            'plan': "Sequential Scan on table (cost=0.00..1.00 rows=100 width=100)"
        }
    elif action_type == 'extract_ddl':
        object_type = event.get('object_type', '')
        object_name = event.get('object_name', '')
        object_schema = event.get('object_schema', '')
        return {
            'ddl': f"CREATE TABLE {object_schema}.{object_name} (id INT, name VARCHAR(100));"
        }
    elif action_type == 'execute_query':
        query = event.get('query', '')
        return {
            'results': [{"id": 1, "name": "test"}, {"id": 2, "name": "example"}],
            'execution_time': "0.05 seconds"
        }
    else:
        return {
            'error': 'Unknown action type'
        }
EOF
)

# Create a temporary file for the Lambda code
LAMBDA_FILE=$(mktemp)
echo "$LAMBDA_CODE" > $LAMBDA_FILE

# Create a zip file for the Lambda function
ZIP_FILE=$(mktemp).zip
zip -j $ZIP_FILE $LAMBDA_FILE

# Load VPC configuration if available
if [ -f "$PROJECT_DIR/config/vpc_config.env" ]; then
    source "$PROJECT_DIR/config/vpc_config.env"
    echo "Loaded VPC configuration"
    echo "VPC ID: $VPC_ID"
    echo "Subnet IDs: $SUBNET_IDS"
    echo "Lambda Security Group ID: $LAMBDA_SECURITY_GROUP_ID"
    echo "DB Security Group IDs: $DB_SECURITY_GROUP_IDS"
    
    # Check if LAMBDA_SECURITY_GROUP_ID is set
    if [ -z "$LAMBDA_SECURITY_GROUP_ID" ]; then
        echo "Error: LAMBDA_SECURITY_GROUP_ID is not set in vpc_config.env"
        exit 1
    fi
    
    # Prepare VPC config JSON
    VPC_CONFIG="{\"SubnetIds\":[\"${SUBNET_IDS//,/\",\"}\"],\"SecurityGroupIds\":[\"$LAMBDA_SECURITY_GROUP_ID\"]}"
    echo "VPC Config: $VPC_CONFIG"
    
    # Load layer configuration if available
    LAYERS_PARAM=""
    if [ -f "$PROJECT_DIR/config/layer_config.env" ]; then
        source "$PROJECT_DIR/config/layer_config.env"
        if [ ! -z "$PSYCOPG2_LAYER_ARN" ]; then
            LAYERS_PARAM="--layers $PSYCOPG2_LAYER_ARN"
            echo "Using psycopg2 layer: $PSYCOPG2_LAYER_ARN"
        fi
    fi
    
    # Create the Lambda function with VPC configuration
    echo "Creating Lambda function with VPC configuration..."
    LAMBDA_RESPONSE=$(aws lambda create-function \
      --function-name DBPerformanceAnalyzer \
      --runtime python3.9 \
      --role $LAMBDA_ROLE_ARN \
      --handler lambda_function.lambda_handler \
      --zip-file fileb://$ZIP_FILE \
      --vpc-config "$VPC_CONFIG" \
      $LAYERS_PARAM \
      --timeout 30 \
      --region $AWS_REGION)
    
else
    # Create the Lambda function without VPC configuration
    echo "Creating Lambda function without VPC configuration..."
    LAMBDA_RESPONSE=$(aws lambda create-function \
      --function-name DBPerformanceAnalyzer \
      --runtime python3.9 \
      --role $LAMBDA_ROLE_ARN \
      --handler lambda_function.lambda_handler \
      --zip-file fileb://$ZIP_FILE \
      --region $AWS_REGION)
fi

LAMBDA_ARN=$(echo $LAMBDA_RESPONSE | jq -r '.FunctionArn')
echo "Lambda function created: $LAMBDA_ARN"

# Add permission for Gateway to invoke Lambda
echo "Adding permission for Gateway to invoke Lambda..."
aws lambda add-permission \
  --function-name DBPerformanceAnalyzer \
  --statement-id GatewayInvoke \
  --action lambda:InvokeFunction \
  --principal $GATEWAY_ROLE_ARN \
  --region $AWS_REGION

# Clean up temporary files
rm $LAMBDA_FILE $ZIP_FILE

# Create config directory if it doesn't exist
mkdir -p "$PROJECT_DIR/config"

# Save Lambda ARN to config
cat > "$PROJECT_DIR/config/lambda_config.env" << EOF
export LAMBDA_ARN=$LAMBDA_ARN
EOF

# Create PGStat Lambda function
echo "Creating PGStat Lambda function..."

# Create a temporary file for the Lambda code
PGSTAT_LAMBDA_FILE=$(mktemp)

# Use the correct path to the pgstat-analyse-database.py file
PGSTAT_PY_FILE="$SCRIPT_DIR/pgstat-analyse-database.py"
if [ -f "$PGSTAT_PY_FILE" ]; then
    cat "$PGSTAT_PY_FILE" > $PGSTAT_LAMBDA_FILE
else
    echo "Error: pgstat-analyse-database.py not found at $PGSTAT_PY_FILE"
    exit 1
fi

# Create a zip file for the Lambda function
PGSTAT_ZIP_FILE=$(mktemp).zip
zip -j $PGSTAT_ZIP_FILE $PGSTAT_LAMBDA_FILE

# Create the Lambda function with VPC configuration if available
if [ -f "$PROJECT_DIR/config/vpc_config.env" ]; then
    # VPC config already loaded above
    
    # Create the Lambda function with VPC configuration
    echo "Creating PGStat Lambda function with VPC configuration..."
    PGSTAT_LAMBDA_RESPONSE=$(aws lambda create-function \
      --function-name PGStatAnalyzeDatabase \
      --runtime python3.9 \
      --role $LAMBDA_ROLE_ARN \
      --handler pgstat-analyse-database.lambda_handler \
      --zip-file fileb://$PGSTAT_ZIP_FILE \
      --vpc-config "$VPC_CONFIG" \
      $LAYERS_PARAM \
      --timeout 300 \
      --region $AWS_REGION)
    
else
    # Create the Lambda function without VPC configuration
    echo "Creating PGStat Lambda function without VPC configuration..."
    PGSTAT_LAMBDA_RESPONSE=$(aws lambda create-function \
      --function-name PGStatAnalyzeDatabase \
      --runtime python3.9 \
      --role $LAMBDA_ROLE_ARN \
      --handler pgstat-analyse-database.lambda_handler \
      --zip-file fileb://$PGSTAT_ZIP_FILE \
      --timeout 300 \
      --region $AWS_REGION)
fi

PGSTAT_LAMBDA_ARN=$(echo $PGSTAT_LAMBDA_RESPONSE | jq -r '.FunctionArn')
echo "PGStat Lambda function created: $PGSTAT_LAMBDA_ARN"

# Add permission for Gateway to invoke Lambda
echo "Adding permission for Gateway to invoke PGStat Lambda..."
aws lambda add-permission \
  --function-name PGStatAnalyzeDatabase \
  --statement-id GatewayInvoke \
  --action lambda:InvokeFunction \
  --principal $GATEWAY_ROLE_ARN \
  --region $AWS_REGION

# Clean up temporary files
rm $PGSTAT_LAMBDA_FILE $PGSTAT_ZIP_FILE

# Append PGStat Lambda ARN to config
cat >> "$PROJECT_DIR/config/lambda_config.env" << EOF
export PGSTAT_LAMBDA_ARN=$PGSTAT_LAMBDA_ARN
EOF

echo "Lambda functions setup completed successfully"