--账号数据库表定义
local accountdb = [[
create table IF NOT EXISTS account
(
    AccountID     bigint not null AUTO_INCREMENT,						#账号ID,自动生成
	Username      varchar(30) not null unique,							#账号名字,注册必须       	*
    Password      varchar(128) not null,								#账号密码,注册必须				*
    ServerName    varchar(128) not null,                                #平台id
	RegDate       timestamp default current_timestamp,		        	#账号注册时间,自动生成
	RealName      varchar(20),											#真实姓名,注册必须				*
	IDCard        varchar(20),											#身份证号码,注册必须			*
	Email         varchar(50),											#关联邮件,注册必须				*
	QQNumber      varchar(32),											#QQ号码
	Sex           tinyint,												#性别,1男,2女
	Birthday      date,													#生日日期
	LastLoginDate date,													#上次登录时间
	Question      varchar(40),											#密保问题
	Answer        varchar(40),											#密保答案
	LastPassword  varchar(30),											#上次密码
	ForbidLogin   int default 0,										#是否禁止登录
	OnlineTime    bigint default 0,										#在线时长
	primary key(AccountID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE account AUTO_INCREMENT = 1000000;
]]

return accountdb