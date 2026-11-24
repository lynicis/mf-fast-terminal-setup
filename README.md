# terminal-setup

Portable, fast Vanilla Zsh, [Starship](https://starship.rs/), [tmux](https://github.com/tmux/tmux), and [Ghostty](https://ghostty.org/) dotfiles for **macOS (Apple Silicon & Intel)** and **Linux (Debian/Ubuntu, Fedora, Arch)** — replace Oh My Zsh and Powerlevel10k with cached completions and ~20ms warm shell startup. Inspired by [mfwebsite.com](https://motherfuckingwebsite.com)

**Licence:** [MIT](LICENSE).

## Why this instead of Oh My Zsh + Powerlevel10k

- **No plugin framework:** Sources `zsh-autosuggestions` and `zsh-syntax-highlighting` directly from your package manager (`/opt/zerobrew`, `/opt/homebrew`, `/usr/local`, `/home/linuxbrew`, or `/usr/share/...` on Linux) and regenerates `compinit` (`-C`) once every 24 hours instead of running a plugin manager on every shell launch (`~0.05s` warm / `~0.33s` cold via `/usr/bin/time -p zsh -i -c exit`).
- **Cached CLI completions:** Provides `_cache_completion` in [`.zshrc`](.zshrc) to generate and cache completions only when the target binary is newer than its cache file.
- **Cross-platform tmux defaults:** Sets `Ctrl-a` prefix, `escape-time 10`, `100000`-line scrollback, pane border titles, and automatic clipboard integration (`pbcopy`/`pbpaste` on macOS, `wl-copy`/`wl-paste` on Wayland, `xclip`/`xsel` on X11, `clip.exe` on WSL) in [`.tmux.conf`](.tmux.conf).
- **Safe clipboard defaults:** Disables `copy-on-select` in Ghostty and `MouseDragEnd1Pane` in tmux so drag-selecting text does not overwrite the system clipboard.
- **Clean local overrides:** Personal SDK paths, Keychain secrets, Zerobrew aliases, and machine-specific settings live in `~/.zshrc.local` (see [`.zshrc.local.example`](.zshrc.local.example)) and `~/.tmux.conf.local` so anyone can adopt the repo cleanly.

## Install & Verify

### Option A: One-command install

[`install.sh`](install.sh) detects your OS and package manager (`brew` on macOS/Linuxbrew, `apt-get`, `dnf`, or `pacman` on Linux), installs the required tools (`zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `direnv`, `fzf`, `starship`, `tmux`, plus `ghostty` and `font-hack-nerd-font` on macOS), clones the repo to `~/Projects/terminal-setup` (override with `TERMINAL_SETUP_DIR` / `TERMINAL_SETUP_REPO`), and runs [`sync.sh`](sync.sh) to symlink configs into `$HOME` (backing up existing files to `~/.terminal_setup_backup_<timestamp>`).

```bash
curl -fsSL https://raw.githubusercontent.com/lynicis/terminal-setup/main/install.sh | bash
```

For headless servers or containers (skipping Ghostty/fonts):

```bash
curl -fsSL https://raw.githubusercontent.com/lynicis/terminal-setup/main/install.sh | bash -s -- --no-gui
```

### Option B: Clone and install locally

```bash
git clone https://github.com/lynicis/terminal-setup.git ~/Projects/terminal-setup
cd ~/Projects/terminal-setup
./install.sh
```

To symlink configs without installing packages, run `./sync.sh install` directly. Expected output ends with `Terminal setup installed successfully.` (plus the backup directory path if existing files were moved).

### Verify startup

```bash
/usr/bin/time -p zsh -i -c exit
```

The first cold run rebuilds `~/.zcompdump` (`~0.33s`); subsequent interactive shells start in `~0.05s`.

## What's Included

```text
terminal-setup/
├── .zshrc                  # Portable Vanilla Zsh: PATH filtering, 24h compinit cache, plugins
├── .zshrc.local.example    # Optional template for ~/.zshrc.local (SDKs, Keychain, personal aliases)
├── .zshenv                 # Sources ~/.telemetry_optout for all shells
├── .zprofile               # Login shell paths (Docker, OrbStack, JetBrains Toolbox, ~/.local/bin)
├── .telemetry_optout       # Global telemetry & analytics opt-out env vars
├── .tmux.conf              # Ctrl-a prefix, 100k scrollback, RGB truecolor, cross-platform clipboard
├── .config/
│   ├── starship.toml       # Starship prompt (Half-Life color palette)
│   └── ghostty/
│       ├── config.ghostty  # Ghostty config (copy-on-select = false, Hack Nerd Font Mono)
│       └── themes/
│           └── noir-cream  # Warm dark Ghostty theme (cyucelen/noir-cream)
├── install.sh              # Cross-platform installer (macOS & Linux + --no-gui)
└── sync.sh                 # Symlink installer (install) and $HOME syncer (update)
```

## Customization

- **Local Zsh overrides:** Copy [`.zshrc.local.example`](.zshrc.local.example) to `~/.zshrc.local` to add machine-specific SDK paths (`ANDROID_HOME`, `FLUTTER_ROOT`), Zerobrew aliases (`brew="zb-brew"`), macOS Keychain `refresh_keys`, or extra `_cache_completion` entries without modifying tracked files.
- **Local tmux overrides:** Create `~/.tmux.conf.local` for machine-specific tmux bindings or status bar tweaks.
- **Modular aliases:** If you keep modular alias files in `~/.aliases` (e.g., `*_aliases` or `*.aliases`), `.zshrc` sources them automatically.
- **Clipboard behavior:** [`config.ghostty`](.config/ghostty/config.ghostty) sets `copy-on-select = false` so drag-selecting text never overwrites the system clipboard. Copy explicitly with `Cmd+C` / `Ctrl+Shift+C` in Ghostty, or `Prefix + y` / `Prefix + P` in tmux.

## Updating from `$HOME`

If you edit a symlinked or copied file in `$HOME` directly and want to pull it back into the repository:

```bash
./sync.sh update
```

## Credits

- Ghostty `noir-cream` theme by [`cyucelen/noir-cream`](https://github.com/cyucelen/noir-cream).
