# Skills

Personal [Agent Skills](https://agentskills.io) for Claude Code, Cursor, Codex, and other coding agents.

## Skills

<!-- SKILLS_TABLE_START -->
| Skill | Description |
|-------|-------------|
| [mac-migration-audit](mac-migration-audit) | Audits an existing macOS environment in read-only mode and generates migration reports, installation scripts, and step-by-step setup guidance for recreating the working environment on a new Mac. Use when the user mentions Mac migration, new Mac setup, environment recreation, Mac audit, create-image, unimage, dev environment backup, or asks to inventory applications, tools, dotfiles, repos, or cloud sync before switching machines. |
| [what-i-did](what-i-did) | Summarize yesterday's GitHub activity and send a Slack DM with the recap. Use when user says "what-i-did", "recap yesterday", "daily summary", or "yesterday summary". |
<!-- SKILLS_TABLE_END -->

## Install

Install everything globally:

```bash
npx skills add BorisSlutski/skills --all -g
```

Install one skill:

```bash
npx skills add BorisSlutski/skills/what-i-did -g -y
```

From a local clone:

```bash
npm run install:global
```

| Flag | Behavior |
|------|----------|
| `-g` | Install globally |
| `-g -y` | Install globally without prompts |
| `--all` | Install every skill in this repo |

## Usage in Cursor

**Global install** — available in all projects:

```bash
npx skills add BorisSlutski/skills/what-i-did -g -y
```

**Project install** — share with the team:

```bash
cp -r what-i-did .cursor/skills/
```

**Manual attach** — type `@` in chat and pick the `SKILL.md` file.

## Add a New Skill

1. Create a folder at the repo root:

```
your-skill-name/
├── SKILL.md        # required
└── README.md       # optional
```

2. Add frontmatter to `SKILL.md`:

```yaml
---
name: your-skill-name
description: What it does and when to use it. Include trigger phrases.
---
```

3. Regenerate the skills table:

```bash
npm run generate
```

4. Validate before committing:

```bash
npm run validate
```

### Tips

- Keep `SKILL.md` under 500 lines
- Put heavy reference material in a separate file and link to it
- Use concrete output templates — they improve quality significantly

## License

MIT
