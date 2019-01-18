--账号数据库表定义
local gamedb = [[
CREATE TABLE IF NOT EXISTS player
(
    account_id      bigint not null,                                      #账号ID
    town_name       varchar(20),                                          #小镇名称
    gold            bigint default 0,                                     #金币
    cash            bigint default 0,                                     #现金
    topaz           bigint default 0,                                     #黄玉
    emerald         bigint default 0,                                     #祖母绿
    ruby            bigint default 0,                                     #红宝石
    amethyst        bigint default 0,                                     #紫水晶
    level           int default 1,                                        #等级
    exp             bigint default 0,                                     #经验
    thumb_up        int default 0,                                        #点赞
    avatar_index    int default 1,                                        #头像

    role_attr           mediumblob,                                       #角色数据
    item_data           mediumblob,                                       #物品数据
    grid_data           mediumblob,                                       #建筑数据
    plant_data          mediumblob,                                       #种植数据
    factory_data        mediumblob,                                       #工厂数据
    feed_data           mediumblob,                                       #养殖数据
    trains_data         mediumblob,                                       #火车数据
    seaport_data        mediumblob,                                       #海港数据
    flight_data         mediumblob,                                       #航班订单
    helicopter_data     mediumblob,                                       #直升机订单
    achievement_data    mediumblob,                                       #成就数据
    market_data         mediumblob,                                       #市场数据
    employment_data     mediumblob,                                       #雇佣数据
    mail_data           mediumblob,                                       #邮件数据
    friend_data         mediumblob,                                       #好友数据
    event_data          mediumblob,                                       #事件数据
    daily_data          mediumblob,                                       #日常数据
	primary key(account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS mail
(
    mail_id             bigint not null AUTO_INCREMENT,                                  #邮件ID
    title               varchar(256),                                     #邮件标题
    content             varchar(1024),                                    #邮件内容
    timestamp           timestamp default current_timestamp,              #发送时间
    item_object         varchar(256),                                     #物品
    primary key(mail_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE mail AUTO_INCREMENT = 1000000;

CREATE TABLE IF NOT EXISTS notice
(
    notice_id          bigint not null,                                    #公告id
    content            varchar(1024),                                      #公告内容
    primary key(notice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]]

return gamedb