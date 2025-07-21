#!/usr/bin/env python3
import os
import json
import boto3
from bedrock_agentcore_starter_toolkit.operations.gateway import GatewayClient

def main():
    # Set up region
    region = os.environ.get('AWS_REGION', 'us-west-2')
    print(f"Using AWS Region: {region}")
    
    # Create GatewayClient
    client = GatewayClient(region_name=region)
    
    # Create Cognito authorizer
    print("Creating Cognito authorizer...")
    cognito_result = client.create_oauth_authorizer_with_cognito("db-performance-analyzer")
    
    # Print Cognito details
    print(f"Cognito User Pool ID: {cognito_result['client_info']['user_pool_id']}")
    print(f"Cognito Client ID: {cognito_result['client_info']['client_id']}")
    print(f"Cognito Client Secret: {cognito_result['client_info']['client_secret']}")
    print(f"Cognito Domain: {cognito_result['client_info']['domain_prefix']}")
    print(f"Discovery URL: {cognito_result['authorizer_config']['customJWTAuthorizer']['discoveryUrl']}")
    
    # Get token
    print("Getting OAuth token...")
    token = client.get_access_token_for_cognito(cognito_result['client_info'])
    print(f"Access Token: {token[:20]}...")
    
    # Get the content to write to the config file
    config_content = f"""export COGNITO_USERPOOL_ID={cognito_result['client_info']['user_pool_id']}
export COGNITO_APP_CLIENT_ID={cognito_result['client_info']['client_id']}
export COGNITO_CLIENT_SECRET={cognito_result['client_info']['client_secret']}
export COGNITO_DOMAIN_NAME={cognito_result['client_info']['domain_prefix']}
export COGNITO_DISCOVERY_URL={cognito_result['authorizer_config']['customJWTAuthorizer']['discoveryUrl']}
export COGNITO_ACCESS_TOKEN={token}
"""
    
    # Save to all possible config locations to ensure it's found
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Save in ../config (when run from scripts directory)
    os.makedirs(os.path.join(script_dir, "../config"), exist_ok=True)
    with open(os.path.join(script_dir, "../config/cognito_config.env"), "w") as f:
        f.write(config_content)
    print(f"Saved Cognito configuration to {os.path.join(script_dir, '../config/cognito_config.env')}")
    
    # Also save in ./config (when run from project root)
    current_dir = os.getcwd()
    os.makedirs(os.path.join(current_dir, "config"), exist_ok=True)
    with open(os.path.join(current_dir, "config/cognito_config.env"), "w") as f:
        f.write(config_content)
    print(f"Saved Cognito configuration to {os.path.join(current_dir, 'config/cognito_config.env')}")
    
    print("Cognito setup completed successfully")
    
    # Return the Cognito result for use in other scripts
    return cognito_result, token

if __name__ == "__main__":
    main()