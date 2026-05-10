def _history_timestamp_column [columns: list<string>] {
    $columns
    | where { |name| $name in ["start_timestamp", "timestamp", "time", "start_time"] }
    | first
}

def _format_history_age [timestamp: any] {
    let dt = if (($timestamp | describe) == "datetime") {
        $timestamp
    } else {
        try { $timestamp | into datetime } catch { null }
    }

    if $dt == null {
        return ""
    }

    let age = (date now) - $dt

    if $age < 1min {
        "just now"
    } else if $age < 1hr {
        $"(($age / 1min | math floor | into int))m ago"
    } else if $age < 1day {
        $"(($age / 1hr | math floor | into int))h ago"
    } else if $age < 90day {
        $"(($age / 1day | math floor | into int))d ago"
    } else {
        $dt | format date "%Y-%m-%d %H:%M"
    }
}

def _pad_left [text: string, width: int] {
    let len = ($text | str length)
    if $len >= $width {
        $text
    } else {
        $"((' ' | fill -w ($width - $len)))($text)"
    }
}

# Shell wrapper for yazi.
export def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  ^yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != $env.PWD and ($cwd | path exists) {
    cd $cwd
  }
  rm -fp $tmp
}

# Fuzzy-search shell history and replace the current command line buffer.
#
# Examples:
#   Open `fzf` with command history and paste the selected entry into the prompt.
#   > fzf-history
export def --env fzf-history [] {
    let query = (commandline)
    commandline edit --replace ""
    print -n $'(ansi --escape "2K")'
    let sep = (char --integer 31)
    let history_long = (history --long)
    let history_columns = ($history_long | columns)
    let ts_column = (_history_timestamp_column $history_columns)

    let selected = (
        if $ts_column == null {
            history
            | get command
            | reverse
            | uniq
            | each { |cmd| [$cmd, $cmd] | str join $sep }
        } else {
            $history_long
            | reverse
            | uniq-by command
            | each { |row|
                let command = $row.command
                let age = (_format_history_age ($row | get $ts_column))
                let display = if ($age | is-empty) {
                    $command
                } else {
                    let age_col = (_pad_left $age 12)
                    let age_display = $"(ansi cyan_dimmed)($age_col)(ansi reset)"
                    $"($age_display) ($command)"
                }
                [$command, $display] | str join $sep
            }
        }
        | to text
        | fzf --height 100% --border --ansi --query $query --delimiter $sep --with-nth 2
        | str trim
    )

    let command = if ($selected | is-empty) {
        $query
    } else {
        $selected | split row $sep --number 2 | first
    }

    commandline edit --replace $command
}
