-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true
vim.keymap.set("n", "<C-b>", "<Cmd>Neotree toggle position=right<CR>")

require("neo-tree").setup({
    default_component_configs = {
        git_status = {
            symbols = {
                -- Change type
                added = "+", -- NOTE: you can set any of these to an empty string to not show them
                deleted = "✕",
                modified = "~",
                renamed = "~",
                -- Status type
                untracked = "",
                ignored = "",
                unstaged = "",
                staged = "",
                conflict = "",
            },
            align = "right",
        },
    },
    close_if_last_window = false,           -- Close Neo-tree if it is the last window left in the tab
    hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree in window.position
    filesystem = {
        follow_current_file = {
            enabled = true,          -- This will find and focus the file in the active buffer every time
            leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
    },
    window = {
        position = "right",
    },
})
