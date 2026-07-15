#!/usr/bin/env bash
# Shared helpers: safe execution (no eval) and secret redaction.

# Redact common secret patterns in shell/config files.
redact_file_to() {
  local src="$1" dest="$2"
  [[ -f "$src" ]] || return 0

  awk '
    BEGIN { in_pem = 0 }

    {
      line = $0

      # Omit PEM private key blocks
      if (line ~ /-----BEGIN (RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----/) {
        print "# [REDACTED PEM private key block]"
        in_pem = 1
        next
      }
      if (in_pem) {
        if (line ~ /-----END (RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----/) in_pem = 0
        next
      }

      # Do not copy instructions to source secret/env files
      if (line ~ /^[[:space:]]*(source|\.)[[:space:]]+[^#]*\.(env|secrets)(\.[A-Za-z0-9._-]+)?([[:space:]]|$)/) {
        print "# [REDACTED source] " line
        next
      }

      # Redact common token formats anywhere on the line
      if (line ~ /(sk-[A-Za-z0-9_-]{8,}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{8,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)/) {
        gsub(/(sk-[A-Za-z0-9_-]{8,}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{8,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)/, "[REDACTED]", line)
      }

      # export VAR=value for secret-like variable names (avoid bare API suffix false positives)
      if (line ~ /^[[:space:]]*(export[[:space:]]+)?[A-Za-z0-9_]*(_KEY|_TOKEN|_SECRET|_PASSWORD|_CREDENTIAL|_AUTH|API_KEY|API_SECRET|ACCESS_TOKEN|REFRESH_TOKEN|CLIENT_SECRET|PRIVATE_KEY|SECRET_KEY|AUTH_TOKEN|PAT)[A-Za-z0-9_]*=/) {
        sub(/=.*/, "=[REDACTED]", line)
      }
      # Generic api_key assignments (key name contains api_key, not trailing API=)
      else if (line ~ /[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][[:space:]]*[=:][[:space:]]*/) {
        sub(/[=:][[:space:]]*.*/, "=[REDACTED]", line)
      }
      # Bearer tokens
      else if (line ~ /[Bb]earer[[:space:]]+[A-Za-z0-9._-]+/) {
        sub(/[Bb]earer[[:space:]]+[A-Za-z0-9._-]+/, "Bearer [REDACTED]", line)
      }
      print line
    }
  ' "$src" > "$dest"
}

safe_mkdir_p() {
  local dir="$1"
  local dry_run="${2:-false}"
  if [[ "$dry_run" == "true" ]]; then
    echo "[dry-run] mkdir -p $dir"
  else
    mkdir -p "$dir"
  fi
}

safe_cp() {
  local src="$1" dest="$2"
  local dry_run="${3:-false}"
  if [[ "$dry_run" == "true" ]]; then
    echo "[dry-run] cp $src $dest"
  else
    safe_mkdir_p "$(dirname "$dest")" false
    cp -a "$src" "$dest"
  fi
}

safe_cp_redacted() {
  local src="$1" dest="$2"
  local dry_run="${3:-false}"
  if [[ ! -f "$src" ]]; then
    return 0
  fi
  if [[ "$dry_run" == "true" ]]; then
    echo "[dry-run] redact and copy $src -> $dest"
  else
    safe_mkdir_p "$(dirname "$dest")" false
    redact_file_to "$src" "$dest"
  fi
}

write_manifest_json() {
  local dest="$1"
  local hostname="$2"
  local macos_version="$3"
  local hardware="$4"
  local created_at
  created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if command -v jq &>/dev/null; then
    jq -n \
      --arg version "1.0" \
      --arg created_at "$created_at" \
      --arg hostname "$hostname" \
      --arg macos_version "$macos_version" \
      --arg hardware "$hardware" \
      '{
        version: $version,
        created_at: $created_at,
        hostname: $hostname,
        macos_version: $macos_version,
        hardware: $hardware,
        bundle_type: "mac-migration-audit",
        read_only_audit: true,
        secrets_included: false
      }' > "$dest"
  else
    # Fallback: escape double quotes in string fields
    local esc_hardware esc_hostname
    esc_hardware="${hardware//\"/\\\"}"
    esc_hostname="${hostname//\"/\\\"}"
    cat > "$dest" <<EOF
{
  "version": "1.0",
  "created_at": "$created_at",
  "hostname": "$esc_hostname",
  "macos_version": "$macos_version",
  "hardware": "$esc_hardware",
  "bundle_type": "mac-migration-audit",
  "read_only_audit": true,
  "secrets_included": false
}
EOF
  fi
}
