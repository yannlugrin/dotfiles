###
### ZSH
###

# Everything under zsh/ in the dotfiles, symlinked here by rcm.
export ZSH=$HOME/.zsh

ZSH_THEME="yannlugrin"

# Generated files go to the cache, never next to the symlinked config.
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# Set early: the glob qualifiers below and in the theme depend on it.
setopt extendedglob

###
### Locale
###

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

###
### PATH
###

# typeset -U keeps the list unique, so re-sourcing this file does not stack
# duplicates.
typeset -U path PATH

path=(
  # Repository-local binaries, for repositories marked as trusted with
  # `git trust` (which creates .git/safe).
  .git/safe/../../bin
  .git/safe/../../vendor/bin
  .git/safe/../../node_modules/.bin

  $HOME/.local/bin
  $HOME/bin

  # Composer's global bin. Hardcoded rather than asked of `composer global
  # config bin-dir`, which costs a PHP startup on every shell.
  ${COMPOSER_HOME:-$HOME/.config/composer}/vendor/bin

  $HOME/.dotfiles/bin

  $path
)

###
### Completion
###

if [[ -d $ZSH/completions ]]; then
  fpath=($ZSH/completions $fpath)
fi

autoload -Uz compinit

# The security check that compinit runs over $fpath is the slow part, so do it
# once a day and take the cached dump the rest of the time.
if [[ -n $ZSH_CACHE_DIR/zcompdump(#qN.mh+24) ]]; then
  compinit -d "$ZSH_CACHE_DIR/zcompdump"
else
  compinit -C -d "$ZSH_CACHE_DIR/zcompdump"
fi

# Completion is case insensitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

###
### Options
###

# History
HISTFILE=~/.zhistory
HISTSIZE=4096
SAVEHIST=4096
setopt hist_ignore_all_dups inc_append_history

# Awesome cd movements from zshkit
setopt autocd autopushd pushdminus pushdsilent pushdtohome
DIRSTACKSIZE=3

###
### Keybindings
###

bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward

###
### Editor
###

export VISUAL=vim
export EDITOR=$VISUAL

###
### Tools
###

if (( $+commands[rbenv] )); then
  eval "$(rbenv init -)"
fi

# nvm is loaded by the zsh-nvm plugin below. Lazy so that the ~0.4s of sourcing
# nvm.sh is paid on first use instead of at every shell start.
export NVM_LAZY_LOAD=true

###
### Load the rest of the configuration
###

# Custom functions. 00-platform sorts first and defines what the others need.
for function in $ZSH/functions/*; do
  source $function
done

[[ -f ~/.aliases ]] && source ~/.aliases

for plugin in $ZSH/plugins/*/*.zsh; do
  source $plugin
done

# nvm's alias resolution silently fails under extendedglob, so sourcing nvm.sh
# does not activate the default version and a shell ends up with no node at
# all. The option has to be off while nvm's own code runs.
#
# _zsh_nvm_load is the one entry point that matters: the lazy node/npm stubs
# call it directly, and it is what replaces `nvm` with nvm.sh's real function,
# which is then wrapped in turn so that later `nvm use default` calls work too.
function _nvm_noextendedglob_wrap() {
  local fn=$1

  (( $+functions[$fn] )) || return 1
  (( $+functions[${fn}_noglob] )) && return 0   # already wrapped

  functions[${fn}_noglob]=$functions[$fn]
  functions[$fn]="setopt localoptions noextendedglob
${fn}_noglob \"\$@\""
}

if (( $+functions[_zsh_nvm_load] )); then
  functions[_zsh_nvm_load_orig]=$functions[_zsh_nvm_load]

  function _zsh_nvm_load() {
    setopt localoptions noextendedglob

    _zsh_nvm_load_orig "$@"

    # nvm.sh has just defined its own `nvm`, replacing the lazy stub.
    _nvm_noextendedglob_wrap nvm
  }
fi

if [[ -f "$ZSH/themes/$ZSH_THEME.zsh-theme" ]]; then
  source "$ZSH/themes/$ZSH_THEME.zsh-theme"
fi

###
### Session status
###

# Last, so it stays the first thing visible above the prompt.
docker_status
