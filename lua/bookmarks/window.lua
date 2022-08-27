local w = {
    bufb = nil,
    bufbw = nil,
    bw = 0, -- bookmarks window width
    bh = 0, -- bookmarks window height

    buff = nil,
    bufw = nil,

    bufp = nil, -- preview buffer
    previeww = nil, -- preview window
    autocmd = 0, -- cursormoved autocmd id
    filename = "", -- current bookmarks filename
    lineNumber = 0, -- current bookmarks line number

    bufd = nil, -- detail buffer
    detailw = nil, -- detail window

    hl_cursorline_name = "hl_bookmarks_csl",
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
        vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.jump, ":lua require'bookmarks'.jump()<cr>",
            { silent = true })
        vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.delete, ":lua require'bookmarks'.delete()<cr>",
            { silent = true })
        vim.api.nvim_buf_set_keymap(w.bufb, "n", config.keymap.order, ":lua require'bookmarks.list'.refresh(true)<cr>",
            { silent = true })
    end

    local ew = vim.api.nvim_get_option("columns")
    local eh = vim.api.nvim_get_option("lines")


    local width = math.floor(ew * config.width)
    local height = math.floor(eh * config.height)

    w.bw = math.floor(width * (1 - config.preview_ratio))
    w.bh = height - 3

    w.bufbw = vim.api.nvim_open_win(w.bufb, true, {
        relative = "editor",
        width = w.bw,
        height = w.bh,
        col = math.floor((ew - width) / 2),
        row = math.floor((eh - height) / 2 + 3),
        border = "rounded",
    })

    vim.api.nvim_win_set_option(w.bufbw, "number", false)
    vim.api.nvim_win_set_option(w.bufbw, "scl", "no")
    vim.api.nvim_win_set_option(w.bufbw, "cursorline", true)
    vim.api.nvim_win_set_option(w.bufbw, "wrap", false)
    vim.api.nvim_win_set_option(w.bufbw, "winhighlight", "CursorLine:" .. w.hl_cursorline_name)

    vim.api.nvim_win_set_buf(w.bufbw, w.bufb)
end

-- open preview window
function w.open_preview(filename, lineNumber)
    if w.bufp == nil or (not vim.api.nvim_buf_is_valid(w.bufp)) then
        w.bufp = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(w.bufp, 'filetype', 'bookmarks_preview')
    end

    w.create_preview_w()

    if filename == nil or (filename == w.filename and lineNumber == w.lineNumber) then
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
                if config.preview_ext_enable then
                    local cuts = filename:split_b(".")
                    local ext = cuts[#cuts]
                    vim.api.nvim_buf_set_option(w.bufp, "filetype", ext)
                end
                vim.api.nvim_win_set_cursor(w.previeww, { lineNumber, 0 })
                vim.api.nvim_buf_set_option(w.bufp, "modifiable", false)
            end
        end
    })

end

function w.create_preview_w()
    local ew = vim.api.nvim_get_option("columns")
    local eh = vim.api.nvim_get_option("lines")

    local width = math.floor(ew * config.width)
    local height = math.floor(eh * config.height)
    local pw = math.floor(ew * config.width - w.bw)

    if w.previeww == nil or (not vim.api.nvim_win_is_valid(w.previeww)) then
        w.previeww = vim.api.nvim_open_win(w.bufp, false, {
            relative = "editor",
            width = pw,
            height = height - 3,
            col = math.floor((ew - width) / 2 + w.bw + 2),
            row = math.floor((eh - height) / 2 + height - w.bh),
            border = "rounded",
            noautocmd = true,
        })
    end
    vim.api.nvim_win_set_option(w.previeww, "number", true)
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

-- detail window shows message and bookmarks position info
function w.open_detail_window(item)
    if w.bufd == nil or (not vim.api.nvim_buf_is_valid(w.bufd)) then
        w.bufd = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(w.bufd, 'filetype', 'bookmarks_detail')
    end

    w.create_detail_w()

    if item ~= nil then
        local lines = {
            "Description: " .. item.description,
            "Filename: " .. item.filename .. ":" .. item.line,
            "Updated_at: " .. os.date("%Y-%m-%d %H:%M:%S", item.updated_at) .. " Fre: " .. item.fre,
        }

        vim.api.nvim_buf_set_option(w.bufd, "modifiable", true)
        vim.api.nvim_buf_set_lines(w.bufd, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(w.bufd, 0, #lines, false, lines)
        vim.api.nvim_buf_set_option(w.bufd, "modifiable", false)
    end
end

function w.create_detail_w()
    local ew = vim.api.nvim_get_option("columns")
    local eh = vim.api.nvim_get_option("lines")

    local width = math.floor(ew * config.width)
    local height = math.floor(eh * config.height)
    if w.detailw == nil or (not vim.api.nvim_win_is_valid(w.detailw)) then
        w.detailw = vim.api.nvim_open_win(w.bufd, false, {
            relative = "editor",
            width = width + 2,
            height = 3,
            col = math.floor((ew - width) / 2),
            row = math.floor((eh - height) / 2 - 1.5),
            border = "rounded",
            noautocmd = true,
        })
    end
    vim.api.nvim_win_set_option(w.detailw, "number", false)
    vim.api.nvim_win_set_option(w.detailw, 'cursorline', false)
end

function w.close_detail_window()
    if w.detailw ~= nil and vim.api.nvim_win_is_valid(w.detailw) then
        vim.api.nvim_win_hide(w.detailw)
        w.detailw = nil
    end
end

return w
