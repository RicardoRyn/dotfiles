local launcher = require("modules.glass_launcher.core.search-launcher")
launcher.prewarm()
require("modules.glass_launcher.config.app-launchers")
require("modules.glass_launcher.actions.launcher-file-conversions")
require("modules.glass_launcher.config.launcher-custom-actions")

return launcher
