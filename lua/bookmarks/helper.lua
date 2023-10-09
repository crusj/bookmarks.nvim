-- check file is exists
local function file_exists(filename)
    local f = io.open(filename, "rb")
    if f then f:close() end
    return f ~= nil
end

-- return file contents
local function read_all_file(filename)
    if not file_exists(filename) then
        return nil
    end

    local lines = {}
    for line in io.lines(filename) do
        lines[#lines + 1] = line
    end

    return lines
end

local function read_preview_content(file_path, window_size, n)
    local file = io.open(file_path, "r")

    if not file then
        return
    end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end

    local start_line = math.max(n - math.floor(window_size / 2), 1)
    local end_line = math.min(start_line + window_size - 1, #lines)

    local content = {}
    for i = start_line, end_line do
        table.insert(content, lines[i])
    end

    file:close()

    return content, n - start_line + 1
end

local function get_str_common_len(a, b)
    local common_len = 0
    local min = #a
    if #a > #b then
        min = #b
    end

    for i = 1, min do
        if string.sub(a, i - 1, 1) == string.sub(b, i - 1, 1) then
            common_len = common_len + 1
        else
            break
        end
    end

    return common_len
end

return {
    file_exists = file_exists,
    read_all_file = read_all_file,
    read_preview_content = read_preview_content,
    get_str_common_len = get_str_common_len
}
