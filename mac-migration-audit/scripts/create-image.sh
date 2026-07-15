#!/usr/bin/env bash
# create-image.sh — Read-only audit of source Mac; builds a migration bundle.
# Usage: create-image.sh [output-dir] [--dry-run]
set -euo pipefail

DRY_RUN=false
OUTPUT_DIR=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *)
      if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Desktop/mac-migration-bundle-$TIMESTAMP}"

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

log() { echo "==> $*"; }

redact_git_config() {
  git config --global --list 2>/dev/null \
    | grep -v -Ei '(token|password|credential|secret|oauth)' \
    || true
}

redact_ssh_config() {
  if [[ -f "$HOME/.ssh/config" ]]; then
    awk '
      /^[[:space:]]*(Password|IdentityFile|CertificateFile|ProxyCommand)/ { next }
      { print }
    ' "$HOME/.ssh/config"
  fi
}

copy_if_exists() {
  local src="$1" dest="$2"
  if [[ -e "$src" ]]; then
    run "mkdir -p \"$(dirname "$dest")\""
    run "cp -a \"$src\" \"$dest\""
  fi
}

log "Mac Migration — create-image (read-only)"
log "Output: $OUTPUT_DIR"
$DRY_RUN && log "DRY RUN — no files will be written"

run "mkdir -p \"$OUTPUT_DIR/raw\" \"$OUTPUT_DIR/dotfiles\" \"$OUTPUT_DIR/extensions\" \"$OUTPUT_DIR/repos\""

# --- OS & hardware ---
log "Collecting OS and hardware info"
{
  echo "# macOS Version"
  sw_vers
  echo
  echo "# Hardware"
  system_profiler SPHardwareDataType SPStorageDataType 2>/dev/null || true
  echo
  echo "# Disk Usage"
  df -h
} > /tmp/mac-migration-os.txt
run "cp /tmp/mac-migration-os.txt \"$OUTPUT_DIR/raw/os-hardware.txt\""

# --- Homebrew ---
log "Collecting Homebrew inventory"
if command -v brew &>/dev/null; then
  {
    brew --version
    echo "---"
    brew list --versions 2>/dev/null || true
    echo "---"
    brew bundle dump --describe --force --file=/dev/stdout 2>/dev/null || true
  } > /tmp/mac-migration-brew.txt
  run "cp /tmp/mac-migration-brew.txt \"$OUTPUT_DIR/raw/homebrew.txt\""
  grep -E '^brew ' /tmp/mac-migration-brew.txt > /tmp/Brewfile 2>/dev/null || true
  if [[ -s /tmp/Brewfile ]]; then
    run "cp /tmp/Brewfile \"$OUTPUT_DIR/Brewfile\""
  fi
else
  echo "Homebrew not installed" > /tmp/mac-migration-brew.txt
  run "cp /tmp/mac-migration-brew.txt \"$OUTPUT_DIR/raw/homebrew.txt\""
fi

# --- Dev tool versions ---
log "Collecting dev tool versions"
{
  for cmd in git node npm yarn pnpm python3 pip3 pipx docker docker-compose kubectl helm terraform go rustc ruby java mvn gradle aws az gcloud trino; do
    if command -v "$cmd" &>/dev/null; then
      echo "$cmd: $($cmd --version 2>&1 | head -1)"
    fi
  done
} > /tmp/mac-migration-devtools.txt
run "cp /tmp/mac-migration-devtools.txt \"$OUTPUT_DIR/raw/dev-tools.txt\""

# --- Git ---
log "Collecting Git config (redacted)"
redact_git_config > /tmp/mac-migration-git.txt
run "cp /tmp/mac-migration-git.txt \"$OUTPUT_DIR/raw/git-config.txt\""
copy_if_exists "$HOME/.gitignore_global" "$OUTPUT_DIR/dotfiles/.gitignore_global"

# --- SSH (public keys + sanitized config only) ---
log "Collecting SSH inventory (no private keys)"
{
  echo "# Public keys"
  ls -la "$HOME/.ssh/"*.pub 2>/dev/null || echo "No public keys found"
  echo
  echo "# SSH config (sanitized)"
  redact_ssh_config
} > /tmp/mac-migration-ssh.txt
run "cp /tmp/mac-migration-ssh.txt \"$OUTPUT_DIR/raw/ssh-inventory.txt\""

# --- Shell dotfiles ---
log "Collecting shell dotfiles"
for f in .zshrc .zprofile .zshenv .bashrc .bash_profile .bash_aliases; do
  copy_if_exists "$HOME/$f" "$OUTPUT_DIR/dotfiles/$f"
done
copy_if_exists "$HOME/.config/starship.toml" "$OUTPUT_DIR/dotfiles/starship.toml"

