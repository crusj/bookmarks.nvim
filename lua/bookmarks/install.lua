require("notify")
local helper = require("bookmarks.helper")
local package_root = helper.get_package_path()
local install_path = package_root .. "/lib"
if not vim.loop.fs_access(install_path, "RW") then
    vim.notify("test", vim.log.levels.INFO)
end

vim.notify("test", "error")
-- local shell_script = package_root .. "/install.sh"
-- local lib_name = "libbookmark.dylib"
-- local dir = vim.fn.system({ "pwd" });
-- print(vim.fn.system({ "sh", shell_script, install_path .. "/bookmark", lib_name }))
-- vim.fn.system({ "cd", dir })
