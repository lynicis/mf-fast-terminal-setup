#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${TERMINAL_SETUP_REPO:-https://github.com/lynicis/terminal-setup.git}"
TARGET_DIR="${TERMINAL_SETUP_DIR:-$HOME/Projects/terminal-setup}"
NO_GUI="${TERMINAL_SETUP_NO_GUI:-0}"
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
REPO_DIR=""

CORE_PACKAGES=(
  zsh-autosuggestions
  zsh-syntax-highlighting
  direnv
  fzf
  tmux
  uutils-coreutils
)

FORMULAE=(
  "${CORE_PACKAGES[@]}"
  starship
)

CASKS=(
  ghostty
  font-hack-nerd-font
)

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --no-gui)
        NO_GUI=1
        ;;
      -h|--help)
        echo "Usage: $0 [--no-gui]"
        echo "  --no-gui    Skip GUI terminal & font installation (useful for servers/containers)"
        exit 0
        ;;
      *)
        echo "Unknown option: $arg" >&2
        exit 1
        ;;
    esac
  done
}

run_privileged() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "Error: root or sudo is required to run: $*" >&2
    exit 1
  fi
}

ensure_brew() {
  command -v brew >/dev/null 2>&1 && return 0
  local brew_bin
  for brew_bin in "$@"; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done
  return 1
}

install_brew_formulae() {
  local pkg
  for pkg in "$@"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      echo "  already installed: $pkg"
    else
      brew install "$pkg"
    fi
  done
}

install_macos() {
  if ! ensure_brew /opt/homebrew/bin/brew /usr/local/bin/brew; then
    echo "Error: Homebrew is required on macOS. Install it from https://brew.sh and re-run." >&2
    exit 1
  fi

  echo "Installing Homebrew formulae..."
  install_brew_formulae "${FORMULAE[@]}"

  if [[ "$NO_GUI" != "1" ]]; then
    echo "Installing Homebrew casks..."
    local cask
    for cask in "${CASKS[@]}"; do
      if brew list --cask "$cask" >/dev/null 2>&1; then
        echo "  already installed: $cask"
      elif [[ "$cask" == "ghostty" && -d "/Applications/Ghostty.app" ]]; then
        echo "  already installed: Ghostty.app"
      else
        brew install --cask "$cask"
      fi
    done
  fi
}

install_starship_linux() {
  command -v starship >/dev/null 2>&1 && return 0
  echo "Installing starship via official installer..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu (apt-get)..."
    run_privileged apt-get update
    run_privileged apt-get install -y zsh "${CORE_PACKAGES[@]}" curl git
    if apt-cache show starship >/dev/null 2>&1; then
      run_privileged apt-get install -y starship
    else
      install_starship_linux
    fi
  elif command -v dnf >/dev/null 2>&1; then
    echo "Detected Fedora/RHEL (dnf)..."
    run_privileged dnf install -y zsh "${CORE_PACKAGES[@]}" curl git
    if dnf info starship >/dev/null 2>&1; then
      run_privileged dnf install -y starship
    else
      install_starship_linux
    fi
  elif command -v pacman >/dev/null 2>&1; then
    echo "Detected Arch Linux (pacman)..."
    run_privileged pacman -S --needed --noconfirm zsh "${FORMULAE[@]}" curl git
  elif ensure_brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; then
    echo "Detected Linuxbrew..."
    install_brew_formulae zsh "${FORMULAE[@]}"
  else
    echo "Error: Unsupported Linux package manager. Install zsh, zsh-autosuggestions, zsh-syntax-highlighting, direnv, fzf, starship, and tmux manually, then run ./sync.sh install." >&2
    exit 1
  fi

  if [[ "$NO_GUI" != "1" ]]; then
    echo "Note: On Linux, install Ghostty (https://ghostty.org/docs/install/binary) and Hack Nerd Font via your distro/desktop if you use a GUI."
  fi
}

resolve_repo_dir() {
  # Determine whether we are running from an existing checkout or standalone (e.g. curl | bash).
  local script_dir=""
  if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
    script_dir="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
  fi

  if [[ -n "$script_dir" && -f "$script_dir/sync.sh" ]]; then
    REPO_DIR="$script_dir"
    return 0
  fi

  REPO_DIR="$TARGET_DIR"
  if [[ -d "$REPO_DIR/.git" ]]; then
    echo "Using existing repository at $REPO_DIR"
  elif [[ -e "$REPO_DIR" ]]; then
    echo "Error: $REPO_DIR exists and is not a git repository." >&2
    exit 1
  else
    echo "Cloning $REPO_URL -> $REPO_DIR..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
}

print_next_steps() {
  local current_shell="${SHELL:-}"
  echo
  echo "Done. Start a new zsh shell or verify startup with:"
  echo "  /usr/bin/time -p zsh -i -c exit"
  if [[ "${current_shell##*/}" != "zsh" ]] && command -v zsh >/dev/null 2>&1; then
    echo "To set zsh as your default shell, run:"
    echo "  chsh -s \"$(command -v zsh)\""
  fi
  if [[ ! -f "$HOME/.zshrc.local" ]]; then
    echo "Optional: copy $REPO_DIR/.zshrc.local.example to ~/.zshrc.local for machine-specific overrides."
  fi
}

main() {
  parse_args "$@"

  local os
  os="$(uname -s)"
  case "$os" in
    Darwin)
      install_macos
      ;;
    Linux)
      install_linux
      ;;
    *)
      echo "Error: Unsupported OS '$os'. Only macOS and Linux are supported." >&2
      exit 1
      ;;
  esac

  resolve_repo_dir
  "$REPO_DIR/sync.sh" install
  print_next_steps
}

main "$@"
