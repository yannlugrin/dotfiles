#!/usr/bin/env zsh

# setup
autoload colors; colors;
export LSCOLORS="Gxfxcxdxbxegedabagacad"
setopt promptsubst
unsetopt beep

# custom path with project and relative root
function custom_path {
  local client_project_root=`pwd | sed -n 's:\(^.*/Development/[^/]*/[^/]*\).*$:\1:p'`

  if [ -n "$client_project_root" ]; then
    local client_project_name=`echo $client_project_root | awk -F/ '{print $(NF-1) "/" $(NF)}'`
    local client_project_path=`pwd | sed "s:^$client_project_root:~:"`

    echo "[$client_project_name] $client_project_path"
  else
    echo '%~'
  fi
}

# return true if current directory is in a git working space
function is_git_repository()
{
  git branch > /dev/null 2>&1
}

# Fetch current repository to update
function fetch_git_repository {
  # Only fetch if we're inside a git repository.
  is_git_repository || return 1

  local pid_path=`git rev-parse --git-dir`/auto_fetch.pid
  local pid=`cat $pid_path 2&>/dev/null`

  if [[ -n "$pid" && "$pid" -ne "$$" ]]; then
    kill -0 $pid && return 0
  fi
  echo $$ > $pid_path

  # Fetch origin
  if [[ $SECONDS -ge $((_ZSH_THEME_GIT_FETCH_SINCE + ZSH_THEME_GIT_FETCH_INTERVAL)) ]]; then
    _ZSH_THEME_GIT_FETCH_SINCE=$SECONDS
    git fetch -q > /dev/null 2>&1 || return 1
  fi
}
_ZSH_THEME_GIT_FETCH_SINCE=0

function custom_git_prompt()
{
    # Only display git info if we're inside a git repository.
    is_git_repository || return 1

    # Capture the output of the "git status" command.
    git_status="$(git status 2> /dev/null)"

    # Set color & icon based on status
    if [[ ${git_status} =~ "Changes to be committed" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_STAGED%{$reset_color%}"
    fi
    if [[ ${git_status} =~ "Changes not staged for commit" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CHANGED%{$reset_color%}"
    fi
    if [[ ${git_status} =~ "Untracked files" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED%{$reset_color%}"
    fi

    # Set remote status
    if [[ ${git_status} =~ "Your branch is ahead" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_AHEAD%{$reset_color%}"
    elif [[ ${git_status} =~ "Your branch is behind" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_BEHIND%{$reset_color%}"
    elif [[ ${git_status} =~ "Your branch and (.*) have diverged" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_DIVERGED%{$reset_color%}"
    fi

    # Set conflict status
    if [[ ${git_status} =~ "Unmerged paths" ]]; then
      STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CONFLICT%{$reset_color%}"
    fi

    # Set clean status
    if [[ "$STATUS" == "" ]]; then
      STATUS="$ZSH_THEME_GIT_PROMPT_CLEAN%{$reset_color%}"
    fi

    # Set current branch
    branch="$(git symbolic-ref HEAD 2>/dev/null)"
    test -z "$branch" && branch='<detached>'
    STATUS="${STATUS}(${branch#refs/heads/})"

    # Display the prompt.
    echo "$STATUS"
}

# auto refresh prompt
TMOUT=10
TRAPALRM() {
  fetch_git_repository
  zle reset-prompt
}

# custom git prompt
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg_bold[green]%}●"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg_no_bold[blue]%}✚"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[red]%}…"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✔"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[green]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_no_bold[blue]%}↓"
ZSH_THEME_GIT_PROMPT_DIVERGED="%{$fg_bold[red]%}↕"
ZSH_THEME_GIT_PROMPT_CONFLICT="%{$fg_bold[red]%}⚡"

ZSH_THEME_GIT_FETCH_INTERVAL="300"

# prompt
PROMPT='%{$fg[cyan]%}$(custom_path) %(?.%{$fg[green]%}.%{$fg[red]%})%B$%b '
RPROMPT='$(custom_git_prompt) [%D{%H:%M}]'
