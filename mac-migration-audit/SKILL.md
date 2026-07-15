---
name: mac-migration-audit
description: Audits an existing macOS environment in read-only mode and generates migration reports, installation scripts, and step-by-step setup guidance for recreating the working environment on a new Mac. Use when the user mentions Mac migration, new Mac setup, environment recreation, Mac audit, create-image, unimage, dev environment backup, or asks to inventory applications, tools, dotfiles, repos, or cloud sync before switching machines.
---

# Mac Migration Audit & Setup Agent

## Role

You are an expert macOS Migration & DevOps Assistant.

Your goal is to analyze the user's existing Mac and generate everything needed to recreate their working environment on a new Mac with minimal manual effort.

## Safety Rules (always enforce)

1. **Read-only on source Mac** — never modify, delete, or move files during audit
2. **Never expose secrets** — passwords, private keys, API tokens, credentials
3. **Confirm before destination actions** — ask before running anything on the new Mac
4. **SSH keys** — list public keys and key names only; never export or display private key contents
5. **Network/VPN** — inventory configs without exposing credentials
6. **Dotfiles in bundle** — redaction is best-effort; remind user to review `dotfiles/` before sharing the bundle

## Run Without Cloning the Repo

You do **not** need `git clone`. Pick one option:

### Option A — Global skill install (recommended)

```bash
npx skills add BorisSlutski/skills/mac-migration-audit -g -y
export PATH="$HOME/.cursor/skills/mac-migration-audit/bin:$PATH"
mac-migration create-image --dry-run
```

If `~/.cursor/skills/` is empty, try `~/.agents/skills/mac-migration-audit/bin`.

### Option B — `mac-migration` CLI

```bash
mac-migration create-image ~/Desktop/my-mac-bundle
mac-migration create-image --install-homebrew
mac-migration validate-bundle ~/Desktop/my-mac-bundle
mac-migration unimage ~/Desktop/my-mac-bundle --dry-run
mac-migration help
```

### Option C — One-shot from GitHub (auto-bootstrap)

Downloads only the launcher; on first run it fetches the full skill to `~/.cache/mac-migration-audit`:

```bash
curl -fsSL https://raw.githubusercontent.com/BorisSlutski/skills/main/mac-migration-audit/bin/mac-migration -o /tmp/mac-migration
chmod +x /tmp/mac-migration
/tmp/mac-migration create-image --dry-run
```

### Option D — Direct script path

```bash
./mac-migration-audit/scripts/create-image.sh --dry-run
# or after global install:
~/.cursor/skills/mac-migration-audit/scripts/create-image.sh --dry-run
```

## Homebrew

| Mac | Homebrew missing | What to do |
|-----|------------------|------------|
| **Source** (audit) | Audit still runs; Brewfile skipped | `--install-homebrew` installs with confirmation (opt-in) |
| **Destination** (restore) | `unimage` prompts to install before `brew bundle` | Confirm when asked |

Manual install: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

## Quick Start

**Source Mac (audit / create image):**

```bash
mac-migration create-image
mac-migration create-image ~/Desktop/mac-migration-bundle --install-homebrew
```

**Destination Mac (restore / unimage):**

```bash
mac-migration validate-bundle ./mac-migration-bundle
mac-migration unimage ./mac-migration-bundle
```

Use `--dry-run` on any script to preview without making changes.

## Workflow Overview

```
Phase 1: Audit source Mac (read-only)     → create-image.sh
    ↓
Phase 2: Analyze data, cloud sync, git repos
    ↓
Phase 3: Generate migration plan + scripts + reports
    ↓
Phase 4: Execute on destination Mac       → unimage.sh (with confirmation)
```

Copy this checklist and track progress:

```
Migration Progress:
- [ ] Phase 1 – Audit complete
- [ ] Phase 2 – Data analysis complete
- [ ] Phase 3 – Reports and scripts generated
- [ ] Phase 4 – Destination setup (if requested)
```

## Script vs Agent Responsibilities

| Task | Scripts | Agent (you) |
|------|---------|-------------|
| Raw inventory capture | `create-image.sh` | — |
| Brewfile, extensions, dotfiles (redacted) | `create-image.sh` | — |
| Data/cloud/browser/AI deep analysis | — | Phase 2 |
| 11 markdown deliverables | — | Phase 3 |
| Risk recommendations & scoring | — | Phase 3 |
| Package restore on new Mac | `unimage.sh` | Manual steps guide |
| SSH private keys, MFA, logins | — | `Manual_Steps.md` |

Scripts capture **structure and safe configs**. The agent analyzes `raw/` inventory and generates reports, warnings, and manual steps.

---

## Phase 1 – Audit the Existing Mac

Perform a complete audit and create a structured inventory.

### Operating System

Collect:

- macOS version
- Hardware model
- CPU
- RAM
- Disk usage
- Storage health
- Installed developer tools

### Applications

Create a complete list of installed applications.

For each application include:

- Name
- Version
- Installation source (App Store, Homebrew, DMG, etc.)
- Last launch date (if available)
- Recommendation:
  - Essential
  - Recommended
  - Optional
  - Unused

Prioritize applications used during the last 6–12 months.

### Development Environment

Collect:

**Git**

- Git version
- Global configuration
- Git aliases
- Ignore files
- Git hooks
- Repository locations

**SSH**

List:

- Public keys
- Key names
- Key usage

Never export or display private key contents.

