require("config.options") -- must be loaded before config.lazy!
require("config.lazy")
require("config.format")
require("config.keymaps")

vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus"
vim.wo.number = true
vim.cmd [[colorscheme tokyonight]]

vim.diagnostic.config({
	virtual_text = {
		spacing = 2,
		source = "if_many",
		prefix = "●",
		-- show only first line (or first N chars) inline
		format = function(d)
			local msg = d.message:gsub("\n", " ")
			local max = 80
			if #msg > max then
				return msg:sub(1, max) .. "…"
			end
			return msg
		end,
	},
	signs = true, -- the E/W icons in the gutter
	underline = true, -- red underline
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
		-- floats wrap by default; this just makes it nicer to read
		max_width = math.floor(vim.o.columns * 0.8),
	},
	jump = { float = true },
	loclist = {
		open = true,
		severity = { min = vim.diagnostic.severity.WARN },

	}
})
