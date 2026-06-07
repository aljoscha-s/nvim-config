return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-tree").setup { sync_root_with_cwd = false, update_focused_file = {
			enable = true,
			update_cwd = false,
		}, filters = {
			dotfiles = false,
			git_ignored = false,
		}, }
		vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
	end,
}
