# ==============================================================================
# 1. Environment & PATH (Load First)
# ==============================================================================
typeset -U path PATH

# Development SDKs & Tools
if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home -v 21 2>/dev/null)"
  [[ -n "$_java_home" ]] && export JAVA_HOME="$_java_home"
  unset _java_home
fi
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_AVD_HOME="$HOME/.android/avd"
export FLUTTER_ROOT="/opt/homebrew/share/flutter"

# XDG & Security Specifications
export XDG_CONFIG_HOME="$HOME/.config"
export SOPS_AGE_KEY_CMD="$XDG_CONFIG_HOME/sops/age/sops-age-key"
export SOPS_AGE_SSH_PRIVATE_KEY_CMD="$XDG_CONFIG_HOME/sops/age/sops-age-key"
export SSH_SK_PROVIDER="/usr/lib/ssh-keychain.dylib"

# Tool Settings & Cloud Config
export MOLE_ENABLE_DISK_VERIFY=1
export ZEROBREW_DIR="$HOME/.zerobrew"
export ZEROBREW_BIN="$HOME/.zerobrew/bin"
export ZEROBREW_ROOT='/opt/zerobrew'
export ZEROBREW_PREFIX='/opt/zerobrew'

# Default Editor (Remote vs Local)
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# PATH Exports (existing dirs only, prioritized left-to-right, deduplicated)
() {
  local -a _candidates _valid
  _candidates=(
    "$HOME/.local/bin/agent-wrappers"
    "$ZEROBREW_PREFIX/opt/uutils-coreutils/libexec/uubin"
    /opt/homebrew/opt/uutils-coreutils/libexec/uubin
    "$ZEROBREW_BIN"
    "$ZEROBREW_ROOT/bin"
    "$ZEROBREW_ROOT/sbin"
    "$HOME/.fzf/bin"
    "$HOME/.local/bin"
    /opt/homebrew/bin
    /opt/homebrew/sbin
    "$HOME/.cargo/bin"
    /opt/homebrew/opt/rustup/bin
    "$HOME/.bun/bin"
    "$HOME/.local/share/uv/tools"
    "$HOME/go/bin"
    "$HOME/.bend/bin"
    ${JAVA_HOME:+"$JAVA_HOME/bin"}
    "$HOME/.pub-cache/bin"
    "$ANDROID_HOME/platform-tools"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/cmdline-tools/latest/bin"
    /opt/homebrew/share/google-cloud-sdk/bin
    "$HOME/Library/TinyTeX/bin/universal-darwin"
  )
  local dir
  for dir in $_candidates; do
    [[ -d "$dir" ]] && _valid+=("$dir")
  done
  path=($_valid $path)
}

# ==============================================================================
# 2. Completions & Fast compinit
# ==============================================================================
typeset -U fpath FPATH
_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_comp_cache"

# Add completion cache and site-functions to fpath before compinit (existing dirs only)
() {
  local -a _fcandidates _fvalid
  _fcandidates=(
    "$_comp_cache"
    "$ZEROBREW_PREFIX/share/zsh/site-functions"
    /opt/homebrew/share/zsh/site-functions
    "$HOME/.bun"
  )
  local dir
  for dir in $_fcandidates; do
    [[ -d "$dir" ]] && _fvalid+=("$dir")
  done
  fpath=($_fvalid $fpath)
}

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

_cache_completion coderabbit "coderabbit completion zsh" "$_comp_cache/_coderabbit"
if [[ -x "$HOME/.bun/bin/omp" ]]; then
  _cache_completion omp '"$HOME/.bun/bin/omp" completions zsh' "$_comp_cache/_omp" "$HOME/.bun/bin/omp"
fi
_cache_completion zb "zb completion zsh" "$_comp_cache/_zb"
if [[ ! -f "$ZEROBREW_PREFIX/share/zsh/site-functions/_mole" ]]; then
  _cache_completion mole "mole completion zsh" "$_comp_cache/_mole"
fi
_cache_completion tdl "tdl completion zsh" "$_comp_cache/_tdl"
_cache_completion openspec "openspec completion generate zsh" "$_comp_cache/_openspec"
unset -f _cache_completion

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
unset _zcompdump _comp_cache

# Enable interactive menu selection with Tab and arrow keys
zstyle ':completion:*' menu select

# Colorize completion lists and highlight selected match (ma=07: reverse video)
if (( $+commands[dircolors] )) && [[ -z "$LS_COLORS" ]]; then
  eval "$(dircolors -b)"
fi
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} "ma=07"

# Allow Shift-Tab to navigate backwards in menu selection
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Custom CLI Autocompletions
if (( $+commands[android] )); then
  _android_complete() {
    local -a completions
    local output
    output=$(android --complete "${words[@]:1:$CURRENT-1}" 2>/dev/null)
    if [[ -n "$output" ]]; then
      completions=(${(z)output})
      compadd -a completions
    fi
  }
  compdef _android_complete android
