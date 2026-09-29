-- Append "Closes #<issue>" to commit messages, where <issue> is the
-- 4-digit number the branch name starts with (e.g. 1234-fix-login).
-- Works for both `git commit` (with nvim as editor) and Neogit.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "gitcommit",
	group = vim.api.nvim_create_augroup("CommitClosesIssue", { clear = true }),
	callback = function(args)
		local buf = args.buf
		local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
		local result = vim.system({ "git", "branch", "--show-current" }, { cwd = dir, text = true }):wait()
		if result.code ~= 0 then
			return
		end

		local issue = vim.trim(result.stdout):match("^(%d%d%d%d)")
		if not issue then
			return
		end

		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local trailer = "Closes #" .. issue

		-- Message lines are everything before the first comment line
		local first_comment = #lines + 1
		for i, line in ipairs(lines) do
			if line == trailer then
				return -- already present (amend, reused message, ...)
			end
			if line:match("^#") and first_comment > #lines then
				first_comment = i
			end
		end

		-- Drop trailing blank lines of the existing message
		local last = first_comment - 1
		while last > 0 and vim.trim(lines[last]) == "" do
			last = last - 1
		end

		local insert
		if last == 0 then
			-- Empty message: subject line, blank, trailer, blank before comments
			insert = { "", "", trailer, "" }
		else
			insert = { "", trailer, "" }
		end
		vim.api.nvim_buf_set_lines(buf, last, first_comment - 1, false, insert)
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end,
})
