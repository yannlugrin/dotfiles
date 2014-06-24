export PATH="~/bin:/usr/local/bin:$PATH:$HOME/.rvm/bin"
export EDITOR="mvim"
# export GIT_EDITOR="mvim -f -c 'au VimLeave * !open -a iTerm'"
export GIT_EDITOR="vim"

# export env variable for rails development
# export RACK_ENV="development"
# export RAILS_ENV="development"
# export SIGNED_COOKIE_SECRET_TOKEN="bc84357593086ce26e825f80ab48d4d7a1b09a6306ed04801f1494d9b7e92ded0f93001012aa29ae59a76ef573f8d76efe05226e0d16fb4d8769ead18ad8ab12"
# export TB_SECRET_TOKEN="2317532531cce5afa3660fcc6852259aee48588d1fe8e8d4a28e6d442e1e3bc3a5e0335cb8491c538003f4c861fb2f16ba175117cd9db40fa9509262679e4ae7"

# Sencha
export SENCHA_SDK_TOOLS_2_0_0_BETA3="/Applications/SenchaSDKTools-2.0.0-beta3"
export SENCHA_CMD_3_0_0="/Users/yannlugrin/Development/Sencha/bin/Sencha/Cmd/4.0.2.67"
export PATH=/Users/yannlugrin/Development/Sencha/bin/Sencha/Cmd/4.0.2.67:$PATH

# homebrew sbin
export PATH="/usr/local/sbin:$PATH"

# npm bin
export PATH="/usr/local/share/npm/bin:$PATH"

# Postgres
export PATH="/Applications/Postgres.app/Contents/MacOS/bin:$PATH"

# android bin
export ANDROID_BIN=~/Development/adt-bundle/sdk/tools/android
export PATH="~/Development/adt-bundle/sdk/tools:$PATH"
export PATH="~/Development/adt-bundle/sdk/platform-tools:$PATH"

# load other bash config files
[[ -f "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"
[[ -f "$HOME/.bash_git"     ]] && . "$HOME/.bash_git"

# load bash completion
[[ -f `brew --prefix`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion

# load rvm
[[ -s "$HOME/.rvm/scripts/rvm"        ]] && . "$HOME/.rvm/scripts/rvm"
[[ -r "$HOME/.rvm/scripts/completion" ]] && . "$HOME/.rvm/scripts/completion"

