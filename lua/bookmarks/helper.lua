local lib = nil
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

local function get_package_path()
    -- Path to this source file, removing the leading '@'
    local source = string.sub(debug.getinfo(1, "S").source, 2)

    -- Path to the package root
    return vim.fn.fnamemodify(source, ":p:h:h:h")
end

local function get_lib()
    if lib == nil then
        if not string.find(package.cpath, "bookmark.so") then
            package.cpath = package.cpath .. ";" .. get_package_path() .. "/lib/bookmark.so"
        end
        lib = require("bookmark")
    end

    return lib
end

local function get_os_type()
    local uname_info = vim.loop.os_uname()
    if uname_info.sysname == "Linux" then
        return "Linux"
    elseif uname_info.sysname == "Darwin" then
        return "macOS"
    elseif uname_info.sysname == "Windows" then
        return "Windows"
    else
        return "Unknown"
    end
end

return {
    file_exists = file_exists,
    read_all_file = read_all_file,
    get_str_common_len = get_str_common_len,
    get_package_path = get_package_path,
    get_lib = get_lib,
    get_os_type = get_os_type
}
