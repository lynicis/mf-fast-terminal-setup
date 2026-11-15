# terminal-setup

Clean, high-performance terminal & shell configuration for macOS (~60ms startup time).

Designed for speed, modularity, and AI agent / developer workflows.

## Components & Structure

```
terminal-setup/
├── .zshrc                  # Refactored vanilla Zsh (cached completions, fast compinit, zero OMZ overhead)
├── .zshenv                 # Minimal environment loader (telemetry opt-out)
├── .zprofile               # Login shell path additions (OrbStack, Docker, etc.)
├── .telemetry_optout       # Global telemetry & analytics opt-out flags
├── .tmux.conf              # Ergonomic tmux setup for multi-agent workflows (Ctrl-a prefix, 100k scrollback, RGB truecolor)
├── .config/
│   ├── starship.toml       # Fast Starship prompt (Half-Life theme recreation)
│   └── ghostty/themes/
│       └── noir-cream      # Warm dark Ghostty terminal theme
├── .zsh/                   # Fallback prompt & completions
└── sync.sh                 # Fast symlink/sync script with automatic backup
```

## Prerequisites

```bash
brew install zsh-autosuggestions zsh-syntax-highlighting direnv fzf starship tmux
```

## Installation & Sync

To link this configuration into your home directory:

```bash
# Clone the repository
git clone git@github.com:lynicis/terminal-setup.git ~/Projects/terminal-setup

# Install symlinks (backs up existing files automatically)
cd ~/Projects/terminal-setup
./sync.sh install
```

To update the repository from your local `$HOME` files:

```bash
./sync.sh update
```

## Note on Aliases

Aliases are modularly managed in a separate repository at [`lynicis/alias`](https://github.com/lynicis/alias) and cloned to `~/.aliases`.
