#!/usr/bin/env bash
# unimage.sh — Restore environment on destination Mac from migration bundle.
# Usage: unimage.sh <bundle-dir> [--dry-run]
set -euo pipefail

DRY_RUN=false
BUNDLE_DIR=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *)
      if [[ -z "$BUNDLE_DIR" ]]; then
        BUNDLE_DIR="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$BUNDLE_DIR" || ! -d "$BUNDLE_DIR" ]]; then
  echo "Usage: unimage.sh <bundle-dir> [--dry-run]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STEP=0
TOTAL_STEPS=6

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

confirm() {
  if $DRY_RUN; then
    echo "  [dry-run] confirm: $1"
    return 0
  fi
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

step() {
  STEP=$((STEP + 1))
  echo
  echo "================================================="
  echo "Mac Migration Assistant"
  echo "================================================="
  echo
  echo "Step $STEP/$TOTAL_STEPS"
  echo "$1"
  echo
}

step "Validate bundle"
"$SCRIPT_DIR/validate-bundle.sh" "$BUNDLE_DIR" || exit 1
echo "Status: Completed."

step "Install Homebrew"
if ! command -v brew &>/dev/null; then
  echo "Status: Running..."
  if $DRY_RUN; then
    echo "  [dry-run] Install Homebrew"
  else
    confirm "Install Homebrew? This requires network access." || { echo "Skipped."; }
    if ! command -v brew &>/dev/null; then
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # shellcheck disable=SC1091
      [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
      # shellcheck disable=SC1091
      [[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
else
  echo "Status: Already installed."
fi
echo "Completed."

step "Install packages from Brewfile"
if [[ -f "$BUNDLE_DIR/Brewfile" ]]; then
  echo "Status: Running..."
  if confirm "Run brew bundle install from captured Brewfile?"; then
    run "brew bundle install --file=\"$BUNDLE_DIR/Brewfile\""
  else
    echo "Skipped."
  fi
else
  echo "Status: No Brewfile found — skipped."
fi
echo "Completed."

step "Restore shell dotfiles"
if [[ -d "$BUNDLE_DIR/dotfiles" ]]; then
  echo "Status: Waiting for user confirmation."
  if confirm "Restore dotfiles from bundle? Existing files will be backed up with .bak suffix."; then
    for src in "$BUNDLE_DIR/dotfiles/"*; do
      [[ -e "$src" ]] || continue
      name=$(basename "$src")
      if [[ "$name" == "starship.toml" ]]; then
        dest="$HOME/.config/starship.toml"
        run "mkdir -p \"$HOME/.config\""
      else
        dest="$HOME/$name"
      fi
      if [[ -f "$dest" ]] && ! $DRY_RUN; then
        cp "$dest" "${dest}.bak"
        echo "  Backed up $dest -> ${dest}.bak"
      fi
      run "cp \"$src\" \"$dest\""
      echo "  Restored $dest"
    done
  else
    echo "Skipped."
  fi
else
  echo "Status: No dotfiles in bundle — skipped."
fi
echo "Completed."

step "Install IDE extensions"
if [[ -f "$BUNDLE_DIR/extensions/vscode.txt" ]] && command -v code &>/dev/null; then
  if confirm "Install VS Code extensions from bundle?"; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] || continue
      run "code --install-extension \"$ext\""
    done < "$BUNDLE_DIR/extensions/vscode.txt"
  fi
fi
if [[ -f "$BUNDLE_DIR/extensions/cursor.txt" ]] && command -v cursor &>/dev/null; then
  if confirm "Install Cursor extensions from bundle?"; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] || continue
      run "cursor --install-extension \"$ext\""
    done < "$BUNDLE_DIR/extensions/cursor.txt"
  fi
fi
echo "Completed."

step "Manual steps reminder"
echo "Status: Review required."
echo
echo "The following cannot be automated — see Manual_Steps.md (generate with agent):"
echo "  - SSH private keys (copy securely from old Mac)"
echo "  - GitHub/GitLab login and MFA"
echo "  - App Store applications"
echo "  - Browser passwords and extensions requiring login"
echo "  - iCloud / cloud storage sync verification"
echo
if [[ -f "$BUNDLE_DIR/raw/git-repos.txt" ]]; then
  echo "Git repos to clone (from audit):"
  head -20 "$BUNDLE_DIR/raw/git-repos.txt" | while IFS='|' read -r path _rest; do
    echo "  - $path"
  done
  count=$(wc -l < "$BUNDLE_DIR/raw/git-repos.txt" | tr -d ' ')
  [[ "$count" -gt 20 ]] && echo "  ... and $((count - 20)) more"
fi
echo
echo "Completed."

echo
echo "================================================="
echo "unimage.sh finished"
$DRY_RUN && echo "(dry-run — no changes made)"
echo "================================================="
