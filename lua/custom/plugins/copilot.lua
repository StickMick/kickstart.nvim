
---@module 'lazy'
---@type LazySpec
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<C-c>",
        }
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<C-y>",
        },
      },
      copilot_node_command = "node", -- use system node
      server_opts_overrides = {},
    })
    vim.keymap.set("n", "<leader>ce", "<cmd>Copilot enable<CR>", { desc = "[C]opilot [E]nable" })
    vim.keymap.set("n", "<leader>cd", "<cmd>Copilot disable<CR>", { desc = "[C]opilot [D]isable" })
  end,
}
