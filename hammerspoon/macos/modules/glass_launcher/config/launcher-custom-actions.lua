local actions = require("modules.glass_launcher.actions.universal-actions")

actions.register("text", {
    title = "Count Characters",
    symbol = "textformat.123",
    run = function(subject)
        hs.alert.show(#subject.text .. " characters")
    end,
})

actions.register("file", {
    title = "Copy Path",
    symbol = "doc.on.clipboard",
    run = function(subject)
        hs.pasteboard.setContents(subject.path)
    end,
})
