# Skills

A collection of [Agent Skills](https://agentskills.io) for Claude Code, Cursor, Codex, and other coding agents.

## Install All

```bash
npx skills add BorisSlutski/skills --all -g
```

Installs all skills globally with symlinks to `~/.agents/skills/`, `~/.claude/skills/`, `~/.cursor/skills/`, and any other detected agents.

## Install Individual

```bash
npx skills add BorisSlutski/skills/what-i-did -g -y
```

| Skill | Description |
|-------|-------------|
| [what-i-did](what-i-did) | Summarize yesterday's GitHub activity, grouped by repo, business unit, and type (bug / feature), and send a Slack DM recap |

## Flags

| Command | Behavior |
|---------|----------|
| `... -g` | Adds the skill globally, asks you for confirmation if needed. |
| `... -g -y` | Adds the skill globally and doesn't ask any questions, installs automatically. |

## How to Use in Cursor

### Option A — Personal (available in all your projects)

```bash
npx skills add BorisSlutski/skills/what-i-did -g -y
```

Cursor will automatically discover the skill. Trigger it by typing the skill name or a phrase from its description in chat.

### Option B — Project (shared with your team)

```bash
cp -r what-i-did .cursor/skills/
```

Anyone who opens this project in Cursor will have access to the skill.

### Option C — Manual attach

In Cursor chat, type `@` and select the `SKILL.md` file directly, or drag it into the chat window.

## How to Use with Claude

1. Open the `SKILL.md` of the skill you want.
2. Paste its contents as a system prompt or as the first user message.
3. Send your task, e.g. `"Run the what-i-did workflow for yesterday."`

## Creating a New Skill

Skills live in `<skill-name>/SKILL.md` at the repo root.

```
your-skill-name/
├── SKILL.md        # Required — main instructions + YAML frontmatter
└── README.md       # Optional — detailed docs for this skill
```

### SKILL.md frontmatter

```yaml
---
name: your-skill-name
description: |
  What the skill does and when to use it.
  Include trigger phrases so the agent auto-discovers it.
---
```

### Tips

- Keep `SKILL.md` under 500 lines
- Put heavy reference material in a separate file and link to it
- Use concrete output templates — they improve quality significantly

## Contributing

1. Fork this repo
2. Add your skill as `your-skill-name/SKILL.md`
3. Add a row to the skills table in this README
4. Open a PR

## License

MIT
