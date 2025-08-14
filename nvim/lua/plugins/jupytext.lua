if vim.g.vscode then
  return {}
else
  return {
    "GCBallesteros/jupytext.nvim",
    config = true,
    opts = {
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown",
    },
  }
end
