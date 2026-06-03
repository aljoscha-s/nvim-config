return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-tree").setup { update_focused_file = {
			enable = true,
			update_cwd = true,
		}, filters = {
			dotfiles = false,
			git_ignored = false,
		}, }
		vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
	end,
}
