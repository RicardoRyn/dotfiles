require("full-border"):setup()
require("git"):setup()
-- show symlink in status bar
Status:children_add(function(self)
  local h = self._current.hovered
  if h and h.link_to then
    return " -> " .. tostring(h.link_to)
  else
    return ""
  end
end, 3300, Status.LEFT)
-- cross instance yank
require("session"):setup({
  sync_yanked = true,
})
-- cloese preview panel when start yazi
require("toggle-pane"):entry("min-preview")
