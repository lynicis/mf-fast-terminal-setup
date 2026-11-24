# Login shell PATH additions & integrations

# Docker Desktop CLI
[[ -d "$HOME/.docker/bin" ]] && export PATH="$PATH:$HOME/.docker/bin"

# OrbStack command-line tools and integration (macOS)
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :

# JetBrains Toolbox scripts (macOS & Linux)
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && \
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
[[ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]] && \
  export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"

# User local binaries
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
