return {
  -- ❌ Disable GitUI integration completely
  { "kdheepak/lazygit.nvim" }, -- ensure lazygit plugin is available
  { "jedrzejboczar/possession.nvim", enabled = false }, -- just an example, ignore if you don’t use it

  {
    "LazyVim/LazyVim",
    opts = {
      -- Rebind GitUI keys to LazyGit
      keys = {
        {
          "<leader>gg",
          function()
            local Util = require("lazyvim.util")
            Util.terminal.open({ "lazygit" }, { cwd = Util.get_root() })
          end,
          desc = "Lazygit (root dir)",
        },
        {
          "<leader>gG",
          function()
            local Util = require("lazyvim.util")
            Util.terminal.open({ "lazygit" }, { cwd = vim.loop.cwd() })
          end,
          desc = "Lazygit (cwd)",
        },
      },
    },
  },

  -- 🔥 Disable GitUI plugin entirely if LazyVim loaded it
  {
    "jiaoshijie/undotree", -- just example plugin structure
    enabled = false,
  },
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- Disable built-in gitui keybinds if they exist
      for i, key in ipairs(opts.keys or {}) do
        if key[1] == "<leader>gg" or key[1] == "<leader>gG" then
          table.remove(opts.keys, i)
        end
      end
    end,
  },
}
