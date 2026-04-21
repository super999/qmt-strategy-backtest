require "rpc"
require "std"

KEY_SPLITTER = "____"

m_tmsSetting = {}
m_ordersMap = {}
orderList = {}
client = nil

local firstPush = true

local XT_COrderDetail = 542
local ALARMTYPE_ORDER = 0
local ALARMTYPE_POSITION = 1
local ALARMTYPE_POSITION_SUB = 2

local function sixIntTimeToSeconds(year, month, day, hour, minute, second)
    month = month - 2
    if 0 >= month then
        month = month + 12
        year = year - 1
    end
    
    local a = math.modf(year / 4)
    local b = math.modf(year / 100)
    local c = math.modf(year / 400)
    local d = math.modf(367 * month / 12)
    return ((((a - b + c + d + day) + year * 365 - 719499) * 24 + hour - 8) * 60 + minute) * 60 + second 
end

local function intTimeToSeconds(datetime)
    local _date = math.modf(datetime / 1000000)
    local _time = datetime % 1000000
    local year =  math.modf(_date / 10000)
    local month = math.modf(_date % 10000 / 100) 
    local day = math.modf(_date % 100)
    local hour = math.modf(_time / 10000)
    local minute = math.modf(_time % 10000 / 100)
    local second = math.modf(_time % 100)
    return sixIntTimeToSeconds(year, month, day, hour, minute, second)
end

local function strTimeToSeconds( timeStr )
    local datetime = 0
    timeStr = string.gsub(timeStr, "-", "")
    timeStr = string.gsub(timeStr, " ", "");
    timeStr = string.gsub(timeStr, ":", "");
    datetime = tonumber(timeStr)

    return intTimeToSeconds(datetime)
end

local function getAccountID( account )
    if account["m_strSubAccount"] == "" then
        return account["m_strAccountID"]
    end
    return account["m_strSubAccount"]
end

local function genAccountKey(accountInfo)
    if accountInfo["m_strSubAccount"] == nil then
        accountInfo["m_strSubAccount"] = ""
    end
    return accountInfo["m_nBrokerType"] .. KEY_SPLITTER .. accountInfo["m_nPlatformID"] .. KEY_SPLITTER ..
            accountInfo["m_strBrokerID"] .. KEY_SPLITTER .. accountInfo["m_nAccountType"] .. KEY_SPLITTER .. 
            accountInfo["m_strAccountID"] .. KEY_SPLITTER .. accountInfo["m_strSubAccount"]
end

function onSendMsg(response, error)
    
end

local function passMessage(type, strMsgm, accountm)
    local reqParam = {}
    if next(accountm["m_addresses"]) == nil then
        accountm["m_addresses"] = nil
    end
    reqParam["function"] = "sendAlarmMsg"
    reqParam.param = {eType = type, strMsg = strMsgm, account = accountm}
    net.request_async(client, "tradingmonitor", reqParam, onSendMsg)
    printLog("send message" ..  strMsgm)
end

local function isSuperAccount(account)
    return account["m_strSubAccount"] == ""
end

function checkOrder(order, orderKey)
    printLog("check order" .. orderKey)
    if orderList[orderKey] ~= nil then
        return 
    end
    orderList[orderKey] = 1
    local strAccountKey = genAccountKey(order["m_accountInfo"])
    if m_ordersMap[strAccountKey] ~= nil then
        local tableOrder = m_ordersMap[strAccountKey]
        local firstIndex = tableOrder[1]
        local tailIndex = tableOrder[2]
        local nAccountAlarmCount = 100
        local nAccountTimeInterval = 5
        if isSuperAccount(order.m_accountInfo) then
            if m_tmsSetting["m_nMainAccountEnabled"] == 0 then
                return ""
            end
            nAccountAlarmCount   = m_tmsSetting["m_nMainAccountAlarmCount"]
            nAccountTimeInterval = m_tmsSetting["m_nMainAccountTimeInterval"]
        else
            if m_tmsSetting["m_nSubAccountEnabled"] == 0 then
                return ""
            end
            nAccountAlarmCount = m_tmsSetting["m_nSubAccountAlarmCount"]            
            nAccountTimeInterval = m_tmsSetting["m_nSubAccountTimeInterval"]
        end
        local rawAccountAlarmCount = nAccountAlarmCount 
        local rawAccountTimeInterval = nAccountTimeInterval
        if nAccountAlarmCount == 1 then
            nAccountAlarmCount = 2 * nAccountAlarmCount
            nAccountTimeInterval = 2 * nAccountTimeInterval
        end
        while (tailIndex - firstIndex - 1) >= nAccountAlarmCount do
            firstIndex = firstIndex + 1
            tableOrder[firstIndex] = nil
        end
        local strTime = order["m_strInsertDate"] .. " " .. order["m_strInsertTime"]
        tableOrder[tailIndex] = strTimeToSeconds(strTime)
        tailIndex = tailIndex + 1
        if (tailIndex - firstIndex - 1) == nAccountAlarmCount then
            local strBeginTime = tableOrder[firstIndex+1]
            local strEndTime   = tableOrder[tailIndex-1]
            local nTimeInterval = strEndTime - strBeginTime
            if nTimeInterval <= nAccountTimeInterval then
                strMsg = "[监控] 账号" .. getAccountID(order["m_accountInfo"]) .. "在" .. rawAccountTimeInterval .. "秒内委托数量超过阈值" .. rawAccountAlarmCount .. "笔"
                passMessage(ALARMTYPE_ORDER, strMsg, order.m_accountInfo);
           end
        end
        tableOrder[1] = firstIndex
        tableOrder[2] = tailIndex 
    else
        local strTime = order["m_strInsertDate"] .. " " .. order["m_strInsertTime"]
        tableOrder = {3, 4, strTimeToSeconds(strTime)}
        m_ordersMap[strAccountKey] = tableOrder
    end
end

function pushSetting(setting)
    printLog("pushSetting")
    m_tmsSetting = setting.settings
end

function pushData(data)
    printLog("data base id" .. data.baseId)
    if data.baseId == XT_COrderDetail then
        checkOrder(data.data, data.key)
    end    
end

function onNotification(func, param)
    printLog(func)
    local f = _G[func]
    f(param)
end

function onLogin(response, error, isFirst)
    printLog("on Login")
end

function onConnected(response, error, isFirst)
    if error == nil then     
        local reqParam = {}
        reqParam.param = {}
        reqParam["function"] = "login"
        net.request_async(client, "tradingmonitor", reqParam, onLogin)
        printLog("on connected")
    else
        printLog("on disconnected")   
    end
end

local function main()
    printLog("start")
    local file = "../config/config_order.ini"
    local engine = net.getRPCEngine()
    engine:init(file)
    printLog("========================")   
    printLog("========start===========")   
    printLog("========================")   
    client = engine:createClient("xtservice")
    net.setNotification(client, onNotification)
    local response, error = net.subscribe_async(client, "connect", {}, onConnected)
    engine:join()
end

main()
