return {
	{
		'nvim-telescope/telescope.nvim',
		version = '*',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local themes = require("telescope.themes")

			telescope.setup({
				extensions = {
					file_browser = {
						grouped = true,
						hidden = true,
					},
				},
			})

			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "file_browser")

			vim.keymap.set("n", "<space>fb", function()
				telescope.extensions.file_browser.file_browser(
					themes.get_ivy({})
				)
			end, { desc = "File Browser" })
			vim.keymap.set("n", "<space>fd", require('telescope.builtin').find_files)
			vim.keymap.set("n", "<space>en", function()
				require('telescope.builtin').find_files {
					cwd = vim.fn.stdpath("config")
				}
			end)
			vim.keymap.set("n", "<space>fg", function()
				require("telescope.builtin").live_grep({
					additional_args = function()
						return { "--hidden", "--glob", "!.git/*" }
					end,
				})
			end, { desc = "Live grep (hidden)" })
			vim.keymap.set("n", "<space>fw", require("telescope.builtin").grep_string, { desc = "Grep word" })
		end
	}
}
