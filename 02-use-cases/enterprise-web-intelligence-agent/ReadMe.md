# Market Intelligence Platform

An enterprise-grade automated web intelligence gathering system powered by Amazon Bedrock AgentCore, demonstrating two different architectural approaches: LangGraph and Strands.

## ⚠️ Important Note on Code Structure

This repository contains **two independent implementations** that cannot share most code due to fundamental architectural differences:

- **LangGraph** (`/langgraph`) - Graph-based workflow with explicit state management
- **Strands** (`/strands`) - Agent-based tool orchestration with built-in AWS integration

Only configuration files and utilities are shared between implementations. Each has its own version of core components due to different async handling, LLM invocation patterns, and state management approaches.

## 🏗️ Architecture Differences

### Why Separate Implementations?

The two frameworks have incompatible approaches to:

1. **Event Loop Management**
   - LangGraph: Standard async/await patterns
   - Strands: Requires nest_asyncio and thread-safe wrappers

2. **LLM Invocation**
   - LangGraph: Uses langchain methods (`await llm.ainvoke()`)
   - Strands: Direct boto3 calls to Bedrock

3. **State Management**
   - LangGraph: Custom TypedDict state with graph nodes
   - Strands: Built-in agent.state with safe accessors

4. **Tool Execution**
   - LangGraph: Tools called within graph nodes
   - Strands: Tools as decorated functions with special handling

## 📁 Project Structure

```
competitive-intelligence-agent/
├── shared/                     # Minimal shared components
│   ├── config.py              # Configuration (shared)
│   ├── cleanup_resources.py   # AWS cleanup scripts (shared)
│   └── utils/
│       └── s3_datasource.py   # S3 replay utilities (shared)
│
├── langgraph/                  # Complete LangGraph implementation
│   ├── agent.py               # Graph-based orchestration
│   ├── browser_tools.py      # Original async version
│   ├── analysis_tools.py     # LangChain LLM calls
│   ├── run_agent.py          # Entry point
│   ├── requirements.txt      # LangGraph dependencies
│   └── utils/
│       └── imports.py        # Path setup for LangGraph
│
└── strands/                    # Complete Strands implementation
    ├── agent.py               # Agent-based orchestration
    ├── browser_tools.py      # Modified for event loops
    ├── analysis_tools.py     # Direct boto3 calls
    ├── run_agent.py          # Entry point
    ├── requirements.txt      # Strands dependencies
    └── utils/
        └── imports.py        # Path setup for Strands
```

## 🚀 Installation

### Prerequisites
- Python 3.9+
- AWS Account with Bedrock access
- IAM role with appropriate permissions

### LangGraph Version
```bash
cd langgraph
uv pip install -r requirements.txt
playwright install chromium
```

### Strands Version
```bash
cd strands
uv pip install -r requirements.txt
playwright install chromium
```

## 🔧 Configuration

Both implementations share the same configuration:

```bash
export AWS_REGION="us-west-2"
export RECORDING_ROLE_ARN="arn:aws:iam::account:role/BedrockAgentCoreRole"
export S3_RECORDING_BUCKET="your-recordings-bucket"
```

## 📊 Implementation Comparison

| Component | LangGraph | Strands |
|-----------|-----------|---------|
| **browser_tools.py** | Original async/await | Modified with nest_asyncio |
| **analysis_tools.py** | LangChain LLM calls | Direct boto3 calls |
| **Event loops** | Standard asyncio | Thread-safe wrappers |
| **LLM calls** | `await llm.ainvoke()` | `bedrock_client.invoke_model()` |
| **State access** | Direct dictionary | Safe getter with defaults |
| **Error handling** | Graph node boundaries | Tool-level try/catch |
| **Code reuse** | ~20% shared | ~20% shared |

## ⚙️ Running Each Implementation

### LangGraph
```bash
cd langgraph
python run_agent.py
# Select competitors and analysis options
```

### Strands
```bash
cd strands  
python run_agent.py
# Select competitors and analysis options
```

## 🔍 Key Differences in Code

### Example: LLM Invocation

**LangGraph** (`langgraph/browser_tools.py`):
```python
response = await self.llm.ainvoke([HumanMessage(content=prompt)])
```

**Strands** (`strands/browser_tools.py`):
```python
response = bedrock_client.invoke_model(
    modelId=self.config.llm_model_id,
    body=json.dumps(native_request)
)
```

### Example: Event Loop Handling

**LangGraph**: Standard async
```python
async def analyze_competitor(self, state):
    result = await self.browser_tools.navigate_to_url(url)
```

**Strands**: Thread-safe execution
```python
future = asyncio.run_coroutine_threadsafe(
    self._analyze_website_async(name, url),
    self.browser_loop
)
return future.result(timeout=120)
```

## 💰 Cost Management

Both implementations share the same cleanup scripts:

```bash
# Manual cleanup (works for both)
cd shared
python cleanup_resources.py --clean-all

# Schedule automatic cleanup
crontab -e
# Add: 0 */6 * * * python /path/to/shared/cleanup_resources.py
```

## 🤝 Contributing

When contributing, please note:
- Changes to `browser_tools.py` or `analysis_tools.py` must be made separately for each implementation
- Test both implementations independently
- Only update shared files if the change works for both frameworks

## 📄 License

MIT License - See LICENSE file for details

## 🆘 Support

- LangGraph issues: Check the graph execution and state management
- Strands issues: Check event loop handling and tool registration
- Both: Verify AWS credentials and Bedrock access

---

**Note**: This is a demonstration project showing two architectural approaches. Choose the implementation that best fits your needs:
- **LangGraph**: Better for complex workflows with explicit control
- **Strands**: Better for rapid development with AWS integration