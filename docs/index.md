# Edge Cloud Platform - Documentation

Welcome to the edge.unboxd.cloud deployment documentation. This guide covers all services running on this platform.

---

## Table of Contents

1. [Edge Console](#edge-console)
2. [MicroCloud Agent API](#microcloud-agent-api)
3. [Chat UI](#chat-ui)

---

## Edge Console

### What is the Edge Console?

The Edge Console is the static landing page and documentation hub for the Edge Cloud Platform. It provides a visual interface for navigating platform resources and serves as the entry point for users discovering the platform capabilities.

### Features

- 📄 Static landing page with platform information
- 📚 Integrated documentation viewer
- 🎨 Modern dark theme UI with animated elements
- 📱 Responsive design for all devices
- 🔗 Quick links to all platform services

### Use Cases

- Platform discovery and onboarding
- Documentation browsing
- Quick access to service links
- Visual presentation of platform capabilities

### How to Access

```
URL: http://edge.unboxd.cloud:8001
```

### Screenshots

```
┌─────────────────────────────────────────────────────────────┐
│                   🦀 Edge Cloud Platform                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ██████╗  █████╗  ██████╗██╗  ██╗ ██████╗  █████╗    │
│   ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔═══██╗██╔══██╗   │
│   ██║  ██║███████║██║     ███████║██║   ██║███████║   │
│   ██║  ██║██╔══██║██║     ██╔══██║██║   ██║██╔══██║   │
│   ██████╔╝██║  ██║╚██████╗██║  ██║╚██████╔╝██║  ██║   │
│   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   │
│                                                             │
│   A production-ready edge cloud platform built on             │
│   Canonical's MicroCloud                                     │
│                                                             │
│   ┌─────────────────────────────────────────────────┐       │
│   │  Documentation  │  API  │  Chat  │  Status   │       │
│   └─────────────────────────────────────────────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## MicroCloud Agent API

### What is the MicroCloud Agent API?

The MicroCloud Agent API is a RESTful API service that provides programmatic access to Canonical MicroCloud automation workflows. It enables infrastructure-as-code operations for edge computing environments.

### Features

- 🌐 **RESTful API** - Full OpenAPI 3.1 compliant endpoints
- 🤖 **Workflow Automation** - Execute pre-defined automation workflows
- 💬 **Chat Interface** - Interactive AI-powered conversations
- 🔄 **Streaming Responses** - Real-time streaming for chat and operations
- 🔐 **Approval Gating** - Security validation for mutating operations
- 📡 **Multiple Channels** - Support for Mattermost, OIDC, OpenAPI integrations
- 🛠️ **Tool Integration** - Ansible, Terraform, LXC, MicroCloud support

### Use Cases

1. **Infrastructure Automation**
   - Deploy MicroCloud clusters programmatically
   - Manage LXD containers and VMs
   - Execute Ansible playbooks
   - Run Terraform configurations

2. **CI/CD Integration**
   - Integrate with GitHub Actions
   - Automated deployment pipelines
   - Infrastructure testing

3. **Monitoring & Operations**
   - Health check automation
   - Resource monitoring
   - Log aggregation

4. **ChatOps**
   - Interactive infrastructure queries
   - Natural language operations
   - Team notifications

### How to Access

**Base URL:**
```
http://edge.unboxd.cloud:8000
```

**API Endpoints:**

| Endpoint | Method | Description |
|---------|--------|-------------|
| `/health` | GET | Service health status |
| `/openapi.json` | GET | OpenAPI specification |
| `/plan` | POST | Plan workflow execution |
| `/run` | POST | Execute workflow |
| `/chat` | POST | Chat message |
| `/chat/stream` | POST | Streaming chat |
| `/notify` | POST | Send notification |
| `/openid-configuration` | GET | OIDC discovery |
| `/oauth2/token` | POST | OAuth2 token |
| `/openapi/request` | POST | External API request |

### Example Usage

**Health Check:**
```bash
curl http://edge.unboxd.cloud:8000/health
```

**Response:**
```json
{
  "approval_granted": false,
  "config": {
    "microcloud_bin": "microcloud",
    "lxc_bin": "lxc",
    "docker_bin": "docker"
  },
  "tools": {
    "microcloud": false,
    "lxc": false,
    "docker": true
  }
}
```

**Chat Request:**
```bash
curl -X POST http://edge.unboxd.cloud:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "what workflows do you support?"}'
```

### Available Workflows

```bash
# Health assessment
microcloud-agent run assess_health --environment lab

# Bootstrap cluster  
microcloud-agent run bootstrap_cluster

# Upgrade cluster (requires approval)
MICROCLOUD_AGENT_APPROVED=approved microcloud-agent run upgrade_cluster

# Assess operator tooling
microcloud-agent run assess_operator_tooling

# Install MicroCloud stack
microcloud-agent run install_microcloud_stack

# Configure single node
microcloud-agent run configure_single_node

# Configure multi-node
microcloud-agent run configure_multi_node --host node-2

# Docker cleanup
microcloud-agent run docker_prune_everything
```

### Screenshots

#### Chat UI
![Chat UI Screenshot](chat-ui.png)

#### Edge Console
![Edge Console Screenshot](edge-console.png)

#### Agent API
![Agent API Screenshot](agent-api.png)

---

## Chat UI

### What is the Chat UI?

The Chat UI is an interactive web-based chat interface powered by Next.js. It provides a conversational interface to interact with the MicroCloud Agent, allowing users to manage their edge cloud infrastructure using natural language.

### Features

- 💬 **Real-time Chat** - Streaming responses from the agent
- 🤖 **AI-Powered** - Natural language processing
- 🎨 **Modern Interface** - Beautiful dark theme UI
- 📱 **Responsive** - Works on desktop and mobile
- 🔗 **API Integration** - Connects to MicroCloud Agent API
- ⌨️ **Input History** - Message history during session

### Use Cases

1. **Interactive Management**
   - Ask questions about infrastructure
   - Execute operations via chat
   - Get real-time status updates

2. **Troubleshooting**
   - Describe issues in natural language
   - Get AI-assisted diagnosis
   - Follow recommended fixes

3. **Onboarding**
   - Learn platform capabilities
   - Get step-by-step guidance
   - Discover available commands

4. **Documentation**
   - Browse available workflows
   - Learn about MicroCloud
   - Explore features

### How to Access

```
URL: http://edge.unboxd.cloud:3000
```

### How to Use

1. **Open the Chat UI** in a web browser
2. **Type your question** in the input field
3. **Press Send** or hit Enter
4. **Receive streaming response** from the agent

### Example Conversations

```
User:    "How do I create a new container?"
Agent:   "You can create a new LXD container using:
         
         lxc launch ubuntu:22.04 my-container
         
         Or via the agent workflow:
         
         microcloud-agent run create_container 
         --image ubuntu:22.04 --name my-container"

─────────────────────────────────────────────────

User:    "What's the cluster status?"
Agent:   "Current cluster status:
         
         • 3 nodes online
         • LXD: Ready
         • MicroCeph: Healthy
         • MicroOVN: Active
         
         All systems operational."

─────────────────────────────────────────────────

User:    "Help me set up a multi-node cluster"
Agent:   "I'll guide you through multi-node setup:
         
         1. Install MicroCloud on all nodes
         2. Initialize the first node:
            microcloud init
         3. Add additional nodes:
            microcloud add-node
         4. Form cluster:
            microcloud cluster bootstrap
         
         Would you like me to execute any of these?"
```

### Screenshots

#### Chat UI
![Chat UI Screenshot](chat-ui.png)

The Chat UI features:
- Real-time streaming chat
- Connection status indicator
- Natural language interface to MicroCloud Agent

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Edge Cloud Platform                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐   │
│   │  Chat UI   │────▶│   Agent    │────▶│ MicroCloud │   │
│   │  :3000   │     │   API     │     │  Cluster  │   │
│   └─────────────┘     │  :8000   │     │           │   │
│                     └─────────────┘     └─────────────┘   │
│                           │                             │
│   ┌─────────────┐         │                             │
│   │Edge Console│◀────────┘                             │
│   │  :8001   │                                       │
│   └─────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Chat UI | 3000 | http://edge.unboxd.cloud:3000 | Interactive chat |
| Agent API | 8000 | http://edge.unboxd.cloud:8000 | REST API |
| Edge Console | 8001 | http://edge.unboxd.cloud:8001 | Landing page |

---

## Getting Help

- **Chat UI**: Visit http://edge.unboxd.cloud:3000 and ask questions
- **API Docs**: http://edge.unboxd.cloud:8000/openapi.json
- **Health Check**: http://edge.unboxd.cloud:8000/health