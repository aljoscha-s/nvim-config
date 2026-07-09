return {
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		opts = {
			ensure_installed = {
				"eslint",
				"lua_ls",
				-- Managed by rustaceanvim now
				-- "rust_analyzer",
				"ts_ls",
				"jsonls"
			},
			automatic_installation = true,
			automatic_enable = {
				-- Managed by rustaceanvim now
				exclude = { "rust_analyzer" },
			},
		},
	},
}
