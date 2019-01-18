local CMD = {}
local print_r = require "print_r"
local syslog =require "syslog"

local function string_split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function CMD.add_gold(role_object,cmd_args)
    local money = tonumber(cmd_args[1])
    role_object:add_gold(money,SOURCE_CODE.gm_power)
    LOG_INFO("add_gold money:%d",money)
    return 0
end

function CMD.add_cash(role_object,cmd_args)
    local money = tonumber(cmd_args[1])
    role_object:add_cash(money,SOURCE_CODE.gm_power)
    return 0
end

function CMD.add_exp(role_object,cmd_args)
    local exp = tonumber(cmd_args[1])
    role_object:add_exp(exp,SOURCE_CODE.gm_power)
    return 0
end

function CMD.add_item(role_object,cmd_args)
    local args = string_split(cmd_args[1]," ")
    local item_index = tonumber(args[1])
    local item_count = 1
    if args[2] then
        item_count = tonumber(args[2])
    end
    role_object:add_item(item_index,item_count,SOURCE_CODE.gm_power)
    return 0
end

function CMD.set_level(role_object,cmd_args)
    local level = tonumber(cmd_args[1])
    assert(level,"set level is nil")
    if role_object:get_level() >= level then return -1 end
    for i=role_object:get_level(),level - 1 do
        local max_exp = role_object:get_role_entry():get_max_exp()
        role_object:add_exp(max_exp,SOURCE_CODE.gm_power)
    end
    return 0
end

function CMD.add_topaz(role_object,cmd_args)
    local money = tonumber(cmd_args[1])
    role_object:add_topaz(money,SOURCE_CODE.gm_power)
    return 0
end

function CMD.add_emerald(role_object,cmd_args)
    local money = tonumber(cmd_args[1])
    role_object:add_emerald(money,SOURCE_CODE.gm_power)
    return 0
end

function CMD.add_ruby(role_object,cmd_args)
    local money = tonumber(cmd_args[1])
    role_object:add_ruby(money,SOURCE_CODE.gm_power)
    return 0
end

function CMD.add_amethyst(role_object,cmd_args)
    local money = tonumber(cmd_args[1])
    role_object:add_amethyst(money,SOURCE_CODE.gm_power)
    return 0
end

return CMD