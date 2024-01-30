function SetUpTheme()
	local catppuccin = require("catppuccin")

	catppuccin.setup({
		transparent_background = true,
		term_colors = true, -- sets terminal colors (e.g. `g:terminal_color_0`)
		integrations = {
			cmp = true,
			treesitter = true,
			telescope = {
				enabled = true,
			},
		},
	})
end

function ColourMyPencils(colour)
	colour = colour or "catppuccin-macchiato"
	vim.cmd.colorscheme(colour)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
end

SetUpTheme()
ColourMyPencils()
