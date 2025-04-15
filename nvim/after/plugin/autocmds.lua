-- Define the autocommand group
local format_group_jsts = vim.api.nvim_create_augroup("MyJsTsFormatChainOnSave", { clear = true })

-- Create the BufWritePre autocommand specifically for JS/TS files
vim.api.nvim_create_autocmd("BufWritePre", {
	group = format_group_jsts,
	pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" }, -- Target only these file patterns/extensions
	callback = function(args)
		-- Step 1: Run Conform (Biome)
		require("conform").format(
			{
				bufnr = args.buf,
				lsp_fallback = true, -- Use same settings for consistency
				timeout_ms = 500,
			},
			-- Step 2: Run TailwindSort in the callback (after conform finishes)
			function(err, _)
				if err then
					vim.notify("conform format error (JS/TS Chain): " .. tostring(err), vim.log.levels.ERROR)
					return -- Don't sort if formatting failed
				end
				-- Execute TailwindSort command silently
				vim.api.nvim_command("silent! TailwindSort")
			end
		)
	end,
})
