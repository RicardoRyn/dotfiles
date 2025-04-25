return {
  -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
  wsl_domains = {
    {
      name = "WSL:Ubuntu",
      distribution = "Ubuntu",
      username = "ricardo",
      default_cwd = "/home/ricardo",
      default_prog = { "zsh", "-l" },
    },
  },

  -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
  ssh_domains = {
    -- yazi's image preview on Windows will only work if launched via ssh from WSL
    {
      name = "Server.ssh",
      remote_address = "192.168.22.171",
      username = "ruanjx",
      multiplexing = "None",
      default_prog = { "bash", "-l" },
      assume_shell = "Posix",
    },
  },

  -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
  unix_domains = {},
}
