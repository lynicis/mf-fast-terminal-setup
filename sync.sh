#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="lynicis/mf-fast-terminal-setup"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.terminal_setup_backup_$(date +%Y%m%d%H%M%S)"

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "Already linked $dest -> $src"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    local base backup_path
    base="$(basename "$dest")"
    backup_path="${BACKUP_DIR}/${base}"
    if [ -e "$backup_path" ]; then
      backup_path="${BACKUP_DIR}/${base}.$(date +%s)"
    fi
    echo "Backing up existing $dest -> $backup_path"
    mv "$dest" "$backup_path"
  fi

  echo "Linking $src -> $dest"
  ln -sfn "$src" "$dest"
}

copy_file() {
  local src="$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    echo "Skipping missing $src"
    return 0
  fi

  if [ -e "$dest" ] && [ "$src" -ef "$dest" ]; then
    echo "Already synced (symlinked) $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp -pv "$src" "$dest"
}

copy_from_home() {
  echo "Updating repo from Home directory..."
  copy_file "${HOME}/.zshrc" "${REPO_DIR}/.zshrc"
  copy_file "${HOME}/.zshenv" "${REPO_DIR}/.zshenv"
  copy_file "${HOME}/.zprofile" "${REPO_DIR}/.zprofile"
  copy_file "${HOME}/.telemetry_optout" "${REPO_DIR}/.telemetry_optout"
  copy_file "${HOME}/.tmux.conf" "${REPO_DIR}/.tmux.conf"

  copy_file "${HOME}/.config/starship.toml" "${REPO_DIR}/.config/starship.toml"
  copy_file "${HOME}/.config/ghostty/themes/noir-cream" "${REPO_DIR}/.config/ghostty/themes/noir-cream"
  copy_file "${HOME}/Library/Application Support/com.mitchellh.ghostty/config.ghostty" "${REPO_DIR}/.config/ghostty/config.ghostty"
  echo "Repo updated."
}

install_links() {
  echo "Installing symlinks to \$HOME..."
  link_file "${REPO_DIR}/.zshrc" "${HOME}/.zshrc"
  link_file "${REPO_DIR}/.zshenv" "${HOME}/.zshenv"
  link_file "${REPO_DIR}/.zprofile" "${HOME}/.zprofile"
  link_file "${REPO_DIR}/.telemetry_optout" "${HOME}/.telemetry_optout"
  link_file "${REPO_DIR}/.tmux.conf" "${HOME}/.tmux.conf"

  link_file "${REPO_DIR}/.config/starship.toml" "${HOME}/.config/starship.toml"
  link_file "${REPO_DIR}/.config/ghostty/themes/noir-cream" "${HOME}/.config/ghostty/themes/noir-cream"
  link_file "${REPO_DIR}/.config/ghostty/config.ghostty" "${HOME}/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

  echo "Terminal setup installed successfully."
  if [ -d "$BACKUP_DIR" ]; then
    echo "Old files safely backed up in: $BACKUP_DIR"
  fi
}

case "${1:-install}" in
  install)
    install_links
    ;;
  update|pull-from-home)
    copy_from_home
    ;;
  *)
    echo "Usage: $0 [install | update]"
    exit 1
    ;;
esac
