-- install lazy.nvim if not present
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

return require("lazy").setup({
	-- telescope
	{ "nvim-lua/plenary.nvim" },
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	{ "nvim-telescope/telescope.nvim", tag = "0.1.5" },
	-- colorscheme
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	-- { "datsfilipe/vesper.nvim" },

	-- lsp
	{ "VonHeikemen/lsp-zero.nvim", branch = "v3.x" },
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "neovim/nvim-lspconfig" },
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	},
	-- autocompletion
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-buffer" }, -- source for text in buffer
	{ "hrsh7th/cmp-path" }, -- source for file system paths
	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {},
		config = function(_, opts)
			require("lsp_signature").setup(opts)
		end,
	}, -- method signatures
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {}, -- this is equalent to setup({}) function
	},
	-- snippets
	{ "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
	-- floating terminal
	{ "akinsho/toggleterm.nvim", version = "2.9.0", config = true },
	-- neotree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
	},
	-- formatter
	{
		"stevearc/conform.nvim",
		opts = {},
	},
	-- git
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	-- tailwind
	{
		"laytan/tailwind-sorter.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
		build = "cd formatter && npm i && npm run build",
		config = true,
	},
	--earthly
	{
		"earthly/earthly.vim",
		branch = "main",
	},
	--protobuf
	{
		"dense-analysis/ale",
		config = function()
			-- vim.g.ale_lint_on_text_changed = "never"
			vim.g.ale_linters_explicit = 1
			vim.g.ale_linters = {
				proto = { "buf-lint" },
			}
		end,
	},
	{
		"bufbuild/vim-buf",
	},
	--codegen
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		build = "make", -- This is Optional, only if you want to use tiktoken_core to calculate tokens count
		opts = {
			-- add any opts here
		},
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below is optional, make sure to setup it properly if you have lazy=true
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
	{
		"apple/pkl-neovim",
		lazy = true,
		ft = "pkl",
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter",
				build = function(_)
					vim.cmd("TSUpdate")
				end,
			},
			"L3MON4D3/LuaSnip",
		},
		config = function()
			require("pkl-neovim.internal").init()
			require("luasnip.loaders.from_snipmate").lazy_load()

			vim.treesitter.language.register("pkl", "pkl")
		end,
	},
	--comment
	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
		dependencies = {

			"JoosepAlviste/nvim-ts-context-commentstring",
		},
	},
}, opts)
