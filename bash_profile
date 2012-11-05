export PATH="~/bin:/usr/local/bin:$PATH:$HOME/.rvm/bin"
export EDITOR="mvim"
export GIT_EDITOR="mvim -f -c 'au VimLeave * !open -a iTerm'"

# export env variable for rails development
export RACK_ENV="development"
export RAILS_ENV="development"
export SIGNED_COOKIE_SECRET_TOKEN="bc84357593086ce26e825f80ab48d4d7a1b09a6306ed04801f1494d9b7e92ded0f93001012aa29ae59a76ef573f8d76efe05226e0d16fb4d8769ead18ad8ab12"

# load other bash config files
[[ -f "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"
[[ -f "$HOME/.bash_git"     ]] && . "$HOME/.bash_git"

# load rvm
[[ -s "$HOME/.rvm/scripts/rvm"        ]] && . "$HOME/.rvm/scripts/rvm"
[[ -r "$HOME/.rvm/scripts/completion" ]] && . "$HOME/.rvm/scripts/completion"

# load bash completion
[[ -f `brew --prefix`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion

export PATH=/Applications/SenchaSDKTools:$PATH

export SENCHA_SDK_TOOLS_2_0_0_BETA3="/Applications/SenchaSDKTools"
