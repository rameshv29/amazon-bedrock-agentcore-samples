# AI-Powered DB Performance Analyzer

This project demonstrates how to build an AI-powered database performance analyzer using Amazon Bedrock AgentCore. It creates an intelligent agent that can analyze database performance, explain queries, provide recommendations, and help optimize your database operations through natural language conversations.

## Overview

The DB Performance Analyzer is an AI-powered assistant that helps database administrators and developers identify and resolve performance issues in PostgreSQL databases. By leveraging Amazon Bedrock AgentCore and large language models, it provides human-like analysis and recommendations based on database metrics and statistics.

## Use Cases

- **Performance Troubleshooting**: Quickly identify and diagnose slow queries, connection issues, and other performance bottlenecks
- **Index Optimization**: Analyze index usage and get recommendations for creating, modifying, or removing indexes
- **Resource Utilization**: Monitor and optimize CPU, memory, and I/O usage
- **Maintenance Planning**: Get insights into autovacuum performance and recommendations for maintenance tasks
- **Replication Monitoring**: Track replication lag and ensure high availability
- **Query Optimization**: Get explanations and improvement suggestions for complex queries

## Architecture

```
┌─────────────────┐     ┌───────────────────┐     ┌─────────────────┐
│                 │     │                   │     │                 │
│   Amazon Q      │────▶│  AgentCore        │────▶│  Lambda         │
│   IDE Plugin    │     │  Gateway          │     │  Functions      │
│                 │     │                   │     │  (in VPC)       │
└─────────────────┘     └───────────────────┘     └────────┬────────┘
                                                           │
                                                           ▼
                                                  ┌─────────────────┐
                                                  │                 │
                                                  │  PostgreSQL     │
                                                  │  Database       │
                                                  │  (in VPC)       │
                                                  └─────────────────┘
```

### VPC Connectivity

The Lambda functions are deployed in the same VPC as your database, allowing secure communication:

1. **Automatic VPC Detection**: The setup script automatically detects the VPC, subnets, and security groups of your database cluster
2. **Security Group Configuration**: Creates a dedicated security group for Lambda functions and configures the database security group to allow access
3. **Private Network Communication**: All database traffic stays within the VPC, never traversing the public internet
4. **Secure Credential Management**: Database credentials are stored in AWS Secrets Manager and accessed securely by the Lambda functions

## Process Flow

1. **User Query**: The user asks a question about database performance in natural language through Amazon Q
2. **Query Processing**: Amazon Q processes the query and routes it to the appropriate AgentCore Gateway
3. **Tool Selection**: The AgentCore Gateway selects the appropriate tool based on the query
4. **Data Collection**: The Lambda function connects to the database and collects relevant metrics and statistics
5. **Analysis**: The Lambda function analyzes the collected data and generates insights
6. **Response Generation**: The results are formatted and returned to the user as natural language explanations and recommendations

## Project Structure

```
.
├── README.md               # This file
├── setup.sh                # Main setup script
├── cleanup.sh              # Cleanup script
├── config/                 # Configuration files (generated during setup)
│   └── *.env               # Environment-specific configuration files (not committed to Git)
└── scripts/                # Supporting scripts
    ├── create_gateway.py   # Creates the AgentCore Gateway
    ├── create_iam_roles.sh # Creates necessary IAM roles
    ├── create_lambda.sh    # Creates Lambda functions
    ├── create_target.py    # Creates Gateway targets
    ├── get_token.py        # Gets/refreshes authentication token
    └── ...                 # Other supporting scripts
```

### Configuration Files

The setup process automatically generates several configuration files in the `config/` directory:

- **cognito_config.env**: Contains Cognito user pool, client, and token information
- **gateway_config.env**: Contains Gateway ID, ARN, and region
- **iam_config.env**: Contains IAM role ARNs and account information
- **db_dev_config.env/db_prod_config.env**: Contains database connection information
- **vpc_config.env**: Contains VPC, subnet, and security group IDs

