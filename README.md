Yann Lugrin's dotfiles
===================

For Ubuntu, on WSL or on a plain Linux desktop. The WSL-only pieces (the
Bitwarden SSH agent bridge, `open` via Windows) are guarded and stay out of the
way elsewhere.

Requirements
------------

Only git, to clone this, and [rcm](https://github.com/thoughtbot/rcm), to
install it. Everything else, zsh included, is installed by the hooks:

    sudo apt update
    sudo apt install -y git rcm

The hooks install packages but never upgrade the system, so upgrade first if
you want to start from an up-to-date machine:

    sudo apt upgrade

Install
-------

Clone into your home directory:

    cd ~; git clone https://github.com/yannlugrin/dotfiles.git .dotfiles

Install:

    rcup -d .dotfiles -x README.md -x LICENSE -x bin -x docs

This creates symlinks for the config files in your home directory, and runs the
hooks. The `-x` options match `EXCLUDES` in `rcrc` and are only needed for this
first run, before `.rcrc` itself is symlinked in.

`hooks/pre-up` does the system-wide setup, which is everything needing `sudo`:
the apt packages and the locale. `hooks/post-up` installs the per-user
toolchains: nvm with the latest LTS node as the default, rbenv's plugins with
the latest stable Ruby as the default, Claude Code, and npiperelay under WSL.

The runtimes belong in `post-up` because rbenv-default-gems reads
`$(rbenv root)/default-gems`, which only exists once `rcup` has linked it. Both
resolve "latest" at run time, so re-running `rcup` picks up newer releases. The
first run compiles Ruby from source and takes a while.

`pre-up` installs zsh, so set it as your login shell once `rcup` has finished:

    chsh -s $(which zsh)

You can safely run `rcup` multiple times to update:

    rcup

Add `-K` to sync the symlinks without re-running the hooks:

    rcup -K

More informations about my config
---------------------------------

- [Bitwarden SSH agent on WSL](docs/bitwarden-ssh-agent.md): use SSH keys
  stored in Bitwarden from WSL, without keeping private keys on disk. Requires
  a few manual steps on the Windows side.

More coming soon (or maybe later).

License
-------

MIT (see LICENSE file)

Inspired by thoughtbot dotfiles licensed under MIT with thoughbot copyright:
https://github.com/thoughtbot/dotfiles
