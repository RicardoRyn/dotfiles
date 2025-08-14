return {
  "smoka7/hop.nvim",
  version = "*",
  opts = {},
  keys = {
    {
      "<leader><leader>w",
      function()
        require("hop").hint_words({
          direction = require("hop.hint").HintDirection.AFTER_CURSOR,
          hint_position = require("hop.hint").HintPosition.END,
        })
      end,
      desc = "Go to next beginning of word",
    },
    {
      "<leader><leader>e",
      function()
        require("hop").hint_words({ direction = require("hop.hint").HintDirection.AFTER_CURSOR })
      end,
      desc = "Go to next end of word",
    },
    {
      "<leader><leader>b",
      function()
        require("hop").hint_words({
          direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
          hint_position = require("hop.hint").HintPosition.END,
        })
      end,
      desc = "Go to previous beginning of word",
    },
    {
      "<leader><leader>v",
      function()
        require("hop").hint_words({ direction = require("hop.hint").HintDirection.BEFORE_CURSOR })
      end,
      desc = "Go to previous end of word",
    },
    {
      "<leader><leader>l",
      function()
        require("hop").hint_camel_case({
          direction = require("hop.hint").HintDirection.AFTER_CURSOR,
          hint_position = require("hop.hint").HintPosition.END,
        })
      end,
      desc = "Go to next camel-case word",
    },
    {
      "<leader><leader>h",
      function()
        require("hop").hint_camel_case({
          direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
          hint_position = require("hop.hint").HintPosition.END,
        })
      end,
      desc = "Go to previous camel-case word",
    },
    {
      "<leader><leader>j",
      function()
        require("hop").hint_lines({ direction = require("hop.hint").HintDirection.AFTER_CURSOR })
      end,
      desc = "Go to line below",
    },
    {
      "<leader><leader>k",
      function()
        require("hop").hint_lines({ direction = require("hop.hint").HintDirection.BEFORE_CURSOR })
      end,
      desc = "Go to line above",
    },
  },
}
