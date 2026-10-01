#!/usr/bin/env bash
# Ona dotfiles entrypoint. Ona clones this repo to ~/dotfiles and runs this
# script when an environment starts.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOME}/.dotfiles-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

export USER="${USER:-$(id -un)}"
export HOME="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"

log() { echo "[dotfiles] $*"; }

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    log "need root for: $*, but sudo is unavailable"
    return 1
  fi
}

source_nix() {
  local f
  for f in \
    "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
    if [ -e "$f" ]; then
      # shellcheck disable=SC1090
      set +u; . "$f"; set -u
      return 0
    fi
  done
  return 1
}

install_nix() {
  if command -v nix >/dev/null 2>&1 || source_nix; then
    log "nix already installed: $(nix --version)"
    return
  fi

  # Single-user install: works in containers without systemd/a nix daemon.
  log "installing nix (single-user)"
  if [ ! -d /nix ]; then
    as_root mkdir -m 0755 /nix
    as_root chown "$USER" /nix
  fi
  curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install | sh -s -- --no-daemon
  source_nix
}

configure_nix() {
  mkdir -p "$HOME/.config/nix"
  local conf="$HOME/.config/nix/nix.conf"
  if ! grep -qs '^experimental-features' "$conf"; then
    echo 'experimental-features = nix-command flakes' >>"$conf"
  fi
}

# Unauthenticated GitHub API calls (used to fetch `github:` flake inputs) are
# limited to 60/hour per IP, which shared egress IPs exhaust quickly. Pass
# $GITHUB_TOKEN to nix for this run if set; it is not persisted.
configure_github_token() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    log "using GITHUB_TOKEN for nix fetches"
    export NIX_CONFIG="access-tokens = github.com=${GITHUB_TOKEN}${NIX_CONFIG:+
$NIX_CONFIG}"
  else
    log "GITHUB_TOKEN not set; github: fetches may hit the API rate limit"
  fi
}

apply_home_manager() {
  log "applying home-manager configuration"
  # -b: back up any pre-existing files home-manager wants to manage.
  nix run "${DOTFILES_DIR}#home-manager" -- \
    switch --flake "${DOTFILES_DIR}#default" --impure -b hm-backup
}

set_default_shell() {
  local fish_path="$HOME/.nix-profile/bin/fish"
  if [ ! -x "$fish_path" ]; then
    log "fish not found at $fish_path, skipping default shell setup"
    return
  fi

  if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
    echo "$fish_path" | as_root tee -a /etc/shells >/dev/null || true
  fi
  if command -v chsh >/dev/null 2>&1; then
    as_root chsh -s "$fish_path" "$USER" || log "chsh failed"
  fi

  # Fallback for terminals that start bash regardless of the login shell.
  local marker="# >>> dotfiles: exec fish >>>"
  if ! grep -qsF "$marker" "$HOME/.bashrc"; then
    cat >>"$HOME/.bashrc" <<EOF

$marker
if [[ \$- == *i* ]] && [ -t 0 ] && [ -z "\${VSCODE_RESOLVING_ENVIRONMENT:-}" ] \\
  && [ -x "$fish_path" ] && [ "\$(basename "\$(ps -o comm= -p \$PPID 2>/dev/null)")" != fish ]; then
  exec "$fish_path"
fi
# <<< dotfiles: exec fish <<<
EOF
  fi
}

install_nix
configure_nix
configure_github_token
apply_home_manager
set_default_shell
log "done"
