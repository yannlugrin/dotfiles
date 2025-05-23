###
### ZSH
###

# ZSH path
export ZSH=$HOME/.zsh

# ZSH theme
ZSH_THEME="yannlugrin"

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Load custom autocompletions
if [ -d $ZSH/completions ]; then
  fpath=($ZSH/completions $fpath)
fi

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

# rbenv
if command -v rbenv >/dev/null 2>&1; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

# Dotfiles scripts
export PATH="$HOME/.dotfiles/bin:$PATH"

# Home bins
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Composer global bin
export PATH="$HOME/.composer/vendor/bin:$PATH"

# repository bin - mkdir .git/safe in the root of repositories you trust
export PATH=".git/safe/../../bin:$PATH"
export PATH=".git/safe/../../vendor/bin:$PATH"
export PATH=".git/safe/../../node_modules/.bin:$PATH"

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# load plugins
for plugin in $ZSH/plugins/*/*.zsh; do
  source $plugin
done

# load zsh theme
if [ -f "$ZSH/themes/$ZSH_THEME.zsh-theme" ]; then
  source "$ZSH/themes/$ZSH_THEME.zsh-theme"
fi

# bun completions
[ -s "/home/yann/.bun/_bun" ] && source "/home/yann/.bun/_bun"


# Composer
export PATH="$(composer global config bin-dir --absolute --quiet):$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
