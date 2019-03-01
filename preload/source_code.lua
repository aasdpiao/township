local source = {}

function source_msg(sc)
	if not sc then
		return "nil"
	end
	return source[sc].desc
end

local function add(sou)
	assert(source[sou.code] == nil, string.format("have the same error code[%x], msg[%s]", sou.code, sou.message))
	source[sou.code] = {desc = sou.desc , type = sou.type}
	return sou.code
end

SOURCE_CODE = {
	no_source            = add{code = 0x0000, desc = "未标记来源"},
	sign_in              = add{code = 0x0001, desc = "签到"},
	levelup              = add{code = 0x0002, desc = "升级"},
	buy_item             = add{code = 0x0003, desc = "购买物品"},
	sale_item            = add{code = 0x0004, desc = "出售物品"},
	harvest              = add{code = 0x0005, desc = "收获"},
	gm_power             = add{code = 0x0006, desc = "GM指令"},
	market               = add{code = 0x0007, desc = "市场购买"},
	commodity            = add{code = 0x0008, desc = "市场搜索购买"},
	finish               = add{code = 0x0009, desc = "完成"},
	reward               = add{code = 0x000a, desc = "奖励"},
	achieve              = add{code = 0x000b, desc = "成就"},
	mail                 = add{code = 0x000c, desc = "邮件"},
	help                 = add{code = 0x000d, desc = "帮助"},
	daily                = add{code = 0x000e, desc = "日常任务"},
	task                 = add{code = 0x000f, desc = "任务"},
	behelped             = add{code = 0x0010, desc = "被帮助"},
	return_consume       = add{code = 0x0011, desc = "消耗返还"},
	seven                = add{code = 0x0012, desc = "七天任务"},
}

return source