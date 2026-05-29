return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
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

			vim.lsp.enable("lua_ls")
			vim.lsp.config("rust_analyzer", {
				settings = {
					["rust-analyzer"] = {
						checkOnSave = { command = "clippy" },
						inlayHints = {
							typeHints = { enable = true },
							parameterHints = { enable = true },
							chainingHints = { enable = true },
						},
						completion = {
							fullFunctionSignatures = { enable = true },
						},
					},
				},
			})

			vim.lsp.enable("rust_analyzer")
			vim.lsp.config("ts_ls", {
				-- IMPORTANT: let prettier handle formatting, not tsserver
				on_attach = function(client)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
				end,
			})
			vim.lsp.enable("ts_ls")

			vim.lsp.config("eslint", {
			})
			vim.lsp.enable("eslint")
			vim.lsp.inlay_hint.enable(true)
		end,
	},
}
