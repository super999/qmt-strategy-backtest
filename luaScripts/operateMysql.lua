local function getCon(mysql_conf)
    local res = string.gmatch(mysql_conf, "([^,]+),")
    local ip = res()
    local port = tonumber(res())
    local db = res()
    local user = res()
    local passwd = res()
    local driver = require "luasql.mysql"
    local env = driver.mysql()
    local con = env:connect(db, user, passwd, ip, port)
    con:setautocommit(true)
    return con
end

local function genQuery_auth_user(user, oldPass)
    local strQuery = "select id from auth_user where username = '" .. user .. "' and password = '" .. oldPass .. "';"
    return strQuery
end

local function genUpdate_auth_user(id, newPass)
    local strQuery = "update auth_user set password = '" .. newPass .. "' where id = " .. id .. ";"
    return strQuery
end

local function genUpdate_user_help(id)
    local strQuery = "update usrmgr_userhelp set update_pwd_user_id = " .. id .. " where user_id = " .. id .. ";"
    return strQuery
end

function updateXtUserPassword(mysql_conf, user, oldPass, newPass)
    local strQuery = genQuery_auth_user(user, oldPass)
    local con = getCon(mysql_conf)
    con:execute[[set names utf8]]
    local cur = con:execute(strQuery)
    if cur:numrows() <= 0 then
        return "用户名或者密码错误"
    end
    local row = cur:fetch({}, "a")
	
    con:execute("begin")
    local strUpdate = genUpdate_auth_user(row["id"], newPass)
    local curUp, dbErrorMsg = con:execute(strUpdate)
    local strUpdate1 = genUpdate_user_help(row["id"])
    local curUp1, dbErrorMsg1 = con:execute(strUpdate1)
	
    if dbErrorMsg ~= nil or dbErrorMsg1 ~= nil then
        con:execute("rollback")
		con:close()
        return "密码更改出错"
    else
        con:execute("commit")
		con:close()
		return "SUCCESS"
    end
end

local function genQuery_account_account(mainAccountId)
    local strQuery = "select id from account_account where name = '" .. mainAccountId .. "';"
    return strQuery
end

local function genQuery_account_subaccount_id(mainAccountDbId)
    local strQuery = "select id from account_subaccount where parent_account_id = " .. tostring(mainAccountDbId) .. ";"
    return strQuery
end

local function genUpdate_account_account(mainAccountDbId, newPass)
    local strUpdate = "update account_account set password = '" .. newPass .. "' where id = " .. tostring(mainAccountDbId) .. ";"
    return strUpdate
end

local function genUpdate_account_subaccount_status(subAccountDbId)
    local strUpdate = "update account_subaccount set status = 1 where id = " .. tostring(subAccountDbId) .. ";"
    return strUpdate
end

function updateLocalPassword(mysql_conf, accountName, oldPass, newPass)
    -- 根据需求，不验证旧密码，直接修改新密码
    local subAccountDbId = 0
    local strMainQuery = genQuery_account_account(accountName)
    local con = getCon(mysql_conf)
    con:execute[[set names utf8]]
    local mainCursor = con:execute(strMainQuery)
    if mainCursor:numrows() <= 0 then
        -- 不考虑子账号
        return "账号不存在"
    else
        -- 主账号
        local mainRow = mainCursor:fetch({}, "a")
        local mainAccountDbId = mainRow["id"]

        local strSubQuery = genQuery_account_subaccount_id(mainAccountDbId)
        local subCursor = con:execute(strSubQuery)
        if subCursor:numrows() <= 0 then
            return "账号数据库错误"
        end
        local subRow = subCursor:fetch({}, "a")
        subAccountDbId = subRow["id"]

        local strMainUpdate = genUpdate_account_account(mainAccountDbId, newPass)
        local mainUpdated = con:execute(strMainUpdate)

        if mainUpdated <= 0 then
            return "新密码与旧密码相同"
        end

        local strSubUpdate = genUpdate_account_subaccount_status(subAccountDbId)
        con:execute(strSubUpdate)

        subCursor:close()
    end
    mainCursor:close()
    con:close()
    return "SUCCESS:" .. tostring(subAccountDbId)
end
