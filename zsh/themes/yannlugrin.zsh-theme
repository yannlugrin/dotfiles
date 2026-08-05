#!/usr/bin/env zsh

# setup
autoload colors; colors;
setopt promptsubst
unsetopt beep

# custom git prompt
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg_bold[green]%}●"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg_no_bold[blue]%}✚"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[red]%}…"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✔"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[green]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_no_bold[blue]%}↓"
ZSH_THEME_GIT_PROMPT_DIVERGED="%{$fg_bold[red]%}↕"
ZSH_THEME_GIT_PROMPT_CONFLICT="%{$fg_bold[red]%}⚡"

# How often the background fetch may run, in seconds.
ZSH_THEME_GIT_FETCH_INTERVAL=300

# Path shown as [client/project] <path relative to the project root> when we are
# inside a project, and as the plain zsh %~ otherwise.
function custom_path {
  local root=$(_project_root)

  if [[ -n "$root" ]]; then
    echo "[${${root:h}:t}/${root:t}] ${PWD/#$root/~}"
  else
    echo '%~'
  fi
}

# Git status for the prompt.
#
# One `git status --porcelain=v2 --branch` call answers everything: whether we
# are in a repository, the branch name, the working tree state and the position
# relative to the upstream. The previous version ran three git processes per
# prompt and leaked its state through globals.
function custom_git_prompt() {
  local status_output branch line ab
  local staged changed untracked conflict
  local prompt=""

  status_output=$(git status --porcelain=v2 --branch 2>/dev/null) || return 1

  for line in ${(f)status_output}; do
    case $line in
      ('# branch.head '*) branch=${line#\# branch.head } ;;
      ('# branch.ab '*)   ab=${line#\# branch.ab } ;;
      # XY field of a changed entry: X is the index, Y the working tree.
      ([12]' '*)
        [[ ${line[3]}  == [^.] ]] && staged=1
        [[ ${line[4]}  == [^.] ]] && changed=1
        ;;
      ('u '*) conflict=1 ;;
      ('? '*) untracked=1 ;;
    esac
  done

  [[ -n "$staged" ]]    && prompt+="$ZSH_THEME_GIT_PROMPT_STAGED%{$reset_color%}"
  [[ -n "$changed" ]]   && prompt+="$ZSH_THEME_GIT_PROMPT_CHANGED%{$reset_color%}"
  [[ -n "$untracked" ]] && prompt+="$ZSH_THEME_GIT_PROMPT_UNTRACKED%{$reset_color%}"

  # branch.ab is "+<ahead> -<behind>", and absent when there is no upstream.
  if [[ -n "$ab" ]]; then
    local ahead=${${ab%% *}#+} behind=${${ab##* }#-}

    if (( ahead && behind )); then
      prompt+="$ZSH_THEME_GIT_PROMPT_DIVERGED%{$reset_color%}"
    elif (( ahead )); then
      prompt+="$ZSH_THEME_GIT_PROMPT_AHEAD%{$reset_color%}"
    elif (( behind )); then
      prompt+="$ZSH_THEME_GIT_PROMPT_BEHIND%{$reset_color%}"
    fi
  fi

  [[ -n "$conflict" ]] && prompt+="$ZSH_THEME_GIT_PROMPT_CONFLICT%{$reset_color%}"

  [[ -z "$prompt" ]] && prompt="$ZSH_THEME_GIT_PROMPT_CLEAN%{$reset_color%}"

  # (detached) is what porcelain=v2 reports for a detached HEAD.
  echo "${prompt}(${branch})"
}

# Update the current repository so the ahead/behind indicator stays honest.
#
# The fetch is fully detached: the prompt must never wait on the network, and
# the fetch must never be able to ask for a password. Both were true of the
# previous version, which ran `git remote update` inline from TRAPALRM.
_ZSH_THEME_GIT_FETCH_SINCE=0

function fetch_git_repository {
  (( SECONDS - _ZSH_THEME_GIT_FETCH_SINCE < ZSH_THEME_GIT_FETCH_INTERVAL )) && return 0

  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0

  # Nothing to fetch without a remote.
  [[ -n "$(git remote 2>/dev/null)" ]] || return 0

  _ZSH_THEME_GIT_FETCH_SINCE=$SECONDS

  local lock_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-git-fetch"
  local lock="$lock_dir/${root//\//%}.lock"

  [[ -d "$lock_dir" ]] || mkdir -p "$lock_dir" || return 0

  # Reclaim a lock left behind by a fetch that was killed.
  [[ -n "$lock"(#qNmm+10) ]] && rmdir "$lock" 2>/dev/null

  # mkdir is atomic, so this doubles as the "already fetching" check.
  mkdir "$lock" 2>/dev/null || return 0

  (
    GIT_TERMINAL_PROMPT=0 \
    GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5' \
      git -C "$root" fetch --quiet --prune --no-tags >/dev/null 2>&1
    rmdir "$lock" 2>/dev/null
  ) &!
}

# auto refresh prompt
TMOUT=10
TRAPALRM() {
  fetch_git_repository
  zle reset-prompt
}

# prompt
PROMPT='%{$fg[cyan]%}$(custom_path) %(?.%{$fg[green]%}.%{$fg[red]%})%B$%b '
RPROMPT='$(custom_git_prompt) [%D{%H:%M}]'
