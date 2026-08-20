Docker Desktop under WSL
========================

Docker in this setup is not a daemon in this distro. The CLI is mounted in from
`/mnt/wsl/docker-desktop/cli-tools`, the engine runs in a second distro called
`docker-desktop`, and both are driven by the Docker Desktop app on Windows:

```
$ wsl -l -v
  NAME              STATE           VERSION
* Ubuntu            Running         2
  docker-desktop    Running         2
```

That second distro is why this exists. Closing the terminal stops Ubuntu, but
`docker-desktop` keeps running, and a running distro keeps the WSL VM — and the
several gigabytes of `vmmemWSL` behind it — alive until the next
`wsl --shutdown`. Stopping Docker Desktop is what lets the machine go idle.

`docker desktop`
----------------

`zsh/functions/docker` wraps the command under WSL, the way `zsh/functions/
bitwarden` wraps `bw`. Only `start` and `status` are answered there, because
they are the only two that know something the CLI does not: `start` needs a CLI
that outlives the app, and `status` has a row to add about the daemon.
`stop`, `diagnose`, `logs`, `restart` and the rest are passed to whichever CLI
can run them, and every other `docker` command goes to the real binary
untouched. A `docker` whose symlink dangles, meaning Docker Desktop is stopped,
is reported as such rather than as a "no such file or directory" naming a path
nobody asked about.

**The command is `docker desktop`; the trap is which binary can run it.** There
are two, and they are available at opposite times:

| | Windows CLI | Linux plugin |
| --- | --- | --- |
| lives in | the Windows install directory | `/mnt/wsl/docker-desktop`, a mount |
| while Docker Desktop runs | works | works, once its socket is linked |
| while it is stopped | still there | **gone**, along with `docker` itself |
| `diagnose`, `logs` | work | want a helper under `/opt/docker-desktop` |

So the Windows CLI is tried first for everything. The Linux plugin is the
fallback for an install with no Windows CLI to reach for, and `start` cannot use
it at all: nothing living inside `/mnt/wsl/docker-desktop` can bring back the app
that mounts it. Failing both, `start` launches `Docker Desktop.exe` itself.

`status` prints the CLI's own table and appends the one row it cannot fill:

```
Name                Value
Status              running     <- the app's answer about itself
SessionID           e8bb0b7f-eebb-4c4a-a650-cbe6cd48daf9
Daemon              running     <- ours
```

The app is up well before the engine in the `docker-desktop` distro is, and it
is the engine that every other `docker` command needs.

Two details worth keeping:

- **The app's `-Shutdown` flag does not work.** Older write-ups recommend
  `"Docker Desktop.exe" -Shutdown`; on 4.85 it brings the window to the front
  and nothing else.
- **`start` launches the app through `cmd /c start`.** Running a Windows GUI
  binary directly leaves a stub process in this distro for as long as the app
  lives, and a process here is precisely what stops WSL going idle — the thing
  this whole arrangement is meant to achieve.

The backend socket
------------------

The Linux plugin looks for Docker Desktop's control socket under
`~/.docker/desktop`, where a Windows or macOS install puts it. The WSL
integration exposes that socket somewhere else entirely and never bridges the
two, which is why the plugin says "Could not retrieve status" while the daemon
answers happily. `hooks/post-up` links them:

```sh
ln -sfn /mnt/wsl/docker-desktop/shared-sockets/host-services/backend.sock \
  ~/.docker/desktop/backend.sock
```

The target exists only while Docker Desktop runs, so the link dangles the rest
of the time — the honest state, and the same shape as the completion symlink in
`zsh/completions/_docker`.

That fixes the socket and nothing else. `docker desktop diagnose` and `logs`
shell out to a helper binary under `/opt/docker-desktop/bin/`, the layout of a
*native Linux* Docker Desktop install; under WSL that path does not exist and no
Linux build of the helper is anywhere in the mounts. Those need the Windows CLI,
which is what the reroute hands them.

`stop-docker-desktop.service`
-----------------------------

Installed and enabled by `hooks/pre-up`, since `/etc/systemd/system` needs root.
The unit does nothing while it runs; the `ExecStop` is the whole point.

It spells the stop out rather than calling the shell function above, because
systemd can only exec a file and a function is not one — and putting a script on
`$PATH` for the sake of one line of shutdown would be a strange price to pay for
a command nobody types:

```ini
[Unit]
After=mnt-c.mount systemd-binfmt.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/bin/sh -c '[ -S <backend.sock> ] && "<docker.exe>" desktop stop --timeout 25 || true'
TimeoutStopSec=30
```

`After=` those two units means the service stops *before* them, because systemd
stops units in reverse order. Both are needed: `/mnt/c` is a real mount unit
here (`mnt-c.mount`), and `systemd-binfmt.service` is what registers
`WSLInterop`. Without that ordering the hook could reach for a Windows binary
that is no longer reachable.

The socket test is the same "is it running" check the shell function uses, and
`|| true` keeps a failed stop from making the shutdown look broken.
`TimeoutStopSec=30` is insurance, and the `--timeout 25` sits just inside it: a wedged Docker Desktop would otherwise hold the whole distro's
shutdown open for the default 90 seconds.

What triggers it, and what does not
-----------------------------------

| how the distro ends | hook runs? |
| --- | --- |
| closing the terminal, letting WSL stop the distro | yes |
| `wsl -t Ubuntu` | yes |
| `wsl --shutdown` | **no** — the VM is killed outright, no systemd shutdown |

`wsl --shutdown` not running it costs nothing in practice: it stops every distro
anyway. The Docker Desktop *app* stays up on the Windows side, and will start
the VM again when it wants it.

That the graceful path really does run a full systemd shutdown is worth
verifying after any WSL upgrade, since the hook is worthless otherwise:

```sh
journalctl -b -1 -n 5    # the previous boot should end at poweroff.target
```

Starting it again
-----------------

Automatic stop means manual start. `docker desktop start` waits for the app to
report itself started, and then for the daemon to answer, which is a second
question: a cold start brings up the app, then the `docker-desktop` distro, then
the engine inside it, and only the last of those makes `docker` usable.

The shell says so too. `docker_status` in `zsh/functions/docker` prints one line
at shell start, and under WSL it names the command:

```
docker is not running (docker desktop start)
```

The 🐳 marker on the Claude Code status line answers the same question while a
session is running, within its 20 second cache. See `claude/statusline.zsh`.
