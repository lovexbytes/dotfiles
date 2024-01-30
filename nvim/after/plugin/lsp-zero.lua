local lsp = require("lsp-zero")

lsp.preset("recommended")

lsp.set_preferences({
	sign_icons = {
		error = "E",
		warn = "W",
		hint = "H",
		info = "I",
	},
})

lsp.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = true }

	-- vim.keymap.set("n", "gd", function()
	-- 	vim.lsp.buf.definition()
	-- end, opts)
	-- vim.keymap.set("n", "gD", function()
	-- 	vim.lsp.buf.declaration()
	-- end, opts)
	-- vim.keymap.set("n", "K", function()
	-- 	vim.lsp.buf.hover()
	-- end, opts)
	-- vim.keymap.set("n", "<leader>vws", function()
	-- 	vim.lsp.buf.workspace_symbol()
	-- end, opts)
	-- vim.keymap.set("n", "<leader>vd", function()
	-- 	vim.diagnostic.open_float()
	-- end, opts)
	-- vim.keymap.set("n", "[d", function()
	-- 	vim.diagnostic.goto_next()
	-- end, opts)
	-- vim.keymap.set("n", "]d", function()
	-- 	vim.diagnostic.goto_prev()
	-- end, opts)
	-- vim.keymap.set("n", "<leader>vca", function()
	-- 	vim.lsp.buf.code_action()
	-- end, opts)
	-- vim.keymap.set("n", "<leader>vrr", function()
	-- 	vim.lsp.buf.references()
	-- end, opts)
	-- vim.keymap.set("n", "<leader>vrn", function()
	-- 	vim.lsp.buf.rename()
	-- end, opts)
	-- vim.keymap.set("i", "<C-h>", function()
	-- 	vim.lsp.buf.signature_help()
	-- end, opts)
end)

vim.diagnostic.config({ update_in_insert = true })

require("mason").setup({
	ui = {
		border = "rounded",
	},
})
require("mason-lspconfig").setup({
	ensure_installed = {
		"tsserver",
		"eslint",
		"gopls",
		"rust_analyzer",
		"quick_lint_js",
		"pyright",
		"lua_ls",
	},
	handlers = {
		lsp.default_setup,
		lua_ls = function()
			local lua_opts = lsp.nvim_lua_ls()
			require("lspconfig").lua_ls.setup(lua_opts)
		end,
	},
})
