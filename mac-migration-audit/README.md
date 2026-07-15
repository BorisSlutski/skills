# Mac Migration Audit

Audit a source Mac in read-only mode and recreate your dev environment on a new Mac.

## Run Without Cloning

### Recommended — install skill globally

```bash
npx skills add BorisSlutski/skills/mac-migration-audit -g -y
export PATH="$HOME/.cursor/skills/mac-migration-audit/bin:$PATH"

mac-migration create-image --dry-run
mac-migration create-image ~/Desktop/my-mac-bundle
mac-migration unimage ~/Desktop/my-mac-bundle --dry-run
```

### One-shot (download CLI from GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/BorisSlutski/skills/main/mac-migration-audit/bin/mac-migration -o /tmp/mac-migration
chmod +x /tmp/mac-migration
/tmp/mac-migration create-image --dry-run
```

### From cloned repo

```bash
./mac-migration-audit/bin/mac-migration create-image --dry-run
# or:
./mac-migration-audit/scripts/create-image.sh --dry-run
```

## Homebrew

| When | If Homebrew is missing |
|------|------------------------|
| **Source Mac** (`create-image`) | Audit continues without brew inventory. Add `--install-homebrew` to install with confirmation first. |
| **Destination Mac** (`unimage`) | Prompts to install Homebrew before restoring packages. |

```bash
# Source — optional install before audit
mac-migration create-image --install-homebrew

# Manual install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Commands

| Command | Description |
|---------|-------------|
| `mac-migration create-image [dir] [--dry-run] [--install-homebrew]` | Build migration bundle |
| `mac-migration validate-bundle <dir>` | Validate bundle |
| `mac-migration unimage <dir> [--dry-run]` | Restore on new Mac |
| `mac-migration help` | Show usage |

## Typical Flow

```bash
# 1. On old Mac
mac-migration create-image ~/Desktop/my-mac-bundle

# 2. Copy bundle to new Mac (AirDrop, USB, cloud)

# 3. On new Mac
mac-migration validate-bundle ~/Desktop/my-mac-bundle
mac-migration unimage ~/Desktop/my-mac-bundle

# 4. In Cursor — attach @SKILL.md and ask agent to generate reports from raw/ inventory
```

## What Gets Captured

- OS/hardware info, disk usage
- Homebrew packages and full Brewfile (casks, taps, mas, vscode)
- Dev tool versions
- Git global config (secrets redacted)
- SSH public keys and sanitized ssh config
- IDE extension lists
- Shell dotfiles (secrets redacted — `KEY`/`TOKEN`/`PASSWORD` values replaced with `[REDACTED]`)
- Application inventory with last-used dates
- Git repo locations and status
- Launch agents, cron, fonts

## What Is Never Captured

- Private SSH keys
- Passwords, tokens, API keys
- Browser saved passwords
- Keychain contents
