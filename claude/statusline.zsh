#!/usr/bin/env zsh
#
# Claude Code status line, in two rows:
#
#   [namespace/project] ~/relative/path                  ✓(main)↑ [14:32]
#   Opus 5 · high · ▓▓▓░░░░░░░ 32%  24% (1h47m) · 41% (3d4h)       🐳🔑
#
# The first row is laid out like the prompt — where we are on the left, the
# state on the right — and shows the same project label, the same git symbols
# and the same clock, so the two read alike. The second is what only Claude
# Code knows: the model, the context window, and how much of the
# subscription's rate limit windows is gone. The five hour window comes first,
# the seven day one second; they go unlabelled. Its right hand end carries the
# two service markers, which say that docker and the ssh agent are answering by
# being there at all.
#
# Claude Code pipes a JSON object on stdin, runs us after every assistant
# message and on the refreshInterval timer, and kills us if the next update
# arrives while we are still going. That budget is what shapes the script: one
# git call, and nothing else in the foreground. The service checks and the git
# fetch all happen in detached processes and are read from their results on a
# later run.

emulate -L zsh
setopt extendedglob

zmodload zsh/datetime

# Everything that makes the prompt say [namespace/project] rather than a plain
# path. Optional: without it we fall back to the path alone.
() {
  local platform="${ZSH:-$HOME/.zsh}/functions/00-platform"
  [[ -r $platform ]] && source $platform
}

###
### Palette
###

# Row one mirrors the zsh theme's colours exactly, so a repository looks the
# same in both places. Row one's docker marker and row two's gauges share the
# ok/warn/alert ramp.
if [[ -n $NO_COLOR ]]; then
  C_RESET='' C_STAGED='' C_CHANGED='' C_UNTRACKED='' C_CLEAN=''
  C_AHEAD='' C_BEHIND='' C_DIVERGED='' C_CONFLICT=''
  C_SYNCED='' C_NO_UPSTREAM='' C_OK='' C_WARN='' C_ALERT='' C_DIM=''
else
  C_RESET=$'\e[0m'
  C_STAGED=$'\e[1;32m'      # bold green ●
  C_CHANGED=$'\e[0;34m'     # blue ✚
  C_UNTRACKED=$'\e[1;31m'   # bold red …
  C_CLEAN=$'\e[1;32m'       # bold green ✓
  C_AHEAD=$'\e[1;32m'       # bold green ↑
  C_BEHIND=$'\e[0;34m'      # blue ↓
  C_DIVERGED=$'\e[1;31m'    # bold red ↕
  C_CONFLICT=$'\e[1;31m'    # bold red ✗
  C_SYNCED=$'\e[2m'         # dim — , being level warrants least attention
  C_NO_UPSTREAM=''          # ○ takes the default foreground, so it stays legible
  C_OK=$'\e[0;32m'
  C_WARN=$'\e[0;33m'
  C_ALERT=$'\e[1;31m'
  C_DIM=$'\e[2m'
fi

# How long a service answer is trusted before a background process re-asks.
SERVICE_CACHE_TTL=20

# The two service markers on row two.
#
# Emoji, against the rule in docs/windows-rendering.md, because they are the
# only pictograms this terminal draws at all: ⧉ and ⚿ come out as tofu, and
# Nerd Font icons render as nothing. What the rule warns about costs us little
# here. The colour is fixed by the emoji font and ANSI cannot touch it, but
# these markers carry their meaning by being present, not by their hue. They
# are also two cells wide while counting as one character, which visible_width
# knows about, and they sit last on their row, so the column they shift is
# nobody's.
DOCKER_GLYPH=$'\U1F433'   # spouting whale, the docker one
SSH_GLYPH=$'\U1F511'      # key

# How often a repository may be fetched in the background. The zsh theme's
# ZSH_THEME_GIT_FETCH_INTERVAL, so the two throttle alike.
GIT_FETCH_INTERVAL=300

# Columns left free at the right edge of both rows.
#
# $COLUMNS is the whole terminal, but the status line renders inside the
# interface's own frame, which indents it on both sides by an amount it does not
# tell us. Anything past that frame is cut and replaced by an ellipsis, and the
# clock is last, so it is the clock that loses its digits.
#
# The two failure modes are not symmetric: too small truncates, too large only
# leaves a slightly wider gap before the right hand group. 3 was measured on a fullscreen
# terminal and still clipped the clock, so 4 it is; raise it again if it ever
# comes back.
ROW_RIGHT_MARGIN=4

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"

