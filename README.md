# terminal-setup

Vanilla Zsh, [Starship](https://starship.rs/), [tmux](https://github.com/tmux/tmux), and [Ghostty](https://ghostty.org/) dotfiles for macOS — replace Oh My Zsh and Powerlevel10k with cached completions and ~50ms warm shell startup.

**Status:** Actively maintained personal daily driver for macOS, updated as tools evolve. **Licence:** [MIT](LICENSE).

## Why this instead of Oh My Zsh + Powerlevel10k

- **No plugin framework:** Sources `zsh-autosuggestions` and `zsh-syntax-highlighting` directly from [Zerobrew](https://github.com/lucasgelfond/zerobrew) (`/opt/zerobrew`) with `/opt/homebrew` fallback, and regenerates `compinit` (`-C`) once every 24 hours instead of running a plugin manager on every shell launch (`0.05s` warm / `0.33s` cold via `/usr/bin/time -p zsh -i -c exit`).
- **Cached CLI completions:** Generates and caches completions (`_cache_completion` in [`.zshrc`](.zshrc)) only when the target binary is newer than its cache file.
- **Multi-agent tmux defaults:** Sets `Ctrl-a` prefix, `escape-time 10`, `100000`-line scrollback, pane border titles, and `pbcopy`/`pbpaste` bindings in [`.tmux.conf`](.tmux.conf).
- **Safe clipboard defaults:** Disables `copy-on-select` in Ghostty and `MouseDragEnd1Pane` in tmux so drag-selecting text does not overwrite the macOS clipboard.

**What this is not:** This is a macOS-only personal configuration, not a cross-platform dotfiles manager (use [chezmoi](https://www.chezmoi.io/) or [GNU Stow](https://www.gnu.org/software/stow/) if you target Linux and macOS) and not a general-purpose Zsh framework (use [Oh My Zsh](https://ohmyz.sh/) or [Zinit](https://github.com/zdharma-continuum/zinit) if you want curated plugin bundles).

## Install & Verify

### Option A: One-command install

[`install.sh`](install.sh) checks for macOS and Homebrew, installs the required formulae and casks (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `direnv`, `fzf`, `starship`, `tmux`, `ghostty`, `font-hack-nerd-font`), clones the repo to `~/Projects/terminal-setup`, and runs [`sync.sh`](sync.sh) to symlink configs into `$HOME` (backing up existing files to `~/.terminal_setup_backup_<timestamp>`).

```bash
curl -fsSL https://raw.githubusercontent.com/lynicis/terminal-setup/main/install.sh | bash
```

### Option B: Clone and install locally

```bash
git clone git@github.com:lynicis/terminal-setup.git ~/Projects/terminal-setup
cd ~/Projects/terminal-setup
./install.sh
```

To symlink configs without running Homebrew, run `./sync.sh install` directly. Expected output ends with `Terminal setup installed successfully.` (plus the backup directory path if existing files were moved).

### Verify startup

```bash
/usr/bin/time -p zsh -i -c exit
```

The first cold run rebuilds `~/.zcompdump` (`~0.33s`); subsequent interactive shells start in `~0.05s`.

## What's Included

```text
terminal-setup/
├── .zshrc                  # Vanilla Zsh: PATH filtering, 24h compinit cache, Keychain secrets, plugins
├── .zshenv                 # Sources ~/.telemetry_optout for all shells
├── .zprofile               # Login shell paths (Docker, OrbStack, JetBrains Toolbox, ~/.local/bin)
├── .telemetry_optout       # Global telemetry & analytics opt-out env vars
├── .tmux.conf              # Ctrl-a prefix, 100k scrollback, RGB truecolor, vi copy mode
├── .config/
│   ├── starship.toml       # Starship prompt (Half-Life color palette)
│   └── ghostty/
│       ├── config.ghostty  # Ghostty config (copy-on-select = false, Hack Nerd Font Mono)
│       └── themes/
│           └── noir-cream  # Warm dark Ghostty theme (cyucelen/noir-cream)
├── install.sh              # One-command macOS installer (Homebrew packages + sync.sh)
└── sync.sh                 # Symlink installer (install) and $HOME syncer (update)
```

## Notes & Personal Defaults

- **Inspect before adopting [`.zshrc`](.zshrc):** It aliases `brew` to `zb-brew` (Zerobrew) with `hbrew` for `/opt/homebrew/bin/brew`, and caches a personal list of API keys from macOS Keychain via `refresh_keys`. Edit or remove sections 6–8 if you do not use Zerobrew or those Keychain entries.
- **Clipboard behavior:** [`config.ghostty`](.config/ghostty/config.ghostty) sets `copy-on-select = false` because `copy-on-select = true` maps to `clipboard` on macOS and overwrites the system clipboard on any mouse selection. Copy explicitly with `Cmd+C` in Ghostty, or `Prefix + y` / `Prefix + P` in tmux.
- **Aliases:** Modular shell aliases live separately in [`lynicis/alias`](https://github.com/lynicis/alias) and are sourced automatically if cloned to `~/.aliases`.

## Updating from `$HOME`

If you edit a file in `$HOME` directly and want to pull it back into the repository:

```bash
./sync.sh update
```

## Credits

- Ghostty `noir-cream` theme by [`cyucelen/noir-cream`](https://github.com/cyucelen/noir-cream).
