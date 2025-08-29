Readme

# Competitive Intelligence Agent with Amazon Bedrock AgentCore

An enterprise-grade competitive intelligence gathering system that automates website analysis using Amazon Bedrock AgentCore tools. This agent demonstrates advanced browser automation, intelligent data extraction, and sophisticated analysis capabilities with complete visibility through live viewing and session recording.

## 🌟 Key Features

### Core Capabilities

- **🤖 Automated Browser Navigation** - Intelligent website exploration using BedrockAgentCore Browser Tool
- **📊 Smart Data Extraction** - LLM-powered extraction of pricing, features, and product information
- **🔍 Content Discovery** - Intelligent scrolling and section identification across diverse website structures
- **📸 Visual Documentation** - Annotated screenshots with automatic S3 storage
- **🌐 API Discovery** - Automatic detection and tracking of API endpoints
- **📈 Advanced Analysis** - Code Interpreter-powered data analysis and visualization
- **📝 Comprehensive Reporting** - Automated generation of competitive intelligence reports

### Live Monitoring & Control

- **👁️ Real-time Browser Viewing** - Watch the agent work through DCV-powered live streaming
- **🎮 Interactive Control Transfer** - Take manual control when needed, release back to automation
- **📐 Adjustable Display Resolution** - Support for HD (720p), HD+ (900p), Full HD (1080p), and 2K (1440p)
- **📹 Automatic Session Recording** - All browser interactions recorded to S3
- **🎬 Session Replay** - Review recorded sessions with full playback controls

### Enterprise Features

- **⚡ Parallel Processing** - Analyze multiple competitors simultaneously
- **💾 Session Persistence** - Save and resume analysis sessions
- **🔄 Multi-page Workflows** - Navigate through pricing, features, documentation pages
- **📋 Form Analysis** - Detect and analyze web forms and input fields
- **⏱️ Performance Metrics** - Capture page load times and resource usage
- **☁️ AWS Integration** - Native S3 storage and IAM-based security

## 📋 Prerequisites

### Required AWS Resources

- AWS Account with appropriate permissions
- Access to Amazon Bedrock with Claude 3.5 Sonnet model enabled
- IAM role for BedrockAgentCore execution
- S3 bucket for session recordings (auto-created if permissions allow)

### Required Software

- Python 3.10 or later
- AWS CLI configured with credentials
- Modern web browser (Chrome, Firefox, Edge, or Safari)

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/awslabs/amazon-bedrock-agentcore-samples.git
cd amazon-bedrock-agentcore-samples/02-use-cases/competitive-intelligence-agent
```

### 2. Install Python Dependencies

```bash
pip install -r requirements.txt
```

Required packages:

- `bedrock-agentcore` - BedrockAgentCore Python SDK
- `boto3` - AWS SDK for Python
- `playwright` - Browser automation
- `langchain-aws` - LangChain AWS integrations
- `langgraph` - Workflow orchestration
- `rich` - Terminal UI
- `pandas` - Data analysis
- `matplotlib` - Visualizations
- `seaborn` - Statistical graphics
- `fastapi` - Web server for live viewing
- `uvicorn` - ASGI server

### 3. Install DCV SDK for Live Viewing

The Amazon DCV SDK enables real-time browser viewing:

```bash
# Download DCV SDK
wget https://d1uj6qtbmh3dt5.cloudfront.net/webclientsdk/nice-dcv-web-client-sdk-1.9.100-952.zip

