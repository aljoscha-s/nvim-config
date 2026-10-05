-- GitLab helpers built on the `glab` CLI.
--
-- :GlMr [glab flags]  Create a draft merge request, assigned to you, from the
--                     current branch on your fork into the main repo. Extra
--                     flags are passed through, e.g. `:GlMr --reviewer someone`
--                     or `:GlMr --draft=false` for a ready MR.
--
-- :GlBranch [issue]   Create a branch for an issue of the main repo, named the
--                     way GitLab's "Create branch" button does (1234-issue-title),
--                     off the main repo's default branch, and push it to your
--                     fork. Without an argument, pick from your assigned issues.

local FORK_REMOTE = "origin"
local UPSTREAM_REMOTES = { "opentalk", "upstream" } -- first existing one wins

local function git(args, cwd)
	local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	return vim.trim(result.stdout)
end

-- Run a command asynchronously, calling back on the main loop with
-- (ok, combined output)
local function run(cmd, cwd, callback)
	vim.system(cmd, { cwd = cwd, text = true }, function(result)
		vim.schedule(function()
			callback(result.code == 0, vim.trim((result.stdout or "") .. "\n" .. (result.stderr or "")))
		end)
	end)
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

local function notifier(title)
	return function(msg, level)
		vim.notify(msg, level or vim.log.levels.INFO, { title = title })
	end
end

-- Find the repo root, fork and main repo remotes, and the main repo's default
-- branch. Reports the problem and returns nil if something is missing.
local function resolve_repo(notify)
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

	-- The main repo's default branch, falling back to main
	local target = (git({ "symbolic-ref", "--short", "refs/remotes/" .. upstream .. "/HEAD" }, root) or "")
	    :gsub("^" .. vim.pesc(upstream) .. "/", "")
	if target == "" then
		target = "main"
	end

	local upstream_url = git({ "remote", "get-url", upstream }, root)
	local host, path = parse_remote(upstream_url)

	-- Username stored by `glab auth login`
	local user = vim.system({ "glab", "config", "get", "user", "--host", host }, { text = true }):wait()

	return {
		root = root,
		upstream = upstream,
		upstream_url = upstream_url,
		target = target,
		host = host,
		path = path,
		username = user.code == 0 and vim.trim(user.stdout) or "",
	}
end

-- GET a GitLab API endpoint of the main repo, calling back with the decoded
-- JSON or nil
local function api_get(repo, endpoint, callback)
	local url = ("projects/%s/%s"):format((repo.path:gsub("/", "%%2F")), endpoint)
	run({ "glab", "api", "--hostname", repo.host, url }, repo.root, function(ok, output)
		local decoded, data = pcall(vim.json.decode, output)
		callback(ok and decoded and type(data) == "table" and data or nil)
	end)
end

