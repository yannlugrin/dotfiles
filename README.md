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

    rcup -d .dotfiles -x README.md -x LICENSE -x bin -x docs -x windows

This creates symlinks for the config files in your home directory, and runs the
hooks. The `-x` options match `EXCLUDES` in `rcrc` and are only needed for this
first run, before `.rcrc` itself is symlinked in.

`hooks/pre-up` does the system-wide setup, which is everything needing `sudo`:
the apt packages and the locale. It also adds GitHub's apt repository, so `gh`
tracks upstream instead of the much older build in Ubuntu's universe.
`hooks/post-up` installs the per-user
toolchains: nvm with the latest LTS node as the default, rbenv's plugins with
the latest stable Ruby as the default, Claude Code, the Dev Containers CLI, the
Bitwarden CLI, and npiperelay under WSL.

The runtimes belong in `post-up` because rbenv-default-gems reads
`$(rbenv root)/default-gems`, which only exists once `rcup` has linked it. Both
resolve "latest" at run time, so re-running `rcup` picks up newer releases. The
first run compiles Ruby from source and takes a while.

`pre-up` installs zsh, so set it as your login shell once `rcup` has finished:

    sudo chsh -s "$(which zsh)" "$USER"

Through `sudo` rather than a bare `chsh`, which authenticates you against PAM and
fails with "PAM: Authentication failure" on a fresh WSL image even when the
password is right.

On WSL, the Windows side is a separate step, since rcm only links into `$HOME`
and cannot reach `/mnt/c`:

    ~/.dotfiles/bin/install-windows-config

It merges the colour scheme, font and editor settings in `windows/` into Windows
Terminal and VS Code, and is safe to re-run. Run it after `rcup`, which installs
the `python3`, `curl`, `jq` and `unzip` it needs; run it before and it will say
what is missing rather than getting halfway.

Then close **every** Windows Terminal window and start it again — not just a new
tab. Windows Terminal re-reads `settings.json` while it runs, so the colour
scheme appears immediately, but a newly installed font and the profile of a newly
installed distribution are only picked up at startup. The same goes for VS Code.

You can safely run `rcup` multiple times to update:

    rcup

Add `-K` to sync the symlinks without re-running the hooks:

    rcup -K

More informations about my config
---------------------------------

- [Bitwarden SSH agent on WSL](docs/bitwarden-ssh-agent.md): use SSH keys
  stored in Bitwarden from WSL, without keeping private keys on disk. Requires
  a few manual steps on the Windows side.
- [Terminal rendering on Windows](docs/windows-rendering.md): one colour scheme
  and one font shared by Windows Terminal and VS Code, why the scheme is not
  Solarized, and which prompt glyphs survive the Windows font fallback.

More coming soon (or maybe later).

License
-------

MIT (see LICENSE file)

Inspired by thoughtbot dotfiles licensed under MIT with thoughbot copyright:
https://github.com/thoughtbot/dotfiles
