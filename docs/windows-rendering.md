Terminal rendering on Windows
=============================

Windows Terminal and VS Code share one colour scheme (**One Half Dark**) and one
terminal font (**Cascadia Mono NF**), both installed by
`bin/install-windows-config`.

    ~/.dotfiles/bin/install-windows-config

The script merges `windows/windows-terminal.json` and
`windows/vscode-settings.json` into the live settings on the Windows side,
backing each file up first and leaving every key it does not manage alone. It
is safe to re-run. rcm cannot help here: it links files into `$HOME`, which
never reaches `/mnt/c`, so the Windows half needs a copy step instead.

One Half Dark ships with Windows Terminal, so no scheme definition is needed —
only the `colorScheme` key. VS Code has no built-in equivalent, so the script
installs the One Dark Pro extension, which uses the same `#282C34` ground.

Why not Solarized
-----------------

Solarized Dark was the previous scheme, inherited from an iTerm setup. Two
problems, one of them a real bug.

It is low contrast by design: `base0` on `base03` measures 4.75:1, right at the
WCAG AA floor, and its red drops to 3.26:1, which fails outright. One Half Dark
measures 10.48:1 for text.

More importantly, Solarized reuses the four *bright* ANSI slots as its grey
ramp — bright green is `#586E75`, a 25%-saturation grey. `zsh/themes/` sets the
clean, ahead and staged marks with `$fg_bold[green]`, which emits `\e[1;32m`,
and Windows Terminal's `intenseTextStyle` defaults to `bright`. Under Solarized
those three marks therefore render as grey at 2.79:1 rather than green. No
other scheme considered does this.

Why One Half Dark
-----------------

Chosen against two constraints: more contrast than Solarized, and a background
that is not black.

Its ground sits at 2.5% relative luminance — lighter than Solarized's 2.0%, and
well clear of Campbell, the Windows Terminal default, at 0.4%. Campbell was
rejected on a second count: its ANSI blue is `#0037DA`, only 2.38:1 against its
own background, and the theme uses non-bold blue for the changed and behind
marks.

The palette also has to survive deuteranopia. Green against red collapses in
every dark scheme tested — One Half Dark included, at ΔE 9.6 — so hue alone
cannot be trusted to separate the git marks. Blue against yellow survives at
ΔE 55.1, and blue against ordinary text at ΔE 25.1, which is why One Half Dark
was preferred over Catppuccin: Catppuccin's foreground is itself blue-tinted
(`#CDD6F4`), leaving blue marks at only ΔE 14.4 against normal text.

Font
----

Cascadia ships *inside* the Windows Terminal app package, where no other
application can see it. Windows Terminal therefore had it by default while VS
Code fell back to Consolas — two different fonts, with different glyph coverage,
rendering the same prompt. Consolas has no `✓`, `✗`, `✚` or `⨯`, so the symbols
that looked right in one terminal broke in the other.

The script installs the Nerd Font builds into
`AppData/Local/Microsoft/Windows/Fonts` and registers them under `HKCU`, which
needs no administrator rights. The NF builds are supersets of the plain ones and
identical in design, so there is nothing to gain from the smaller variant.

Both terminals are set to **Cascadia Mono NF**. Mono rather than Code because
Code has ligatures, and `!=` or `->` collapsing into one glyph is unhelpful when
reading command output verbatim. `editor.fontFamily` is deliberately left unset:
the editor shares no glyphs with the prompt, so it is free. Cascadia Code NF is
installed alongside for anyone who wants ligatures there.

Prompt glyphs
-------------

Symbols in `zsh/themes/` and `claude/statusline.zsh` must avoid codepoints with
a Unicode emoji property. Where the terminal font has no glyph, Windows falls
back to Segoe UI Emoji, which draws a double-width colour glyph into a single
cell: the symbol renders in the wrong colour and everything after it shifts a
column.

Two symbols were replaced for this reason:

| was | now | why |
| --- | --- | --- |
| `✔` U+2714 | `✓` U+2713 | U+2714 is `Emoji=Yes` and falls back; U+2713 has no emoji property |
| `⚡` U+26A1 | `✗` U+2717 | U+26A1 is `Emoji_Presentation=Yes`, so it is *always* a colour emoji |

The `⚡` in the statusline's fast-mode segment was dropped rather than replaced,
since the segments beside it (`no-think`, the effort label) carry no glyph.

