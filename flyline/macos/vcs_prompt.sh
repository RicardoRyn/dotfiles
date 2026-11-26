#!/usr/bin/env bash
#
# jj_prompt.sh — starship-compatible Jujutsu (jj) prompt segments, in pure bash.
#
# Emulates four starship modules, in starship's default order:
#
#   jj_bookmark   "on  <bookmark>@<remote>* (+N others) "
#   jj_change     "<change-id> "   (unique prefix bold, remaining chars dimmed)
#   jj_metrics    "+<added> -<deleted> "
#   jj_status     "[!◌+=✘~»] "
#
# When the current directory is not inside a jj workspace, falls back to
# starship's git modules:
#
#   git_branch    "on  <branch> "
#   git_metrics   "+<added> -<deleted> "
#   git_status    "[=!✘»!+?] "  (conflicted, stashed, deleted, renamed, modified, staged, untracked, ahead/behind)
#
# Like starship, it runs exactly ONE `jj show` per invocation, with a template
# that emits TOML-ish `current.*` / `parents.*` lines which are parsed here.
# The git fallback uses `git status --porcelain=2 --branch` and `git diff --shortstat`.
#
# Usage:
#   jj_prompt.sh            print the segments (nothing when not in any repo)
#   jj_prompt.sh --help     show every option and environment variable
#
# Starship integration (starship.toml):
#   [custom.jj]
#   command = "/absolute/path/to/jj_prompt.sh"
#   when = true
#   format = "$output"
#
# Shell integration:
#   PROMPT_COMMAND='PS1_PREFIX=$(jj_prompt.sh)'
#
# Exit status: 0 normally, 0 when not inside any repo (prints nothing),
# 2 on bad usage. Never fails a prompt.
#
# Requires: bash 3.2+ (macOS default) and a fairly recent jj — the template uses
# json(), stringify(), file.status_char() and --no-integrate-operation.
# Verified byte-for-byte against starship 1.27.0 and jj 0.47.1.

# ---------------------------------------------------------------------------
# Configuration (environment variables, all optional)
# ---------------------------------------------------------------------------

JJ_BIN=${JJ_BIN:-jj}
JJ_REVSET=${JJ_REVSET:-'@ | latest(heads(mutable() & ::@ & conflicts()), 1) | latest(bookmarks() & ::@, 1)'}

# auto | always | never  (auto = on unless NO_COLOR is set)
JJ_COLOR=${JJ_COLOR:-auto}

# 1/0 per segment
JJ_SHOW_BOOKMARK=${JJ_SHOW_BOOKMARK:-1}
JJ_SHOW_CHANGE=${JJ_SHOW_CHANGE:-1}
JJ_SHOW_METRICS=${JJ_SHOW_METRICS:-1}
JJ_SHOW_STATUS=${JJ_SHOW_STATUS:-1}

# jj_change: total characters shown = max(unique prefix, this)
JJ_HASH_LENGTH=${JJ_HASH_LENGTH:-7}
# jj_change: also append "(commit-id)" after the change id
JJ_SHOW_COMMIT=${JJ_SHOW_COMMIT:-0}

# jj_bookmark
JJ_BOOKMARK_SYMBOL=${JJ_BOOKMARK_SYMBOL-$(printf ' ')}
JJ_BOOKMARK_DIVERGED_SYMBOL=${JJ_BOOKMARK_DIVERGED_SYMBOL:-*}
JJ_BOOKMARK_IGNORE_NAMES=${JJ_BOOKMARK_IGNORE_NAMES:-}
JJ_BOOKMARK_IGNORE_REMOTES=${JJ_BOOKMARK_IGNORE_REMOTES:-}
# 0 = no truncation (starship: truncate_text with length 0 is a no-op too)
JJ_BOOKMARK_TRUNCATION_LENGTH=${JJ_BOOKMARK_TRUNCATION_LENGTH:-0}
JJ_BOOKMARK_TRUNCATION_SYMBOL=${JJ_BOOKMARK_TRUNCATION_SYMBOL:-…}

# Styles, starship syntax ("bold purple", "green bold", "dimmed", ...)
JJ_BOOKMARK_STYLE=${JJ_BOOKMARK_STYLE:-bold purple}
JJ_CHANGE_PREFIX_STYLE=${JJ_CHANGE_PREFIX_STYLE:-green bold}
JJ_CHANGE_SUFFIX_STYLE=${JJ_CHANGE_SUFFIX_STYLE:-dimmed}
JJ_CHANGE_OFFSET_STYLE=${JJ_CHANGE_OFFSET_STYLE:-bold}
JJ_METRICS_ADDED_STYLE=${JJ_METRICS_ADDED_STYLE:-bold green}
JJ_METRICS_DELETED_STYLE=${JJ_METRICS_DELETED_STYLE:-bold red}
JJ_STATUS_STYLE=${JJ_STATUS_STYLE:-bold yellow}

