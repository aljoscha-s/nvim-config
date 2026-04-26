local group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    -- Only try to format normal files
    if vim.bo[args.buf].buftype ~= "" then
      return
    end

    -- Only format if some attached LSP client supports formatting
    local clients = vim.lsp.get_clients({ bufnr = args.buf })
    for _, client in ipairs(clients) do
      if client.supports_method("textDocument/formatting") then
        vim.lsp.buf.format({
          bufnr = args.buf,
          timeout_ms = 2000,
        })
        return
      end
    end
  end,
})
