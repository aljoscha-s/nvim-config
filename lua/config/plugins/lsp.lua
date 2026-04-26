return {
  {
    "neovim/nvim-lspconfig",
    config = function()

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = { command = "clippy" },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("lua_ls")
    end,
  },
}
