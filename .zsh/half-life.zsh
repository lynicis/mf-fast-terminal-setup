# Standalone half-life theme for Zsh (no Oh-My-Zsh required)

autoload -U colors && colors
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# Extended color palette
if [[ $TERM = (*256color|*rxvt*|xterm-ghostty*) ]]; then
  turquoise="%{${(%):-"%F{81}"}%}"
  orange="%{${(%):-"%F{166}"}%}"
  purple="%{${(%):-"%F{135}"}%}"
  hotpink="%{${(%):-"%F{161}"}%}"
  limegreen="%{${(%):-"%F{118}"}%}"
else
  turquoise="%{${(%):-"%F{cyan}"}%}"
  orange="%{${(%):-"%F{yellow}"}%}"
  purple="%{${(%):-"%F{magenta}"}%}"
  hotpink="%{${(%):-"%F{red}"}%}"
  limegreen="%{${(%):-"%F{green}"}%}"
fi

# Enable VCS systems
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*:prompt:*' check-for-changes true

PR_RST="%{${reset_color}%}"
FMT_BRANCH=" on ${turquoise}%b%u%c${PR_RST}"
FMT_ACTION=" performing a ${limegreen}%a${PR_RST}"
FMT_UNSTAGED="${orange} ●"
FMT_STAGED="${limegreen} ●"

zstyle ':vcs_info:*:prompt:*' unstagedstr   "${FMT_UNSTAGED}"
zstyle ':vcs_info:*:prompt:*' stagedstr     "${FMT_STAGED}"
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

function _halflife_chpwd {
  PR_GIT_UPDATE=1
}

function _halflife_preexec {
  case "$2" in
    *git*|*svn*) PR_GIT_UPDATE=1 ;;
  esac
}

function _halflife_precmd {
  (( PR_GIT_UPDATE )) || return

  if [[ -n "$(git ls-files --other --exclude-standard 2>/dev/null)" ]]; then
    PR_GIT_UPDATE=1
    FMT_BRANCH="${PR_RST} on ${turquoise}%b%u%c${hotpink} ●${PR_RST}"
  else
    FMT_BRANCH="${PR_RST} on ${turquoise}%b%u%c${PR_RST}"
  fi
  zstyle ':vcs_info:*:prompt:*' formats "${FMT_BRANCH}"

  vcs_info 'prompt'
  PR_GIT_UPDATE=
}

PR_GIT_UPDATE=1

add-zsh-hook chpwd _halflife_chpwd
add-zsh-hook precmd _halflife_precmd
add-zsh-hook preexec _halflife_preexec

function virtualenv_prompt_info() {
  [[ -n "$VIRTUAL_ENV" ]] && echo " with%F{red} (${VIRTUAL_ENV:t})%{$reset_color%}"
}

setopt prompt_subst
PROMPT="${purple}%n%{$reset_color%} in ${limegreen}%~%{$reset_color%}\$(virtualenv_prompt_info)\$vcs_info_msg_0_${orange} λ%{$reset_color%} "
