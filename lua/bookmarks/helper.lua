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
    get_str_common_len = get_str_common_len
}
