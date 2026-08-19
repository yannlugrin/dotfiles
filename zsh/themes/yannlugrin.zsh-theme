#!/usr/bin/env zsh

# setup
autoload colors; colors;
setopt promptsubst
unsetopt beep

# custom git prompt
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg_bold[green]%}●"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg_no_bold[blue]%}✚"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[red]%}…"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✓"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[green]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_no_bold[blue]%}↓"
ZSH_THEME_GIT_PROMPT_DIVERGED="%{$fg_bold[red]%}↕"
ZSH_THEME_GIT_PROMPT_CONFLICT="%{$fg_bold[red]%}✗"
ZSH_THEME_GIT_PROMPT_SYNCED=$'%{\e[2m%}—'
ZSH_THEME_GIT_PROMPT_NO_UPSTREAM="○"

# How often the background fetch may run, in seconds.
ZSH_THEME_GIT_FETCH_INTERVAL=300

# Path shown as [namespace/project] <path relative to the project root> when we
# are inside a project, and as the plain zsh %~ otherwise. A project without a
# namespace shows as [project].
function custom_path {
  local root=$(_project_root)

  if [[ -n "$root" ]]; then
    echo "[$(_project_label "$root" /)] ${PWD/#$root/~}"
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
  local worktree="" remote=""

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

  # Left of the branch: the state of the working tree.
  [[ -n "$staged" ]]    && worktree+="$ZSH_THEME_GIT_PROMPT_STAGED%{$reset_color%}"
  [[ -n "$changed" ]]   && worktree+="$ZSH_THEME_GIT_PROMPT_CHANGED%{$reset_color%}"
  [[ -n "$untracked" ]] && worktree+="$ZSH_THEME_GIT_PROMPT_UNTRACKED%{$reset_color%}"
  [[ -n "$conflict" ]]  && worktree+="$ZSH_THEME_GIT_PROMPT_CONFLICT%{$reset_color%}"

  # Clean describes the working tree alone, so that a tidy checkout that is
  # merely ahead still reads as clean.
  [[ -z "$worktree" ]] && worktree="$ZSH_THEME_GIT_PROMPT_CLEAN%{$reset_color%}"

  # Right of the branch: where we stand against the upstream. branch.ab is
  # "+<ahead> -<behind>", and absent whenever the branch tracks nothing --
  # either the repository has no remote, or this branch has no upstream set.
  # Telling those two apart would cost a second git call, which is not worth it.
  if [[ -z "$ab" ]]; then
    remote="$ZSH_THEME_GIT_PROMPT_NO_UPSTREAM%{$reset_color%}"
  else
    local ahead=${${ab%% *}#+} behind=${${ab##* }#-}

    if (( ahead && behind )); then
      remote="$ZSH_THEME_GIT_PROMPT_DIVERGED%{$reset_color%}"
    elif (( ahead )); then
      remote="$ZSH_THEME_GIT_PROMPT_AHEAD%{$reset_color%}"
    elif (( behind )); then
      remote="$ZSH_THEME_GIT_PROMPT_BEHIND%{$reset_color%}"
    else
      remote="$ZSH_THEME_GIT_PROMPT_SYNCED%{$reset_color%}"
    fi
  fi

  # (detached) is what porcelain=v2 reports for a detached HEAD.
  echo "${worktree}(${branch})${remote}"
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
# Blue rather than green for success. Green against red is the one pair a deutan
# eye cannot separate -- dE 14.6 under simulation, where blue against red is
# 68.5. Blue also marks changed and behind, but those sit right of the branch
# while this sits left of the command, so position keeps them apart.
PROMPT='%{$fg[cyan]%}$(custom_path) %(?.%{$fg[blue]%}.%{$fg[red]%})%B$%b '
RPROMPT='$(custom_git_prompt) [%D{%H:%M}]'
