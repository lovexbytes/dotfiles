require("ts_context_commentstring").setup({
	-- Comment.nvim uses the pre_hook below, so the plugin's CursorHold
	-- autocmd is redundant and can crash when no Treesitter language tree exists.
	enable_autocmd = false,
})

require("Comment").setup({
	toggler = {
		line = "<C/>",
	},
	opleader = {
		line = "<C/>",
	},
	pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
})
