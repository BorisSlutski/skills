#!/usr/bin/env bash
# validate-bundle.sh — Validate a migration bundle before restore.
# Usage: validate-bundle.sh <bundle-dir>
set -euo pipefail

BUNDLE_DIR="${1:-}"
if [[ -z "$BUNDLE_DIR" || ! -d "$BUNDLE_DIR" ]]; then
  echo "Usage: validate-bundle.sh <bundle-dir>" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0

check() {
  local path="$1" required="${2:-true}"
  if [[ -e "$BUNDLE_DIR/$path" ]]; then
    echo "  OK   $path"
  elif [[ "$required" == "true" ]]; then
    echo "  FAIL $path (required)" >&2
    ERRORS=$((ERRORS + 1))
  else
    echo "  WARN $path (optional, missing)"
    WARNINGS=$((WARNINGS + 1))
  fi
}

echo "Validating bundle: $BUNDLE_DIR"
echo

echo "Required files:"
check "manifest.json"
check "raw/os-hardware.txt"
check "raw/homebrew.txt"
check "raw/dev-tools.txt"
check "raw/git-config.txt"
check "raw/ssh-inventory.txt"
check "raw/applications.txt"
check "raw/git-repos.txt"

echo
echo "Optional files:"
check "Brewfile" false
check "dotfiles/.zshrc" false
check "extensions/vscode.txt" false
check "extensions/cursor.txt" false
check "install.sh" false
check "restore.sh" false

echo
if [[ -f "$BUNDLE_DIR/manifest.json" ]]; then
  echo "Manifest:"
  if command -v jq &>/dev/null; then
    if jq empty "$BUNDLE_DIR/manifest.json" 2>/dev/null; then
      jq . "$BUNDLE_DIR/manifest.json"
    else
      echo "  FAIL manifest.json is not valid JSON" >&2
      ERRORS=$((ERRORS + 1))
    fi
  else
    cat "$BUNDLE_DIR/manifest.json"
  fi

  if grep -q '"secrets_included": true' "$BUNDLE_DIR/manifest.json" 2>/dev/null; then
    echo "  FAIL manifest claims secrets are included — do not restore" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

echo
echo "Brewfile:"
if [[ -f "$BUNDLE_DIR/Brewfile" ]]; then
  if [[ ! -s "$BUNDLE_DIR/Brewfile" ]]; then
    echo "  WARN Brewfile is empty" >&2
    WARNINGS=$((WARNINGS + 1))
  elif command -v brew &>/dev/null; then
    if brew bundle check --file="$BUNDLE_DIR/Brewfile" --verbose 2>/dev/null; then
      echo "  OK   Brewfile (brew bundle check passed)"
    else
      echo "  WARN Brewfile failed brew bundle check (may still be valid on destination)" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "  WARN Brewfile present; brew not installed — skipped brew bundle check"
    WARNINGS=$((WARNINGS + 1))
  fi
elif [[ -f "$BUNDLE_DIR/raw/homebrew.txt" ]] && grep -qi "Homebrew not installed" "$BUNDLE_DIR/raw/homebrew.txt"; then
  echo "  OK   No Brewfile (source Mac had no Homebrew)"
else
  echo "  WARN No Brewfile (optional)"
  WARNINGS=$((WARNINGS + 1))
fi

echo
if [[ $ERRORS -gt 0 ]]; then
  echo "Validation FAILED ($ERRORS errors, $WARNINGS warnings)" >&2
  exit 1
fi

echo "Validation PASSED ($WARNINGS warnings)"
exit 0