local function create_mr(extra_args)
	local notify = notifier("GitLab MR")
	local repo = resolve_repo(notify)
	if not repo then
		return
	end
	local root = repo.root

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

	local issue = branch:match("^(%d+)")
	local fallback_title = git({ "log", "-1", "--format=%s" }, root)

	local function submit(title)
		local cmd = {
			"glab", "mr", "create",
			"--repo", repo.upstream_url,
			"--head", git({ "remote", "get-url", FORK_REMOTE }, root),
			"--source-branch", branch,
			"--target-branch", repo.target,
			"--title", title,
			"--description", issue and ("Closes #" .. issue) or "",
			"--draft",
			"--yes",
		}
		if repo.username ~= "" then
			vim.list_extend(cmd, { "--assignee", repo.username })
		end
		vim.list_extend(cmd, extra_args)

		notify(("Creating MR %s → %s:%s ..."):format(branch, repo.upstream, repo.target))
		run(cmd, root, function(ok, output)
			if not ok then
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
	end

	if not issue then
		return submit(fallback_title)
	end

	-- Use the issue title as MR title, falling back to the last commit subject
	api_get(repo, "issues/" .. issue, function(data)
		if data and data.title then
			submit(data.title)
		else
			notify(("Couldn't fetch issue #%s, using last commit subject as title"):format(issue),
				vim.log.levels.WARN)
			submit(fallback_title)
		end
	end)
end

-- Common accented letters, transliterated like Rails' I18n default does
local TRANSLITERATE = {
	["ä"] = "a", ["ö"] = "o", ["ü"] = "u", ["Ä"] = "a", ["Ö"] = "o", ["Ü"] = "u", ["ß"] = "ss",
	["à"] = "a", ["á"] = "a", ["â"] = "a", ["ç"] = "c", ["è"] = "e", ["é"] = "e", ["ê"] = "e",
	["ë"] = "e", ["í"] = "i", ["î"] = "i", ["ï"] = "i", ["ñ"] = "n", ["ó"] = "o", ["ô"] = "o",
	["ú"] = "u", ["û"] = "u",
}

-- Mirrors GitLab's Issue#to_branch_name: "<iid>-<title.parameterize>",
-- truncated to 100 chars at a word boundary
local function issue_branch_name(issue)
	if issue.confidential then
		return issue.iid .. "-confidential-issue"
	end
	local slug = issue.title:gsub("\xC3[\x80-\xBF]", TRANSLITERATE):lower()
	slug = slug:gsub("[^%w%-_]+", "-"):gsub("%-%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
	local name = issue.iid .. "-" .. slug
	if #name > 100 then
		name = name:sub(1, 100):gsub("%-[^-]*$", "")
	end
	return name
end

local function create_issue_branch(issue)
	local notify = notifier("GitLab branch")
	local repo = resolve_repo(notify)
	if not repo then
		return
	end
	local root = repo.root

	local function checkout(data)
		local branch = issue_branch_name(data)

		if git({ "rev-parse", "--verify", "-q", "refs/heads/" .. branch }, root) then
			run({ "git", "switch", branch }, root, function(ok, output)
				if not ok then
					return notify("git switch failed:\n" .. output, vim.log.levels.ERROR)
				end
				notify(("Branch '%s' already exists, switched to it"):format(branch))
			end)
			return
		end

		local base = repo.upstream .. "/" .. repo.target
		notify(("Creating '%s' from %s ..."):format(branch, base))
		run({ "git", "fetch", repo.upstream, repo.target }, root, function(ok, output)
			if not ok then
				return notify("git fetch failed:\n" .. output, vim.log.levels.ERROR)
			end
			run({ "git", "switch", "--no-track", "-c", branch, base }, root, function(ok, output)
				if not ok then
					return notify("git switch failed:\n" .. output, vim.log.levels.ERROR)
				end
				run({ "git", "push", "-u", FORK_REMOTE, branch }, root, function(ok, output)
					if not ok then
						return notify(("Created '%s' but push to '%s' failed:\n%s"):format(branch, FORK_REMOTE, output),
							vim.log.levels.ERROR)
					end
					vim.cmd.checktime() -- reload buffers changed by the switch
					notify(("Switched to '%s', pushed to '%s'"):format(branch, FORK_REMOTE))
				end)
			end)
		end)
	end

	if issue then
		api_get(repo, "issues/" .. issue, function(data)
			if not (data and data.iid) then
				return notify(("Couldn't fetch issue #%s"):format(issue), vim.log.levels.ERROR)
			end
			checkout(data)
		end)
		return
	end

	-- No issue given: pick one of the open issues assigned to you
	if repo.username == "" then
		return notify("Unknown GitLab user, pass the issue number: :GlBranch 1234", vim.log.levels.ERROR)
	end
	local query = "issues?state=opened&per_page=100&order_by=updated_at&assignee_username=" .. repo.username
	api_get(repo, query, function(issues)
		if not issues then
			return notify("Couldn't fetch issues", vim.log.levels.ERROR)
		end
		if #issues == 0 then
			return notify("No open issues assigned to you, pass the issue number: :GlBranch 1234",
				vim.log.levels.WARN)
		end
		vim.ui.select(issues, {
			prompt = "Create branch for issue",
			format_item = function(item)
				return ("#%d  %s"):format(item.iid, item.title)
			end,
		}, function(choice)
			-- The builtin select (inputlist) stays on screen until a redraw,
			-- which the async git steps below don't trigger
			vim.cmd.redraw()
			if choice then
				checkout(choice)
			end
		end)
	end)
end

vim.api.nvim_create_user_command("GlMr", function(opts)
	create_mr(opts.fargs)
end, { nargs = "*", desc = "Create GitLab MR from fork branch into main repo" })

vim.api.nvim_create_user_command("GlBranch", function(opts)
	local issue = opts.args:match("^#?(%d+)$")
	if opts.args ~= "" and not issue then
		return notifier("GitLab branch")("Expected an issue number, e.g. :GlBranch 1234", vim.log.levels.ERROR)
	end
	create_issue_branch(issue)
end, { nargs = "?", desc = "Create and push a branch for a GitLab issue" })

vim.keymap.set("n", "<leader>gm", "<cmd>GlMr<cr>", { desc = "Create GitLab MR" })
vim.keymap.set("n", "<leader>gi", "<cmd>GlBranch<cr>", { desc = "Create branch from GitLab issue" })
