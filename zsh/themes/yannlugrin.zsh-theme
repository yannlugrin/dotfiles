#!/usr/bin/env zsh

# setup
autoload colors; colors;
export LSCOLORS="Gxfxcxdxbxegedabagacad"
setopt promptsubst

# custom path with project and relative root
function custom_path {
  local client_project_root=`pwd | sed -n 's:\(^.*/clients/[^/]*/[^/]*\).*$:\1:p'`

  if [ -n "$client_project_root" ]; then
    local client_project_name=`echo $client_project_root | awk -F/ '{print $(NF-1) "/" $(NF)}'`
    local client_project_path=`pwd | sed "s:^$client_project_root:~:"`

    echo "[$client_project_name] $client_project_path"
  else
    echo '%~'
  fi

}

# prompt

PROMPT='%{$fg[cyan]%}$(custom_path) %(?.%{$fg[green]%}.%{$fg[red]%})%B$%b '
RPROMPT='todo: git'

