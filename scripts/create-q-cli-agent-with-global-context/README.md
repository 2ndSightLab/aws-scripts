# Q CLI Agent Creator with Global Context

## What This Script Does

This script creates custom Amazon Q CLI agent with persistent global context. It automates the setup of personalized AI agents that remember your specific rules, preferences, and system information across chat sessions.

## Why Use This Script

- **Persistent Context**: Your agent remembers custom rules and preferences between sessions
- **Personalization**: Create agents tailored to specific workflows or projects
- **Automation**: Eliminates manual agent configuration
- **Consistency**: Ensures your agent always has the same baseline context

## How to Use

### Prerequisites
- Amazon Q CLI installed and configured
- Bash shell environment
- Write permissions to `~/.aws/amazonq/cli-agents/` and `~/.myagents/`

### Running the Script

1. Run the script:
   ```bash
   ./run.sh
   ```

2. Follow the prompts:
   - Enter an agent name (letters, numbers, hyphens only)
   - Add custom rules for your agent (press Enter twice when finished)

### Using Your Custom Agent

Launch a chat session with your agent:
```bash
q chat --agent your-agent-name
```

### Updating Agent Context

Edit the context file to modify your agent's rules:
```bash
nano ~/.myagents/your-agent-name.md
```

## File Structure

The script creates:
- `~/.myagents/agent-name.md` - Global context and rules
- `~/.aws/amazonq/cli-agents/agent-name.json` - Agent configuration

## Example Use Cases

- Development-focused agents with coding preferences
- AWS-specific agents with infrastructure rules
- Project-specific agents with domain knowledge
- Security-focused agents with compliance guidelines
