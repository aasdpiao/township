local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local print_r = require "print_r"
local syslog = require "syslog"
require "skynet.manager"

local accountdbtable = require "db.accountdb"
local gamedbtable = require "db.gamedb"
local globaldbtable = require "db.globaldb"

local accountprocedure = require "db.accountprocedure"
local gameprocedure = require "db.gameprocedure"
local globalprocedure = require "db.globalprocedure"

local defalut_count = 10

local mysqlhost = skynet.getenv "mysqlhost"
local mysqlport = tonumber(skynet.getenv "mysqlport")

local township_accountdb = skynet.getenv "township_accountdb"
local township_gamedb = skynet.getenv "township_gamedb"
local township_globaldb = skynet.getenv "township_globaldb"

local dbconfig = {
    host=mysqlhost,
    port=mysqlport,
    user="township",
    password="123456",
    max_packet_size = 1024 * 1024,
    compact_arrays = true
}

local dbnames = {
    township_accountdb,
    township_gamedb,
    township_globaldb
}

local dbtables = {
    accountdbtable,
    gamedbtable,
    globaldbtable
}

local dbprocedures = {
    accountprocedure,
    gameprocedure,
    globalprocedure
} 

local gamedbpool = {}
local accountdbpool = {}
local globaldbpool = {}

local accountconf = {
	host = mysqlhost,
	port = mysqlport,
	database = township_accountdb,
	user="township",
	password="123456",
	max_packet_size = 1024 * 1024,
	compact_arrays = true
}

local gameconf = {
	host = mysqlhost,
	port = mysqlport,
	database = township_gamedb,
	user="township",
	password="123456",
	max_packet_size = 1024 * 1024,
	compact_arrays = true
}

local globalconf = {
	host = mysqlhost,
	port = mysqlport,
	database = township_globaldb,
	user="township",
	password="123456",
	max_packet_size = 1024 * 1024,
	compact_arrays = true
}

local server = {}

function server.initial()
    local db=mysql.connect(dbconfig)
    if not db then
        skynet.error("failed to connect to mysql server")
    end
    skynet.error("success to connect to mysql server")
    local has_res = db:query("show databases")
    local hasdb = {}
    for k,v in pairs(has_res) do
        local dbname = v[1]
        hasdb[dbname] = true
    end
    for index,dbname in ipairs(dbnames) do
        if not hasdb[dbname] then
            local ret = db:query(string.format("create database %s character set utf8 collate utf8_general_ci", dbname))
            if ret.err or ret.errno then
                skynet.error("create database fail")
                return
            end
            skynet.error("success to create database")
            db:query(string.format("use %s", dbname))
            local dbtable = dbtables[index]
            ret = db:query(dbtable)
            if ret.err or ret.errno then
                skynet.error("create table fail")
                return
            end
            skynet.error("success to create table")
        else
            db:query(string.format("use %s", dbname))
        end
        local dbprocedure = dbprocedures[index]
        ret = db:query(dbprocedure)
        if ret.err or ret.errno then
            skynet.error("create procedure fail")
            skynet.error(ret.err..ret.errno)
            return
        end
        skynet.error("success to create procedure")
    end
    db:disconnect()
    server.start()
end

local function connect_account_db()
    for i = 1,defalut_count do
        local accountdb = mysql.connect(accountconf)
        if not accountdb then
            return false
        end
        table.insert(accountdbpool,accountdb)
    end
    return true
end

local function connect_game_db()
    for i = 1,defalut_count do
        local gamedb = mysql.connect(gameconf)
	    if not gamedb then
            return false
        end
        table.insert(gamedbpool,gamedb)
    end    
    return true
end

local function connect_global_db()
    for i = 1,defalut_count do
        local globaldb = mysql.connect(globalconf)
        if not globaldb then
            return false
        end
        table.insert(globaldbpool,globaldb)
    end
    return true
end

local accountdb_index = 2
local function get_accountdb_connect(sync)
    local db
    if sync then
        db = accountdbpool[1] 
    else
        db = accountdbpool[accountdb_index]
        assert(db)
        accountdb_index = accountdb_index + 1
        if accountdb_index > defalut_count then
            accountdb_index = 2
        end
    end
    return db
end


local gamedb_index = 2
local function get_gamedb_connect(sync)
    local db
    if sync then
        db = gamedbpool[1] 
    else
        db = gamedbpool[gamedb_index]
        assert(db)
        gamedb_index = gamedb_index + 1
        if gamedb_index > defalut_count then
            gamedb_index = 2
        end
    end
    return db
end

local globaldb_index = 2
local function get_globaldb_connect(sync)
    local db
    if sync then
        db = globaldbpool[1] 
    else
        db = globaldbpool[globaldb_index]
        assert(db)
        globaldb_index = globaldb_index + 1
        if globaldb_index > defalut_count then
            globaldb_index = 2
        end
    end
    return db
end

function server.start()
	assert(connect_account_db())
	assert(connect_global_db())
	assert(connect_game_db())
end

local CMD = {}

function CMD.querygamedb(sql,sync)
    --syslog.debug(sql)
    local gamedb = get_gamedb_connect(sync)
    local ret = gamedb:query(sql)
    --print_r(ret)
    return ret
end

function CMD.queryaccountdb(sql,sync)
    --syslog.debug(sql)
    local accountdb = get_accountdb_connect(sync)
    local ret = accountdb:query(sql)
    --print_r(ret)
    return ret
end

function CMD.queryglobaldb(sql,sync)
    local globaldb = get_globaldb_connect(sync)
    return globaldb:query(sql)
end

skynet.start(function()
    server.initial()
    skynet.dispatch("lua", function (_,_,cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        end
    end)
	skynet.register(SERVICE_NAME)
end)