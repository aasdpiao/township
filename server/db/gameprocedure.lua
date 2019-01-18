local gameprocedure = 
[[
DROP PROCEDURE IF EXISTS new_player;
CREATE PROCEDURE new_player(
    in in_account_id bigint,
    in in_town_name  varchar(20)
)
label_proc : BEGIN
    declare var_count INT;
    select count(*) into var_count from player where account_id = in_account_id;
    if var_count > 0 then
        select -1, "";
        leave label_proc;
    end if;
    insert into player
    (account_id, town_name)
    values(in_account_id, in_town_name);
    select 0;
END;


DROP PROCEDURE IF EXISTS load_player;
CREATE PROCEDURE load_player(
  in in_account_id bigint
)
  label_proc:begin 
    declare var_count int;
    select count(*) into var_count from player where account_id = in_account_id;
    if var_count <= 0 then 
      select -1,"角色数据不存在";
      leave label_proc;
    end if;
    select 0,town_name,gold,cash,topaz,emerald,ruby,amethyst,level,exp,thumb_up,avatar_index,
    role_attr,item_data,grid_data,plant_data,factory_data,feed_data,
    trains_data,seaport_data,flight_data,helicopter_data,achievement_data,market_data,employment_data,mail_data,friend_data,event_data,daily_data
    from player where account_id = in_account_id;
END;

DROP PROCEDURE IF EXISTS save_player;
CREATE PROCEDURE save_player(
      IN in_account_id          bigint,           IN in_town_name         varchar(20),
      IN in_gold                bigint,           IN in_cash              bigint, 
      IN in_topaz               bigint,           IN in_emerald           bigint,
      IN in_ruby                bigint,           IN in_amethyst          bigint, 
      IN in_level               int,              IN in_exp               bigint,
      IN in_thumb_up            int,              IN in_avatar_index      int,
      IN in_role_attr           mediumblob,       IN in_item_data         mediumblob,
      IN in_grid_data           mediumblob,       IN in_plant_data        mediumblob,
      IN in_factory_data        mediumblob,       IN in_feed_data         mediumblob,
      IN in_trains_data         mediumblob,       IN in_seaport_data      mediumblob,
      IN in_flight_data         mediumblob,       IN in_helicopter_data   mediumblob,
      IN in_achievement_data    mediumblob,       IN in_market_data       mediumblob,
      IN in_employment_data     mediumblob,       IN in_mail_data         mediumblob,
      IN in_friend_data         mediumblob,       IN in_event_data        mediumblob,
      IN in_daily_data          mediumblob)
label_proc:begin
      declare var_count int;
      select count(*) into var_count from player where account_id = in_account_id;
      if var_count <= 0 then
        select -1,"role_data_not_exists";
        leave label_proc;
      end if;
      UPDATE player SET
      town_name                       = in_town_name       ,
      gold                            = in_gold            ,
      cash                            = in_cash            ,
      topaz                           = in_topaz           ,
      emerald                         = in_emerald         ,
      ruby                            = in_ruby            ,
      amethyst                        = in_amethyst        ,
      level                           = in_level           ,
      exp                             = in_exp             ,
      thumb_up                        = in_thumb_up        ,
      avatar_index                    = in_avatar_index    ,

      role_attr                       = in_role_attr       ,
      item_data                       = in_item_data       ,
      grid_data                       = in_grid_data       ,
      plant_data                      = in_plant_data      ,
      factory_data                    = in_factory_data    ,
      feed_data                       = in_feed_data       ,
      trains_data                     = in_trains_data     ,
      seaport_data                    = in_seaport_data    ,
      flight_data                     = in_flight_data     ,
      helicopter_data                 = in_helicopter_data ,
      achievement_data                = in_achievement_data,
      market_data                     = in_market_data     ,
      employment_data                 = in_employment_data ,
      mail_data                       = in_mail_data       ,
      friend_data                     = in_friend_data     ,
      event_data                      = in_event_data     ,
      daily_data                      = in_daily_data
      WHERE in_account_id             = account_id;
      select 0,"save_data_sucess";
END;


DROP PROCEDURE IF EXISTS send_mail;
CREATE PROCEDURE send_mail(
  IN in_account_id      bigint, IN in_mail_data         mediumblob)
label_proc:begin
      declare var_count int;
      select count(*) into var_count from player where account_id = in_account_id;
      if var_count <= 0 then
        select -1,"role_data_not_exists";
        leave label_proc;
      end if;
      UPDATE player SET
      mail_data                       = in_mail_data
      WHERE in_account_id             = account_id;
      select 0,"save_data_sucess";
END;


DROP PROCEDURE IF EXISTS load_mail;
CREATE PROCEDURE load_mail()
label_proc:begin
      SELECT mail_id,title,content,timestamp,item_object FROM mail where DATE_SUB(CURDATE(), INTERVAL 30 DAY) <= date(timestamp);
END;


DROP PROCEDURE IF EXISTS save_mail;
CREATE PROCEDURE save_mail(
  IN in_title          varchar(256),    IN in_content          varchar(1024),
  IN in_item_object    varchar(256))
label_proc:begin
  insert into mail
  (title, content,item_object)
  values(in_title, in_content,in_item_object);
  select @@identity;
END;


DROP PROCEDURE IF EXISTS update_notice;
CREATE PROCEDURE update_notice( 
  IN in_content          varchar(1024))
label_proc:begin
    INSERT INTO notice(notice_id,content) VALUES(100000,in_content) ON DUPLICATE KEY UPDATE content=in_content;
END;


DROP PROCEDURE IF EXISTS load_notice;
CREATE PROCEDURE load_notice()
label_proc:begin
  SELECT notice_id,content FROM notice;
END;

DROP PROCEDURE IF EXISTS load_friends;
CREATE PROCEDURE load_friends()
label_proc:begin
  SELECT account_id,town_name,level,exp,avatar_index FROM player; 
END;

]]

return gameprocedure