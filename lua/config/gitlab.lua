-- GitLab helpers built on the `glab` CLI.
--
-- :GlMr [glab flags]  Create a draft merge request, assigned to you, from the
--                     current branch on your fork into the main repo. Extra
--                     flags are passed through, e.g. `:GlMr --reviewer someone`
--                     or `:GlMr --draft=false` for a ready MR.

local FORK_REMOTE = "origin"
local UPSTREAM_REMOTES = { "opentalk", "upstream" } -- first existing one wins

local function git(args, cwd)
	local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	return vim.trim(result.stdout)
end

-- Split a remote URL into host and project path, e.g.
-- ssh://git@gitlab.example.com:2222/group/project.git.> git.opentalk.dev, group/project
local function parse_remote(url)
	local authority, path = url:match("^%a+://([^/]+)/(.+)$") -- ssh:// or https://
	local host = authority and authority:gsub("^.*@", ""):gsub(":%d+$", "")
	if not host then
		host, path = url:match("^[^@]+@([^:]+):(.+)$") -- git@host:group/project.git
	end
	return host, ((path or ""):gsub("%.git$", ""))
end

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "GitLab MR" })
end

local function create_mr(extra_args)
	if vim.fn.executable("glab") == 0 then
		return notify("`glab` is not installed", vim.log.levels.ERROR)
	end

	local root = git({ "rev-parse", "--show-toplevel" }, vim.fn.getcwd())
	if not root then
		return notify("Not inside a git repository", vim.log.levels.ERROR)
	end

	local remotes = vim.split(git({ "remote" }, root) or "", "\n")
	local upstream
	for _, name in ipairs(UPSTREAM_REMOTES) do
		if vim.tbl_contains(remotes, name) then
			upstream = name
			break
		end
	end
	if not upstream or not vim.tbl_contains(remotes, FORK_REMOTE) then
		return notify(
			("Need remotes '%s' (fork) and one of %s (main repo)"):format(
				FORK_REMOTE,
				table.concat(UPSTREAM_REMOTES, "/")
			),
			vim.log.levels.ERROR
		)
	end

	local branch = git({ "branch", "--show-current" }, root)
	if not branch or branch == "" then
		return notify("Detached HEAD, check out a branch first", vim.log.levels.ERROR)
	end

	-- The MR is built from what's on the fork, so make sure it's up to date
	local remote_head = git({ "rev-parse", "--verify", "-q", FORK_REMOTE .. "/" .. branch }, root)
	if remote_head ~= git({ "rev-parse", "HEAD" }, root) then
		return notify(
			("'%s' is not pushed to '%s' (or is out of date), push first"):format(branch, FORK_REMOTE),
			vim.log.levels.ERROR
		)
	end

	-- Target the main repo's default branch, falling back to main
	local target = (git({ "symbolic-ref", "--short", "refs/remotes/" .. upstream .. "/HEAD" }, root) or "")
	    :gsub("^" .. vim.pesc(upstream) .. "/", "")
	if target == "" then
		target = "main"
	end

	local upstream_url = git({ "remote", "get-url", upstream }, root)
	local issue = branch:match("^(%d+)")
	local fallback_title = git({ "log", "-1", "--format=%s" }, root)
	local host, path = parse_remote(upstream_url)

	-- Username stored by `glab auth login`, used to assign the MR to yourself
	local user = vim.system({ "glab", "config", "get", "user", "--host", host }, { text = true }):wait()
	local username = user.code == 0 and vim.trim(user.stdout) or ""

	local function submit(title)
		local cmd = {
			"glab", "mr", "create",
			"--repo", upstream_url,
			"--head", git({ "remote", "get-url", FORK_REMOTE }, root),
			"--source-branch", branch,
			"--target-branch", target,
			"--title", title,
			"--description", issue and ("Closes #" .. issue) or "",
			"--draft",
			"--yes",
		}
		if username ~= "" then
			vim.list_extend(cmd, { "--assignee", username })
		end
		vim.list_extend(cmd, extra_args)

		notify(("Creating MR %s → %s:%s ..."):format(branch, upstream, target))
		vim.system(cmd, { cwd = root, text = true }, function(result)
			vim.schedule(function()
				local output = vim.trim((result.stdout or "") .. "\n" .. (result.stderr or ""))
				if result.code ~= 0 then
					return notify("glab failed:\n" .. output, vim.log.levels.ERROR)
				end
				local url = output:match("https?://%S+/%-/merge_requests/%d+")
				if url then
					vim.fn.setreg("+", url)
					notify("Created " .. url .. " (copied to clipboard)")
					vim.ui.open(url)
				else
					notify(output)
				end
			end)
		end)
	end

	if not issue then
		return submit(fallback_title)
	end

	-- Use the issue title as MR title, falling back to the last commit subject
	local endpoint = ("projects/%s/issues/%s"):format((path:gsub("/", "%%2F")), issue)
	vim.system({ "glab", "api", "--hostname", host, endpoint }, { cwd = root, text = true }, function(result)
		vim.schedule(function()
			local ok, data = pcall(vim.json.decode, result.stdout or "")
			if result.code == 0 and ok and type(data) == "table" and data.title then
				submit(data.title)
			else
				notify(("Couldn't fetch issue #%s, using last commit subject as title"):format(issue),
					vim.log.levels.WARN)
				submit(fallback_title)
			end
		end)
	end)
end

vim.api.nvim_create_user_command("GlMr", function(opts)
	create_mr(opts.fargs)
end, { nargs = "*", desc = "Create GitLab MR from fork branch into main repo" })

vim.keymap.set("n", "<leader>gm", "<cmd>GlMr<cr>", { desc = "Create GitLab MR" })
