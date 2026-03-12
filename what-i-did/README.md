# what-i-did

Summarizes **yesterday's** GitHub activity and sends a Slack DM recap to yourself.

## What it does

- Fetches all GitHub activity from yesterday (commits, PRs, reviews, comments) across public and private repos
- Groups the summary **per repository**, then **per business unit** (Billing / Finance / Replicas / etc.) and **per type** (Bug Fix / Feature)
- Shows a "Needs Your Review" section for open PRs where you are a requested reviewer
- Writes a casual, human-sounding TL;DR standup message
- Sends the TL;DR to your Slack DM via the `MCP-SLACK` MCP

**Trigger phrases:** "what-i-did", "recap yesterday", "daily summary", "yesterday summary"

## Requirements

- `gh` CLI installed and authenticated (`gh auth status`)
- Cursor with `MCP-SLACK` MCP enabled
- Your Slack email (asked once, used to resolve your Slack user ID)

## Install

**Using npx (recommended):**

```bash
# Global — available in all projects
npx skills add BorisSlutski/skills/what-i-did -g -y

# Project-only
npx skills add BorisSlutski/skills/what-i-did -y
```

**Manual copy:**

```bash
# Personal (all projects)
cp -r . ~/.cursor/skills/what-i-did

# Project-only (team-shared)
cp -r . .cursor/skills/what-i-did
```

## How to trigger

**Cursor:** Type any of the trigger phrases above in the chat. The agent will run the full workflow automatically.

**Claude:** Paste the contents of `SKILL.md` as a system prompt, then send your task.

For full usage instructions see the [repo README](../README.md).
