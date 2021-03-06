-- Author: myth929
-- Description: 插件相关封装，packer封装

-- 先导入 options 用户设置文件，后面可能会用到
local options = require("core.options")
local path = require("utils.api.path")
local packer_install_tbl = require("config.pluginsMap")
local CONSTANT = require('utils.constant')

-- 检查是否下载了 Packer，如果没有则自动下载
local init = function()
    local fn = vim.fn
    local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"

    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1e222a" })

    if fn.empty(fn.glob(install_path)) > 0 then
        print "Cloning packer .."
        fn.system { "git", "clone", "--depth", "1", CONSTANT.githubSource .. "wbthomason/packer.nvim", install_path }
        vim.cmd "packadd packer.nvim"
    end
end
init()

local packer = require("packer")

packer.init({
    git = {
        default_url_format = CONSTANT.githubSource .. "%s"
    },
})

packer.startup({
    function(use)
        for plug_name, plug_config in pairs(packer_install_tbl) do
            -- 定义新的插件配置文件，其实就是将 key 和 value 合并了
            local plug_options = vim.tbl_extend("force", { plug_name }, plug_config)

            -- 这里就是插件配置文件在磁盘中的路径，以 nv_ 开头，比如插件名称是 test_plugin
            -- 那么它的配置文件名称就是 nv_test_plugin.lua，注意是全小写的
            local plug_filename = plug_options.as or string.match(plug_name, "/([%w-_]+).?")
            local load_disk_path = path.join("config", "plugins", string.format("nv_%s", plug_filename:lower()))
            local file_disk_path = path.join(vim.fn.stdpath("config"), "lua", string.format("%s.lua", load_disk_path))

            -- 查看磁盘中该文件是否存在
            if path.is_exists(file_disk_path) then
                -- 判断插件类型
                if plug_config.ptp == "viml" then
                    plug_options.setup = string.format("require('%s').entrance()", load_disk_path)
                else
                    plug_options.setup = string.format("require('%s').before()", load_disk_path)
                    plug_options.config = string.format(
                        [[
                        require('%s').load()
                        require('%s').after()
                        ]],
                        load_disk_path,
                        load_disk_path
                    )
                end
            end
            use(plug_options)
        end
    end,
    -- 使用浮动窗口预览 packer 中插件的下载信息
    config = { display = { open_fn = require("packer.util").float } },
})

-- 创建一个自动命令，如果该文件被更改，则重新生成编译文件
local packer_user_config = vim.api.nvim_create_augroup("packer_user_config", { clear = true })

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "plugins.lua" },
    callback = function()
        vim.cmd("source <afile>")
        vim.cmd("PackerCompile")
        vim.pretty_print("Recompile plugins successify...")
    end,
    group = packer_user_config,
})

return packer