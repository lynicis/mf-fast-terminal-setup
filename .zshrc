# ==============================================================================
# 1. Environment & PATH (Load First)
# ==============================================================================
typeset -U path PATH

# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Detect Zerobrew / Homebrew prefixes (macOS Apple Silicon, Intel, Linuxbrew)
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  for _brew_prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew"; do
    if [[ -x "$_brew_prefix/bin/brew" ]]; then
      export HOMEBREW_PREFIX="$_brew_prefix"
      break
    fi
  done
  unset _brew_prefix
fi

if [[ -d /opt/zerobrew || -d "$HOME/.zerobrew" ]]; then
  export ZEROBREW_DIR="${ZEROBREW_DIR:-$HOME/.zerobrew}"
  export ZEROBREW_BIN="${ZEROBREW_BIN:-$HOME/.zerobrew/bin}"
  export ZEROBREW_ROOT="${ZEROBREW_ROOT:-/opt/zerobrew}"
  export ZEROBREW_PREFIX="${ZEROBREW_PREFIX:-/opt/zerobrew}"
fi

# macOS Java & Security Keychain
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /usr/libexec/java_home ]]; then
    _java_home="$(/usr/libexec/java_home 2>/dev/null)"
    [[ -n "$_java_home" ]] && export JAVA_HOME="$_java_home"
    unset _java_home
  fi
  [[ -f /usr/lib/ssh-keychain.dylib ]] && export SSH_SK_PROVIDER="/usr/lib/ssh-keychain.dylib"
fi

# Prepend existing directories to a path-like Zsh array (unset at end of .zshrc)
_prepend_existing_dirs() {
  local target="$1" dir
  shift
  local -a valid=()
  for dir in "$@"; do
    [[ -n "$dir" && -d "$dir" ]] && valid+=("$dir")
  done
  (( ${#valid} )) && set -A "$target" "${valid[@]}" "${(@P)target}"
}

# PATH Exports (existing dirs only, prioritized left-to-right, deduplicated)
_prepend_existing_dirs path \
  ${ZEROBREW_PREFIX:+"$ZEROBREW_PREFIX/opt/uutils-coreutils/libexec/uubin"} \
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/opt/uutils-coreutils/libexec/uubin"} \
  ${ZEROBREW_BIN:+"$ZEROBREW_BIN"} \
  ${ZEROBREW_PREFIX:+"$ZEROBREW_PREFIX/bin"} \
  ${ZEROBREW_PREFIX:+"$ZEROBREW_PREFIX/sbin"} \
  "$HOME/.fzf/bin" \
  "$HOME/.local/bin" \
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/bin"} \
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/sbin"} \
  "$HOME/.cargo/bin" \
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/opt/rustup/bin"} \
  "$HOME/.bun/bin" \
  "$HOME/.local/share/uv/tools" \
  "$HOME/go/bin" \
  ${JAVA_HOME:+"$JAVA_HOME/bin"} \
  "$HOME/.pub-cache/bin"

# Default Editor (Remote vs Local, fallback to vim/vi)
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  (( $+commands[vim] )) && export EDITOR='vim' || export EDITOR='vi'
elif (( $+commands[nvim] )); then
  export EDITOR='nvim'
elif (( $+commands[vim] )); then
  export EDITOR='vim'
else
  export EDITOR='vi'
fi

# ==============================================================================
# 2. Completions & Fast compinit
# ==============================================================================
typeset -U fpath FPATH
_comp_cache="${XDG_CACHE_HOME}/zsh/completions"
mkdir -p "$_comp_cache"

# Add completion cache and site-functions to fpath before compinit (existing dirs only)
_prepend_existing_dirs fpath \
  "$_comp_cache" \
  ${ZEROBREW_PREFIX:+"$ZEROBREW_PREFIX/share/zsh/site-functions"} \
  ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/share/zsh/site-functions"} \
  /usr/local/share/zsh/site-functions \
  /usr/share/zsh/site-functions \
  "$HOME/.bun"

# Cache generated completions for CLIs missing zsh packages (avoids slow subshells on startup)
_cache_completion() {
  local cmd="$1" generator="$2" outfile="$3"
  local bin_path="${4:-${commands[$cmd]:-}}"
  [[ -n "$bin_path" && -x "$bin_path" ]] || return 0
  if [[ ! -s "$outfile" || "$bin_path" -nt "$outfile" ]]; then
    local tmp="${outfile}.tmp.$$"
    if eval "$generator" >| "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
      mv -f "$tmp" "$outfile"
    else
      rm -f "$tmp"
    fi
  fi
}

# Load complist module before compinit for menu selection
zmodload -i zsh/complist

# Fast compinit: only re-analyze definitions once a day (24h)
autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ ! -f "$_zcompdump" || -n ${_zcompdump}(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

# Enable interactive menu selection with Tab and arrow keys
zstyle ':completion:*' menu select

# Colorize completion lists and highlight selected match (ma=07: reverse video)
if [[ -z "${LS_COLORS:-}" ]]; then
  if (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
  elif (( $+commands[gdircolors] )); then
    eval "$(gdircolors -b)"
  fi
fi
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} "ma=07"

# Allow Shift-Tab to navigate backwards in menu selection
bindkey -M menuselect '^[[Z' reverse-menu-complete

# ==============================================================================
# 3. Interactive Plugins & Tool Integrations
# ==============================================================================
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Work around Bun bug where `bun update -g` / `bun update -i -g` fails with MissingPackageJSON
if (( $+commands[bun] )); then
  bun() {
    emulate -L zsh
    [[ "${1:-}" == (update|up) ]] || { command bun "$@"; return }
    local global_dir="${BUN_INSTALL_GLOBAL_DIR:-${BUN_INSTALL:-$HOME/.bun}/install/global}"
    [[ -f "$global_dir/package.json" ]] || { command bun "$@"; return }

    local -a args=()
    local -i is_global=0 i
    local arg rest
    for (( i = 2; i <= $#; i++ )); do
      arg="${@[i]}"
      case "$arg" in
        --)
          args+=("${@[i,-1]}")
          break
          ;;
        --cwd|--cwd=*)
          command bun "$@"
          return
          ;;
        -g|--global)
          is_global=1
          ;;
        --*)
          args+=("$arg")
          ;;
        -c|-F)
          args+=("$arg")
          if (( i < $# )); then
            (( i++ ))
            args+=("${@[i]}")
          fi
          ;;
        -c*|-F*)
          args+=("$arg")
          ;;
        -*g*)
          is_global=1
          rest="${arg//g/}"
          [[ "$rest" != "-" ]] && args+=("$rest")
          ;;
        *)
          args+=("$arg")
          ;;
      esac
    done

    if (( is_global )); then
      command bun "$1" --cwd "$global_dir" "${args[@]}"
    else
      command bun "$@"
    fi
  }
