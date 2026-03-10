---
name: coordinate-work
description: Analyze task complexity and dependencies, select optimal execution pattern (parallel vs sequential), and launch appropriate agents. Use when user mentions subagents, coordination, or multi-step work.
---

# Coordinating Multi-Agent Work

**Announce at start:** "I'm analyzing this task to coordinate the appropriate agents."

## The Process

### Step 1: Task Analysis

Analyze the request and classify:

**Independent Tasks (Pattern A - Parallel Execution):**
- Multiple distinct tasks with no shared dependencies
- Examples: separate bug fixes, documentation in different areas, non-overlapping refactoring
- **Execute:** Launch agents in parallel, automated validation at end

**Interdependent Tasks (Pattern B - Phased Execution):**
- One agent's decisions constrain another's work
- Examples: feature development requiring design, architectural changes, API modifications
- **Execute:** Sequential phases with validation checkpoints

### Step 2: Agent Selection

**Pure Engineering** (bugs, refactoring, tech debt, docs):
- Launch: engineer → reviewer
- Models: All Sonnet

**Feature Development** (new features, integrations):
- Launch: product-manager + ux-designer + architect (parallel)
- Wait for completion → validation checkpoint
- Launch: engineer → reviewer
- Models: architect=Opus, others=Sonnet

**Complex Features** (system redesign, multi-team):
- Launch: product-manager + ux-designer + architect (parallel)
- Wait for completion → architect synthesizes conflicts (if any)
- Launch: engineer (iterative with deviation signaling) → reviewer
- Models: architect=Opus, others=Sonnet

### Step 3: Launch Agents

Use Task tool to launch selected agents:
- Provide clear context and success criteria
- For parallel agents: launch in single message with multiple Task calls
- For sequential: launch next phase after validation checkpoint

### Step 4: Validation Checkpoints

**After Planning Phase** (Pattern B):
- Check: All planning agents completed?
- Check: Any conflicting requirements?
- If conflicts → Launch architect to resolve
- If aligned → Proceed to implementation

**After Implementation:**
- Reviewer validates alignment with plan
- Deviation resolution: Exact match → Approve / Reasonable → Document + Approve / Unclear → Architect / Violation → Reject

## Key Principles

- **Maximize parallelization** for independent work (80% performance gain)
- **Minimize checkpoints** - only at natural dependency boundaries
- **Cost optimization** - Opus only for architect (complex reasoning)
- **Autonomous agents** - clear success criteria, signal when help needed
- **Tiered validation** - Automated → Reviewer → Architect → Human

## Trigger Keywords

Use this skill when user says:
- "using subagents" / "appropriate subagents"
- "coordinate this work"
- "multi-agent" / "multiple agents"
- "complex task" requiring orchestration
- Requests involving multiple distinct activities

## Remember

- Announce you're coordinating the work
- Classify pattern before launching agents
- Launch parallel agents in single message
- Don't over-coordinate - let agents work autonomously
- Checkpoints only where dependencies exist
