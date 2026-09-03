return {
	{
		"stevearc/conform.nvim",
		opts = {
			-- Use prettier for JS/TS/React (uses your project config automatically)
			formatters_by_ft = {
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
			},

			-- format on save
			format_on_save = {
				timeout_ms = 2000,
				lsp_fallback = true, -- for filetypes where you didn't configure a formatter
			},
		},
	},
}
