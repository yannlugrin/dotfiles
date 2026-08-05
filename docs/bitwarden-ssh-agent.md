Bitwarden SSH agent on WSL
==========================

Use SSH keys stored in Bitwarden from WSL, without ever copying a private key
to disk. The keys stay in the vault; Bitwarden Desktop on Windows signs on
behalf of `ssh`, and every use can require an explicit approval prompt.

How it works
------------

Bitwarden Desktop serves its agent on a **Windows named pipe**,
`\\.\pipe\openssh-ssh-agent`. The path is hardcoded and cannot be changed
([bitwarden/clients#16123](https://github.com/bitwarden/clients/issues/16123)).
WSL2 runs in its own VM and has no access to Windows named pipes, so a Windows
process has to open the pipe on its behalf:

    Bitwarden Desktop (Windows)
      └─ \\.\pipe\openssh-ssh-agent
           └─ npiperelay.exe            Windows process, one per connection
                └─ stdio
                     └─ socat           WSL
                          └─ ~/.ssh/bitwarden-agent.sock
                               └─ $SSH_AUTH_SOCK → ssh / git

`npiperelay.exe` translates the named pipe to stdio, and `socat` exposes that
as a normal Unix socket. Nothing runs permanently on the Windows side beyond
Bitwarden itself: `socat` spawns `npiperelay.exe` per incoming connection.

The Windows binary deliberately lives under the Windows user profile
(`%USERPROFILE%\.local\bin\npiperelay.exe`), not in the WSL filesystem and not
on the WSL `$PATH`.

Windows setup
-------------

### 1. Install Bitwarden Desktop

Install the desktop application — the browser extension and the CLI do **not**
provide an SSH agent. Either:

    winget install Bitwarden.Bitwarden

or the Microsoft Store / [installer from
bitwarden.com](https://bitwarden.com/download/). Sign in and unlock the vault.

### 2. Disable the Windows OpenSSH agent

Bitwarden claims the same named pipe as Windows' built-in OpenSSH
Authentication Agent, so that service must not be running. In an **elevated**
PowerShell:

```powershell
Stop-Service ssh-agent; Set-Service ssh-agent -StartupType Disabled
```

Verify it reports `Stopped` / `Disabled`:

```powershell
Get-Service ssh-agent | Select-Object Status, StartType
```

### 3. Enable the agent in Bitwarden

Settings → **Enable SSH agent**, then **restart Bitwarden Desktop**. The toggle
does not take effect until the app restarts.

Keep **Ask for authorization when using SSH agent** on unless the prompts get
in the way — it is the main security benefit of holding keys in the vault.

### 4. Check the pipe exists

```powershell
[System.IO.Directory]::GetFiles('\\.\pipe\') -match 'openssh'
```

This must print `\\.\pipe\openssh-ssh-agent`. If it prints nothing, the agent
is not enabled or the app was not restarted — nothing on the WSL side can work
until it does.

### 5. Add keys to the vault

Create an SSH key item in Bitwarden (**New → SSH key**), either by generating
one or by pasting an existing private key. Only SSH key items are offered to
the agent.

WSL setup
---------

Handled by the dotfiles:

    rcup

`hooks/pre-up` installs `socat`. `hooks/post-up` installs `npiperelay.exe`: it
downloads a pinned release of
[albertony/npiperelay](https://github.com/albertony/npiperelay) — a maintained
fork of the original, which is unmaintained — verifies its SHA-256, installs it
under `%USERPROFILE%\.local\bin\`, and records the resolved path in
`~/.config/bitwarden-ssh-agent/npiperelay-path`. It re-downloads only when the
binary is missing or is not the pinned build, so `rcup` stays cheap to re-run.

`zsh/functions/bitwarden-ssh-agent` reads that path, starts the `socat` relay if
it is not already running, and exports `SSH_AUTH_SOCK`. The healthy case costs
no subprocesses at shell startup: liveness is checked against a pidfile and
`/proc` using shell builtins only.

Off WSL, this function does nothing and `zsh/functions/keychain` takes over,
keeping a shared `ssh-agent` alive with `~/.ssh/id_ed25519` loaded.

Verify
------

Open a new shell and list the keys the agent offers:

    ssh-add -l

The SSH key items from your vault should be listed. Then test against a host:

    ssh -T git@github.com

Bitwarden should prompt for approval (if enabled), and GitHub should greet you
by username.

Troubleshooting
---------------

**`Error connecting to agent: No such file or directory`**
The relay is not running. Restart it:

    bitwarden-ssh-agent

Then check `~/.cache/bitwarden-ssh-agent.log` for socat errors.

**`The agent has no identities`**
The vault is locked, or the items are not SSH key items. Unlock Bitwarden
Desktop and re-run `ssh-add -l`.

**Everything stops working after restarting Bitwarden**
Restarting the app tears down the named pipe, and the existing relay stays
attached to the dead one. Rebuild it:

    bitwarden-ssh-agent

**`agent refused operation`**
An approval prompt was dismissed or timed out, or the vault locked mid-request.
Unlock Bitwarden and retry. If the agent stays unresponsive, restart Bitwarden
Desktop *and* re-run `bitwarden-ssh-agent` — the agent does not always recover
on its own.

**`ssh-add -l` hangs**
Usually the Windows OpenSSH service reclaimed the pipe. Re-check step 2, then
restart Bitwarden.

**Nothing works after a Windows username change or a new machine**
The recorded npiperelay path is stale. Re-run `rcup` to resolve and record it
again.

Notes
-----

- The relay is per-WSL-session; each new shell reuses the running one.
- The socket is created with mode `600` — other users on the machine cannot
  reach the agent through it.
- Agent forwarding (`ssh -A`) works as usual: the forwarded agent is Bitwarden,
  so approval prompts appear on the Windows desktop.
