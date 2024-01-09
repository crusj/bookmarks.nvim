local M = {
    data = nil,
}

function M.setup(user_config)
    M.data = {
        storage_dir = "", -- default vim.fn.stdpath("data").."/bookmarks",
        mappings_enabled = true,
        keymap = {
            toggle = "<tab><tab>",    -- toggle bookmarks
            add = "\\z",              -- add bookmarks
            jump = "<CR>",            -- jump from bookmarks
            delete = "dd",            -- delete bookmarks
            order = "<space><space>", -- order bookmarks by frequency or updated_time
            delete_on_virt = "\\dd",  -- delete bookmark at virt text line
            show_desc = "\\sd",       -- show bookmark desc
            focus_tags = "<c-j>",      -- focus tags window
            focus_bookmarks = "<c-k>", -- focus bookmarks window
            toogle_focus = "<S-Tab>", -- toggle window focus (tags-win <-> bookmarks-win)
        },
        width = 0.8,                  -- bookmarks window width:  (0, 1]
        height = 0.7,                 -- bookmarks window height: (0, 1]
        preview_ratio = 0.45,         -- bookmarks preview window ratio (0.1]
        tags_ratio = 0.1,
        fix_enable = false,
        virt_text = "", -- Show virt text at the end of bookmarked lines, if it is empty, use the description of bookmarks instead.
        sign_icon = "󰃃", -- if it is not empty, show icon in signColumn.
        virt_pattern = { "*.go", "*.lua", "*.sh", "*.php", "*.rs" }, -- Show virt text only on matched pattern
        border_style = "single", -- border style: "single", "double", "rounded"
        hl = {
            border = "TelescopeBorder", -- border highlight
            cursorline = "guibg=Gray guifg=White", -- cursorline highlight
        },
        sep_path = "/",
    }

    if user_config ~= nil and type(user_config) == "table" then
        for dk, dv in pairs(M.data) do
            if type(dv) ~= "table" or dk == 'virt_pattern' then
                if user_config[dk] ~= nil then
                    M.data[dk] = user_config[dk]
                end
            else
                for fk, _ in pairs(dv) do
                    if user_config[dk] ~= nil and user_config[dk][fk] ~= nil then
                        M.data[dk][fk] = user_config[dk][fk]
                    end
                end
            end
        end
    end
    vim.cmd("hi link bookmarks_virt_text_hl Comment")

    -- check dir sep.
    local os_name = vim.loop.os_uname().sysname
    if os_name == "Windows" or os_name == "Windows_NT" then
        M.data.sep_path = "\\"
    end

    -- set default storage dir.
    if M.data.storage_dir == "" then
        M.data.storage_dir = vim.fn.stdpath("data") .. M.data.sep_path .. "bookmarks"
    end

    if M.data.sign_icon ~= "" then
        vim.fn.sign_define("BookmarkSign", { text = M.data.sign_icon })
    end
end

function M.get_data()
    return M.data
end

return M