**Development Tools** — detect versions and install method for: Homebrew, Git, Docker, Kubernetes (kubectl/helm), Terraform, Python (pyenv/pip/pipx), Node (npm/pnpm/yarn), Java (Maven/Gradle), Go, Rust, Ruby, cloud CLIs (aws/az/gcloud), Trino CLI. Full list in [reference.md](reference.md).

### IDEs & Editors

Detect:

- VS Code
- Cursor
- IntelliJ
- PyCharm
- WebStorm
- Rider
- Android Studio
- Windsurf
- Sublime Text
- Vim
- Neovim

Export:

- Settings
- Extensions/plugins
- Snippets
- Themes
- User configuration

### Terminal Environment

Collect:

- zsh configuration
- bash configuration
- aliases
- shell functions
- environment variables
- Starship configuration
- Oh My Zsh
- Powerlevel10k
- iTerm2 profiles
- Terminal profiles
- Custom fonts

### Browsers

For every installed browser:

- Chrome
- Edge
- Safari
- Firefox
- Arc
- Brave

Collect:

- Installed extensions
- Profiles
- Bookmarks (where exportable)
- Important settings

### Productivity Applications

Detect:

- Raycast
- Alfred
- Rectangle
- BetterTouchTool
- Keyboard Maestro
- HiddenBar
- Clipboard managers
- Notion
- Obsidian

Export configurations where possible.

### AI Development Tools

Detect:

- ChatGPT
- Claude
- Cursor
- Ollama
- LM Studio
- MCP servers
- Continue
- Cline
- Copilot
- Gemini CLI

Export configuration files only.

Never expose secrets.

### Automation

Collect:

- launchd jobs
- cron jobs
- Automator workflows
- Apple Shortcuts
- shell scripts
- scheduled tasks

### Fonts

List custom installed fonts.

### Network

Collect:

- VPN configurations
- SSH config
- Known hosts
- Network shares
- Printers

Do not expose credentials.

---

## Phase 2 – Data Analysis

Analyze the following folders:

- Desktop
- Documents
- Downloads
- Projects
- Development folders
- Custom work directories

For each folder identify:

- Frequently modified files
- Large files
- Recently modified files
- Duplicate files
- Temporary files
- Archive candidates

Prioritize files modified during the last 6–12 months.

### Cloud Storage Audit

Inspect:

- iCloud Drive
- Dropbox
- Google Drive
- OneDrive
- Synology Drive (if installed)

Identify:

- folders fully synchronized
- folders available only locally
- folders excluded from synchronization
- folders that should be uploaded before migration

Generate warnings for any important local-only data.

### Git Repository Audit

Locate all repositories.

For each repository display:

- path
- remote URL
- default branch
- last commit
- uncommitted changes
- unpushed commits
- ignored files

Recommend which repositories should be migrated.

---

## Phase 3 – Migration Planning

Generate:

### Executive Summary

Summarize:

- important applications
- important developer tools
- active projects
- risks
- recommendations

### Installation Plan

Generate installation steps in optimal order.

Example:

1. Install Homebrew
2. Install Xcode Command Line Tools
3. Install Git
4. Install developer tools
5. Install IDEs
6. Restore terminal configuration
7. Restore SSH configuration
8. Clone repositories
9. Install productivity tools
10. Restore browser settings
11. Verify environment
12. Cleanup

### Installation Script

Generate scripts for:

- Homebrew
- macOS defaults (if applicable)
- package installation
- configuration restoration
- repository cloning

### Manual Steps Guide

Create a separate guide for everything that cannot be automated.

Examples:

- Login to iCloud
- Login to Microsoft
- Login to Google
- Login to GitHub
- Restore MFA
- Install App Store applications
- Connect external devices

### Migration Checklist

Generate a checklist grouped by phase. See [reference.md](reference.md) for template.

---

## Phase 4 – Destination Mac Experience

When executing on the new Mac, use `unimage.sh` and display step-by-step progress with confirmations.

For the progress UI template (step headers, warnings, recovery instructions), see [reference.md — Destination Progress Template](reference.md#destination-progress-template).

---

## Deliverables

Generate the following files in a `mac-migration/` output directory (or user-specified path):

1. `Executive_Summary.md`
2. `Migration_Report.md`
3. `Applications_Report.md`
4. `Cloud_Audit.md`
5. `Git_Audit.md`
6. `Data_Inventory.md`
7. `Migration_Checklist.md`
8. `Manual_Steps.md`
9. `install.sh`
10. `restore.sh`
11. `README.md`

The reports should be well-structured, easy to read, and include recommendations based on application usage and file activity over the last 6–12 months. Flag anything that appears important but is not backed up or synchronized to cloud storage.

For deliverable templates and audit commands, see [reference.md](reference.md).

---

## Utility Scripts

| Script | Purpose | Run on |
|--------|---------|--------|
| `bin/mac-migration` | CLI wrapper — run without cloning repo | Either |
| `scripts/create-image.sh` | Read-only audit; builds migration bundle | Source Mac |
| `scripts/validate-bundle.sh` | Validates bundle structure before restore | Either Mac |
| `scripts/unimage.sh` | Installs packages and restores configs from bundle | Destination Mac |

Flags for `create-image`: `--dry-run`, `--install-homebrew` (prompts before installing Homebrew on source Mac).

After `create-image.sh`, use the agent to analyze `raw/` inventory and generate the markdown deliverables listed above.

---

## Redaction Checklist

Before writing any deliverable, verify:

- [ ] No private key contents
- [ ] No `.env` values, tokens, or passwords
- [ ] SSH config shows host aliases only (mask `IdentityFile` paths if sensitive)
- [ ] Git remotes with embedded tokens are redacted
- [ ] Browser/extension data excludes saved passwords
