require("conform").setup({
	formatters = {
		biome = {
			args = { "format", "--stdin-file-path", "$FILENAME" },
			stdin = true,
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "biome" },
		typescript = { "biome" },
		typescriptreact = { "biome" },
		go = { "goimports", "gofmt" },
		sql = { "sql_formatter" },
		ddl = { "sql_formatter" },
		-- Use the "*" filetype to run formatters on all filetypes.
		["*"] = { "codespell" },
		-- Use the "_" filetype to run formatters on filetypes that don't
		-- have other formatters configured.
		["_"] = { "trim_whitespace" },
	},
	-- Configure format_on_save to FILTER OUT JS/TS types
	format_on_save = {
		lsp_fallback = true, -- Apply these options to the files that *do* run conform automatically
		timeout_ms = 500,
		-- Filter function: return 'false' to SKIP automatic formatting for these filetypes
		filter = function(bufnr)
			-- FIRST: Check if bufnr is actually a valid buffer number (positive integer)
			if type(bufnr) ~= "number" or bufnr <= 0 then
				-- vim.notify("Conform filter: Received invalid bufnr: " .. tostring(bufnr), vim.log.levels.WARN)
				-- Default to allowing conform's automatic formatting to proceed if bufnr is invalid.
				-- This prevents the filter itself from causing errors for other filetypes.
				return true
			end

			-- If bufnr is valid, proceed to get the filetype
			local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

			if type(ft) ~= "string" then
				-- vim.notify(
				-- "Conform filter: Invalid filetype for buffer " .. bufnr .. ": " .. tostring(ft),
				-- vim.log.levels.WARN
				-- )
				return true
			end

			local js_ts_types = {
				javascript = true,
				javascriptreact = true,
				typescript = true,
				typescriptreact = true,
			}
			-- Filter logic remains the same
			return not js_ts_types[ft]
		end,
	},
	-- Set the log level. Use `:ConformInfo` to see the location of the log file.
	log_level = vim.log.levels.ERROR,
	-- Conform will notify you when a formatter errors
	notify_on_error = true,
})
