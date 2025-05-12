require("telescope").setup({
	defaults = {
		layout_strategy = "flex",
		layout_config = { height = 0.95, width = 0.95 },
		file_ignore_patterns = {
			"node_modules",
		},
	},
})

local builtin = require("telescope.builtin")

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

local function make_fd_command()
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

vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files({
		find_command = make_fd_command(),
	})
end)

vim.keymap.set("n", "<leader>gf", builtin.git_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", {})
vim.keymap.set("n", "gm", "<cmd>Telescope lsp_document_symbols<CR>", {})
