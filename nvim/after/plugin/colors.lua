function SetUpTheme()
	-- local catppuccin = require("catppuccin")
	--
	-- catppuccin.setup({
	-- 	transparent_background = true,
	-- 	term_colors = true, -- sets terminal colors (e.g. `g:terminal_color_0`)
	-- 	integrations = {
	-- 		cmp = true,
	-- 		treesitter = true,
	-- 		telescope = {
	-- 			enabled = true,
	-- 		},
	-- 	},
	-- })
	require("vesper").setup({
		transparent = false, -- Boolean: Sets the background to transparent
		italics = {
			comments = true, -- Boolean: Italicizes comments
			keywords = true, -- Boolean: Italicizes keywords
			functions = true, -- Boolean: Italicizes functions
			strings = true, -- Boolean: Italicizes strings
			variables = true, -- Boolean: Italicizes variables
		},
		overrides = {}, -- A dictionary of group names, can be a function returning a dictionary or a table.
		palette_overrides = {},
	})
end

function ColourMyPencils(colour)
	-- colour = colour or "catppuccin-macchiato"
	colour = colour or "vesper"
	vim.cmd.colorscheme(colour)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
end

SetUpTheme()
ColourMyPencils()
