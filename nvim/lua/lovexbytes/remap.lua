-- project view
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- toggle highlighting
vim.api.nvim_create_user_command("ToggleSearchHighlight", function()
	if vim.v.hlsearch == 1 then
		vim.api.nvim_command("nohlsearch")
	else
		vim.api.nvim_command("set hlsearch")
	end
end, {})
vim.api.nvim_set_keymap("n", "<leader>h", ":ToggleSearchHighlight<CR>", { noremap = true, silent = true })

-- move visual selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- align cursor when half moving page
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- clipboard
vim.keymap.set("x", "<leader>p", '"_dp')

vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- splitters
vim.keymap.set("n", "<C-l>", "<C-w>l<CR>")
vim.keymap.set("n", "<C-h>", "<C-w>h<CR>")

-- replace all occurences of a word on cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- comments
vim.keymap.set("n", "<C-_>", ":norm gcc<CR>")
vim.keymap.set("x", "<C-_>", "gb", { remap = true })

-- hunk
local Terminal = require("toggleterm.terminal").Terminal
local hunk_terms = {}

local function close_hunk(term, root)
	vim.schedule(function()
		term:shutdown()
		hunk_terms[root] = nil
	end)
end

local function current_git_root()
	local argv0 = vim.fn.argv(0)
	if type(argv0) == "string" and argv0 ~= "" and vim.fn.isdirectory(argv0) == 1 then
		local root = vim.fs.root(vim.fn.fnamemodify(argv0, ":p"), ".git")
		if root ~= nil then
			return root
		end
	end

	local cwd = vim.fn.getcwd()
	local root = vim.fs.root(cwd, ".git")
	if root ~= nil then
		return root
	end

	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return nil
	end

	return vim.fs.root(vim.fs.dirname(path), ".git")
end

vim.keymap.set("n", "<leader>gd", function()
	local root = current_git_root()
	if root == nil then
		vim.notify("Hunk must be opened from inside a Git repository", vim.log.levels.WARN)
		return
	end

	if hunk_terms[root] == nil then
		hunk_terms[root] = Terminal:new({
			cmd = "hunk diff --watch",
			dir = root,
			direction = "float",
			hidden = true,
			close_on_exit = false,
			float_opts = {
				border = "curved",
			},
			on_open = function(term)
				vim.keymap.set({ "n", "t" }, "q", function()
					close_hunk(term, root)
				end, { buffer = term.bufnr, noremap = true, silent = true })

				vim.keymap.set({ "n", "t" }, "<Esc>", function()
					close_hunk(term, root)
				end, { buffer = term.bufnr, noremap = true, silent = true })
			end,
		})
	end

	hunk_terms[root]:toggle()
end, { desc = "Open Hunk", noremap = true, silent = true })
