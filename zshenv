# ZSH path
export ZSH=$HOME/.zsh

# homebrew
export PATH="/usr/local/bin:$PATH"

# npm bin
export PATH="/usr/local/share/npm/bin:$PATH"

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# travis
[ -f /Users/yannlugrin/.travis/travis.sh ] && source /Users/yannlugrin/.travis/travis.sh

# Dotfiles scripts
export PATH="$HOME/.dotfiles/bin:$PATH"

# repository bin - mkdir .git/safe in the root of repositories you trust
export PATH=".git/safe/../../bin:$PATH"
export PATH=".git/safe/../../node_modules/.bin:$PATH"

# use vim as the visual editor
export VISUAL=vim
export EDITOR=$VISUAL
