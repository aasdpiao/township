--账号数据库表定义
local globaldb = [[
create table IF NOT EXISTS global
(
    AccountID     bigint not null AUTO_INCREMENT,						#账号ID,自动生成
	primary key(AccountID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE global AUTO_INCREMENT = 1000000;
]]

return globaldb