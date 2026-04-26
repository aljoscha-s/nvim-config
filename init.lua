require("config.lazy")
require("config.format")

vim.opt.clipboard = "unnamedplus"
vim.wo.number = true
vim.cmd [[colorscheme tokyonight]]

vim.diagnostic.config({
	virtual_text = {
		enabled = true,
		-- optional tweaks:
		spacing = 2,
		source = "if_many", -- show which LSP (use "always" to always show)
		prefix = "●", -- could also be "■", "▎", "", etc.
	},
	signs = true, -- the E/W icons in the gutter
	underline = true, -- red underline
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
	},
})
