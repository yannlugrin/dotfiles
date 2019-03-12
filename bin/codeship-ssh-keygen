#!/usr/bin/env bash
set -ex

CODESHIP_FOLDER=.codeship
KEYS_FOLDER=.codeship/keys

# ensure codeship directory exists
mkdir -p $KEYS_FOLDER

if [ ! -f $KEYS_FOLDER/codeship.aes ]; then
  printf "\033[0;31mFile '$KEYS_FOLDER/codeship.aes' must exist, can be downloaded from Codeship Pro project general settings tab.\033[0m\n"
  exit 1
fi

# Generate the key
printf "\033[0;34m* Generate SSH private key.\033[0m\n"
docker run -it --rm -v $(pwd)/$KEYS_FOLDER:/keys/ codeship/ssh-helper generate "dev@antistatique.net"

# Generate .env file then remove private key
if [ -f $CODESHIP_FOLDER/env.encrypted ]; then
  printf "\033[0;34m* Decrpty existing .env encrypted file.\033[0m\n"
  jet decrypt $CODESHIP_FOLDER/env.encrypted $KEYS_FOLDER/codeship.env --key-path $KEYS_FOLDER/codeship.aes
  sed '/PRIVATE_SSH_KEY/d' $KEYS_FOLDER/codeship.env > $KEYS_FOLDER/codeship.env.new
  mv $KEYS_FOLDER/codeship.env.new $KEYS_FOLDER/codeship.env
fi
printf "\033[0;34m* Add or replace SSH private key in .env file.\033[0m\n"
docker run -it --rm -v $(pwd)/$KEYS_FOLDER:/keys/ codeship/ssh-helper prepare
rm $KEYS_FOLDER/codeship_deploy_key

# Encrypt .env file then remove clear .env file
printf "\033[0;34m* Encrypt .env file.\033[0m\n"
jet encrypt $KEYS_FOLDER/codeship.env $CODESHIP_FOLDER/env.encrypted --key-path $KEYS_FOLDER/codeship.aes
rm $KEYS_FOLDER/codeship.env

# Just check that keys cannot be commited
if grep -v -q $KEYS_FOLDER .gitignore; then
  printf "\033[0;31mYou must add '$KEYS_FOLDER' to .gitignore file to avoid to commit it's content!\033[0m\n"
fi

# Print public key
printf "\033[0;34m* The public keys ($KEYS_FOLDER/codeship_deploy_key.pub):\n\n$(cat "$KEYS_FOLDER/codeship_deploy_key.pub")\033[0m\n"
