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

# Capistrano
function deploy {
  if [[ -d "db/migrate" ]]
  then
    bundle exec cap deploy:migrations
  else
    bundle exec cap deploy
  fi
}
