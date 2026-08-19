Terminal rendering on Windows
=============================

Windows Terminal and VS Code share one colour scheme (**One Half Dark**) and one
terminal font (**Cascadia Mono NF**), both installed by
`bin/install-windows-config`.

    ./bin/install-windows-config

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