Appending U+FE0E, the text-presentation variation selector, **does not work** —
Windows Terminal still renders U+2714 from the emoji font with the selector
applied. The codepoint has to change.

`✚` U+271A, `↕` U+2195 and `⨯` U+2A2F were checked and render correctly, so they
were left alone.

Two of the symbols are not in Cascadia at all — `✗` U+2717 and `✚` U+271A — and
come from Windows' fallback chain. That is fine: they resolve to a *text* font,
so they stay single-width and take the colour they are given. Only a fallback to
Segoe UI Emoji causes the double-width colour glyph this file is about. Of the
`✓`/`✗` pair, only `✓` is native; `×` U+00D7 is the natively-covered alternative
if the fallback ever stops behaving.

Shape, position, hue
--------------------

Green against red is indistinguishable under deuteranopia, so the git marks are
separated by shape and by position rather than by colour:

    <working tree>(branch)<remote>
    ●✚…(main)↑

Working-tree state sits left of the branch, remote state right of it. Nothing
has to be told apart by colour, because nothing that means different things
shares a slot.

The group on the left can carry several marks at once, and always assembles in
this order:

| mark | meaning |
| --- | --- |
| `●` | staged in the index |
| `✚` | changed in the working tree, not staged |
| `…` | untracked files present |
| `✗` | conflicts from a merge or rebase |
| `✓` | none of the above; the tree is clean |

`✓` is the odd one out: it stands in for the whole group when the group would
otherwise be empty, so it never appears beside the other four. Because it
describes the working tree alone, a clean checkout that is merely ahead reads as
`✓(main)↑` rather than hiding the tick behind the arrow.

The slot on the right always carries exactly one mark, and they read as a single
compass:

| mark | meaning |
| --- | --- |
| `↑` | ahead of the upstream |
| `↓` | behind it |
| `↕` | diverged from it |
| `—` | level with it |
| `○` | nothing to measure against |

A flat line for level and a circle for no reference point continue the arrows
rather than interrupting them, and because the slot is never empty the prompt
does not change width as the state changes. `—` is dim, being the state that
warrants least attention; `○` takes the default foreground so it stays legible.

`○` covers both "the repository has no remote" and "this branch has no
upstream". Telling those two apart would need a second git call per prompt,
which is not worth it.

The exception is the prompt marker itself, where `$` is green on success and red
on failure with no other difference. That one is still hue-only.

VS Code diff colours
--------------------

One Dark Pro never sets `diffEditor.insertedLineBackground` or its siblings, so
VS Code falls back to its own defaults, which were not designed against this
theme. The result is a heavy green wash that costs more contrast than the theme
can spare: ordinary body text drops to **4.48:1**, below the AA floor, and
`markup.quote.markdown` — already the dimmest token in the theme at `#5c6370` —
lands at **1.58:1**, which is unreadable. Markdown blockquotes inside a diff were
where this showed up first.

The second problem was invisible until measured: green added rows against red
removed rows sit **ΔE 7.5** apart under deuteranopia, near enough to identical
that the `+`/`-` gutter was doing all the work.

`windows/vscode-settings.json` therefore sets the four keys explicitly, using
One Dark's own blue and orange at a lower alpha:

| key | value |
| --- | --- |
| `diffEditor.insertedLineBackground` | `#61AFEF22` |
| `diffEditor.insertedTextBackground` | `#61AFEF2A` |
| `diffEditor.removedLineBackground` | `#D19A6622` |
| `diffEditor.removedTextBackground` | `#D19A662A` |

Body text now measures 4.84:1 on a diff row and added-versus-removed separates at
ΔE 13.2. `markup.quote.markdown` is lifted to `#abb2bf` and italicised: at that
value it matches body text, so the slant carries the hierarchy that dimness used
to — the same trade the prompt glyphs make.

Lightening the original green and red instead was measured and rejected. It
improves the text contrast but moves the two row colours *closer* together, to
ΔE 3.9, because the tint that separated them is the thing being removed.

The gutter marks (`editorGutter.addedBackground` and friends) are left alone.
They already separate acceptably at ΔE 12.7 to 17.9, and matching them naively to
the new hues would push deleted against modified down to ΔE 12.1 — one pair
better, another worse.

What the fragments manage
-------------------------

`windows/` holds only the keys worth reproducing. Everything else in the live
files is either machine-generated or already the default, and managing it would
mean fighting the applications for ownership.

**Windows Terminal.** Checked against `defaults.json` from the terminal
repository, since the copy shipped in the app package is not readable:

