#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.terminal_setup_backup_$(date +%Y%m%d%H%M%S)"

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up existing $dest -> $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi

  echo "Linking $src -> $dest"
  ln -sfn "$src" "$dest"
}

copy_from_home() {
  echo "Updating repo from Home directory..."
  cp -pv "${HOME}/.zshrc" "${REPO_DIR}/.zshrc"
  cp -pv "${HOME}/.zshenv" "${REPO_DIR}/.zshenv"
  cp -pv "${HOME}/.zprofile" "${REPO_DIR}/.zprofile"
  cp -pv "${HOME}/.telemetry_optout" "${REPO_DIR}/.telemetry_optout"
  cp -pv "${HOME}/.tmux.conf" "${REPO_DIR}/.tmux.conf"

  mkdir -p "${REPO_DIR}/.config/ghostty/themes"
  cp -pv "${HOME}/.config/starship.toml" "${REPO_DIR}/.config/starship.toml"
  cp -pv "${HOME}/.config/ghostty/themes/noir-cream" "${REPO_DIR}/.config/ghostty/themes/noir-cream"
  cp -pv "${HOME}/Library/Application Support/com.mitchellh.ghostty/config.ghostty" "${REPO_DIR}/.config/ghostty/config.ghostty"
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
