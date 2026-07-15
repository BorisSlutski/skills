#!/usr/bin/env bash
# Shared Homebrew helpers for mac-migration-audit scripts.

setup_brew_shellenv() {
  if [[ -f /opt/homebrew/bin/brew ]]; then
    # shellcheck disable=SC1091
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    # shellcheck disable=SC1091
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  local dry_run="${1:-false}"

  if command -v brew &>/dev/null; then
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "[dry-run] Would install Homebrew from https://brew.sh"
    return 1
  fi

  echo "Homebrew is not installed."
  read -r -p "Install Homebrew now? This requires network access. [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Skipped Homebrew install."
    return 1
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  setup_brew_shellenv

  if command -v brew &>/dev/null; then
    echo "Homebrew installed successfully."
    return 0
  fi

  echo "Homebrew install finished but 'brew' is not on PATH. Open a new terminal or run:" >&2
  echo '  eval "$(/opt/homebrew/bin/brew shellenv)"' >&2
  return 1
}
