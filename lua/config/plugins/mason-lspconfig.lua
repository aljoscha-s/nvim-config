return {
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		opts = {
			ensure_installed = {
				"eslint",
				"lua_ls",
				"rust_analyzer",
				"ts_ls",
			},
			automatic_installation = true,
		},
	},
}
