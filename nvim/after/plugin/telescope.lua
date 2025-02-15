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

vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files({
		find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
	})
end)

vim.keymap.set("n", "<leader>gf", builtin.git_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", {})
vim.keymap.set("n", "gm", "<cmd>Telescope lsp_document_symbols<CR>", {})
