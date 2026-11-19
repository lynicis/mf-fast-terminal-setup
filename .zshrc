# ==============================================================================
# 1. Environment & PATH (Load First)
# ==============================================================================
typeset -U path PATH

# Development SDKs & Tools
if [[ -x /usr/libexec/java_home ]]; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null)"
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

# PATH Exports (prioritized left-to-right, deduplicated automatically)
path=(
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
  "$JAVA_HOME/bin"
  "$HOME/.pub-cache/bin"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/cmdline-tools/latest/bin"
  /opt/homebrew/share/google-cloud-sdk/bin
  "$HOME/Library/TinyTeX/bin/universal-darwin"
  $path
)

# ==============================================================================
# 2. Completions & Fast compinit
# ==============================================================================
typeset -U fpath FPATH
_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_comp_cache"

# Add completion cache and custom site-functions to fpath before compinit
fpath=(
  "$_comp_cache"
  "$HOME/.bun"
  /opt/homebrew/share/zsh/site-functions
  $fpath
)

# Cache generated completions for CLIs missing zsh packages (avoids slow subshells on startup)
_cache_completion() {
  local cmd="$1" generator="$2" outfile="$3"
  if (( $+commands[$cmd] )); then
    if [[ ! -s "$outfile" || "$commands[$cmd]" -nt "$outfile" ]]; then
      eval "$generator" >| "$outfile" 2>/dev/null
    fi
  fi
}

_cache_completion coderabbit "coderabbit completion zsh" "$_comp_cache/_coderabbit"
_cache_completion omp "omp completions zsh" "$_comp_cache/_omp"
_cache_completion zb "zb completion zsh" "$_comp_cache/_zb"
_cache_completion mole "mole completion zsh" "$_comp_cache/_mole"
_cache_completion tdl "tdl completion zsh" "$_comp_cache/_tdl"
_cache_completion openspec "openspec completion generate zsh" "$_comp_cache/_openspec"
unset -f _cache_completion

# Load complist module before compinit for menu selection
zmodload -i zsh/complist

# Fast compinit: only re-analyze definitions once a day (24h)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m+1) ]]; then
  compinit
else
  compinit -C
fi

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
# >>> android autocomplete >>>
#compdef android
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
# <<< android autocomplete <<<

# Zerobrew alias completion
compdef _zb zerobrew 2>/dev/null

# Bun completions fallback
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ==============================================================================
# 3. Interactive Plugins & Tool Integrations
# ==============================================================================
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[fzf] )) && eval "$(fzf --zsh)"

# Autosuggestions (must be loaded before syntax highlighting)
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ==============================================================================
# 4. Prompt Theme (Starship)
# ==============================================================================
if [[ "$TERM" != "dumb" ]] && (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# ==============================================================================
# 5. Telemetry & History Settings
# ==============================================================================
[[ -f "$HOME/.telemetry_optout" ]] && source "$HOME/.telemetry_optout"

# Sanitize history against leaking sensitive tokens or credentials
zshaddhistory() { [[ $1 != *(TOKEN|PASSWORD|SECRET|API_KEY)* ]] }

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
  local service="$1"
  read -s "?Enter your password: " secret
  echo
  security add-generic-password -a "$USER" -s "$service" -w "$secret" -U
}

get_secret() {
  local service="$1"
  security find-generic-password -a "$USER" -s "$service" -w
}

delete_secret() {
  local service="$1"
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
      echo "Usage: secret-tool {store|lookup|clear} account service"
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
  (
    umask 077
    cat <<'EOF' > "$_API_KEYS_CACHE"
# Generated from macOS Keychain via refresh_keys
EOF
    for key in MEM0_API_KEY GEMINI_API_KEY DASHSCOPE_API_KEY TYPESAFE_API_KEY \
               MISTRAL_API_KEY EVREN_API_KEY FIRECRAWL_API_KEY CONTEXT7_API_KEY GITHUB_MCP_PAT; do
      val=$(security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null)
      [[ -n "$val" ]] && echo "export $key=\"$val\"" >> "$_API_KEYS_CACHE"
    done
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
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
