# Agent Instructions

## Commands
| Task | Command |
|------|---------|
| Check Zsh syntax | `zsh -n path/to/file` |
| Check Bash syntax | `bash -n sync.sh` |
| Benchmark shell startup | `time zsh -i -c exit` |
| Link configs to `$HOME` | `./sync.sh install` |
| Pull `$HOME` edits to repo | `./sync.sh update` |

## External References
| Need | File |
|------|------|
| Setup & overview | `README.md` |
| Symlink & backup map | `sync.sh` |

## Key Conventions
- Edit files in this repo, not `$HOME`; add new config paths to both `install_links` and `copy_from_home` in `sync.sh`.
- `.config/ghostty/config.ghostty` symlinks to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` on macOS.
- Keep `.zshrc` free of Oh My Zsh and heavy synchronous loaders; prefer `/opt/zerobrew` with `/opt/homebrew` fallback.
- Keep `copy-on-select = false` in `.config/ghostty/config.ghostty` to avoid overwriting the macOS clipboard on selection.
- Do not add shell aliases here; aliases belong in `~/.aliases` (`lynicis/alias`).
- Never commit secrets, `*.env`, `*.key`, `*.secret`, or `*api_keys*` files.
