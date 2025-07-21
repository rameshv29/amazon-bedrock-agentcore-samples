Amazon Bedrock AgentCore Gateway can connect to both AWS resources and external services. This means that along with the standard AWS Identity and Access Management (IAM) for managing permissions in Amazon Bedrock AgentCore Gateway, the permissions model supports additional external authentication mechanisms.

When working with Gateways, there are three main categories of permissions to consider:

Gateway Management Permissions - Permissions needed to create and manage Gateways

Gateway Access Permissions or Inbound Auth Configuration - Who can invoke what via the MCP protocol

Gateway Execution Permissions or Outbound Auth configuration - Permissions that a Gateway needs to perform actions on other resources and services

You'll configure Gateway Access Permissions when Creating gateways in the next section, and Gateway Execution Permissions when Adding targets.

Gateway Management Permissions

These permissions allow you to create and manage Gateways. You can create a gateway specific policy (example name BedrockAgentCoreGatewayFullAccess) which could look like:



{
  "Version": "2012-10-17",
  "Statement": [
    {   
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:*Gateway*",
        "bedrock-agentcore:*WorkloadIdentity",
        "bedrock-agentcore:*CredentialProvider",
        "bedrock-agentcore:*Token*",
        "bedrock-agentcore:*Access*"
      ],
      "Resource": "arn:aws:bedrock-agentcore:*:*:*gateway*"
    }
  ]
}
      
You may also need additional permissions for related services:

s3:GetObject and s3:PutObject for storing and retrieving schemas when you configure targets based on S3

kms:Encrypt, kms:Decrypt, kms:GenerateDataKey* for encryption operations

Other service-specific permissions based on your Gateway's functionality or configuration

For more comprehensive permissions across all AgentCore services, consider using the BedrockAgentCoreFullAccess managed policy, especially when working with multiple AgentCore products.

If you prefer to follow the principle of least privilege, you can create a custom policy that grants only specific permissions. Here's an example of a ReadOnly Gateway permission policy:



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:ListGateways",
        "bedrock-agentcore:GetGateway",
        "bedrock-agentcore:ListGatewayTargets",
        "bedrock-agentcore:GetGatewayTarget"
      ],
      "Resource": "arn:aws:bedrock-agentcore:*:*:*gateway*"
    }
  ]
}
      
Gateway Access Permissions or Inbound Auth Configuration

Unlike other AWS services, which use standard AWS IAM mechanisms for access control, Amazon Bedrock AgentCore Gateway uses JWT token-based authentication as specified in the Model Context Protocol (MCP). These configurations have to be specified as a property of the gateway.

You'll configure these permissions when Creating gateways in the next section.

Gateway Execution Permissions or Outbound Auth configuration

When creating a Gateway, you need to provide an execution role that will be used by the Gateway to access AWS resources or external services. This role defines the permissions that the Gateway has when making requests to other services. Based on the type of target, the role would either have permissions to access the AWS resources configured for the target, or for external resources, the role would have permissions to acquire the needed auth to invoke the external resources. You will configure these after you have setup your gateway while Adding targets.

At the very least, whatever type of target is being configured, the execution role must have a trust policy that allows the Amazon Bedrock AgentCore service to assume the role:



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GatewayAssumeRolePolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock-agentcore.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "{{accountId}}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock-agentcore:{{region}}:{{accountId}}:gateway/{{gatewayName}}-*"
        }
      }
    }
  ]
}
      
