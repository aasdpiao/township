local globalprocedure = 
[[
DROP PROCEDURE IF EXISTS save_global;
CREATE PROCEDURE save_global(
)
label_proc : BEGIN
    select 0;
END;
]]


return globalprocedure