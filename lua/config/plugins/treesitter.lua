return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.config", -- tells lazy to call require("nvim-treesitter.configs").setup(opts)
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		opts = {
			ensure_installed = {
				"lua",
				"rust",
				"typescript",
				"tsx",
				"javascript",
				"json",
			},
			highlight = { enable = true },
			indent = { enable = true },
			auto_install = true,

			textobjects = {
				move = {
					enable = true,
					set_jumps = true,
					lookahead = true,
				},
			},
		},
	},
}
