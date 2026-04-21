require "rpc"
require "std"
require "../../config/global.lua"

local mysql_conf = g_mysql_config
local KEY_SPLITTER = "____"
local XT_CAccountDetail = 543

local fieldName = {"m_dBBalance", "m_dDelCommission", "m_dDelMargin", "m_dIOGold", "m_dEBalance", "m_dAvailCap", "m_dCloseProfit", "m_dMortgage",
                    "m_dRisk", "m_dPositionProfit", "m_dClientBalance", "m_dAddToCash", "m_dCommission", "m_dOccupyMargin", "m_dBaseMargin", "m_dChangeAmout"}

local FIELDNUMBER = 16

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

local function getStateByAccountAndDay(account, strDate)
    local client = engine:createClient("traderservice")
    local response, error = net.request(client, "connect", {})
	local reqPtr = {account = account , TradingDay = strDdate}
	
    response, error = net.request(client, "querySettlementInfo", {req = reqPtr})
    return response
end

local function getAccountKey(account)
    local strKey = account.m_nBrokerType .. KEY_SPLITTER .. account.m_nPlatformID .. KEY_SPLITTER .. account.m_strBrokerID ..
                        KEY_SPLITTER .. account.m_nAccountType .. KEY_SPLITTER .. account.m_strAccountID .. KEY_SPLITTER .. account.m_strSubAccount
    return strKey
end

local function genQueryDateOfStateSql(strKey)
    local strQuery = "select m_strDate from idata_cstatement where m_priKey_tag = '" .. strKey .. "' order by m_strDate desc limit 1;"
    return strQuery
end

local function genQueryDataOfStateSql(priKey, strDate)
    local strQuery = "select * from idata_cstatement where m_priKey_tag = '" .. priKey .. "' and m_strDate = '" .. strDate .. "';"
    return strQuery
end

local function genUpdateDataOfStateSql(priKey, retNum, strDate)
    local strSql = "update idata_cstatement set {{SET_CONTENT}}" .. " where m_priKey_tag = '" .. priKey .. "' and m_strDate = '" .. strDate .. "';"
    local sCont = ""
    local first = true
    for k, v in pairs(retNum) do
        if first == false then
            sCont = sCont .. ", "
        end
        sCont = sCont .. k .. " = " .. v
        first = false
    end
    strSql = string.gsub(strSql, "{{SET_CONTENT}}", sCont)
    return strSql
end

local function genInsertDataOfStateSql(priKey, retNum, strDate)
    local strSql = "insert into idata_cstatement(m_priKey_tag, {{FIELD_NAME}} m_strDate) values('" .. priKey .. "', " .. "{{FIELD_VALUE}} '" .. strDate .. "');"
    local fName = ""
    local fValue = ""
    for k, v in pairs(retNum) do
        fName = fName .. k .. ", "
        fValue = fValue .. v .. ", "
    end
    strSql = string.gsub(strSql, "{{FIELD_NAME}}", fName)
    strSql = string.gsub(strSql, "{{FIELD_VALUE}}", fValue)
    return strSql
end

local function dealStatement( strCont )
    local numRes = string.gmatch( strCont, '[-+]?%d*[.]?%d+')
    
    retTable = {}
    
    for i = 1, FIELDNUMBER, 1 do
        retTable[fieldName[i]] = numRes()
    end
    --[[local st, et = string.find(strCont, '出 *入 *金')
    local dR, dL = string.find(strCont, '[-+]?%d*[.]?%d+', et)
    local dIOGold = string.sub(strCont, dR, dL)
    
    st, et = string.find(strCont, '期 *末 *结 *存 *')
    dR, dL = string.find(strCont, '[-+]?%d*[.]?%d+', et)
    
    local dBalance = string.sub(strCont, dR, dL)]]--
    return retTable
end

local function updateMySqlOfState(strCont, strDate, strKey, con)
    local retNum = dealStatement(strCont)
    local strQuery = genQueryDataOfStateSql(strKey, strDate)
    local cur = con:execute(strQuery)
    local rowNum = cur:numrows()
    
    local strSql = ""
    if rowNum == 0 then
        strSql = genInsertDataOfStateSql(strKey, retNum, strDate)
    else
        strSql= genUpdateDataOfStateSql(strKey, retNum, strDate)
    end
    cur = con:execute(strSql)
end

local function getAccountDetail(accountm)
    local client = engine:createClient("xtservice")
    local response, error = net.request(client, "connect", {})
    local reqParam = {}
    reqParam["function"] = "queryData"
    reqParam.param = {account = accountm, typeId = XT_CAccountDetail}
    response, error = net.request(client, "tradingmonitor", reqParam)
    return response, (error == nil)
end

local function getAccountList()
    local client = engine:createClient("xtservice")
    local response, error = net.request(client, "connect", {})
    local reqParam = {}
    reqParam["function"] = "queryAccounts"
    reqParam.param = {}
    response, error = net.request(client, "tradingmonitor", reqParam)
	return response
end

local function main()
    print "START"
    local file = "config.ini"
    local daySec = 60 * 60 * 24
    engine = net.getRPCEngine()
    engine:init(file)
    local con = getCon(mysql_conf)
    
    accountList = getAccountList()
    for k, account in ipairs(accountList.accounts) do
        local strKey = getAccountKey(account)
        local strQuery = genQueryDateOfStateSql(strKey)
        local cur = con:execute(strQuery)
        local rowNum = cur:numrows()
        local startDate = ""
        if rowNum == 0 then
            accountDetail = getAccountDetail(account)
            if accountDetail ~= nil and accountDetail.content[1].m_strOpenDate ~= "" then
                startDate = accountDetail.content[1].m_strOpenDate
            else
                startDate = "20050104"
            end
        else
            local row = cur:fetch({}, "n")
            startDate = row[1]
        end
        local timeTable = {}
        timeTable.year = tonumber(string.sub(startDate, 1, 4))
        timeTable.month = tonumber(string.sub(startDate, 5, 6))
        timeTable.day = tonumber(string.sub(startDate, 7, 8))
        timeTable.hour = 0
        timeTable.sec = 1
        local startSec = os.time(timeTable)
        local endSec = os.time()
  
        for i = startSec, endSec, daySec do
            if tonumber(os.date("%w", i)) <= 5 and tonumber(os.date("%w", i)) > 0 then
                local dateTable = os.date("*t", i)
                mD = ""
                if dateTable.month < 10 then
                    mD = "0"
                end
                dD = ""
                if dateTable.day < 10 then
                    dD = "0"
                end
                strDate = dateTable.year .. mD .. dateTable.month .. dD .. dateTable.day
                strCont = getStateByAccountAndDay(account, strDate)
                strState = ""
                if strCont ~= nil then
                    strState = strCont.content[2].Content .. strCont.content[3].Content
                end
                if strState ~= "" then
                    updateMySqlOfState(strState, strDate, strKey, con)
                end
            end
        end
    end
    con:close()
    print "OVER"
    engine:join()
end

main()