# jj_status: per-symbol format, `$count` is replaced by the file count
JJ_STATUS_CONFLICTED=${JJ_STATUS_CONFLICTED:-!}
JJ_STATUS_DESCRIPTION_EMPTY=${JJ_STATUS_DESCRIPTION_EMPTY:-◌}
JJ_STATUS_DESCRIPTION_PRESENT=${JJ_STATUS_DESCRIPTION_PRESENT:-}
JJ_STATUS_HIDDEN=${JJ_STATUS_HIDDEN:-}
JJ_STATUS_IMMUTABLE=${JJ_STATUS_IMMUTABLE:-◆}
JJ_STATUS_ADDED=${JJ_STATUS_ADDED:-+}
JJ_STATUS_COPIED=${JJ_STATUS_COPIED:-=}
JJ_STATUS_DELETED=${JJ_STATUS_DELETED:-✘}
JJ_STATUS_MODIFIED=${JJ_STATUS_MODIFIED:-'~'}
JJ_STATUS_RENAMED=${JJ_STATUS_RENAMED:-»}

# Escape hatch for prompt latency: 1 = pass --ignore-working-copy (status/metrics
# then lag by one jj command). Starship does NOT do this; it needs the snapshot.
JJ_NO_SNAPSHOT=${JJ_NO_SNAPSHOT:-0}

# Advanced/testing: if set, parse this raw template output instead of running jj.
JJ_RAW=${JJ_RAW:-}

# Git fallback (used when the current directory is not inside a jj workspace)
GIT_BIN=${GIT_BIN:-git}
GIT_SHOW_BRANCH=${GIT_SHOW_BRANCH:-1}
GIT_SHOW_METRICS=${GIT_SHOW_METRICS:-1}
GIT_SHOW_STATUS=${GIT_SHOW_STATUS:-1}

GIT_BRANCH_SYMBOL=${GIT_BRANCH_SYMBOL-$(printf ' ')}
GIT_BRANCH_STYLE=${GIT_BRANCH_STYLE:-bold purple}
GIT_METRICS_ADDED_STYLE=${GIT_METRICS_ADDED_STYLE:-bold green}
GIT_METRICS_DELETED_STYLE=${GIT_METRICS_DELETED_STYLE:-bold red}
GIT_STATUS_STYLE=${GIT_STATUS_STYLE:-bold yellow}
GIT_STATUS_CONFLICTED=${GIT_STATUS_CONFLICTED:-=}
GIT_STATUS_STASHED=${GIT_STATUS_STASHED:-\$}
GIT_STATUS_DELETED=${GIT_STATUS_DELETED:-✘}
GIT_STATUS_RENAMED=${GIT_STATUS_RENAMED:-»}
GIT_STATUS_MODIFIED=${GIT_STATUS_MODIFIED:-!}
GIT_STATUS_STAGED=${GIT_STATUS_STAGED:-+}
GIT_STATUS_UNTRACKED=${GIT_STATUS_UNTRACKED:-\?}
GIT_STATUS_AHEAD=${GIT_STATUS_AHEAD:-⇡}
GIT_STATUS_BEHIND=${GIT_STATUS_BEHIND:-⇣}
GIT_STATUS_DIVERGED=${GIT_STATUS_DIVERGED:-⇕}

# Advanced/testing: if set, use these instead of running git commands.
GIT_RAW_STATUS=${GIT_RAW_STATUS:-}
GIT_RAW_DIFF=${GIT_RAW_DIFF:-}

# ---------------------------------------------------------------------------
# Helpers: colors and starship-style style strings
# ---------------------------------------------------------------------------

RESET=$(printf '\033[0m')

