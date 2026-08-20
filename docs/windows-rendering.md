Terminal rendering on Windows
=============================

Windows Terminal and VS Code share one colour scheme (**One Half Dark**) and one
terminal font (**Cascadia Mono NF**), both installed by
`bin/install-windows-config`.

    ~/.dotfiles/bin/install-windows-config

The script merges `windows/windows-terminal.json` and
`windows/vscode-settings.json` into the live settings on the Windows side,
backing each file up first and leaving every key it does not manage alone. It is
safe to re-run. rcm cannot help here: it links files into `$HOME`, which never
reaches `/mnt/c`, so the Windows half needs a copy step instead.

Afterwards close **every** Windows Terminal window and start it again — not just
a new tab. `settings.json` is re-read while it runs, but a newly installed font
and the profile of a newly installed distribution are only picked up at startup.

Colour scheme
-------------

One Half Dark ships with Windows Terminal, so only the `colorScheme` key is
needed. VS Code has no built-in equivalent, so the script installs the One Dark
Pro extension, which uses the same `#282C34` ground.

It replaced Solarized Dark, which is low contrast by design and reuses the four
*bright* ANSI slots as its grey ramp — bright green is `#586E75`. The theme sets
its clean, ahead and staged marks with `$fg_bold[green]`, and Windows Terminal's
`intenseTextStyle` defaults to `bright`, so under Solarized those marks rendered
as grey rather than green.

Font
----

Cascadia ships *inside* the Windows Terminal app package, where no other
application can see it, so VS Code fell back to Consolas — two fonts with
different glyph coverage rendering the same prompt. The script installs the Nerd
Font builds into `AppData/Local/Microsoft/Windows/Fonts` and registers them under
`HKCU`, which needs no administrator rights.

Both terminals use **Cascadia Mono NF**. Mono rather than Code because Code has
ligatures, and `!=` or `->` collapsing into one glyph is unhelpful when reading
command output verbatim. `editor.fontFamily` is deliberately left unset: the
editor shares no glyphs with the prompt. Cascadia Code NF is installed alongside
for anyone who wants ligatures there.

Font size is pinned. The WSL fragment contributes `"font": {"face": "Ubuntu
Mono", "size": 13}` to the Ubuntu profile, and `profiles.defaults` overrides it
*key by key* — setting only `face` would leave `size` inherited from whatever
that package happens to specify.

Prompt glyphs
-------------

Symbols in `zsh/themes/` and `claude/statusline.zsh` must avoid codepoints with a
Unicode emoji property, save for the two service markers at the end of this
section. Where the terminal font has no glyph, Windows falls back to Segoe UI
Emoji, which draws a double-width colour glyph into a single cell: the symbol
renders in the wrong colour and everything after it shifts a column.

| was | now | why |
| --- | --- | --- |
| `✔` U+2714 | `✓` U+2713 | U+2714 is `Emoji=Yes` and falls back; U+2713 has no emoji property |
| `⚡` U+26A1 | `✗` U+2717 | U+26A1 is `Emoji_Presentation=Yes`, so it is *always* a colour emoji |

The `⚡` in the status line's fast-mode segment was dropped rather than replaced,
since the segments beside it carry no glyph.

Appending U+FE0E, the text-presentation variation selector, does **not** work —
Windows Terminal still renders U+2714 from the emoji font with it applied. The
codepoint has to change.

`✗` U+2717 and `✚` U+271A are not in Cascadia at all and come from Windows'
fallback chain. That is fine: they resolve to a *text* font, so they stay
single-width and take the colour they are given. `×` U+00D7 is the natively
covered alternative if that ever stops behaving.

**The one exception — the service markers.** The two markers at the right of the
status line's second row — 🐳 U+1F433 for docker, 🔑 U+1F511 for the ssh agent —
are emoji on purpose. They are pictograms, and every non-emoji pictogram tried
for them draws nothing at all here:

| tried | result |
| --- | --- |
| `⧉` U+29C9, `⚿` U+26BF | tofu — no font in the fallback chain covers them |
| U+E7B0, U+F084, U+F0868 (Nerd Font) | blank, even though the terminal font is the NF build |

What the rule above warns about is real but cheap here. The emoji font fixes
their colour and ANSI cannot touch it — which costs nothing, because these
markers mean "this service answers" by being present, and say nothing by their
hue. They are two cells wide while zsh counts them as one character, which
`visible_width` in `claude/statusline.zsh` corrects for. And they sit last on
their row, so the column they shift belongs to no one.

Anything *else* in these two files still follows the rule. Before adding a
pictogram, print the candidates to the terminal and look: coverage here is
narrower than it appears, and the question dialog is not a fair test of it.

Shape, position, hue
--------------------

Green against red is indistinguishable under deuteranopia, so the git marks are
separated by shape and by position rather than by colour:

    <working tree>(branch)<remote>
    ●✚…(main)↑

The group on the left can carry several marks at once, always in this order:

| mark | meaning |
| --- | --- |
| `●` | staged in the index |
| `✚` | changed in the working tree, not staged |
| `…` | untracked files present |
| `✗` | conflicts from a merge or rebase |
| `✓` | none of the above; the tree is clean |

`✓` stands in for the whole group when it would otherwise be empty, so it never
appears beside the other four. Because it describes the working tree alone, a
clean checkout that is merely ahead reads as `✓(main)↑`.

The slot on the right always carries exactly one mark, and they read as a single
compass:

