###
### ZSH
###

# ZSH path
export ZSH=$HOME/.zsh

# ZSH theme
ZSH_THEME="yannlugrin"

# load auto completion from homebrew pacakge
if [ -d /usr/local/share/zsh/site-functions ]; then
  fpath=(/usr/local/share/zsh/site-functions $fpath)
fi

# load our own completion functions
fpath=($ZSH/completion $fpath)

# completion
autoload -U compinit
compinit -d "$ZSH/.zcompdump"

# load custom executable functions
for function in $ZSH/functions/*; do
  source $function
done

# enable colored output from ls, etc
export CLICOLOR=1

# history settings
setopt hist_ignore_all_dups inc_append_history
HISTFILE=~/.zhistory
HISTSIZE=4096
SAVEHIST=4096

# awesome cd movements from zshkit
setopt autocd autopushd pushdminus pushdsilent pushdtohome
DIRSTACKSIZE=3

# Enable extended globbing
setopt extendedglob

# Completion is case insentitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# handy keybindings
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward

# use vim as the visual editor
export VISUAL=vim
export EDITOR=$VISUAL

# homebrew
export PATH="/usr/local/bin:$PATH"

# npm bin
export PATH="/usr/local/share/npm/bin:$PATH"

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# travis
[ -f /Users/yannlugrin/.travis/travis.sh ] && source /Users/yannlugrin/.travis/travis.sh

# Dotfiles scripts
export PATH="$HOME/.dotfiles/bin:$PATH"

# repository bin - mkdir .git/safe in the root of repositories you trust
export PATH=".git/safe/../../bin:$PATH"
export PATH=".git/safe/../../node_modules/.bin:$PATH"

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# load zsh theme
if [ -f "$ZSH/themes/$ZSH_THEME.zsh-theme" ]; then
  source "$ZSH/themes/$ZSH_THEME.zsh-theme"
fi
