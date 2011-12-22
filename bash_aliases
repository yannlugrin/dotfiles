# l
alias ll='ls -l'
alias la='ls -la'

# powder
function powder_custom_host {
  echo -n $(ruby -e "puts Dir.pwd.split('/')[-2..-1].reverse.join('.')")
}

alias pl='powder link $(powder_custom_host)'
alias pr='powder remove $(powder_custom_host)'
alias po='powder open $(powder_custom_host)'

# homebrew
alias brew='rvm system exec brew'

# mvim
function m {
  if [ $# -gt 0 ]
  then
    mvim $@
  else
    mvim .
  fi
}

# Ruby tools
alias rc='rails console'

function bundle_rake {
  if [[ -f "Gemfile" ]]
  then
    bundle exec rake $@
  else
    rake $@
  fi
}
alias rake="bundle_rake"

function bundle_guard {
  if [[ -f "Gemfile" ]]
  then
    bundle exec guard $@
  else
    guard $@
  fi
}
alias guard="bundle_guard"

function bundle_nanoc {
  if [[ -f "Gemfile" ]]
  then
    bundle exec nanoc $@
  else
    guard $@
  fi
}
alias nanoc="bundle_nanoc"

# Capistrano
alias deploy='bundle exec cap deploy:migrations'
