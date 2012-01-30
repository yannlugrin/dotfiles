export PATH="~/bin:/usr/local/bin:$PATH"
export EDITOR="mvim"
export GIT_EDITOR="mvim -f -c 'au VimLeave * !open -a iTerm'"

# load other bash config files
[[ -f "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"
[[ -f "$HOME/.bash_git"     ]] && . "$HOME/.bash_git"

# load rvm
[[ -s "$HOME/.rvm/scripts/rvm"        ]] && . "$HOME/.rvm/scripts/rvm"
[[ -r "$HOME/.rvm/scripts/completion" ]] && . "$HOME/.rvm/scripts/completion"

# load bash completion
[[ -f `brew --prefix`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion
