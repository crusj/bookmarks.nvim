local pickers       = require("telescope.pickers")
local finders       = require("telescope.finders")
local conf          = require("telescope.config").values
local actions       = require("telescope.actions")
local entry_display = require('telescope.pickers.entry_display')
local helper        = require("bookmarks.helper")

local function display_func(opts)
    local displayer = entry_display.create {
        separator = " |",
        items = {
            { width = 3 },
            { width = 33 },
            { width = 5 },
            { width = 20 },
            { remaining = true },
        }
    }

    local line_info = { opts.lnum, "TelescopeResultsLineNr" }
    local updated_at = os.date("%Y-%m-%d %H:%M:%S", opts["value"].updated_at)

    local common_len = helper.get_str_common_len(vim.fn.getcwd(), opts["filename"])
    local file_name = string.sub(opts["filename"], common_len + 2)
    local icon = (require 'nvim-web-devicons'.get_icon(opts.filename)) or ""
    return displayer {
        line_info,
        opts["value"]["description"],
        opts["value"]["fre"],
        updated_at,
        icon .. " " .. file_name,
    }
end


local function entry_maker_func(entry)
    return {
        value = entry,
        ordinal = entry["description"],
        display = display_func,
        filename = entry["filename"],
        lnum = entry["line"],
    }
end

local function picker_func(opts)
    opts = opts or {}
    local finder_func = function()
        local bookmarks = {}
        for _, bookmark in pairs(require("bookmarks.data").bookmarks) do
            table.insert(bookmarks, bookmark)
        end

        return finders.new_table {
            results = bookmarks,
            entry_maker = entry_maker_func,
        }
    end

    pickers.new(opts, {
        prompt_title = "Bookmarks",
        finder = finder_func(),
        previewer = conf.qflist_previewer(opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            local default_func = function()
                local entry = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                if not entry then
                    actions.close(prompt_bufnr)
                    return
                end
                require("bookmarks.list").telescope_jump_update(entry.value.id)
                actions.close(prompt_bufnr)
                -- 打开文件entry.value.filename 并跳转到entry.value.line行
                vim.api.nvim_command("edit " .. entry.value.filename)
                vim.api.nvim_win_set_cursor(0, {entry.value.line, 0})
            end
            map("n", "<CR>", default_func)
            map("i", "<CR>", default_func)

            return true
        end,
    }):find()
end


return require("telescope").register_extension {
    exports = {
        bookmarks = picker_func
    }
}
