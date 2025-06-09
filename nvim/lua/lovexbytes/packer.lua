-- install lazy.nvim if not present
--
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

local telescope_fd = require("lovexbytes.telescope_fd")
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
		config = function()
			require("tailwind-sorter").setup({
				on_save_enabled = false,
				on_save_pattern = {
					"*.html",
					"*.js",
					"*.jsx",
					"*.tsx",
					"*.twig",
					"*.hbs",
					"*.php",
					"*.heex",
					"*.astro",
				},
				node_path = "node",
			})
		end,
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
		version = false,
		opts = {
			provider = "claude",
			cursor_applying_provider = "claude",
			behaviour = {
				enable_cursor_planning_mode = true,
			},
			providers = {
				openai = {
					api_key = os.getenv("OPENAI_API_KEY"), -- Reads OPENAI_API_KEY from your environment
					-- Default parameters for OpenAI models
					-- request_params = {
					--   temperature = 0.8,
					--   max_tokens = 2048,
					-- }
				},
				claude = {
					api_key = os.getenv("ANTHROPIC_API_KEY"), -- Reads OPENAI_API_KEY from your environment
					-- Default parameters for OpenAI models
					-- request_params = {
					--   temperature = 0.8,
					--   max_tokens = 2048,
					-- }
				},
			},
			file_selector = {
				provider = "telescope",
				provider_opts = {
					get_filepaths = telescope_fd.get_filepaths,
				},
			},
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"echasnovski/mini.pick", -- for file_selector provider mini.pick
			"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"ibhagwan/fzf-lua", -- for file_selector provider fzf
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
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
		build = function()
			require("pkl-neovim").init()

			-- Set up syntax highlighting.
			vim.cmd("TSInstall pkl")
		end,
		config = function()
			-- Set up snippets.
			require("luasnip.loaders.from_snipmate").lazy_load()

			-- Configure pkl-lsp
			vim.g.pkl_neovim = {
				-- start_command = { "java", "-jar", "/path/to/pkl-lsp.jar" },
				-- or if pkl-lsp is installed with brew:
				start_command = { "pkl-lsp" },
				pkl_cli_path = "/opt/homebrew/bin/pkl",
			}
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
