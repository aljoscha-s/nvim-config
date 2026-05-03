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

			--
			-- File pickers
			--
			vim.keymap.set("n", "<leader>fb", function()
				telescope.extensions.file_browser.file_browser(
					themes.get_ivy({})
				)
			end, { desc = "File Browser" })
			vim.keymap.set("n", "<leader>fd", require('telescope.builtin').find_files)
			vim.keymap.set("n", "<leader>en", function()
				require('telescope.builtin').find_files {
					cwd = vim.fn.stdpath("config")
				}
			end)
			vim.keymap.set("n", "<leader>fg", function()
				require("telescope.builtin").live_grep({
					additional_args = function()
						return { "--hidden", "--glob", "!.git/*" }
					end,
				})
			end, { desc = "Live grep (hidden)" })
			vim.keymap.set("n", "<leader>fw", require("telescope.builtin").grep_string,
				{ desc = "Grep word" })
			--
			-- Git pickers
			--
			vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Git files" })
			vim.keymap.set("n", "<leader>gs", require("telescope.builtin").git_status,
				{ desc = "Git status" })
			vim.keymap.set("n", "<leader>gc", require("telescope.builtin").git_commits,
				{ desc = "Git commits" })
			vim.keymap.set("n", "<leader>gC", require("telescope.builtin").git_bcommits,
				{ desc = "Git commits (file)" })
			vim.keymap.set("n", "<leader>gb", require("telescope.builtin").git_branches,
				{ desc = "Git branches" })
			vim.keymap.set("n", "<leader>gS", require("telescope.builtin").git_stash, { desc = "Git stash" })
			---
			--- LSP pickers
			---
			vim.keymap.set("n", "<leader>dd", require("telescope.builtin").diagnostics,
				{ desc = "Diagnostics (buffer)" })
		end
	}
}
