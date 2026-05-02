-- Show diagnostic message in a floating window
vim.keymap.set("n", "<leader>gl", function()
	vim.diagnostic.open_float(nil, { scope = "cursor", focus = false })
end, { desc = "Diagnostic float" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })

-- Copy diagnostic message on the current line to clipboard (+ register)
vim.keymap.set("n", "<leader>yd", function()
	local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
	if not diags or vim.tbl_isempty(diags) then
		print("No diagnostics on this line")
		return
	end
	vim.fn.setreg("+", diags[1].message)
	print("Copied diagnostic to clipboard")
end, { desc = "Yank diagnostic" })

-- Show type/info for symbol under cursor (LSP hover)
vim.keymap.set("n", "<leader>t", function()
	vim.lsp.buf.hover()
end, { desc = "Type / hover" })

vim.keymap.set("n", "<leader>s", function()
	vim.lsp.buf.signature_help()
end, { desc = "Signature help" })
