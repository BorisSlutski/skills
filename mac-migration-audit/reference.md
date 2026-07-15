# Mac Migration — Reference

## Deliverable Templates

### Executive_Summary.md

```markdown
# Executive Summary — Mac Migration

**Audit date:** [date]
**Source Mac:** [model] — macOS [version]
**Target:** New Mac setup

## Key Findings
- [3–5 bullet summary]

## Essential Applications ([count])
| App | Version | Source | Recommendation |
|-----|---------|--------|----------------|

## Active Development Stack
- [tools with versions]

## Risks & Warnings
- ⚠️ [local-only data paths]
- ⚠️ [repos with unpushed commits]
- ⚠️ [apps requiring manual reinstall]

## Recommended Migration Order
1. ...
```

### Applications_Report.md

```markdown
# Applications Report

## Summary
| Category | Count |
|----------|-------|
| Essential | |
| Recommended | |
| Optional | |
| Unused | |

## Full Inventory
| Name | Version | Source | Last Launch | Recommendation | Notes |
|------|---------|--------|-------------|----------------|-------|
```

### Cloud_Audit.md

```markdown
# Cloud Storage Audit

## Providers Detected
- [ ] iCloud Drive
- [ ] Dropbox
- [ ] Google Drive
- [ ] OneDrive
- [ ] Synology Drive

## Sync Status
| Path | Provider | Status | Action Required |
|------|----------|--------|-----------------|

## Local-Only Warnings
> Upload or manually copy before decommissioning source Mac.
```

### Git_Audit.md

```markdown
# Git Repository Audit

## Summary
| Metric | Count |
|--------|-------|
| Total repos | |
| With uncommitted changes | |
| With unpushed commits | |
| No remote | |

## Repositories
| Path | Remote | Branch | Last Commit | Dirty | Unpushed | Migrate? |
|------|--------|--------|-------------|-------|----------|----------|
```

### Data_Inventory.md

```markdown
# Data Inventory

## Folder Analysis
### ~/Documents
- Total size:
- Files modified (6–12 mo):
- Large files (>100MB):
- Archive candidates:

[Repeat per folder]

## Duplicate Candidates
| File A | File B | Size |
|--------|--------|------|
```

### Migration_Checklist.md

Use checkbox format. Group by phase:

```markdown
# Migration Checklist

## Pre-Migration (Source Mac)
- [ ] Review local-only data warnings
- [ ] Push all git repos
- [ ] Export browser bookmarks
- [ ] Backup SSH keys securely (manual)

## Installation (Destination Mac)
- [ ] Install Homebrew
- [ ] Install Xcode CLT
...

## Verification
- [ ] `git --version` matches expected
- [ ] `docker ps` works
- [ ] SSH to GitHub succeeds
- [ ] IDE extensions restored
```

### Manual_Steps.md

```markdown
# Manual Steps (Cannot Be Automated)

## Account Logins
1. **Apple ID / iCloud** — ...
2. **GitHub** — regenerate PAT, re-enable MFA
...

## App Store Apps
| App | Why Manual |
|-----|------------|

## Security
- Restore MFA authenticator apps
- Re-pair security keys
```

### install.sh skeleton

Uses direct commands (no `eval`) — same pattern as `scripts/lib/common.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

run_cmd() {
  if $DRY_RUN; then
    printf '[dry-run]'
    printf ' %q' "$@"
    echo
  else
    "$@"
  fi
}

echo "=== Mac Migration: install.sh ==="

# 1. Homebrew
if ! command -v brew &>/dev/null; then
  if $DRY_RUN; then
    echo "[dry-run] install Homebrew from https://brew.sh"
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

# 2. Brewfile packages
# run_cmd brew bundle install --file=./Brewfile

# 3. Dev tools
# run_cmd brew install git node

echo "=== install.sh complete ==="
```

### restore.sh skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${1:-./migration-backup}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

confirm() {
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

restore_file() {
  local src="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    confirm "Overwrite $dest?" || return 0
  fi
  if $DRY_RUN; then echo "[dry-run] cp $src $dest"; else cp "$src" "$dest"; fi
}

echo "=== Mac Migration: restore.sh ==="
# restore_file "$BACKUP_DIR/dotfiles/.zshrc" "$HOME/.zshrc"

echo "=== restore.sh complete ==="
```

### README.md

```markdown
# Mac Migration Package

Generated: [date]
Source: [hostname / model]

## Contents
| File | Purpose |
|------|---------|
| Executive_Summary.md | High-level overview |
| Migration_Report.md | Full audit details |
| ... | |

## Quick Start (Destination Mac)
1. Copy this folder to the new Mac
2. Review Executive_Summary.md and Cloud_Audit.md warnings
3. Run `./install.sh`
4. Complete Manual_Steps.md
5. Run `./restore.sh`
6. Work through Migration_Checklist.md

## Safety
- Scripts do not contain secrets
- Review before executing
- Use `--dry-run` to preview
```

---

## IDE Config Paths

| Editor | Settings | Extensions |
|--------|----------|------------|
| VS Code | `~/Library/Application Support/Code/User/` | `code --list-extensions` |
| Cursor | `~/Library/Application Support/Cursor/User/` | `cursor --list-extensions` 2>/dev/null |
| JetBrains | `~/Library/Application Support/JetBrains/<product><version>/` | plugins in `plugins/` |

## AI Tool Config Paths

| Tool | Config location |
|------|-----------------|
| Claude Code | `~/.claude/` |
| Cursor | `~/.cursor/` |
| Ollama | `~/.ollama/` |
| Continue | `~/.continue/` |
| MCP | `~/.cursor/mcp.json`, project `.cursor/mcp.json` |

Never copy secret values — inventory file names and structure only.

## Browser Extension Export

| Browser | Method |
|---------|--------|
| Chrome/Edge/Brave/Arc | Sync via Google account, or export via extension managers |
| Firefox | `profiles.ini` + `extensions.json` inventory |
| Safari | iCloud sync; extensions via App Store reinstall |

## Recommendation Heuristics

**Essential** — launched in last 30 days AND (dev tool OR daily driver app)

**Recommended** — launched in last 6 months OR required dependency of essential tool

**Optional** — launched 6–12 months ago

**Unused** — no launch in 12+ months OR never launched (if data available)

Use `mdls -name kMDItemLastUsedDate` on `.app` bundles when available.

---

## Destination Progress Template

Use this format when executing Phase 4 on the destination Mac:

```
=================================================
Mac Migration Assistant
=================================================

Step 1/15
Install Homebrew

Status:
Running...

Completed.

---

Step 4/15
Restoring SSH configuration...

Waiting for user confirmation.

---

Step 5/15
Cloud Verification

Warning:

The following folders exist only locally on the old Mac:

- Projects/Archive
- Documents/Finance

Recommendation:

Upload these folders to cloud storage or copy them manually before continuing.

Continue? (Y/N)
```

Every step must include:

- Step number
- Description
- Purpose
- Automatic or Manual
- Progress indicator
- Success or failure status
- Recovery instructions if something fails

