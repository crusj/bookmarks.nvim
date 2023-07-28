local helper = require("bookmarks.helper")
local package_root = helper.get_package_path()
local install_path = package_root .. "/lib"

local function complie()
    if not vim.loop.fs_access(install_path, "RW") then
        vim.notify("Access error, " .. install_path)
    end

    if not vim.loop.fs_stat(install_path .. "/bookmark.so") then
        local shell_script = package_root .. "/install.sh"
        local os_name = helper.get_os_type()
        local plugin_name = ""
        if os_name == "macOS" then
            plugin_name = "libbookmark.dylib"
        elseif os_name == "Linux" then
            plugin_name = "libbookmark.so"
        end
        vim.notify("Install bookmark plugin...", vim.log.levels.INFO)
        vim.fn.jobstart({ "sh", shell_script, install_path .. "/bookmark", plugin_name }, {
            on_stdout = function(_, data)
                for _, v in ipairs(data) do
                    if #v ~= 0 then
                        print(v)
                    end
                end
            end,
            on_exit = function(_, data)
                if vim.loop.fs_stat(install_path .. "/bookmark.so") then
                    vim.notify("Install bookmark plugin success.")
                else
                    vim.notify("Install bookmark plugin failed.")
                end
            end
        })
    end
end
