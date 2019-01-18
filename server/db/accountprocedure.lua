local accountprocedure = 
[[
DROP PROCEDURE IF EXISTS register_new_account;
CREATE PROCEDURE register_new_account(
	in in_user_name varchar(32), 
	in in_password varchar(32),
	in in_server_name varchar(32)
)
label_proc : BEGIN
    declare var_count int;
	declare var_user_name varchar(32);

	set var_user_name = trim(in_user_name);
	select count(*) into var_count from account where Username = in_user_name;
	if var_count > 0 then
		select 101, 0;
		leave label_proc;
	end if;
	insert into account
	(Username, Password,ServerName)
	values(var_user_name, in_password,in_server_name);
	select 100,@@identity;
END;

DROP PROCEDURE IF EXISTS check_account_id;
CREATE PROCEDURE check_account_id(
    IN in_accountid bigint
)
label_proc : BEGIN
	declare var_count int;
	select count(*) into var_count from account where AccountID = in_accountid;
	if var_count > 0 then
		select 1;
		leave label_proc;
	end if;
	select 0;
END;

DROP PROCEDURE IF EXISTS check_account_and_password;
CREATE PROCEDURE check_account_and_password(
	in in_user_name VARCHAR(32), 
	in in_password VARCHAR(32)
)
label_proc : BEGIN
		declare var_accountID VARCHAR(32);
		declare var_ForbidLogin int;
		select AccountID,ForbidLogin into var_accountID,var_ForbidLogin from account where Username = in_user_name
		and Password = in_password;

		if ISNULL(var_accountID) then
			select 201,0;
		else
			if var_ForbidLogin = 1 then
				select 202,0;
			else
				select 200, var_accountID;
			end if;
		end if;
END;

DROP PROCEDURE IF EXISTS forbid_account_login;
CREATE PROCEDURE forbid_account_login(
    IN in_accountid bigint
)
label_proc : BEGIN
    update account 
    set ForbidLogin = 1
    where AccountID = in_accountid;
END;

DROP PROCEDURE IF EXISTS update_account_online_time;
CREATE PROCEDURE update_account_online_time(
    IN in_accountid bigint,
    IN in_online_time int
)
BEGIN
	update account set
	OnlineTime = OnlineTime + in_online_time,
	LastLoginDate = now()
	where in_accountid = AccountID;
END;

]]

return accountprocedure