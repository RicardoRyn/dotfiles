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

export def --env nvim [...args] {
  $env.NVIM_APPNAME = "nvim"
  ^nvim ...$args
}

export def --env nvimbak [...args] {
  $env.NVIM_APPNAME = "nvim-bak"
  ^nvim ...$args
}

export def --env mininvim [...args] {
  $env.NVIM_APPNAME = "nvim-mini"
  ^nvim ...$args
}

export def --env nvimpure [...args] {
  $env.NVIM_APPNAME = "nvim-pure"
  ^nvim ...$args
}