fi

if (( $+commands[fzf] )); then
  # fzf >= 0.48 supports `fzf --zsh`; older distro packages use static scripts
  if _fzf_init="$(fzf --zsh 2>/dev/null)" && [[ -n "$_fzf_init" ]]; then
    eval "$_fzf_init"
  else
    for _fzf_script in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/fzf/completion.zsh; do
      [[ -f "$_fzf_script" ]] && source "$_fzf_script"
    done
    unset _fzf_script
  fi
  unset _fzf_init
fi

# Source a zsh plugin from standard macOS/Linux package prefixes (unset at end of .zshrc)
_source_zsh_plugin() {
  local plugin="$1" candidate
  for candidate in \
    ${ZEROBREW_PREFIX:+"$ZEROBREW_PREFIX/share/$plugin/$plugin.zsh"} \
    ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/share/$plugin/$plugin.zsh"} \
    "/usr/local/share/$plugin/$plugin.zsh" \
    "/usr/share/$plugin/$plugin.zsh" \
    "/usr/share/zsh/plugins/$plugin/$plugin.zsh"; do
    if [[ -f "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 0
}

# Autosuggestions (must be loaded before syntax highlighting)
_source_zsh_plugin zsh-autosuggestions

# ==============================================================================
# 4. Prompt Theme (Starship)
# ==============================================================================
if [[ "${TERM:-}" != "dumb" ]] && (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# ==============================================================================
# 5. Telemetry & History Settings
# ==============================================================================
# Note: ~/.telemetry_optout is sourced in ~/.zshenv for all shells.

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY EXTENDED_HISTORY NO_BEEP

# Sanitize history against leaking sensitive tokens or credentials (case-insensitive)
zshaddhistory() { [[ ${1:u} != *(TOKEN|PASSWORD|SECRET|API_KEY|PRIVATE_KEY|BEARER)* ]] }

# ==============================================================================
# 6. Modular Aliases & Local Overrides
# ==============================================================================
# Modular ~/.aliases loader
if [[ -d "$HOME/.aliases" ]]; then
  typeset -U _alias_files
  _alias_files=("$HOME"/.aliases/**/*_aliases(ND) "$HOME"/.aliases/**/*.aliases(ND))
  for _file in $_alias_files; do
    [[ -f "$_file" ]] && source "$_file"
  done
  unset _alias_files _file
fi

# Machine-local overrides (secrets, SDK paths, personal aliases)
# Copy .zshrc.local.example -> ~/.zshrc.local to customize without touching tracked files.
[[ -f "${ZDOTDIR:-$HOME}/.zshrc.local" ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"

# ==============================================================================
# 7. Syntax Highlighting (Must be loaded last)
# ==============================================================================
_source_zsh_plugin zsh-syntax-highlighting

unset -f _prepend_existing_dirs _cache_completion _source_zsh_plugin 2>/dev/null
unset _comp_cache
