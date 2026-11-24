# Login shell PATH additions & integrations

# Docker Desktop CLI
[[ -d "$HOME/.docker/bin" ]] && export PATH="$PATH:$HOME/.docker/bin"

# OrbStack command-line tools and integration
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :

# JetBrains Toolbox scripts
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && \
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# User local binaries (jcode, zerobrew, etc.)
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