usage() {
  cat <<'EOF'
jj_prompt.sh — starship-compatible jj prompt segments in bash

USAGE
  jj_prompt.sh [--help]

  Prints, on one line: jj_bookmark, jj_change, jj_metrics, jj_status —
  using starship's default formats, styles and symbols. When the current
  directory is not inside a jj workspace, falls back to git_branch,
  git_metrics and git_status (mirroring starship's git modules).

OPTIONS
  -h, --help                 show this help

ENVIRONMENT
  Output & speed
    JJ_COLOR=auto|always|never   auto = on unless NO_COLOR is set
    JJ_NO_SNAPSHOT=1              --ignore-working-copy: faster, but status/metrics lag
    JJ_REVSET=<revset>            override the revset (default: starship's)
    JJ_BIN=jj                     jj executable

  Segments (1/0)
    JJ_SHOW_BOOKMARK  JJ_SHOW_CHANGE  JJ_SHOW_METRICS  JJ_SHOW_STATUS

  jj_change
    JJ_HASH_LENGTH=7              chars shown, min = unique prefix length
    JJ_SHOW_COMMIT=1              append "(<commit-id>)" after the change id
    JJ_CHANGE_PREFIX_STYLE="green bold"
    JJ_CHANGE_SUFFIX_STYLE="dimmed"
    JJ_CHANGE_OFFSET_STYLE="bold"

  jj_bookmark
    JJ_BOOKMARK_SYMBOL=" "        prefix symbol (default: nerd-font branch)
    JJ_BOOKMARK_DIVERGED_SYMBOL="*"
    JJ_BOOKMARK_IGNORE_NAMES="main master"
    JJ_BOOKMARK_IGNORE_REMOTES="upstream"
    JJ_BOOKMARK_TRUNCATION_LENGTH=0    0 = off, else truncate to N chars
    JJ_BOOKMARK_TRUNCATION_SYMBOL="…"
    JJ_BOOKMARK_STYLE="bold purple"

  jj_metrics
    JJ_METRICS_ADDED_STYLE="bold green"
    JJ_METRICS_DELETED_STYLE="bold red"

  jj_status
    JJ_STATUS_STYLE="bold red"
    JJ_STATUS_CONFLICTED="!"       JJ_STATUS_DESCRIPTION_EMPTY="◌"
    JJ_STATUS_DESCRIPTION_PRESENT=""  JJ_STATUS_HIDDEN=""
    JJ_STATUS_IMMUTABLE="◆"        JJ_STATUS_ADDED="+"
    JJ_STATUS_COPIED="="           JJ_STATUS_DELETED="✘"
    JJ_STATUS_MODIFIED="~"         JJ_STATUS_RENAMED="»"
    Symbols support $count, e.g. JJ_STATUS_MODIFIED='~$count'

  Git fallback (when not in a jj workspace)
    GIT_BIN=git                     git executable
    GIT_SHOW_BRANCH  GIT_SHOW_METRICS  GIT_SHOW_STATUS  (1/0)

    GIT_BRANCH_SYMBOL=" "        GIT_BRANCH_STYLE="bold purple"
    GIT_METRICS_ADDED_STYLE="bold green"
    GIT_METRICS_DELETED_STYLE="bold red"
    GIT_STATUS_STYLE="bold red"
    GIT_STATUS_CONFLICTED="="       GIT_STATUS_STASHED="$"
    GIT_STATUS_DELETED="✘"         GIT_STATUS_RENAMED="»"
    GIT_STATUS_MODIFIED="!"        GIT_STATUS_STAGED="+"
    GIT_STATUS_UNTRACKED="?"       GIT_STATUS_AHEAD="⇡"
    GIT_STATUS_BEHIND="⇣"          GIT_STATUS_DIVERGED="⇕"

EXAMPLES
  JJ_BOOKMARK_IGNORE_NAMES="main" jj_prompt.sh
  JJ_STATUS_HIDDEN='👻' JJ_STATUS_DESCRIPTION_PRESENT='󰏭 ' jj_prompt.sh
  NO_COLOR=1 jj_prompt.sh | cat -v

TESTING
  JJ_RAW="<raw template output>"   skip jj and parse the given TOML-ish text
  GIT_RAW_STATUS="..." GIT_RAW_DIFF="..."  skip git and use given output
EOF
}

case ${1:-} in
-h | --help)
  usage
  exit 0
  ;;
"") : ;;
*)
  printf 'jj_prompt.sh: unknown argument: %s (try --help)\n' "$1" >&2
  exit 2
  ;;
esac

color_wanted() {
  case $JJ_COLOR in
  never | 0 | no | off) return 1 ;;
  always | 1 | yes | on | force) return 0 ;;
  esac
  [ -z "${NO_COLOR:-}" ]
}

if color_wanted; then
  COLOR=1
else
  COLOR=0
fi

# sgr "bold purple" -> ESC[1;35m (prints nothing for an empty/unknown style)
sgr() {
  local style=$1 word mods="" col="" rgb code=""
  local IFS=$' \t'
  set -f
  for word in $style; do
    word=${word//_/-}
    case $word in
    bold | strong) mods="$mods;1" ;;
    dimmed | dim | faint) mods="$mods;2" ;;
    italic) mods="$mods;3" ;;
    underline | underlined) mods="$mods;4" ;;
    blink) mods="$mods;5" ;;
    reverse | reversed | invert) mods="$mods;7" ;;
    hidden) mods="$mods;8" ;;
    strikethrough | striked) mods="$mods;9" ;;
    black) col="30" ;;
    red) col="31" ;;
    green) col="32" ;;
    yellow) col="33" ;;
    blue) col="34" ;;
    purple | magenta) col="35" ;;
    cyan) col="36" ;;
    white) col="37" ;;
    bright-black | gray | grey) col="90" ;;
    bright-red) col="91" ;;
    bright-green) col="92" ;;
    bright-yellow) col="93" ;;
    bright-blue) col="94" ;;
    bright-purple | bright-magenta) col="95" ;;
    bright-cyan) col="96" ;;
    bright-white) col="97" ;;
    '#'??????)
      rgb=${word#\#}
      col="38;2;$((16#${rgb:0:2}));$((16#${rgb:2:2}));$((16#${rgb:4:2}))"
      ;;
    [0-9] | [0-9][0-9] | [0-9][0-9][0-9]) col="38;5;$word" ;;
    none | "") : ;;
    esac
  done
  set +f
  mods=${mods#;}
  # Same byte order as starship/nu-ansi-term: attributes first, then color.
  [ -n "$mods" ] && code=$mods
  [ -n "$col" ] && code="${code:+$code;}$col"
  [ -n "$code" ] && printf '\033[%sm' "$code"
}

