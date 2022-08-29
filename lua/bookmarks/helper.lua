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

return {
    file_exists = file_exists,
    read_all_file = read_all_file
}
