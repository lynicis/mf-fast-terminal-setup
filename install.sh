#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${TERMINAL_SETUP_REPO:-https://github.com/lynicis/terminal-setup.git}"
TARGET_DIR="${TERMINAL_SETUP_DIR:-$HOME/Projects/terminal-setup}"

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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: terminal-setup only supports macOS." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Error: Homebrew is required. Install it from https://brew.sh and re-run." >&2
    exit 1
  fi
fi

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

echo "Installing Homebrew formulae..."
for pkg in "${FORMULAE[@]}"; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    echo "  already installed: $pkg"
  else
    brew install "$pkg"
  fi
done

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

"$REPO_DIR/sync.sh" install

echo
echo "Done. Start a new shell or verify startup with:"
echo "  /usr/bin/time -p zsh -i -c exit"