# paint <style> <text>: styled text, or plain text when colors are off
paint() {
  local style=$1 text=$2 code
  if [ -z "$text" ]; then
    return 0
  fi
  [ "$COLOR" = 1 ] || {
    printf '%s' "$text"
    return 0
  }
  code=$(sgr "$style")
  if [ -n "$code" ]; then
    printf '%s%s%s' "$code" "$text" "$RESET"
  else
    printf '%s' "$text"
  fi
}

# ---------------------------------------------------------------------------
# Helpers: text / number / json-array handling
# ---------------------------------------------------------------------------

# sanitize_int <value>: print a non-negative integer, or 0
sanitize_int() {
  case $1 in
  '' | *[!0-9]*) printf '0' ;;
  *) printf '%s' "$1" ;;
  esac
}

# truncate_item <text> <max> <symbol>
# Keeps the first <max> characters and appends <symbol> when it actually cut.
truncate_item() {
  local text=$1 max=$2 symbol=$3
  [ "$max" = 0 ] && {
    printf '%s' "$text"
    return 0
  }
  if [ "${#text}" -gt "$max" ]; then
    printf '%s%s' "${text:0:$max}" "$symbol"
  else
    printf '%s' "$text"
  fi
}

# json_array_items <json-array>: one unescaped element per line
# Handles the escaping jj's json() emits (" , \ , \n , \t , \r , \uXXXX).
json_array_items() {
  local s=$1 i=0 n ch buf="" in_str=0 esc=0
  local -a out=()
  s=${s#[}
  s=${s%]}
  n=${#s}
  while [ "$i" -lt "$n" ]; do
    ch=${s:$i:1}
    if [ "$in_str" = 1 ]; then
      if [ "$esc" = 1 ]; then
        case $ch in
        '"') buf="$buf\"" ;;
        '\') buf="$buf\\" ;;
        n) buf="$buf$(printf '\n')" ;;
        t) buf="$buf$(printf '\t')" ;;
        r) buf="$buf$(printf '\r')" ;;
        u)
          i=$((i + 4))
          buf="$buf?"
          ;;
        *) buf="$buf$ch" ;;
        esac
        esc=0
      else
        case $ch in
        '\') esc=1 ;;
        '"')
          out[${#out[@]}]="$buf"
          buf=""
          in_str=0
          ;;
        *) buf="$buf$ch" ;;
        esac
      fi
    else
      [ "$ch" = '"' ] && in_str=1
    fi
    i=$((i + 1))
  done
  [ "${#out[@]}" -gt 0 ] && printf '%s\n' "${out[@]}"
}

# ---------------------------------------------------------------------------
# Locate the workspace root — same heuristic as starship: walk up to `.jj`
# ---------------------------------------------------------------------------