| mark | meaning |
| --- | --- |
| `↑` | ahead of the upstream |
| `↓` | behind it |
| `↕` | diverged from it |
| `—` | level with it |
| `○` | nothing to measure against |

Because the slot is never empty the prompt does not change width as the state
changes. `—` is dim, being the state that warrants least attention; `○` takes the
default foreground so it stays legible. `○` covers both "no remote" and "no
upstream" — telling them apart would need a second git call per prompt.

The prompt marker is the one place where hue carries the meaning alone: `$` is
blue after a command that succeeded, red after one that failed. Blue rather than
green because green against red is the pair a deutan eye cannot separate. Blue
also marks *changed* and *behind*, but those sit right of the branch while the
marker sits left of the command.

VS Code diff colours
--------------------

One Dark Pro never sets `diffEditor.insertedLineBackground` or its siblings, so
VS Code falls back to its own defaults. Those are heavy enough that body text
drops below the AA floor and `markup.quote.markdown`, the dimmest token in the
theme, becomes unreadable — markdown blockquotes inside a diff are where it
shows. Added and removed rows are also near-indistinguishable under deuteranopia.

`windows/vscode-settings.json` sets the four keys explicitly, using One Dark's
own blue and orange at a lower alpha:

| key | value |
| --- | --- |
| `diffEditor.insertedLineBackground` | `#61AFEF22` |
| `diffEditor.insertedTextBackground` | `#61AFEF2A` |
| `diffEditor.removedLineBackground` | `#D19A6622` |
| `diffEditor.removedTextBackground` | `#D19A662A` |

`markup.quote.markdown` is lifted to `#abb2bf` and italicised: at that value it
matches body text, so the slant carries the hierarchy that dimness used to.

What the fragments manage
-------------------------

`windows/` holds only the keys worth reproducing. Everything else in the live
files is either machine-generated or already the default.

**Windows Terminal:**

| key | why it is here |
| --- | --- |
| `profiles.defaults.colorScheme` | One Half Dark |
| `profiles.defaults.font` | face and size |
| `profiles.defaults.suppressApplicationTitle` | `false`, so tab titles work |
| `keybindings` | `ctrl+c` / `ctrl+v` / `alt+shift+d` |
| `copyFormatting` | `"none"`; the default is `true` |

Not managed: `profiles.list` is regenerated by Windows Terminal from installed
distros, and `schemes`, `themes` and `actions` are empty arrays that add nothing
to the built-in sets — which is why `One Half Dark` resolves with
`"schemes": []`.

`keybindings` is an array and the merge replaces arrays wholesale, so this file
owns that list. Add new bindings here rather than through the settings UI.

**VS Code:** the theme, the terminal font, the diff colours above, the
`claudeCode.*` preferences and two editor settings.
`editor.unicodeHighlight.nonBasicASCII` is the one that looks unrelated and is
not: left at its default, VS Code boxes every non-ASCII character as a possible
homoglyph, which means every symbol in the theme files.

The default profile
-------------------

`defaultProfile` is resolved at run time by `set_default_profile`, not stored.
Windows Terminal identifies profiles by GUID, and the GUID is generated per
installation — installing the same distribution twice produces two different
ones.

Candidates come from two places. Profiles Windows Terminal has written into
`settings.json` carry a `source` naming their generator — `Windows.Terminal.Wsl`
for its own, `Microsoft.WSL` for the Store WSL app — and any source containing
`wsl` counts. But Windows Terminal only discovers fragment profiles at startup,
so a distribution installed while it was running exists solely as a fragment
under `AppData/Local/Microsoft/Windows Terminal/Fragments`. Those directories are
read too, de-duplicated by GUID. That window is the normal case for a second
distribution: its profile is not in the menu yet, so the way in is `wsl -d
Debian`, which is exactly where the dotfiles get cloned and this script gets run.

An existing WSL default is never overridden — installing into a second
distribution should configure it, not promote it. Otherwise, with one candidate
it is chosen; with several the script asks, marking the distribution this shell
is running in (`$WSL_DISTRO_NAME`) as the default answer. Anything that is not a
listed number leaves the key alone, and with no terminal to ask on it falls back
to the running distribution. `--choose-default` re-opens the question.

Tab titles
----------

The tab reads the same way as the prompt and the Claude status line: the project
in brackets, then where we are inside it.

| where | tab reads |
| --- | --- |
| project root | `[acme/blog] ~` |
| inside the project | `[acme/blog] ~/src/deep` |
| outside any project | `/tmp` |
| Claude Code running | `✴ [acme/blog] ~/src/deep` |

It uses the same `_project_label` and `${PWD/#$root/~}` rewrite as the prompt, so
the two can never disagree.

Two hooks rather than one. `precmd` runs between commands, but a shell running
Claude Code is blocked for the whole session and never reaches it, so the tab
would sit showing whatever preceded it. `preexec` labels the tab on the way in;
`precmd` restores the plain project name on the way out. The command is matched
on its basename, so `/usr/local/bin/claude` counts. `CLAUDECODE=1` is not usable
for this: it exists inside Claude Code's environment, not in the shell that
launched it.

Claude Code retitles the tab itself once it starts, so `zshrc` exports
`CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1`.

The marker is `✴` U+2734, Claude Code's own mark. It leads rather than trails
because Windows Terminal truncates tab labels from the right, and it is a plain
Unicode glyph rather than a Nerd Font icon because the tab bar draws in the
system UI font, not the terminal font.

None of this works by default: the WSL fragment sets `suppressApplicationTitle`
on the Ubuntu profile, which makes Windows Terminal ignore any title an
application asks for.
