-- Project-wide search & replace with live preview (uses ripgrep)
return {
	"MagicDuck/grug-far.nvim",
	cmd = { "GrugFar", "GrugFarWithin" },
	opts = {},
	keys = {
		{
			"<leader>rr",
			function()
				require("grug-far").open()
			end,
			desc = "Search & replace in project",
		},
		{
			"<leader>rw",
			function()
				require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
			end,
			desc = "Search & replace word under cursor",
		},
		{
			"<leader>rw",
			function()
				require("grug-far").with_visual_selection()
			end,
			mode = "x",
			desc = "Search & replace selection",
		},
		{
			"<leader>rf",
			function()
				require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
			end,
			desc = "Search & replace in current file",
		},
	},
}
