#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${TERMINAL_SETUP_REPO:-https://github.com/lynicis/terminal-setup.git}"
TARGET_DIR="${TERMINAL_SETUP_DIR:-$HOME/Projects/terminal-setup}"
NO_GUI="${TERMINAL_SETUP_NO_GUI:-0}"

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

FORMULAE=(
  zsh-autosuggestions
  zsh-syntax-highlighting
  direnv
  fzf
  starship
  tmux
)

CASKS=(
  ghostty
  font-hack-nerd-font
)

OS="$(uname -s)"

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

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      echo "Error: Homebrew is required on macOS. Install it from https://brew.sh and re-run." >&2
      exit 1
    fi
  fi

  echo "Installing Homebrew formulae..."
  for pkg in "${FORMULAE[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      echo "  already installed: $pkg"
    else
      brew install "$pkg"
    fi
  done

  if [[ "$NO_GUI" != "1" ]]; then
    echo "Installing Homebrew casks..."
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
    run_privileged apt-get install -y zsh zsh-autosuggestions zsh-syntax-highlighting direnv fzf tmux curl git
    if apt-cache show starship >/dev/null 2>&1; then
      run_privileged apt-get install -y starship
    else
      install_starship_linux
    fi
  elif command -v dnf >/dev/null 2>&1; then
    echo "Detected Fedora/RHEL (dnf)..."
    run_privileged dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting direnv fzf tmux curl git
    if dnf info starship >/dev/null 2>&1; then
      run_privileged dnf install -y starship
    else
      install_starship_linux
    fi
  elif command -v pacman >/dev/null 2>&1; then
    echo "Detected Arch Linux (pacman)..."
    run_privileged pacman -S --needed --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting direnv fzf starship tmux curl git
  elif command -v brew >/dev/null 2>&1 || [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "Detected Linuxbrew..."
    for pkg in zsh "${FORMULAE[@]}"; do
      brew list --formula "$pkg" >/dev/null 2>&1 || brew install "$pkg"
    done
  else
    echo "Error: Unsupported Linux package manager. Install zsh, zsh-autosuggestions, zsh-syntax-highlighting, direnv, fzf, starship, and tmux manually, then run ./sync.sh install." >&2
    exit 1
  fi

  if [[ "$NO_GUI" != "1" ]]; then
    echo "Note: On Linux, install Ghostty (https://ghostty.org/docs/install/binary) and Hack Nerd Font via your distro/desktop if you use a GUI."
  fi
}

# Determine whether we are running from an existing checkout or standalone (e.g. curl | bash).
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/sync.sh" ]]; then
  REPO_DIR="$SCRIPT_DIR"
else
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
fi

case "$OS" in
  Darwin)
    install_macos
    ;;
  Linux)
    install_linux
    ;;
  *)
    echo "Error: Unsupported OS '$OS'. Only macOS and Linux are supported." >&2
    exit 1
    ;;
esac

"$REPO_DIR/sync.sh" install

echo
echo "Done. Start a new zsh shell or verify startup with:"
echo "  /usr/bin/time -p zsh -i -c exit"
if [[ "${SHELL##*/}" != "zsh" ]] && command -v zsh >/dev/null 2>&1; then
  echo "To set zsh as your default shell, run:"
  echo "  chsh -s \"$(command -v zsh)\""
fi
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  echo "Optional: copy $REPO_DIR/.zshrc.local.example to ~/.zshrc.local for machine-specific overrides."
fi
