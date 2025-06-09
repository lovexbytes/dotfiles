-- ~/.config/nvim/after/plugin/telescope.lua
local telescope_fd = require("lovexbytes.telescope_fd")
local builtin = require("telescope.builtin")

require("telescope").setup({
	defaults = {
		layout_strategy = "flex",
		layout_config = { height = 0.95, width = 0.95 },
		file_ignore_patterns = { "node_modules" }, -- still applies if you want,
	},
	pickers = {
		find_files = {
			previewer = false, -- ✦ disables preview
			layout_config = {
				-- this makes full use of the window:
				width = 0.95,
				height = 0.95,
				preview_cutoff = 1, -- minimal threshold: always disable preview
			},
		},
		-- you can add more pickers here, e.g.:
		-- git_files = { previewer = false },
	},
})

-- wired to your <leader>ff
vim.keymap.set("n", "<leader>ff", function()
	builtin.find_files({
		find_command = telescope_fd.make_fd_command(),
	})
end)

-- other mappings…
vim.keymap.set("n", "<leader>gf", builtin.git_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", {})
vim.keymap.set("n", "gm", "<cmd>Telescope lsp_document_symbols<CR>", {})