###
### Helpers
###

# $2 copies of $1. Spelled out rather than done with the (l) padding flag,
# whose pad argument is taken literally: a `$char` in there pads with the four
# characters of the name, not with what the variable holds.
function repeat_string() {
  local char=$1 out=""
  local -i width=$2 i

  for (( i = 0; i < width; i++ )); do
    out+=$char
  done

  print -rn -- "$out"
}

# Width of $1 on screen: its length with the ANSI escapes taken out, plus one
# for each of the double-width glyphs, which zsh counts as one character and
# the terminal draws in two cells. Only the glyphs this script prints itself
# need to be known here.
function visible_width() {
  local plain=${1//$'\e'\[[0-9;]#m/}
  local narrow=${plain//[$DOCKER_GLYPH$SSH_GLYPH]/}
  local -i wide=$(( ${#plain} - ${#narrow} ))

  print -r -- $(( ${#plain} + wide ))
}

# $1 seconds as a short human duration: 3d4h, 1h47m, 12m.
function short_duration() {
  local -i seconds=$1 days hours minutes

  (( seconds < 0 )) && seconds=0

  days=$(( seconds / 86400 ))
  hours=$(( seconds % 86400 / 3600 ))
  minutes=$(( seconds % 3600 / 60 ))

  if (( days )); then
    print -r -- "${days}d${hours}h"
  elif (( hours )); then
    print -r -- "${hours}h${minutes}m"
  else
    print -r -- "${minutes}m"
  fi
}

# The ok/warn/alert colour for a percentage, with the thresholds as $2 and $3.
function gauge_color() {
  local -i value=$1 warn=$2 alert=$3

  if (( value >= alert )); then
    print -r -- $C_ALERT
  elif (( value >= warn )); then
    print -r -- $C_WARN
  else
    print -r -- $C_OK
  fi
}

# Run the check $2... in the background and leave its verdict in the cache file
# $1, for whichever run of this script comes next.
#
# Detached on purpose: an unresponsive docker daemon, or an ssh agent whose
# relay has lost the pipe behind it, would otherwise stall every redraw, and a
# status line that takes longer than the gap between two assistant messages is
# a status line that never gets to print. The exit status is the whole verdict,
# which matters for docker in particular: under WSL its client prints its
# complaints on stdout rather than stderr, so the output cannot be trusted.
function refresh_service_cache() {
  local cache=$1
  shift
  local lock="$cache.lock"
  local -a limit

  # Reclaim a lock left behind by a check that was killed.
  [[ -n "$lock"(#qNmm+1) ]] && rmdir "$lock" 2>/dev/null

  # mkdir is atomic, so this doubles as the "already checking" test.
  mkdir "$lock" 2>/dev/null || return 0

  (( $+commands[timeout] )) && limit=( timeout 5 )

  # Detaching is not enough on its own: a child that keeps our stdout open
  # keeps whoever reads it waiting for the pipe to close, which would hand the
  # status line exactly the delay this whole arrangement exists to avoid. The
  # verdict goes to the cache file, so the child needs no output of its own.
  (
    local state=down

    $limit "$@" && state=up

    print -r -- $state >| "$cache"
    rmdir "$lock" 2>/dev/null
  ) >/dev/null 2>&1 &!
}

# Whether the service named $1 was up when it was last asked: up, down, or
# nothing at all before the first background check has come back. $2... is the
# command that answers that, and its verdict is trusted for SERVICE_CACHE_TTL
# seconds.
function service_state() {
  local name=$1
  shift
  local cache="$CACHE_DIR/$name"

  [[ -d $CACHE_DIR ]] || mkdir -p $CACHE_DIR 2>/dev/null || return 0

  [[ -n "$cache"(#qNms-$SERVICE_CACHE_TTL) ]] || refresh_service_cache "$cache" "$@"

  [[ -r $cache ]] && print -r -- "$(<$cache)"
}

###
### Row one
###

# The project label and the path to show, in $reply. The label is empty outside
# a project, where the path is the plain ~-relative one the prompt falls back
# to.
function status_path() {
  local dir=$1 root

  reply=( "" "${dir/#$HOME/~}" )

  (( $+functions[_project_root] )) || return 0
  root=$(_project_root "$dir") || return 0

  reply=( "$(_project_label "$root" /)" "${dir/#$root/~}" )
}

# Git state as <worktree>(branch)<remote>, from the one `git status` call that
# answers everything: the branch, the working tree, and the position relative to
# the upstream. Working-tree state sits left of the branch and remote state sits
# right of it, so the two never have to be told apart by colour. Same reading as
# the zsh theme, symbol for symbol.
#
# Reads only what is already on disk; fetch_git_repository is what keeps that
# fresh, and its result shows up here on a later run.
function status_git() {
  local dir=$1
  local output line branch ab
  local staged changed untracked conflict
  local worktree="" remote=""

  output=$(git -C "$dir" status --porcelain=v2 --branch 2>/dev/null) || return 1

  for line in ${(f)output}; do
    case $line in
      ('# branch.head '*) branch=${line#\# branch.head } ;;
      ('# branch.ab '*)   ab=${line#\# branch.ab } ;;
      # XY field of a changed entry: X is the index, Y the working tree.
      ([12]' '*)
        [[ ${line[3]} == [^.] ]] && staged=1
        [[ ${line[4]} == [^.] ]] && changed=1
        ;;
      ('u '*) conflict=1 ;;
      ('? '*) untracked=1 ;;
    esac
  done

  # Left of the branch: the state of the working tree.
  [[ -n $staged ]]    && worktree+="${C_STAGED}●${C_RESET}"
  [[ -n $changed ]]   && worktree+="${C_CHANGED}✚${C_RESET}"
  [[ -n $untracked ]] && worktree+="${C_UNTRACKED}…${C_RESET}"
  [[ -n $conflict ]]  && worktree+="${C_CONFLICT}✗${C_RESET}"

  # Clean describes the working tree alone, so that a tidy checkout that is
  # merely ahead still reads as clean.
  [[ -z $worktree ]] && worktree="${C_CLEAN}✓${C_RESET}"

  # Right of the branch: where we stand against the upstream. branch.ab is
  # "+<ahead> -<behind>", and absent whenever the branch tracks nothing --
  # either the repository has no remote, or this branch has no upstream set.
  # Telling those two apart would cost a second git call, which is not worth it.
  if [[ -z $ab ]]; then
    remote="${C_NO_UPSTREAM}○${C_RESET}"
  else
    local ahead=${${ab%% *}#+} behind=${${ab##* }#-}

    if (( ahead && behind )); then
      remote="${C_DIVERGED}↕${C_RESET}"
    elif (( ahead )); then
      remote="${C_AHEAD}↑${C_RESET}"
    elif (( behind )); then
      remote="${C_BEHIND}↓${C_RESET}"
    else
      remote="${C_SYNCED}—${C_RESET}"
    fi
  fi

  # (detached) is what porcelain=v2 reports for a detached HEAD.
  print -r -- "${worktree}(${branch})${remote}"
}

# Bring the current repository's remote-tracking refs up to date, so that the
# ahead and behind arrows stay honest.
#
# The theme fetches too, but only from TRAPALRM, and zsh arms that alarm solely
# while a shell waits at a prompt. The shell that launched Claude Code is blocked
# on a foreground command for the whole session and so never fires it: without
# this, ↑ and ↓ freeze at whatever they were when the session started. A shell
# idling elsewhere in the same repository still helps, which is what the shared
# lock below is for.
#
# Everything past the throttle happens in a detached subshell, resolving the
# repository root included, so a run that does not fetch costs no git process at
# all. The fetch must never make the status line wait, and must never be able to
# ask for a password. Its stdout is closed for the same reason as the service
# checks': a child holding that pipe open is a reader kept waiting.
function fetch_git_repository() {
  local dir=$1
  local stamp_dir="$CACHE_DIR/git-fetch"
  local stamp="$stamp_dir/${dir//\//%}"

  [[ -d $stamp_dir ]] || mkdir -p $stamp_dir 2>/dev/null || return 0

  # Keyed by the directory, not by the repository root, which it would take a
  # git process to learn. The lock below is keyed by the root, so two
  # subdirectories of one repository still cannot fetch at the same time.
  [[ -n "$stamp"(#qNms-$GIT_FETCH_INTERVAL) ]] && return 0

  # Stamp the attempt rather than the success: a repository with no remote, or
  # one behind an unreachable host, must not be retried on every redraw.
  : >| "$stamp"

  (
    local root lock_dir lock

    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0

    # Nothing to fetch without a remote.
    [[ -n "$(git -C "$root" remote 2>/dev/null)" ]] || exit 0

    # The theme's lock directory, under the theme's name for it, so that the two
    # can never fetch one repository at once.
    lock_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-git-fetch"
    lock="$lock_dir/${root//\//%}.lock"

    [[ -d $lock_dir ]] || mkdir -p $lock_dir 2>/dev/null || exit 0

    # Reclaim a lock left behind by a fetch that was killed.
    [[ -n "$lock"(#qNmm+10) ]] && rmdir "$lock" 2>/dev/null

    # mkdir is atomic, so this doubles as the "already fetching" check.
    mkdir "$lock" 2>/dev/null || exit 0

    GIT_TERMINAL_PROMPT=0 \
    GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5' \
      git -C "$root" fetch --quiet --prune --no-tags

    rmdir "$lock" 2>/dev/null
  ) >/dev/null 2>&1 &!
}

###
### Row two
###

# The whale, while the docker daemon answers, and nothing when it does not.
# Silent too when docker is not installed at all, and until the first
# background check comes back.
#
# `docker version` is the cheapest command that talks to the server.
function status_docker() {
  (( $+commands[docker] )) || return 0

  [[ "$(service_state docker docker version --format '{{.Server.Version}}')" == up ]] || return 0

  print -r -- "$DOCKER_GLYPH"
}

# The key, while the ssh agent answers and holds at least one key.
#
# `ssh-add -l` exits 0 with keys, 1 for an agent that answers but is empty, and
# 2 when there is no agent to reach. Only the first earns the marker: a
# Bitwarden vault that has locked itself leaves the relay up and the agent
# empty, and that is precisely when pushing starts to fail.
#
# Nothing here knows which agent it is talking to, which is the point: the
# Bitwarden relay under WSL and the keychain-held agent everywhere else both
# answer on $SSH_AUTH_SOCK, inherited from the shell that started Claude Code.
function status_ssh_agent() {
  (( $+commands[ssh-add] )) || return 0

  [[ "$(service_state ssh-agent ssh-add -l)" == up ]] || return 0

  print -r -- "$SSH_GLYPH"
}

# A ten block bar for the share of the context window in use.
function status_context() {
  local -i pct=$1 width=10 filled empty
  local color

  filled=$(( pct * width / 100 ))
  (( filled > width )) && filled=$width
  empty=$(( width - filled ))

  color=$(gauge_color $pct 60 80)

  print -r -- "${color}$(repeat_string ▓ $filled)${C_DIM}$(repeat_string ░ $empty)${C_RESET} ${color}${pct}%${C_RESET}"
}

# One rate limit window as "24% (1h47m)", or nothing when Claude Code did not
# send it. It only sends these for Claude.ai subscriptions, and only once the
# session has had an API response back.
#
# The windows go unlabelled and are told apart by their order, the five hour one
# first. The reset is parenthesised rather than marked with an arrow: ↻ and its
# neighbours are missing from enough terminal fonts to come out as a box.
function status_rate_limit() {
  local percentage=$1 resets_at=$2
  local color

  [[ -n $percentage ]] || return 0

  local -i pct=${percentage%%.*}

  color=$(gauge_color $pct 50 80)

  local out="${color}${pct}%${C_RESET}"

  [[ -n $resets_at ]] && out+=" ${C_DIM}($(short_duration $(( resets_at - EPOCHSECONDS ))))${C_RESET}"

  print -r -- "$out"
}

###
### Assemble
###

if (( ! $+commands[jq] )); then
  print -r -- "${C_ALERT}statusline: jq is not installed${C_RESET}"
  exit 1
fi

input=$(cat)

# One jq call for everything, one field per line. The trailing "." is a
# sentinel: command substitution eats trailing newlines, and without it an
# absent last field would shift nothing but would also be indistinguishable
# from a truncated read.
fields=$(jq -r '
  [ .workspace.current_dir // .cwd // "",
    .model.display_name // "",
    .effort.level // "",
    (.fast_mode | if . == null then false else . end | tostring),
    (.thinking.enabled | if . == null then true else . end | tostring),
    (.context_window.used_percentage // 0 | floor | tostring),
    (.rate_limits.five_hour.used_percentage // "" | tostring),
    (.rate_limits.five_hour.resets_at // "" | tostring),
    (.rate_limits.seven_day.used_percentage // "" | tostring),
    (.rate_limits.seven_day.resets_at // "" | tostring),
    "."
  ] | .[]' <<<"$input" 2>/dev/null) || exit 1

typeset -a field
field=( "${(@f)fields}" )

dir=${field[1]:-$PWD}
model=${field[2]}
effort=${field[3]}
fast_mode=${field[4]}
thinking=${field[5]}
context_pct=${field[6]}
five_hour_pct=${field[7]}
five_hour_reset=${field[8]}
seven_day_pct=${field[9]}
seven_day_reset=${field[10]}

# Row one, laid out like the prompt: where we are on the left, the state on the
# right, as PROMPT and RPROMPT are in the zsh theme. The right hand group ends
# with the clock, in the same brackets and to the same minute.

status_path "$dir"
project_label=$reply[1]
project_path=$reply[2]

git_segment=$(status_git "$dir")

# An empty git segment means this is not a repository, which saves the fetch a
# pointless fork. What it brings back lands on a later redraw, not this one.
[[ -n $git_segment ]] && fetch_git_repository "$dir"

typeset -a right_segments
[[ -n $git_segment ]] && right_segments+=( "$git_segment" )
right_segments+=( "[$(strftime '%H:%M' $EPOCHSECONDS)]" )

row_one_right="${(j: :)right_segments}"

# The left hand group, in the three forms it takes as the terminal narrows: the
# whole path, its last component, then nothing but the project label.
function path_group() {
  local label="${project_label:+${C_DIM}[${C_RESET}${project_label}${C_DIM}]${C_RESET}}"

  case $1 in
    (full)  print -r -- "${label:+$label }${project_path}" ;;
    (leaf)  print -r -- "${label:+$label }…/${project_path:t}" ;;
    (label) print -r -- "${label:-${project_path:t}}" ;;
  esac
}

# Claude Code exports the terminal size before running us; it cannot be read
# any other way from here, as our stdout is a pipe. Give up the path before the
# git state, which is the part worth keeping.
row_one_left=$(path_group full)
row_one_gap=0
row_one_width=$(( ${COLUMNS:-0} - ROW_RIGHT_MARGIN ))

if (( row_one_width > 0 )); then
  for form in full leaf label; do
    row_one_left=$(path_group $form)
    row_one_gap=$((
      row_one_width - $(visible_width "$row_one_left") - $(visible_width "$row_one_right")
    ))

    (( row_one_gap >= 2 )) && break
  done
fi

if (( row_one_gap >= 2 )); then
  print -r -- "${row_one_left}$(repeat_string ' ' $row_one_gap)${row_one_right}"
else
  # Nothing fits; two spaces is all the separation there is room for.
  print -r -- "${row_one_left}  ${row_one_right}"
fi

# Row two.

typeset -a session_segments

[[ -n $model ]]        && session_segments+=( "$model" )
[[ -n $effort ]]       && session_segments+=( "${C_DIM}${effort}${C_RESET}" )
[[ $fast_mode == true ]] && session_segments+=( "${C_WARN}fast${C_RESET}" )
[[ $thinking == false ]] && session_segments+=( "${C_DIM}no-think${C_RESET}" )

session_segments+=( "$(status_context $context_pct)" )

typeset -a limit_segments
limit_segments+=( ${(f)"$(status_rate_limit "$five_hour_pct" "$five_hour_reset")"} )
limit_segments+=( ${(f)"$(status_rate_limit "$seven_day_pct" "$seven_day_reset")"} )

row_two_left="${(j: · :)session_segments}"
(( $#limit_segments )) && row_two_left+="  ${(j: · :)limit_segments}"

# The service markers, at the right hand end of row two, run together as one
# block. Each is there or it is not; nothing takes their place when a service
# is down, which is why they can be dropped whole when the terminal is too
# narrow to hold them.
typeset -a service_segments
service_segments+=( ${(f)"$(status_docker)"} )
service_segments+=( ${(f)"$(status_ssh_agent)"} )

row_two_right="${(j::)service_segments}"
row_two_gap=0

if [[ -n $row_two_right ]]; then
  row_two_gap=$((
    ${COLUMNS:-0} - ROW_RIGHT_MARGIN
      - $(visible_width "$row_two_left") - $(visible_width "$row_two_right")
  ))
fi

if (( row_two_gap >= 2 )); then
  print -r -- "${row_two_left}$(repeat_string ' ' $row_two_gap)${row_two_right}"
else
  # No room for the markers on their own side of the row, so they go
  # unreported rather than crowding what row two is mainly for.
  print -r -- "$row_two_left"
fi
