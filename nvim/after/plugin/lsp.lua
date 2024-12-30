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

-- Enable diagnostics update in insert mode
vim.diagnostic.config({ update_in_insert = true })

-- Set up default keymaps on attach
lsp.on_attach(function(client, bufnr)
	lsp.default_keymaps({ buffer = bufnr })
end)

-- Configure mason
require("mason").setup({
	ui = {
		border = "rounded",
	},
})

-- Configure mason-lspconfig
require("mason-lspconfig").setup({
	ensure_installed = {
		"tsserver",
		"tailwindcss",
		"eslint",
		"gopls",
		-- "goimports",
		"rust_analyzer",
		"quick_lint_js",
		"pyright",
		"lua_ls",
		"yamlls",
	},
	handlers = {
		lsp.default_setup,
		lua_ls = function()
			local lua_opts = lsp.nvim_lua_ls()
			require("lspconfig").lua_ls.setup(lua_opts)
			require("typescript-tools").setup({})
		end,
	},
})

-- Configure completion
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
	sources = {
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "nvim_lua" },
	},
	formatting = lsp.cmp_format(),
	mapping = cmp.mapping.preset.insert({
		["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
		["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
		["<C-y>"] = cmp.mapping.confirm({ select = true }),
	}),
})
