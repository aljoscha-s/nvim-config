return {
 {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
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
          themes.get_ivy({ })
        )
      end, { desc = "File Browser" })
      vim.keymap.set("n", "<space>fd", require('telescope.builtin').find_files)
      vim.keymap.set("n", "<space>en", function()
        require('telescope.builtin').find_files {
	  cwd = vim.fn.stdpath("config")
        }
      end)
    end
  }
}