| key | why it is here |
| --- | --- |
| `profiles.defaults.colorScheme` | One Half Dark; see above |
| `profiles.defaults.font` | face and size, see below |
| `keybindings` | `ctrl+c` / `ctrl+v` / `alt+shift+d`, which differ from the defaults |
| `copyFormatting` | `"none"`; the default is `true` |


Deliberately not managed: `profiles.list` is regenerated by Windows Terminal from
installed distros and Store profiles, and `schemes`, `themes` and `actions` are
empty arrays that add nothing to the built-in sets — the built-ins remain
available regardless, which is why `One Half Dark` resolves with `"schemes": []`.

One caveat: `keybindings` is an array, and the merge replaces arrays wholesale,
so this file now owns that list. Add new bindings here rather than through the
settings UI, or they will be reverted on the next run.

`defaultProfile` is deliberately **not** in the fragment. Windows Terminal
identifies profiles by GUID, and the GUID the WSL package generates is derived
per installation, not from the distribution name — `uuid5` over `Ubuntu` in the
WSL generator namespace does not reproduce it, and the `--distribution-id` the
fragment passes is a random v4 GUID minted when the distro was installed.
Installing the same Debian twice produced two different profile GUIDs, which
settles it. A
hard-coded value would therefore be wrong on every other machine. Instead `set_default_profile` in the install script resolves it from the local
settings.

Candidates come from two places, and both are needed.

Profiles Windows Terminal has already written into `settings.json` carry a
`source` naming their generator: `Windows.Terminal.Wsl` for its own,
`Microsoft.WSL` for the Store WSL app. Any source containing `wsl` counts.

But `settings.json` lags behind reality. Windows Terminal discovers fragment
profiles **at startup**, and only then writes them into `settings.json`. A
terminal that was already running when a distribution was installed knows nothing
about it, so between installing a distribution and the next restart the profile
exists **only** as a fragment under `AppData/Local/Microsoft/Windows Terminal/
Fragments`.

That window is not hypothetical, it is the normal case for a second
distribution. The new profile is not in the menu yet, so the way in is `wsl -d
Debian` from a shell that already exists — and that is precisely where the
dotfiles get cloned and this script gets run. Both halves were measured:
installing Debian while the terminal was open left `settings.json` untouched,
mtime and all, and restarting the terminal wrote the profile in.

So the fragment directories under `AppData/Local` and `ProgramData` are read as
well, de-duplicated by GUID.

Among the candidates, the profile whose name equals `$WSL_DISTRO_NAME` wins — the
script runs inside the very distribution it is configuring, so that identifies
the right one even on a machine running several.

**An existing WSL default is never overridden.** Installing these dotfiles into a
second distribution — a Debian alongside Ubuntu, say — should configure that
distribution, not quietly promote it over the one already in use. If
`defaultProfile` already names any WSL profile, the script reports it and moves
on.

Otherwise, with one candidate it is chosen; with several the script asks, listing
them and marking the one this shell is running in as the default answer. Anything
that is not a listed number leaves the key alone rather than guessing, and when
there is no terminal to ask on it falls back to the running distribution. On a
machine with no WSL profile at all the key is left alone, so a default is never
invented.

Passing `--choose-default` re-opens that question even when a WSL profile is
already the default.

The colour scheme and font need no equivalent handling: they live in
`profiles.defaults`, which applies to every profile Windows Terminal knows about,
so a newly installed distribution picks them up as soon as its profile exists.

**Font size.** The WSL fragment that Windows installs contributes per-profile
settings to the Ubuntu profile, including `"font": {"face": "Ubuntu Mono", "size":
13}`. A user's `profiles.defaults` overrides those, but *key by key*: setting only
`face` left `size` inherited from the fragment. Size is pinned here so the
appearance does not depend on what that package happens to specify.

Worth knowing that Ubuntu Mono carries 1242 glyphs and has none of `✓ ✗ ✚ ● ○ ↕
⨯`, so if that fragment ever did win, every prompt symbol would come from the
fallback chain.

**VS Code.** No equivalent defaults file to diff against; extension-contributed
defaults were read from each extension's `package.json`. The fragment carries the
theme, the terminal font, the diff colours above, the `claudeCode.*` preferences
and two editor settings. `editor.unicodeHighlight.nonBasicASCII` is the one that
looks unrelated and is not: left at its default, VS Code boxes every non-ASCII
character as a possible homoglyph, which means every symbol in the theme files.
