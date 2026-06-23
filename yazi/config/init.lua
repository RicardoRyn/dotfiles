th.git = th.git or {}
th.git.added_sign = ""
th.git.modified_sign = "○"
th.git.deleted_sign = ""
th.git.untracked_sign = "?"
th.git.ignored_sign = " "
th.git.updated_sign = " "
require("git"):setup({ order = 1500 })
require("full-border"):setup()
require("starship"):setup()
require("toggle-pane"):entry("min-preview")
