# zsh-config

Clean, high-performance vanilla Zsh setup for macOS (~60ms startup time).

## Included Files
- `.zshrc`: Main shell configuration (optimized PATH order, cached completions, tool hooks).
- `.zshenv`: Minimal shell environment.
- `.zprofile`: Login shell path additions.
- `.telemetry_optout`: Global telemetry and analytics opt-out flags.
- `.zsh/half-life.zsh`: Standalone Half-Life prompt theme (uses native `vcs_info` and `colors`, zero OMZ dependency).
- `.zsh/completions/`: Custom completions (`_actup`, `_coderabbit`, `_vt`).

## Prerequisites
```bash
brew install zsh-autosuggestions zsh-syntax-highlighting direnv fzf
```

## Note on Aliases
Aliases are modularly managed in a separate repository at [`lynicis/alias`](https://github.com/lynicis/alias) and cloned to `~/.aliases`.
