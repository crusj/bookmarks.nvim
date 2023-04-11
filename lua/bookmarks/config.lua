local M = {
    data = nil
}

function M.setup(user_config)
    M.data = {
        keymap = {
            toggle = "<tab><tab>", -- toggle bookmarks
            add = "\\z", -- add bookmarks
            jump = "<CR>", -- jump from bookmarks
            delete = "dd", -- delete bookmarks
            order = "<space><space>", -- order bookmarks by frequency or updated_time
            delete_on_virt = "\\dd", -- delete bookmark at virt text line
            show_desc = "\\sd" -- show bookmark desc
        },
        width = 0.8, -- bookmarks window width:  (0, 1]
        height = 0.7, -- bookmarks window height: (0, 1]
        preview_ratio = 0.45, -- bookmarks preview window ratio (0.1]
        preview_ext_enable = false, -- if true, preview buf will add file ext, preview window may be highlighed(treesitter), but may be slower
        fix_enable = false,
        virt_text = "🔖", -- Show virt text at the end of bookmarked lines
        virt_pattern = { "*.go", "*.lua", "*.sh", "*.php", "*.rs" }, -- Show virt text only on matched pattern
        border_style = "single", -- border style: "single", "double", "rounded" 
        hl = {
            border = "TelescopeBorder", -- border highlight
            cursorline = "guibg=Gray guifg=White", -- cursorline highlight
        }
    }

    if user_config == nil or type(user_config) ~= "table" then
        return
    end

    for dk, dv in pairs(M.data) do
        if type(dv) ~= "table" then
            if user_config[dk] ~= nil then
                M.data[dk] = user_config[dk]
            end
        else
            for fk, fv in pairs(dv) do
                if user_config[dk] ~= nil and user_config[dk][fk] ~= nil then
                    M.data[dk][fk] = user_config[dk][fk]
                end
            end
        end
    end
end

function M.get_data()
    return M.data
end

return M
