-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true
vim.keymap.set("n", "<C-b>", "<Cmd>Neotree toggle position=right<CR>")

require("neo-tree").setup({
	close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
	hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree in window.position
	window = {
		position = "right",
	},
})
