vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false -- don't fold everything on file open
vim.opt.foldlevel = 99     -- start with all folds open
vim.opt.relativenumber = true
