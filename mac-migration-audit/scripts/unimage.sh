#!/usr/bin/env bash
# unimage.sh — Restore environment on destination Mac from migration bundle.
# Usage: unimage.sh <bundle-dir> [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/homebrew.sh
source "$SCRIPT_DIR/lib/homebrew.sh"

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

STEP=0
TOTAL_STEPS=6

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
if command -v brew &>/dev/null; then
  echo "Status: Already installed."
  setup_brew_shellenv
elif $DRY_RUN; then
  echo "Status: Running..."
  install_homebrew true || echo "Skipped."
else
  echo "Status: Waiting for user confirmation."
  install_homebrew false || echo "Skipped — some restore steps will not work without Homebrew."
fi
echo "Completed."

step "Install packages from Brewfile"
if [[ -f "$BUNDLE_DIR/Brewfile" ]]; then
  echo "Status: Running..."
  if confirm "Run brew bundle install from captured Brewfile?"; then
    if $DRY_RUN; then
      echo "  [dry-run] brew bundle install --file=$BUNDLE_DIR/Brewfile"
    else
      brew bundle install --file="$BUNDLE_DIR/Brewfile"
    fi
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
        if $DRY_RUN; then
          echo "  [dry-run] mkdir -p $HOME/.config && cp $src $dest"
        else
          mkdir -p "$HOME/.config"
          [[ -f "$dest" ]] && cp "$dest" "${dest}.bak" && echo "  Backed up $dest -> ${dest}.bak"
          cp "$src" "$dest"
          echo "  Restored $dest"
        fi
      else
        dest="$HOME/$name"
        if $DRY_RUN; then
          echo "  [dry-run] cp $src $dest"
        else
          [[ -f "$dest" ]] && cp "$dest" "${dest}.bak" && echo "  Backed up $dest -> ${dest}.bak"
          cp "$src" "$dest"
          echo "  Restored $dest"
        fi
      fi
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
      if $DRY_RUN; then
        echo "  [dry-run] code --install-extension $ext"
      else
        code --install-extension "$ext"
      fi
    done < "$BUNDLE_DIR/extensions/vscode.txt"
  fi
fi
if [[ -f "$BUNDLE_DIR/extensions/cursor.txt" ]] && command -v cursor &>/dev/null; then
  if confirm "Install Cursor extensions from bundle?"; then
    while IFS= read -r ext; do
      [[ -n "$ext" ]] || continue
      if $DRY_RUN; then
        echo "  [dry-run] cursor --install-extension $ext"
      else
        cursor --install-extension "$ext"
      fi
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
