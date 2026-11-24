#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
BACKUP_DIR="${HOME}/.terminal_setup_backup_$(date +%Y%m%d%H%M%S)"

if [[ "$(uname -s)" == "Darwin" ]]; then
  GHOSTTY_CONFIG_DEST="${HOME}/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
else
  GHOSTTY_CONFIG_DEST="${XDG_CONFIG_HOME}/ghostty/config.ghostty"
fi

# Alternating pairs of: repo source path, $HOME destination path (Bash 3.2+ safe)
CONFIG_FILES=(
  "${REPO_DIR}/.zshrc"                            "${HOME}/.zshrc"
  "${REPO_DIR}/.zshenv"                           "${HOME}/.zshenv"
  "${REPO_DIR}/.zprofile"                         "${HOME}/.zprofile"
  "${REPO_DIR}/.telemetry_optout"                 "${HOME}/.telemetry_optout"
  "${REPO_DIR}/.tmux.conf"                        "${HOME}/.tmux.conf"
  "${REPO_DIR}/.config/starship.toml"             "${XDG_CONFIG_HOME}/starship.toml"
  "${REPO_DIR}/.config/ghostty/themes/noir-cream" "${XDG_CONFIG_HOME}/ghostty/themes/noir-cream"
  "${REPO_DIR}/.config/ghostty/config.ghostty"    "${GHOSTTY_CONFIG_DEST}"
)

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "Already linked $dest -> $src"
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP_DIR"
    local base backup_path n=1
    base="$(basename "$dest")"
    backup_path="${BACKUP_DIR}/${base}"
    while [[ -e "$backup_path" || -L "$backup_path" ]]; do
      backup_path="${BACKUP_DIR}/${base}.${n}"
      n=$((n + 1))
    done
    echo "Backing up existing $dest -> $backup_path"
    mv "$dest" "$backup_path"
  fi

  echo "Linking $src -> $dest"
  ln -sfn "$src" "$dest"
}

copy_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "Skipping missing $src"
    return 0
  fi

  if [[ -e "$dest" && "$src" -ef "$dest" ]]; then
    echo "Already synced (symlinked) $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp -pv "$src" "$dest"
}

copy_from_home() {
  echo "Updating repo from Home directory..."
  local i
  for (( i = 0; i < ${#CONFIG_FILES[@]}; i += 2 )); do
    copy_file "${CONFIG_FILES[i + 1]}" "${CONFIG_FILES[i]}"
  done
  echo "Repo updated."
}

install_links() {
  echo "Installing symlinks to \$HOME..."
  local i
  for (( i = 0; i < ${#CONFIG_FILES[@]}; i += 2 )); do
    link_file "${CONFIG_FILES[i]}" "${CONFIG_FILES[i + 1]}"
  done

  echo "Terminal setup installed successfully."
  if [[ -d "$BACKUP_DIR" ]]; then
    echo "Old files safely backed up in: $BACKUP_DIR"
  fi
}

main() {
  case "${1:-install}" in
    install)
      install_links
      ;;
    update|pull-from-home)
      copy_from_home
      ;;
    *)
      echo "Usage: $0 [install | update]" >&2
      exit 1
      ;;
  esac
}

main "$@"
