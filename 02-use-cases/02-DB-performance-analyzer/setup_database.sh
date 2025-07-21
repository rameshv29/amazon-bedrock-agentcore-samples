#!/bin/bash
set -e

# Check if virtual environment exists, create if not
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install boto3
else
    source venv/bin/activate
fi

# Parse command line arguments
CLUSTER_NAME=""
ENVIRONMENT=""
USERNAME=""
PASSWORD=""
EXISTING_SECRET=""
REGION="us-west-2"

print_usage() {
    echo "Usage: $0 --cluster-name <cluster_name> --environment <prod|dev> [--username <username>] [--existing-secret <secret_name>] [--region <region>]"
    echo ""
    echo "Options:"
    echo "  --cluster-name      RDS/Aurora cluster name"
    echo "  --environment       Environment (prod or dev)"
    echo "  --username          Database username (if not using existing secret)"
    echo "  --existing-secret   Name of existing secret in AWS Secrets Manager"
    echo "  --region            AWS region (default: us-west-2)"
    echo ""
    echo "Note: If --existing-secret is not provided, the script will look for a secret"
    echo "      with the cluster name. If not found, it will prompt for credentials."
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --cluster-name)
            CLUSTER_NAME="$2"
            shift
            shift
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift
            shift
            ;;
        --username)
            USERNAME="$2"
            shift
            shift
            ;;
        --existing-secret)
            EXISTING_SECRET="$2"
            shift
            shift
            ;;
        --region)
            REGION="$2"
            shift
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$CLUSTER_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Error: Missing required parameters"
    print_usage
    exit 1
fi

# Validate environment
if [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "dev" ]; then
    echo "Error: Environment must be either 'prod' or 'dev'"
    print_usage
    exit 1
fi

# Create config directory if it doesn't exist
mkdir -p config

# Check for existing secret or try to find one based on cluster name
if [ -z "$EXISTING_SECRET" ]; then
    # Try to find a secret with the cluster name
    echo "Looking for existing secrets for cluster $CLUSTER_NAME..."
    POTENTIAL_SECRETS=$(aws secretsmanager list-secrets \
        --filters Key=name,Values="$CLUSTER_NAME" \
        --query "SecretList[].Name" \
        --output text \
        --region "$REGION" 2>/dev/null || echo "")
    
    if [ ! -z "$POTENTIAL_SECRETS" ]; then
        # Found potential secrets, ask user to select one
        echo "Found potential secrets for this cluster:"
        SECRET_ARRAY=()
        i=1
        while read -r secret; do
            if [ ! -z "$secret" ]; then
                echo "$i) $secret"
                SECRET_ARRAY[i]="$secret"
                i=$((i+1))
            fi
        done <<< "$POTENTIAL_SECRETS"
        
        echo "$i) None of these (enter credentials manually)"
        
        # Ask user to select a secret
        read -p "Select a secret to use [1-$i]: " SECRET_CHOICE
        
        if [[ $SECRET_CHOICE -ge 1 && $SECRET_CHOICE -lt $i ]]; then
            EXISTING_SECRET=${SECRET_ARRAY[$SECRET_CHOICE]}
            echo "Using existing secret: $EXISTING_SECRET"
        else
            echo "Will prompt for credentials instead."
        fi
    else
        echo "No existing secrets found for cluster $CLUSTER_NAME."
    fi
fi

# If we have an existing secret, use it
if [ ! -z "$EXISTING_SECRET" ]; then
    echo "Setting up database access using existing secret..."
    python3 scripts/setup_database_access.py \
        --cluster-name "$CLUSTER_NAME" \
        --environment "$ENVIRONMENT" \
        --existing-secret "$EXISTING_SECRET" \
        --region "$REGION"
else
    # Otherwise prompt for credentials if needed
    if [ -z "$USERNAME" ]; then
        read -p "Enter database username: " USERNAME
    fi
    
    # Always prompt for password (never pass as command line argument)
    read -s -p "Enter database password: " PASSWORD
    echo ""
    
    echo "Setting up database access..."
    python3 scripts/setup_database_access.py \
        --cluster-name "$CLUSTER_NAME" \
        --environment "$ENVIRONMENT" \
        --username "$USERNAME" \
        --password "$PASSWORD" \
        --region "$REGION"
fi

# Deactivate virtual environment
deactivate

echo "Database setup complete!"