These files contain sensitive information and are excluded from Git via `.gitignore`.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Python 3.9 or higher
- Boto3 library installed
- jq command-line tool installed
- Access to an Amazon Aurora PostgreSQL or RDS PostgreSQL database
- Permissions to create secrets in AWS Secrets Manager
- Permissions to create parameters in AWS Systems Manager Parameter Store
- Permissions to create and modify VPC security groups
- Permissions to create Lambda functions with VPC configuration

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/awslabs/amazon-bedrock-agentcore-samples.git
   cd amazon-bedrock-agentcore-samples/02-use-cases/02-DB-performance-analyzer
   ```

2. Create a Python virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. Set up database access:
   ```bash
   ./setup_database.sh --cluster-name your-aurora-cluster --environment prod
   ```

   This script will:
   - Look for existing secrets for the cluster
   - If found, let you select one to use
   - If not found, prompt for username and password
   - Retrieve the cluster endpoint and port from RDS
   - Create a secret in AWS Secrets Manager with the required format
   - Store the secret name in SSM Parameter Store
   - Save the configuration to a file
   
   You can also specify an existing secret directly:
   ```bash
   ./setup_database.sh --cluster-name your-aurora-cluster --environment prod --existing-secret your-secret-name
   ```

4. Run the main setup script:
   ```bash
   ./setup.sh
   ```

   This script will:
   - Set up Amazon Cognito resources for authentication
   - Create necessary IAM roles
   - Create Lambda functions for DB performance analysis
   - Create an Amazon Bedrock AgentCore Gateway
   - Create Gateway targets for the Lambda functions
   - Configure everything to work together

4. Configure Amazon Q to use the gateway:
   ```bash
   source venv/bin/activate
   python3 scripts/get_token.py
   deactivate
   ```

   This will update your `~/.aws/amazonq/mcp.json` file with the gateway configuration.

## Using the DB Performance Analyzer

Once set up, you can use the DB Performance Analyzer through Amazon Q:

1. Open Amazon Q in your IDE
2. Select the "db-performance-analyzer" agent
3. Ask questions about database performance, such as:
   - "Analyze slow queries in my production database"
   - "Check for connection management issues in dev environment"
   - "Analyze index usage in my database"
   - "Check for autovacuum issues in production"

## Available Analysis Tools

The DB Performance Analyzer provides several tools:

- **Slow Query Analysis**: Identifies and explains slow-running queries, providing recommendations for optimization
- **Connection Management**: Analyzes connection issues, idle connections, and connection patterns to improve resource utilization
- **Index Analysis**: Evaluates index usage, identifies missing or unused indexes, and suggests improvements
- **Autovacuum Analysis**: Checks autovacuum settings, monitors dead tuples, and recommends configuration changes
- **I/O Analysis**: Analyzes I/O patterns, buffer usage, and checkpoint activity to identify bottlenecks
- **Replication Analysis**: Monitors replication status, lag, and health to ensure high availability
- **System Health**: Provides overall system health metrics, including cache hit ratios, deadlocks, and long-running transactions

## Key Benefits

- **Natural Language Interface**: Interact with your database using plain English questions
- **Proactive Recommendations**: Get actionable suggestions to improve performance
- **Time Savings**: Quickly identify issues that would take hours to diagnose manually
- **Educational**: Learn about database internals and best practices through AI explanations
- **Accessible**: No need to remember complex SQL queries or monitoring commands
- **Comprehensive**: Covers multiple aspects of database performance in one tool

## Cleanup

To remove all resources created by this project:

```bash
./cleanup.sh
```

This will delete:
- Lambda functions
- Gateway targets
- Gateway
- Cognito resources
- IAM roles
- Configuration files

Note: The script will not delete the secrets in AWS Secrets Manager or parameters in SSM Parameter Store by default. To delete these resources as well, use:

```bash
./cleanup.sh --delete-secrets
```

## Refreshing Authentication

If your authentication token expires, run:

```bash
source venv/bin/activate
python3 scripts/get_token.py
deactivate
```

## Troubleshooting

- **Gateway Connection Issues**: Check if your token has expired and run `get_token.py`
- **Lambda Execution Errors**: Check CloudWatch Logs for the Lambda functions
- **Permission Issues**: Verify IAM roles have the correct permissions

## Example Queries

Here are some example queries you can ask the DB Performance Analyzer:

- "What are the top 5 slowest queries in my production database?"
- "Are there any connection management issues in the dev environment?"
- "Analyze the index usage in my database and suggest improvements"
- "Is autovacuum working effectively in my production database?"
- "What's causing high I/O in my database right now?"
- "Check if there's any replication lag in my database"
- "Give me an overall health check of my production database"
- "Explain the execution plan for this query: SELECT * FROM users WHERE email LIKE '%example.com'"

## Future Enhancements

- Support for additional database engines (MySQL, SQL Server, Oracle)
- Integration with monitoring tools like CloudWatch and Prometheus
- Automated performance tuning recommendations
- Historical performance analysis and trend detection
- Query rewriting suggestions
- Cost-based optimization recommendations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.