find_workspace_root() {
  local dir=$1
  while :; do
    [ -d "$dir/.jj" ] && {
      printf '%s' "$dir"
      return 0
    }
    [ "$dir" = "/" ] && return 1
    dir=${dir%/*}
    [ -z "$dir" ] && dir=/
  done
}

# ---------------------------------------------------------------------------
# The one and only jj invocation
# ---------------------------------------------------------------------------

# starship's template, verbatim (src/context/jj_repo.rs). It prints TOML-ish
# `current.*` lines for the working copy and `parents.*` lines for the closest
# conflicted/bookmarked ancestor, so `@` and its parent can be described with a
# single process.
jj_template() {
  cat <<'JJ_TEMPLATE'
if(
    current_working_copy,
    join(
        "\n",
        concat("current.has_description = ", description.len() > 0),
        concat("current.hidden = ", hidden),
        concat("current.immutable = ", immutable),
        concat("current.divergent = ", divergent),
        concat("current.change_offset = ", change_offset),
        concat("current.change_id = \"", change_id, "\""),
        concat("current.change_id_prefix_len = ", change_id.shortest().prefix().len()),
        concat("current.commit_id = \"", commit_id, "\""),
        concat("current.commit_id_prefix_len = ", commit_id.shortest().prefix().len()),
        concat("current.lines_added = ", diff.stat().total_added()),
        concat("current.lines_removed = ", diff.stat().total_removed()),
        concat("current.conflicted = ", conflict),
        concat("current.bookmarks = [", bookmarks.map(|bm| json(stringify(bm))).join(","), "]"),
        concat(
            "current.statuses = \"",
            self
                .diff()
                .files()
                .map(|file| file.status_char())
                .join(""),
            "\"",
        ),
        "",
    ),
    concat(
        if(
            conflict,
            "parents.conflicted = true\n",
        ),
        if(
            bookmarks.len() > 0,
            concat("parents.bookmarks = [", bookmarks.map(|bm| json(stringify(bm))).join(","), "]\n"),
        ),
    ),
)
JJ_TEMPLATE
}

# Prints the raw template output, or nothing on failure.
jj_raw_output() {
  local root args
  if [ -n "$JJ_RAW" ]; then
    printf '%s' "$JJ_RAW"
    return 0
  fi

  root=$(find_workspace_root "$PWD") || return 1

  args=("$JJ_BIN" --color never --no-integrate-operation --no-pager --quiet)
  if [ "$JJ_NO_SNAPSHOT" = 1 ]; then
    args+=(--ignore-working-copy)
  fi
  args+=(--repository "$root" show "$JJ_REVSET" --no-patch --template "$(jj_template)")

  "${args[@]}" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Parse the template output
# ---------------------------------------------------------------------------

cur_has_description=false
cur_hidden=false
cur_immutable=false
cur_divergent=false
cur_conflicted=false
par_conflicted=false
cur_change_offset=0
cur_change_plen=0
cur_commit_plen=0
cur_lines_added=0
cur_lines_removed=0
cur_change_id=""
cur_commit_id=""
cur_statuses=""
cur_bookmarks="[]"
par_bookmarks="[]"

parse_raw() {
  local line key val
  while IFS= read -r line; do
    case $line in
    *'='*) ;;
    *) continue ;;
    esac
    key=${line%%=*}
    key=${key//[[:space:]]/}
    val=${line#*=}
    val=${val# }
    case $key in
    current.has_description) cur_has_description=$val ;;
    current.hidden) cur_hidden=$val ;;
    current.immutable) cur_immutable=$val ;;
    current.divergent) cur_divergent=$val ;;
    current.change_offset) cur_change_offset=$(sanitize_int "$val") ;;
    current.change_id)
      cur_change_id=${val#\"}
      cur_change_id=${cur_change_id%\"}
      ;;
    current.change_id_prefix_len) cur_change_plen=$(sanitize_int "$val") ;;
    current.commit_id)
      cur_commit_id=${val#\"}
      cur_commit_id=${cur_commit_id%\"}
      ;;
    current.commit_id_prefix_len) cur_commit_plen=$(sanitize_int "$val") ;;
    current.lines_added) cur_lines_added=$(sanitize_int "$val") ;;
    current.lines_removed) cur_lines_removed=$(sanitize_int "$val") ;;
    current.conflicted) cur_conflicted=$val ;;
    current.bookmarks) cur_bookmarks=$val ;;
    current.statuses)
      cur_statuses=${val#\"}
      cur_statuses=${cur_statuses%\"}
      ;;
    parents.conflicted) par_conflicted=$val ;;
    parents.bookmarks) par_bookmarks=$val ;;
    esac
  done <<<"$1"
}

# split_list <"a b,c">: one entry per line, whitespace/comma separated
split_list() {
  local raw=$1 item
  local IFS=$', \t'
  set -f
  for item in $raw; do
    [ -n "$item" ] && printf '%s\n' "$item"
  done
  set +f
}

load_ignore_lists() {
  local item
  IGNORE_NAMES=()
  IGNORE_REMOTES=()
  while IFS= read -r item; do
    IGNORE_NAMES[${#IGNORE_NAMES[@]}]=$item
  done < <(split_list "$JJ_BOOKMARK_IGNORE_NAMES")
  while IFS= read -r item; do
    IGNORE_REMOTES[${#IGNORE_REMOTES[@]}]=$item
  done < <(split_list "$JJ_BOOKMARK_IGNORE_REMOTES")
}

# ---------------------------------------------------------------------------
# Render one segment per starship module
# ---------------------------------------------------------------------------

# jj_bookmark: "on <symbol><first bookmark>(@remote)(*)(+N others) "
render_bookmark() {
  local bm name remote div ignored ig
  local first_name="" first_remote="" first_div=0 others=0 seen=0 text

  while IFS= read -r bm; do
    [ -z "$bm" ] && continue

    div=0
    case $bm in
    *'*')
      div=1
      bm=${bm%'*'}
      ;;
    esac

    name=${bm%%@*}
    remote=""
    case $bm in
    *@*) remote=${bm#*@} ;;
    esac

    ignored=0
    if [ "${#IGNORE_NAMES[@]}" -gt 0 ]; then
      for ig in "${IGNORE_NAMES[@]}"; do
        if [ "$ig" = "$name" ]; then
          ignored=1
          break
        fi
      done
    fi
    if [ "$ignored" = 0 ] && [ -n "$remote" ] && [ "${#IGNORE_REMOTES[@]}" -gt 0 ]; then
      for ig in "${IGNORE_REMOTES[@]}"; do
        if [ "$ig" = "$remote" ]; then
          ignored=1
          break
        fi
      done
    fi
    [ "$ignored" = 1 ] && continue

    if [ "$seen" = 0 ]; then
      first_name=$name
      first_remote=$remote
      first_div=$div
      seen=1
    else
      others=$((others + 1))
    fi
  done < <(
    json_array_items "$cur_bookmarks"
    json_array_items "$par_bookmarks"
  )

  [ "$seen" = 0 ] && return 0

  text=$JJ_BOOKMARK_SYMBOL
  text="$text$(truncate_item "$first_name" "$JJ_BOOKMARK_TRUNCATION_LENGTH" "$JJ_BOOKMARK_TRUNCATION_SYMBOL")"
  if [ -n "$first_remote" ]; then
    text="$text@$(truncate_item "$first_remote" "$JJ_BOOKMARK_TRUNCATION_LENGTH" "$JJ_BOOKMARK_TRUNCATION_SYMBOL")"
  fi
  [ "$first_div" = 1 ] && text="$text$JJ_BOOKMARK_DIVERGED_SYMBOL"
  [ "$others" -gt 0 ] && text="$text (+$others others)"

  printf 'on '
  paint "$JJ_BOOKMARK_STYLE" "$text"
  printf ' '
}

# jj_change: unique prefix (bold green) + rest (dimmed) + optional "/offset"
render_change() {
  local id=$cur_change_id plen=$cur_change_plen total prefix suffix
  local commit_len

  [ -z "$id" ] && return 0

  total=$plen
  [ "$JJ_HASH_LENGTH" -gt "$total" ] && total=$JJ_HASH_LENGTH
  [ "$total" -gt "${#id}" ] && total=${#id}
  prefix=${id:0:$plen}
  suffix=${id:$plen:$((total - plen))}

  paint "$JJ_CHANGE_PREFIX_STYLE" "$prefix"
  paint "$JJ_CHANGE_SUFFIX_STYLE" "$suffix"
  if [ "$cur_divergent" = true ] && [ "$cur_change_offset" -gt 0 ]; then
    paint "$JJ_CHANGE_OFFSET_STYLE" "/$cur_change_offset"
  fi
  if [ "$JJ_SHOW_COMMIT" = 1 ] && [ -n "$cur_commit_id" ]; then
    commit_len=$cur_commit_plen
    [ "$JJ_HASH_LENGTH" -gt "$commit_len" ] && commit_len=$JJ_HASH_LENGTH
    [ "$commit_len" -gt "${#cur_commit_id}" ] && commit_len=${#cur_commit_id}
    printf ' ('
    paint "$JJ_CHANGE_SUFFIX_STYLE" "${cur_commit_id:0:$commit_len}"
    printf ')'
  fi

  printf ' '
}

# jj_metrics: "+<added> " / "-<deleted> ", zeros skipped
render_metrics() {
  if [ "$cur_lines_added" -gt 0 ]; then
    paint "$JJ_METRICS_ADDED_STYLE" "+$cur_lines_added"
    printf ' '
  fi
  if [ "$cur_lines_removed" -gt 0 ]; then
    paint "$JJ_METRICS_DELETED_STYLE" "-$cur_lines_removed"
    printf ' '
  fi
}

# jj_status: "[!◌+=✘~»] ", in starship's `$all` order
render_status() {
  local all="" n

  if [ "$cur_conflicted" = true ] || [ "$par_conflicted" = true ]; then
    [ -n "$JJ_STATUS_CONFLICTED" ] && all="$all$JJ_STATUS_CONFLICTED"
  fi
  if [ "$cur_has_description" = true ]; then
    all="$all$JJ_STATUS_DESCRIPTION_PRESENT"
  else
    all="$all$JJ_STATUS_DESCRIPTION_EMPTY"
  fi
  [ "$cur_hidden" = true ] && all="$all$JJ_STATUS_HIDDEN"
  [ "$cur_immutable" = true ] && all="$all$JJ_STATUS_IMMUTABLE"

  n=${cur_statuses//[^A]/}
  [ "${#n}" -gt 0 ] && all="$all${JJ_STATUS_ADDED//\$count/${#n}}"
  n=${cur_statuses//[^C]/}
  [ "${#n}" -gt 0 ] && all="$all${JJ_STATUS_COPIED//\$count/${#n}}"
  n=${cur_statuses//[^D]/}
  [ "${#n}" -gt 0 ] && all="$all${JJ_STATUS_DELETED//\$count/${#n}}"
  n=${cur_statuses//[^M]/}
  [ "${#n}" -gt 0 ] && all="$all${JJ_STATUS_MODIFIED//\$count/${#n}}"
  n=${cur_statuses//[^R]/}
  [ "${#n}" -gt 0 ] && all="$all${JJ_STATUS_RENAMED//\$count/${#n}}"

  [ -z "$all" ] && return 0
  paint "$JJ_STATUS_STYLE" "[$all]"
  printf ' '
}

# ---------------------------------------------------------------------------
# Git fallback — used when the current directory is not inside a jj workspace.
# Emulates starship's git_branch, git_metrics and git_status modules.
# ---------------------------------------------------------------------------

git_repo_root() {
  local dir=$1
  while :; do
    if [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; then
      printf '%s' "$dir"
      return 0
    fi
    [ "$dir" = "/" ] && return 1
    dir=${dir%/*}
    [ -z "$dir" ] && dir=/
  done
}

# Run git with --no-optional-locks when the binary supports it.
run_git() {
  local out
  out=$($GIT_BIN --no-optional-locks --version 2>/dev/null) || true
  if [ -n "$out" ]; then
    GIT_OPTIONAL_LOCKS=0 $GIT_BIN "$@"
  else
    $GIT_BIN "$@"
  fi
}

git_query_repo() {
  local root
  root=$(git_repo_root "$PWD") || return 1

  # Skip bare repositories.
  run_git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

  # --- Branch ---
  GIT_BRANCH=""
  GIT_BRANCH=$(run_git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null) || true
  if [ -z "$GIT_BRANCH" ]; then
    GIT_BRANCH=$(run_git -C "$root" rev-parse --short HEAD 2>/dev/null) || true
    [ -z "$GIT_BRANCH" ] && GIT_BRANCH="HEAD"
  fi

  # --- Status (porcelain v2, with branch header for ahead/behind) ---
  local status_out=""
  if [ -n "$GIT_RAW_STATUS" ]; then
    status_out=$GIT_RAW_STATUS
  else
    status_out=$(run_git -C "$root" status --porcelain=2 --branch 2>/dev/null) || true
  fi

  GIT_CONFLICTED=0; GIT_DELETED=0; GIT_MODIFIED=0; GIT_STAGED=0
  GIT_UNTRACKED=0; GIT_RENAMED=0; GIT_AHEAD=0; GIT_BEHIND=0

  local line xy x y
  while IFS= read -r line; do
    case $line in
    "# branch.head (no branch)")
      GIT_BRANCH="(no branch)"
      ;;
    "# branch.ab "*)
      GIT_AHEAD=${line#*ab +}
      GIT_AHEAD=${GIT_AHEAD%% *}
      GIT_BEHIND=${line##*-}
      GIT_BEHIND=${GIT_BEHIND%% *}
      ;;
    "1 "*)
      xy=${line:2:2}
      x=${xy:0:1}
      y=${xy:1:1}
      case $x in A | M | T) GIT_STAGED=$((GIT_STAGED + 1)) ;; esac
      case $x in D) GIT_DELETED=$((GIT_DELETED + 1)) ;; esac
      case $y in M | A) GIT_MODIFIED=$((GIT_MODIFIED + 1)) ;; esac
      case $y in D) GIT_DELETED=$((GIT_DELETED + 1)) ;; esac
      case $y in R) GIT_RENAMED=$((GIT_RENAMED + 1)) ;; esac
      ;;
    "2 "*)
      xy=${line:2:2}
      x=${xy:0:1}
      y=${xy:1:1}
      case $x in A | M | T) GIT_STAGED=$((GIT_STAGED + 1)) ;; esac
      case $x in D) GIT_DELETED=$((GIT_DELETED + 1)) ;; esac
      case $y in M | A) GIT_MODIFIED=$((GIT_MODIFIED + 1)) ;; esac
      case $y in D) GIT_DELETED=$((GIT_DELETED + 1)) ;; esac
      case $y in R) GIT_RENAMED=$((GIT_RENAMED + 1)) ;; esac
      ;;
    "u "*)
      GIT_CONFLICTED=$((GIT_CONFLICTED + 1))
      ;;
    "? "*)
      GIT_UNTRACKED=$((GIT_UNTRACKED + 1))
      ;;
    esac
  done <<<"$status_out"

  # --- Diff metrics (working tree vs index) ---
  GIT_LINES_ADDED=0
  GIT_LINES_DELETED=0
  local diff_out=""
  if [ -n "$GIT_RAW_DIFF" ]; then
    diff_out=$GIT_RAW_DIFF
  else
    diff_out=$(run_git -C "$root" diff --shortstat 2>/dev/null) || true
  fi
  if [ -n "$diff_out" ]; then
    local before_num
    case $diff_out in
    *insertion*)
      before_num=${diff_out%% insertion*}
      GIT_LINES_ADDED=${before_num##*, }
      GIT_LINES_ADDED=$((GIT_LINES_ADDED + 0))
      ;;
    esac
    case $diff_out in
    *deletion*)
      before_num=${diff_out%% deletion*}
      GIT_LINES_DELETED=${before_num##*, }
      GIT_LINES_DELETED=$((GIT_LINES_DELETED + 0))
      ;;
    esac
  fi

  # --- Stash count ---
  GIT_STASHED=0
  if [ -n "$GIT_STATUS_STASHED" ]; then
    local cnt
    cnt=$(run_git -C "$root" stash list 2>/dev/null | wc -l) || true
    cnt=${cnt##* }
    cnt=${cnt%% *}
    GIT_STASHED=$((cnt + 0))
  fi

  return 0
}

render_git_branch() {
  [ "$GIT_SHOW_BRANCH" = 1 ] || return 0
  [ -z "$GIT_BRANCH" ] && return 0
  printf 'on '
  paint "$GIT_BRANCH_STYLE" "$GIT_BRANCH_SYMBOL$GIT_BRANCH"
  printf ' '
}

render_git_metrics() {
  [ "$GIT_SHOW_METRICS" = 1 ] || return 0
  if [ "$GIT_LINES_ADDED" -gt 0 ]; then
    paint "$GIT_METRICS_ADDED_STYLE" "+$GIT_LINES_ADDED"
    printf ' '
  fi
  if [ "$GIT_LINES_DELETED" -gt 0 ]; then
    paint "$GIT_METRICS_DELETED_STYLE" "-$GIT_LINES_DELETED"
    printf ' '
  fi
}

render_git_status() {
  [ "$GIT_SHOW_STATUS" = 1 ] || return 0
  local all=""

  [ "$GIT_CONFLICTED" -gt 0 ] && [ -n "$GIT_STATUS_CONFLICTED" ] &&
    all="$all$GIT_STATUS_CONFLICTED"
  [ "$GIT_STASHED" -gt 0 ] && [ -n "$GIT_STATUS_STASHED" ] &&
    all="$all$GIT_STATUS_STASHED"
  [ "$GIT_DELETED" -gt 0 ] && [ -n "$GIT_STATUS_DELETED" ] &&
    all="$all$GIT_STATUS_DELETED"
  [ "$GIT_RENAMED" -gt 0 ] && [ -n "$GIT_STATUS_RENAMED" ] &&
    all="$all$GIT_STATUS_RENAMED"
  [ "$GIT_MODIFIED" -gt 0 ] && [ -n "$GIT_STATUS_MODIFIED" ] &&
    all="$all$GIT_STATUS_MODIFIED"
  [ "$GIT_STAGED" -gt 0 ] && [ -n "$GIT_STATUS_STAGED" ] &&
    all="$all$GIT_STATUS_STAGED"
  [ "$GIT_UNTRACKED" -gt 0 ] && [ -n "$GIT_STATUS_UNTRACKED" ] &&
    all="$all$GIT_STATUS_UNTRACKED"

  # Ahead / behind upstream.
  local ab=""
  if [ "$GIT_AHEAD" -gt 0 ] && [ "$GIT_BEHIND" -gt 0 ]; then
    ab=${GIT_STATUS_DIVERGED//\$ahead_count/$GIT_AHEAD}
    ab=${ab//\$behind_count/$GIT_BEHIND}
  elif [ "$GIT_AHEAD" -gt 0 ]; then
    ab=${GIT_STATUS_AHEAD//\$count/$GIT_AHEAD}
  elif [ "$GIT_BEHIND" -gt 0 ]; then
    ab=${GIT_STATUS_BEHIND//\$count/$GIT_BEHIND}
  fi
  all="$all$ab"

  [ -z "$all" ] && return 0
  paint "$GIT_STATUS_STYLE" "[$all]"
  printf ' '
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local raw

  # A bogus numeric option must never break the prompt.
  JJ_HASH_LENGTH=$(sanitize_int "$JJ_HASH_LENGTH")
  JJ_BOOKMARK_TRUNCATION_LENGTH=$(sanitize_int "$JJ_BOOKMARK_TRUNCATION_LENGTH")

  # Try jj first; fall back to git when we are not in a jj workspace.
  raw=$(jj_raw_output) || raw=""
  if [ -z "$raw" ]; then
    git_query_repo || exit 0
    render_git_branch
    render_git_metrics
    render_git_status
    exit 0
  fi

  parse_raw "$raw"
  load_ignore_lists

  # Render functions print directly: no command substitution, fewer forks.
  [ "$JJ_SHOW_BOOKMARK" = 1 ] && render_bookmark
  [ "$JJ_SHOW_CHANGE" = 1 ] && render_change
  [ "$JJ_SHOW_METRICS" = 1 ] && render_metrics
  [ "$JJ_SHOW_STATUS" = 1 ] && render_status
}

main
