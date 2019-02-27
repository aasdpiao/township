local skynet = require "skynet"
local datacenter = require "skynet.datacenter"

local item_config = require "config.item_config"
local build_config = require "config.build_config"
local build_unlock_config = require "config.build_unlock_config"
local product_plant = require "config.product_plant"
local levelup_config = require "config.levelupInfo_config"
local speedup_config = require "config.speed_up_config"
local product_build = require "config.product_build"
local product_config = require "config.product_factory"
local product_breed = require "config.product_breed"
local undeveloped_config = require "config.undeveloped_config"
local trains_config = require "config.trains_config"
local trains_order_config = require "config.trains_order_config"
local trains_reward = require "config.trains_reward"
local terminal_config = require "config.terminal_config"
local worker_config = require "config.worker_config"
local worker_levelup = require "config.worker_levelup"
local worker_profession = require "config.worker_profession"
local worker_skill = require "config.worker_skill"
local worker_starup = require "config.worker_starup"
local employ_config = require "config.employ_config"
local flight_order_config = require "config.plane_order_config"
local flight_reward_config = require "config.plane_reward_config"
local sign_box_config = require "config.sign_box_config"
local sign_in_config = require "config.sign_in_config"
local businessman_config = require "config.businessman_config"
local market_count_config = require "config.market_count_config"
local market_order_config = require "config.market_order_config"
local helicopter_count_config = require "config.helicopter_count_config"
local helicopter_order_config = require "config.helicopter_order_config"
local helicopter_person_config = require "config.helicopter_person_config"
local island_config = require "config.island_config"
local island_reward_config = require "config.island_reward_config"
local achievement_config = require "config.achievement_config"
local barn_config = require "config.barn_config"
local passerby_order_config = require "config.passerby_order_config"
local daily_config = require "config.daily_config"
local daily_reward_config = require "config.daily_reward_config"
local seven_config = require "config.seven_config"

local build_data = require "init_data.build_data"
local floor_data = require "init_data.floor_data"
local green_data = require "init_data.green_data"
local road_data = require "init_data.road_data"
local ground_data = require "init_data.ground_data"

skynet.start(function()
	datacenter.set("item_config", item_config)
	datacenter.set("build_config", build_config)
	datacenter.set("build_unlock_config", build_unlock_config)
	datacenter.set("product_plant", product_plant)
	datacenter.set("levelup_config", levelup_config)
	datacenter.set("speedup_config", speedup_config)
	datacenter.set("product_build", product_build)
	datacenter.set("product_config", product_config)
	datacenter.set("product_breed", product_breed)
	datacenter.set("undeveloped_config", undeveloped_config)
	datacenter.set("trains_config", trains_config)
	datacenter.set("trains_order_config", trains_order_config)
	datacenter.set("trains_reward", trains_reward)
	datacenter.set("terminal_config", terminal_config)
	datacenter.set("worker_levelup", worker_levelup)
	datacenter.set("worker_profession", worker_profession)
	datacenter.set("worker_skill", worker_skill)
	datacenter.set("worker_starup", worker_starup)
	datacenter.set("worker_config", worker_config)
	datacenter.set("employ_config", employ_config)
	datacenter.set("flight_order_config", flight_order_config)
	datacenter.set("flight_reward_config", flight_reward_config)
	datacenter.set("sign_box_config", sign_box_config)
	datacenter.set("sign_in_config", sign_in_config)
	datacenter.set("businessman_config", businessman_config)
	datacenter.set("market_count_config", market_count_config)
	datacenter.set("market_order_config", market_order_config)
	datacenter.set("helicopter_count_config", helicopter_count_config)
	datacenter.set("helicopter_order_config", helicopter_order_config)
	datacenter.set("helicopter_person_config", helicopter_person_config)
	datacenter.set("island_config", island_config)
	datacenter.set("island_reward_config", island_reward_config)
	datacenter.set("achievement_config", achievement_config)
	datacenter.set("barn_config", barn_config)
	datacenter.set("passerby_order_config", passerby_order_config)
	datacenter.set("daily_config", daily_config)
	datacenter.set("daily_reward_config", daily_reward_config)
	datacenter.set("seven_config", seven_config)

	datacenter.set("build_data", build_data)
	datacenter.set("floor_data", floor_data)
	datacenter.set("green_data", green_data)
	datacenter.set("road_data", road_data)
	datacenter.set("ground_data", ground_data)
end)
