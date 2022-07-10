local w = {
    bufb = nil,
    bufbw = nil,
    bw = 0, -- bookmarks window width
    bh = 0, -- bookmarks window height

    buff = nil,
    bufw = nil,

    bufp = nil,
    previeww = nil,
    hl_cursorline_name = "hl_bookmarks_csl",

    autocmd = 0,

    filename = "",
    lineNumber = 0,
}

local config = nil

function w.setup()
    config = require("bookmarks.config").get_data()
    vim.cmd(string.format("highlight hl_bookmarks_csl %s", config.hl_cursorline))
end

function w.open_list_window()
    w.buff = vim.api.nvim_get_current_buf()
    w.bufw = vim.api.nvim_get_current_win()

    if w.bufb == nil or not vim.api.nvim_buf_is_valid(w.bufb) then
        w.bufb = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(w.bufb, 'filetype', 'bookmarks')
        vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.jump, ":lua require'bookmarks'.jump()<cr>", { silent = true })
        vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.delete, ":lua require'bookmarks'.delete()<cr>", { silent = true })
        vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.order, ":lua require'bookmarks.list'.refresh(true)<cr>", { silent = true })
    end

    local ew = vim.api.nvim_get_option("columns")
    local eh = vim.api.nvim_get_option("lines")


    local width = ew * config.width

    w.bw = math.floor(width * (1 - config.preview_ratio))
    w.bh = math.floor(eh * config.height)

    w.bufbw = vim.api.nvim_open_win(w.bufb, true, {
        relative = "editor",
        width = w.bw,
        height = w.bh,
        col = math.floor((ew - width) / 2),
        row = math.floor((eh - w.bh) / 2),
        border = "double",
    })

    vim.api.nvim_win_set_option(w.bufbw, "number", true)
    vim.api.nvim_win_set_option(w.bufbw, "relativenumber", false)
    vim.api.nvim_win_set_option(w.bufbw, "scl", "no")
    vim.api.nvim_win_set_option(w.bufbw, "cursorline", true)
    vim.api.nvim_win_set_option(w.bufbw, "wrap", false)
    vim.api.nvim_win_set_option(w.bufbw, "winhighlight", "CursorLine:" .. w.hl_cursorline_name)

    vim.api.nvim_win_set_buf(w.bufbw, w.bufb)
end

function w.open_preview(filename, lineNumber)
    if w.bufp == nil or (not vim.api.nvim_buf_is_valid(w.bufp)) then
        w.bufp = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(w.bufp, 'filetype', 'bookmarks_preview')
    end

    w.create_preview_w()

    if filename == nil or ( filename == w.filename and lineNumber == w.lineNumber) then
        return
    end

    local lines = {}
    vim.fn.jobstart("cat " .. filename, {
        on_stdout = function(_, data)
            for _, line in pairs(data) do
                lines[#lines + 1] = line
            end
        end,
        on_exit = function()
            if vim.api.nvim_buf_is_valid(w.bufp) then
                w.filename = filename
                w.lineNumber = lineNumber

                vim.api.nvim_buf_set_option(w.bufp, "modifiable", true)
                vim.api.nvim_buf_set_lines(w.bufp, 0, -1, false, {})
                vim.api.nvim_buf_set_lines(w.bufp, 0, #lines, false, lines)

                vim.api.nvim_set_current_win(w.previeww)
                vim.fn.execute("normal " .. lineNumber .. "G")
                vim.fn.execute("normal zz")
                vim.api.nvim_set_current_win(w.bufbw)

                vim.api.nvim_buf_set_option(w.bufp, "modifiable", false)
            end
        end
    })

end

function w.create_preview_w()
    local ew = vim.api.nvim_get_option("columns")
    local eh = vim.api.nvim_get_option("lines")

    local width = ew * config.width
    local pw = math.floor(ew * config.width * config.preview_ratio)

    if w.previeww == nil or (not vim.api.nvim_win_is_valid(w.previeww)) then
        w.previeww = vim.api.nvim_open_win(w.bufp, false, {
            relative = "editor",
            width = pw,
            height = w.bh,
            col = math.floor((ew - width) / 2 + w.bw + 1),
            row = math.floor((eh - w.bh) / 2),
            border = "double",
        })
    end
end

function w.close_previeww()
    if w.previeww ~= nil and vim.api.nvim_win_is_valid(w.previeww) then
        vim.api.nvim_win_hide(w.previeww)
        w.previeww = nil
        w.filename = ""
        w.lineNumber = ""
    end
end

function w.close_bw()
    vim.api.nvim_win_hide(w.bufbw)
    w.bufbw = nil
end

return w
