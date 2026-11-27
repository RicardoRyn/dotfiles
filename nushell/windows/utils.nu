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

export def --env nvim [...args: string] {
    let log = ($env.TEMP? | default $env.TMP? | default "/tmp") + $"/nvim-startup-(random uuid).log"
    with-env { NVIM_STARTUP_LOG: $log } {
        ^nvim --startuptime $log ...$args
    }
    let rc = $env.LAST_EXIT_CODE
    try {
        rm -f $log
    } catch {
    }
    if $rc != 0 {
        error make { msg: $"nvim exited with code ($rc)" }
    }
}

export def --env nvim_pure [...args] {
  $env.NVIM_APPNAME = "nvim_pure"
  ^nvim ...$args
}