# Extract to the correct location
unzip nice-dcv-web-client-sdk-1.9.100-952.zip
mkdir -p ../../../01-tutorials/05-AgentCore-tools/02-Agent-Core-browser-tool/interactive_tools/static/dcvjs
cp -r dcvjs-umd/* ../../../01-tutorials/05-AgentCore-tools/02-Agent-Core-browser-tool/interactive_tools/static/dcvjs/
```

### 4. Configure AWS Environment

```bash
# Set your AWS region
export AWS_REGION=us-west-2

# Set IAM role (or let the agent create default)
export RECORDING_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT:role/BedrockAgentCoreRole

# Optional: Customize S3 bucket for recordings
export S3_RECORDING_BUCKET=my-competitive-intel-recordings
export S3_RECORDING_PREFIX=sessions/
```

## 💻 Usage

### Basic Usage - Analyze Competitors

Run the agent with the interactive menu:

```bash
python run_agent.py
```

You’ll see an interactive menu:

```
Select analysis option:
1. 🎯 AWS Bedrock AgentCore Pricing Only
2. 🆚 Compare Bedrock AgentCore vs Vertex AI  
3. ✏️ Custom competitors
```

### Custom Competitor Analysis

Select option 3 to analyze your own competitors:

```python
# You'll be prompted to enter:
# - Competitor name
# - Website URL
# The agent auto-detects what to analyze based on the URL
```

### Advanced Usage - Parallel Processing

For multiple competitors, the agent offers parallel processing:

```python
# When analyzing 2+ competitors, you'll be asked:
⚡ Use parallel processing for 3 competitors? [y/N]

# Parallel mode:
# - Creates separate browser sessions for each competitor
# - Reduces total analysis time significantly
# - Limited live view visibility (can only watch one session)
```

### Resume Previous Session

The agent supports session persistence:

```bash
# On startup, you'll be asked:
Do you want to resume a previous session? [y/N]
# Enter session ID: 20240315_143022
```

## 🎯 Features in Action

### Live Browser Viewing

When the agent starts, it automatically opens a browser window showing the live view:

- **URL**: http://localhost:8000
- **Features**:
  - Real-time display of browser automation
  - Take/Release control buttons
  - Display size adjustment
  - Session information panel

### Intelligent Website Exploration

The agent performs sophisticated exploration:

```python
# The agent will:
1. Navigate to the competitor's homepage
2. Perform intelligent scrolling to discover content
3. Identify pricing, features, and product sections
4. Navigate to pricing pages automatically
5. Explore documentation and API pages
6. Capture screenshots at key points
```

### Data Extraction Capabilities

For each competitor, the agent extracts:

- **Pricing Information**: Tiers, plans, costs, billing cycles
- **Product Features**: Key capabilities, differentiators
- **Interactive Elements**: Forms, CTAs, sign-up flows
- **Technical Details**: API endpoints, integration options
- **Performance Metrics**: Page load times, resource usage

### Analysis and Visualization

Using the Code Interpreter, the agent:

```python
# Creates comprehensive analysis including:
- Competitive comparison matrices
- Pricing distribution charts
- Feature parity analysis
- Market positioning insights
- Trend identification
```

### Session Recording and Replay

All sessions are automatically recorded:

```bash
# Recordings stored in S3:
s3://your-bucket/competitive_intel/SESSION_ID/

# To replay a session:
# 1. After analysis completes, choose "View session replay"
# 2. Or run standalone replay viewer:
python -m live_view_sessionreplay.view_recordings \
  --bucket your-bucket \
  --prefix competitive_intel
```

## 📁 Project Structure

```
competitive-intelligence-agent/
├── agent.py                 # Main LangGraph agent implementation
├── browser_tools.py         # Browser automation with BedrockAgentCore
├── analysis_tools.py        # Code Interpreter integration
├── config.py               # Configuration management
├── run_agent.py            # Main entry point
├── requirements.txt        # Python dependencies
└── utils/
    ├── imports.py          # Path configuration for interactive tools
    └── s3_datasource.py    # S3 integration for recordings
```

## ⚙️ Configuration Options

### Environment Variables

|Variable                 |Description                   |Default                         |
|-------------------------|------------------------------|--------------------------------|
|`AWS_REGION`             |AWS region for services       |us-west-2                       |
|`RECORDING_ROLE_ARN`     |IAM role for browser execution|Auto-generated                  |
|`S3_RECORDING_BUCKET`    |Bucket for session recordings |session-record-test-{ACCOUNT_ID}|
|`S3_RECORDING_PREFIX`    |Prefix for recordings in S3   |competitive_intel/              |
|`BEDROCK_AGENTCORE_STAGE`|Service stage                 |prod                            |

### Agent Configuration

Edit `config.py` to customize:

```python
@dataclass
class AgentConfig:
    # LLM Configuration
    llm_model_id: str = "anthropic.claude-3-5-sonnet-20240620-v1:0"
    
    # Timeouts
    browser_timeout: int = 60000  # 60 seconds
    browser_session_timeout: int = 3600  # 1 hour
    code_session_timeout: int = 1800  # 30 minutes
    
    # Port Configuration
    live_view_port: int = 8000
    replay_viewer_port: int = 8002
```

## 🔍 Monitoring and Debugging

### Console Output

The agent provides rich console output with color-coded information:

- 🔍 Blue: Current operation
- ✅ Green: Success messages
- ⚠️ Yellow: Warnings
- ❌ Red: Errors

### Live Browser Viewer

Access the live viewer at http://localhost:8000 to:

- Watch real-time browser automation
- Take manual control when needed
- Adjust display resolution
- Monitor session progress

### Session Recordings

All sessions are recorded with:

- Complete browser interaction history
- Network requests and API calls
- Screenshots at key points
- Performance metrics

### Debug Mode

Enable detailed logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 🐛 Troubleshooting

### DCV SDK Not Found

If you see “DCV SDK Not Found” error:

1. Download the SDK from the provided URL
1. Extract to the correct directory structure
1. Verify files exist in `interactive_tools/static/dcvjs/`

### Browser Session Not Starting

- Verify IAM role has correct permissions
- Check AWS credentials are configured
- Ensure Bedrock AgentCore is available in your region

### S3 Recording Issues

- Verify S3 bucket exists or IAM role can create buckets
- Check S3 write permissions
- Ensure bucket name is globally unique

### LLM Rate Limiting

If you encounter throttling:

- The agent automatically handles rate limits
- Reduce parallel processing sessions
- Consider using a different Bedrock model

### Session Replay Not Working

- Wait 30 seconds after session completes for S3 upload
- Verify recordings exist: `aws s3 ls s3://your-bucket/prefix/`
- Check browser console for JavaScript errors

## 📊 Performance Considerations

- **Sequential Mode**: ~2-3 minutes per competitor
- **Parallel Mode**: ~1-2 minutes total for multiple competitors
- **Recording Size**: ~5-10 MB per minute of session
- **Live View Bandwidth**: ~1-2 Mbps for smooth streaming

## 🔐 Security

- All browser sessions run in isolated AWS cloud environments
- IAM role-based access control
- Session recordings encrypted in S3
- No local browser execution - all processing in AWS
- WebSocket connections use SigV4 authentication