fi

# Zerobrew alias completion
compdef _zb zerobrew 2>/dev/null

# ==============================================================================
# 3. Interactive Plugins & Tool Integrations
# ==============================================================================
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[fzf] )) && eval "$(fzf --zsh)"

# Autosuggestions (must be loaded before syntax highlighting)
for _autosuggest in \
  "$ZEROBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -f "$_autosuggest" ]]; then
    source "$_autosuggest"
    break
  fi
done
unset _autosuggest

# ==============================================================================
# 4. Prompt Theme (Starship)
# ==============================================================================
if [[ "$TERM" != "dumb" ]] && (( $+commands[starship] )); then
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
# 6. Aliases & Functions
# ==============================================================================
# macOS Defaults
alias dcNo="defaults write -g NSRecentDocumentsLimit 0"
alias dcOn="defaults delete -g NSRecentDocumentsLimit"

# Android & Emulation
alias adbstart="android emulator start 'Medium_Phone'"
alias adbss="adb exec-out screencap -p >"
alias adbwindow="adb shell uiautomator dump /sdcard/window.xml && adb pull /sdcard/window.xml ."

# GPG Security
alias gpgunlock="echo test | gpg --clearsign > /dev/null"
alias gpglock="gpgconf --kill gpg-agent"

# Package Managers (Zerobrew & Homebrew)
alias zerobrew="zb"
alias brew="zb-brew"
alias hbrew="/opt/homebrew/bin/brew"

# Modular ~/.aliases loader
if [[ -d "$HOME/.aliases" ]]; then
  typeset -U _alias_files
  _alias_files=("$HOME"/.aliases/**/*_aliases(ND) "$HOME"/.aliases/**/*.aliases(ND))
  for _file in $_alias_files; do
    [[ -f "$_file" ]] && source "$_file"
  done
  unset _alias_files _file
fi

# ==============================================================================
# 7. macOS Secrets Management (Keychain)
# ==============================================================================
add_secret() {
  local service="$1" secret
  [[ -n "$service" ]] || { echo "Usage: add_secret <service>" >&2; return 1; }
  read -rs "?Enter secret for ${service}: " secret
  echo
  security add-generic-password -a "$USER" -s "$service" -w "$secret" -U
}

get_secret() {
  local service="$1"
  [[ -n "$service" ]] || { echo "Usage: get_secret <service>" >&2; return 1; }
  security find-generic-password -a "$USER" -s "$service" -w
}

delete_secret() {
  local service="$1"
  [[ -n "$service" ]] || { echo "Usage: delete_secret <service>" >&2; return 1; }
  security delete-generic-password -a "$USER" -s "$service"
}

secret-tool() {
  case "$1" in
    store|add)
      add_secret "$2"
      ;;
    lookup|get)
      get_secret "$2"
      ;;
    clear|delete|remove)
      delete_secret "$2"
      ;;
    *)
      echo "Usage: secret-tool {store|lookup|clear} <service>"
      return 1
      ;;
  esac
}

# ==============================================================================
# 8. API Keys: Fast cached loader (~0.5ms)
# ==============================================================================
_API_KEYS_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/api_keys.env"

refresh_keys() {
  echo "Refreshing API keys from macOS Keychain..."
  mkdir -p "${_API_KEYS_CACHE:h}"
  local tmp="${_API_KEYS_CACHE}.tmp.$$"
  (
    umask 077
    cat <<'EOF' >| "$tmp"
# Generated from macOS Keychain via refresh_keys
EOF
    local key val
    for key in MEM0_API_KEY GEMINI_API_KEY DASHSCOPE_API_KEY TYPESAFE_API_KEY \
               MISTRAL_API_KEY EVREN_API_KEY FIRECRAWL_API_KEY CONTEXT7_API_KEY GITHUB_MCP_PAT \
               EXA_API_KEY PARALLEL_API_KEY BRAVE_API_KEY; do
      val=$(security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null)
      [[ -n "$val" ]] && printf 'export %s=%q\n' "$key" "$val" >> "$tmp"
    done
    mv -f "$tmp" "$_API_KEYS_CACHE"
  )
  source "$_API_KEYS_CACHE"
  echo "Keys cached in $_API_KEYS_CACHE (mode 600)."
}

if [[ ! -f "$_API_KEYS_CACHE" || "$HOME/.zshrc" -nt "$_API_KEYS_CACHE" ]]; then
  refresh_keys
else
  source "$_API_KEYS_CACHE"
fi

# ==============================================================================
# 9. Syntax Highlighting (Must be loaded last)
# ==============================================================================
for _highlight in \
  "$ZEROBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -f "$_highlight" ]]; then
    source "$_highlight"
    break
  fi
done
unset _highlight
