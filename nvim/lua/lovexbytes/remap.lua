-- project view
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)


-- toggle highlighting
vim.api.nvim_create_user_command('ToggleSearchHighlight', function()
  if vim.v.hlsearch == 1 then
    vim.api.nvim_command('nohlsearch')
  else
    vim.api.nvim_command('set hlsearch')
  end
end, {})
vim.api.nvim_set_keymap('n', '<leader>h', ':ToggleSearchHighlight<CR>', {noremap = true, silent = true})

-- align cursor when half moving page
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- clipboard
vim.keymap.set("x", "<leader>p", "\"_dp")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")



vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")


