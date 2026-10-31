# ==========================================
# 1. Environment & PATH (Load first)
# ==========================================
typeset -U path PATH

export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_AVD_HOME="$HOME/.android/avd"

export FLUTTER_ROOT="/opt/homebrew/share/flutter"
export CHROME_EXECUTABLE="/Applications/Chromium.app"

export XDG_CONFIG_HOME="$HOME/.config"
export SOPS_AGE_KEY_CMD="$XDG_CONFIG_HOME/sops/age/sops-age-key"
export SOPS_AGE_SSH_PRIVATE_KEY_CMD="$XDG_CONFIG_HOME/sops/age/sops-age-key"

export MOLE_ENABLE_DISK_VERIFY=1
export JCODE_REPO_DIR="$HOME/Projects/jcode"
export GHIDRA_INSTALL_DIR="/opt/homebrew/Cellar/ghidra/12.1.4/libexec"
export HOPPER_LAUNCHER_PATH="$HOME/Downloads/Hopper Disassembler.app/Contents/MacOS/Hopper Disassembler"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# PATH Exports
path=(
  /opt/homebrew/opt/uutils-coreutils/libexec/uubin
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

# ==========================================
# 2. Completions & Fast compinit
# ==========================================
fpath=(
  "$HOME/.zsh/completions"
  /opt/homebrew/share/zsh/site-functions
  $fpath
)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m+1) ]]; then
  compinit
else
  compinit -C
fi

# ==========================================
# 3. Prompt Theme
# ==========================================
[ -f "$HOME/.zsh/half-life.zsh" ] && source "$HOME/.zsh/half-life.zsh"

# ==========================================
# 4. Tool Integrations & Interactive Plugins
# ==========================================
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[fzf] )) && eval "$(fzf --zsh)"

[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ==========================================
# 5. Telemetry & History Settings
# ==========================================
[ -f ~/.telemetry_optout ] && source ~/.telemetry_optout

zshaddhistory() { [[ $1 != *(TOKEN|PASSWORD|SECRET|API_KEY)* ]] }

# ==========================================
# 6. Custom Aliases
# ==========================================
if [ -d "$HOME/.aliases" ]; then
  typeset -U _alias_files
  _alias_files=("$HOME"/.aliases/**/*_aliases(ND) "$HOME"/.aliases/**/*.aliases(ND))
  for _file in $_alias_files; do
    [ -f "$_file" ] && source "$_file"
  done
  unset _alias_files _file
fi

alias adbstart="android emulator start 'Medium_Phone'"
alias adbss="adb exec-out screencap -p >"
alias adbwindow="adb shell uiautomator dump /sdcard/window.xml && adb pull /sdcard/window.xml ."
alias gpgunlock="echo test | gpg --clearsign > /dev/null"
alias gpglock="gpgconf --kill gpg-agent"

# ==========================================
# 7. API Keys: Fast cached loader (~0.5ms)
# ==========================================
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
               MISTRAL_API_KEY EVREN_API_KEY FIRECRAWL_API_KEY CONTEXT7_API_KEY GH_MCP_PAT; do
      val=$(security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null)
      [[ -n "$val" ]] && echo "export $key=\"$val\"" >> "$_API_KEYS_CACHE"
    done
  )
  source "$_API_KEYS_CACHE"
  echo "Keys cached in $_API_KEYS_CACHE (mode 600)."
}

if [[ -f "$_API_KEYS_CACHE" ]]; then
  source "$_API_KEYS_CACHE"
else
  refresh_keys
fi

# ==========================================
# 8. Extra CLI Autocompletions
# ==========================================
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

# bun completions
[ -s "/Users/lynicis/.bun/_bun" ] && source "/Users/lynicis/.bun/_bun"

# tdl completions
(( $+commands[tdl] )) && source <(tdl completion zsh)
