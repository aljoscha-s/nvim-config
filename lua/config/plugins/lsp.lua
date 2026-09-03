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
			vim.lsp.config("ts_ls", {
				-- IMPORTANT: let prettier handle formatting, not tsserver
				on_attach = function(client)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
				end,
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "none",
							includeInlayFunctionParameterTypeHints = false,
							includeInlayVariableTypeHints = true,
							includeInlayVariableTypeHintsWhenTypeMatchesName = false,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = false,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "none",
							includeInlayFunctionParameterTypeHints = false,
							includeInlayVariableTypeHints = true,
							includeInlayVariableTypeHintsWhenTypeMatchesName = false,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = false,
						},
					},
				},
			})
			vim.lsp.enable("ts_ls")

			vim.lsp.config("jsonls", {
				on_attach = function(client)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
				end,
			})
			vim.lsp.enable("jsonls")

			vim.lsp.config("eslint", {
			})
			vim.lsp.enable("eslint")
			vim.lsp.inlay_hint.enable(true)
		end,
	},
}
