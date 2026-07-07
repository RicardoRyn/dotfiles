th.git = th.git or {}
th.git.added_sign = "_A"
th.git.modified_sign = "_M"
th.git.deleted_sign = "_D"
th.git.untracked_sign = "??"
th.git.ignored_sign = "!!"
th.git.updated_sign = "M_"
require("git"):setup({ order = 999 })
require("full-border"):setup()
require("starship"):setup()
require("toggle-pane"):entry("min-preview")
require("linemode-plus"):setup({})