For AWS resources as targets like Lambda functions, don't forget to give the Gateway permissions to access it in that resource's (ex. Lambda's) policy as well.

Best practices for Gateway permissions

Follow the principle of least privilege
Grant only the permissions necessary for your Gateway to function

Use specific resource ARNs rather than wildcards when possible

Regularly review and audit permissions

Separate roles by function
Use different roles for management and execution

Create separate roles for different Gateways with different purposes

Secure credential storage
Store API keys and OAuth credentials in AWS Secrets Manager

Rotate credentials regularly

Monitor and audit
Enable CloudTrail logging for Gateway operations

Regularly review access patterns and permissions usage

Use conditions in policies
Add conditions to limit when and how permissions can be used

Consider using source IP restrictions for management operations

Before creating your Gateway, you need to set up inbound auth to validate callers attempting to access targets through your Amazon Bedrock AgentCore Gateway.

Note
If you're using the AgentCore SDK, the Cognito EZ Auth can configure this automatically for you, so you can skip the manual inbound Auth setup.

Inbound Auth works with OAuth authorization, where the client application must authenticate with the OAuth authorizer before using the Gateway. Your client would receive an access token which is used at runtime.

You need to specify an OAuth discovery server and client IDs/audiences when you create the gateway. You can specify the following:

Discovery Url — String that must match the pattern ^.+/\.well-known/openid-configuration$ for OpenID Connect discovery URLs

At least one of the below options depending on the chosen identity provider.

Allowed audiences — List of allowed audiences for JWT tokens

Allowed clients — List of allowed client identifiers

Setting up identity providers for Inbound Auth

Choose your preferred identity provider from the options below. For general information about setting up different identity providers, see Amazon Cognito.


Amazon Cognito EZ Auth with AgentCore SDK

Amazon Cognito

Auth0
Amazon Cognito provides a fully managed user directory service that can be used to authenticate users for your Gateway.

To create a Cognito user pool for machine-to-machine authentication
Create a user pool:



aws cognito-idp create-user-pool \
  --region us-west-2 \
  --pool-name "gateway-user-pool"
                
Note the user pool ID from the response or retrieve it using:



aws cognito-idp list-user-pools \
  --region us-west-2 \
  --max-results 60
                
Create a resource server for the user pool:



aws cognito-idp create-resource-server \
  --region us-west-2 \
  --user-pool-id <UserPoolId> \
  --identifier "gateway-resource-server" \
  --name "GatewayResourceServer" \
  --scopes '[{"ScopeName":"read","ScopeDescription":"Read access"}, {"ScopeName":"write","ScopeDescription":"Write access"}]'
                
Create a client for the user pool:



aws cognito-idp create-user-pool-client \
  --region us-west-2 \
  --user-pool-id <UserPoolId> \
  --client-name "gateway-client" \
  --generate-secret \
  --allowed-o-auth-flows client_credentials \
  --allowed-o-auth-scopes "gateway-resource-server/read" "gateway-resource-server/write" \
  --allowed-o-auth-flows-user-pool-client \
  --supported-identity-providers "COGNITO"
                
Note the client ID and client secret from the response.

Create a domain for your user pool (if one is not already created by default):



aws cognito-idp create-user-pool-domain \
  --domain <UserPoolIdWithoutUnderscore> \
  --user-pool-id <UserPoolId> \
  --region us-west-2
                
Construct the discovery URL for your Cognito user pool:



https://cognito-idp.us-west-2.amazonaws.com/<UserPoolId>/.well-known/openid-configuration
                
Configure the Gateway Inbound Auth with the following values:

Discovery URL: The URL constructed in the previous step

Allowed clients: The client ID obtained when creating the user pool client



authorizerConfiguration= {
  "customJWTAuthorizer": {  
    "discoveryUrl": "https://cognito-idp.us-west-2.amazonaws.com/user-pool-id/.well-known/openid-configuration",
    "allowedClients": ["client-id"]
  }
}
            
To obtain a bearer token for use with the Data Plane API:



curl --http1.1 -X POST https://<UserPoolIdWithoutUnderscore>.auth.us-west-2.amazoncognito.com/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<ClientId>&client_secret=<ClientSecret>"
            
The response will include an access token that can be used as a bearer token when making requests to the Gateway.

Once you have set up your identity provider, you can create your Gateway using one of the following methods:


AgentCore SDK

CLI

Console

Boto3

API
The following Python code shows how to create a gateway with boto3 (AWS SDK for Python)



import boto3
# create the agentcore client
agentcore_client = boto3.client('bedrock-agentcore-control')
# create a gateway
gateway = agentcore_client.create_gateway(
    name="<target-name e.g. ProductSearch>",
    roleArn="<existing role ARN e.g. arn:aws:iam::123456789012:role/MyRole>",
    protocolType="MCP",
    authorizerType="CUSTOM_JWT",
    authorizerConfiguration= {
        "customJWTAuthorizer": {  
            "discoveryUrl": "<existing discovery URL e.g. https://cognito-idp.us-west-2.amazonaws.com/some-user-pool/.well-known/openid-configuration>",
            "allowedClients": ["<clientId>"]
        }
    }
)