# --- IDE extensions ---
log "Collecting IDE extension lists"
if command -v code &>/dev/null; then
  code --list-extensions > /tmp/vscode-extensions.txt 2>/dev/null || true
  run "cp /tmp/vscode-extensions.txt \"$OUTPUT_DIR/extensions/vscode.txt\""
fi
if command -v cursor &>/dev/null; then
  cursor --list-extensions > /tmp/cursor-extensions.txt 2>/dev/null || true
  run "cp /tmp/cursor-extensions.txt \"$OUTPUT_DIR/extensions/cursor.txt\""
fi

# --- Applications ---
log "Collecting application inventory"
{
  for app_dir in /Applications /Applications/Utilities "$HOME/Applications"; do
    [[ -d "$app_dir" ]] || continue
    for app in "$app_dir"/*.app; do
      [[ -d "$app" ]] || continue
      name=$(basename "$app" .app)
      version=$(defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
      last_used=$(mdls -name kMDItemLastUsedDate -raw "$app" 2>/dev/null || echo "unknown")
      echo "$name|$version|$app_dir|$last_used"
    done
  done
} > /tmp/mac-migration-apps.txt
run "cp /tmp/mac-migration-apps.txt \"$OUTPUT_DIR/raw/applications.txt\""

# --- Git repos (shallow scan) ---
log "Scanning git repositories (max depth 5)"
if $DRY_RUN; then
  echo "[dry-run] find git repos in \$HOME (maxdepth 5)" > /tmp/mac-migration-repos.txt
else
  {
    find "$HOME" -maxdepth 5 -name .git -type d -prune 2>/dev/null | head -200 | while read -r gitdir; do
    repo="${gitdir%/.git}"
    branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "unknown")
    remote=$(git -C "$repo" remote get-url origin 2>/dev/null | sed -E 's/(:\/\/)[^@]+@/\1***@/g' || echo "none")
    last_commit=$(git -C "$repo" log -1 --format='%h %ci %s' 2>/dev/null || echo "unknown")
    dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "$repo|$branch|$remote|$last_commit|dirty=$dirty"
    done
  } > /tmp/mac-migration-repos.txt
fi
run "cp /tmp/mac-migration-repos.txt \"$OUTPUT_DIR/raw/git-repos.txt\""

# --- Automation ---
log "Collecting automation inventory"
{
  echo "# User LaunchAgents"
  ls "$HOME/Library/LaunchAgents/" 2>/dev/null || echo "none"
  echo
  echo "# Cron"
  crontab -l 2>/dev/null || echo "no crontab"
} > /tmp/mac-migration-automation.txt
run "cp /tmp/mac-migration-automation.txt \"$OUTPUT_DIR/raw/automation.txt\""

# --- Fonts ---
log "Collecting fonts"
{
  ls "$HOME/Library/Fonts/" 2>/dev/null || true
  ls /Library/Fonts/ 2>/dev/null || true
} > /tmp/mac-migration-fonts.txt
run "cp /tmp/mac-migration-fonts.txt \"$OUTPUT_DIR/raw/fonts.txt\""

# --- Manifest ---
log "Writing manifest"
MANIFEST="$OUTPUT_DIR/manifest.json"
if $DRY_RUN; then
  echo "[dry-run] write manifest.json"
else
  cat > "$MANIFEST" <<EOF
{
  "version": "1.0",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$HOSTNAME",
  "macos_version": "$(sw_vers -productVersion)",
  "hardware": "$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name|Chip|Memory/ {print $2}' | tr '\n' ' ' | sed 's/ $//')",
  "bundle_type": "mac-migration-audit",
  "read_only_audit": true,
  "secrets_included": false
}
EOF
fi

# --- Stub scripts for agent to expand ---
if ! $DRY_RUN; then
  [[ -f "$OUTPUT_DIR/install.sh" ]] || cp "$(dirname "$0")/templates/install.sh" "$OUTPUT_DIR/install.sh" 2>/dev/null || cat > "$OUTPUT_DIR/install.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "Run unimage.sh instead, or customize this script after agent generates install plan."
STUB
  [[ -f "$OUTPUT_DIR/restore.sh" ]] || cat > "$OUTPUT_DIR/restore.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "Run unimage.sh instead, or customize this script after agent generates restore plan."
STUB
  chmod +x "$OUTPUT_DIR/install.sh" "$OUTPUT_DIR/restore.sh" 2>/dev/null || true
fi

log "Done. Bundle created at: $OUTPUT_DIR"
log "Next: copy bundle to new Mac, then run validate-bundle.sh and unimage.sh"
log "Optional: attach @SKILL.md and ask agent to generate reports from raw/ inventory"
