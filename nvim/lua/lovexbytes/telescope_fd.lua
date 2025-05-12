local M = {}

local always_exclude = {
	"node_modules",
	"dist",
	".env",
	".git",
	".next",
	".DS_Store",
	".husky",
	"target",
}

function M.make_fd_command()
	local cmd = {
		"fd",
		"--type",
		"f",
		"--hidden", -- still search hidden files
		"--no-ignore", -- stop respecting .gitignore/.ignore/etc
	}
	for _, pattern in ipairs(always_exclude) do
		table.insert(cmd, "--exclude")
		table.insert(cmd, pattern)
	end
	return cmd
end

function M.get_filepaths(params)
	local cwd = params.cwd or vim.fn.getcwd()
	local cmd = M.make_fd_command()

	table.insert(cmd, ".")
	table.insert(cmd, cwd)

	return vim.fn.systemlist(cmd)
end

return M
