# Mac Migration Audit

Audit a source Mac in read-only mode and recreate your dev environment on a new Mac.

## Install

```bash
npx skills add BorisSlutski/skills/mac-migration-audit -g -y
```

## Scripts

| Script | Mac | Description |
|--------|-----|-------------|
| `scripts/create-image.sh` | Source | Build a migration bundle (inventory + configs, no secrets) |
| `scripts/validate-bundle.sh` | Either | Check bundle before restore |
| `scripts/unimage.sh` | Destination | Install packages and restore configs from bundle |

All scripts support `--dry-run`.

## Typical Flow

```bash
# 1. On old Mac — create bundle
./mac-migration-audit/scripts/create-image.sh ~/Desktop/my-mac-bundle

# 2. Copy bundle to new Mac (AirDrop, USB, cloud)

# 3. On new Mac — validate and restore
./mac-migration-audit/scripts/validate-bundle.sh ~/Desktop/my-mac-bundle
./mac-migration-audit/scripts/unimage.sh ~/Desktop/my-mac-bundle

# 4. In Cursor — attach @SKILL.md and ask agent to generate reports from raw/ inventory
```

## What Gets Captured

- OS/hardware info, disk usage
- Homebrew packages and Brewfile
- Dev tool versions
- Git global config (secrets redacted)
- SSH public keys and sanitized ssh config
- IDE extension lists
- Shell dotfiles (structure + safe copies)
- Application inventory with last-used dates
- Git repo locations and status
- Launch agents, cron, fonts

## What Is Never Captured

- Private SSH keys
- Passwords, tokens, API keys
- Browser saved passwords
- Keychain contents
