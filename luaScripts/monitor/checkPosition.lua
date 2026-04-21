require "rpc"
require "std"

local KEY_SPLITTER = "____"

local CHECK_POSITION_INTERVAL = 15

local XT_CAccountDetail = 543
local XT_CPositionDetail = 545
local XT_CPositionStatics = 547
    
local ALARMTYPE_ORDER = 0
local ALARMTYPE_POSITION = 1
local ALARMTYPE_POSITION_SUB = 2
local TIME_LIMIT = 60
local accountLastTime = {}

local function getAccountID(account)
    if account["m_strSubAccount"] == "" then
        return account["m_strAccountID"]
    end
    return account["m_strSubAccount"]
end

local function genAccountKey(accountInfo)
    local retStr = accountInfo["m_nBrokerType"] .. KEY_SPLITTER .. accountInfo["m_nPlatformID"] .. KEY_SPLITTER .. 
            accountInfo["m_strBrokerID"] .. KEY_SPLITTER .. accountInfo["m_nAccountType"] .. KEY_SPLITTER .. 
            accountInfo["m_strAccountID"] .. KEY_SPLITTER .. accountInfo["m_strSubAccount"]
    return retStr
end

local function genParAccountKey(accountInfo)
    local retStr = accountInfo["m_nBrokerType"] .. KEY_SPLITTER .. accountInfo["m_nPlatformID"] .. KEY_SPLITTER .. 
            accountInfo["m_strBrokerID"] .. KEY_SPLITTER .. accountInfo["m_nAccountType"] .. KEY_SPLITTER .. 
            accountInfo["m_strAccountID"]
    return retStr
end

local function loadM_tmsSetting()
    local reqParam = {}
    while true do
        reqParam["function"] = "querySettings"
        reqParam.param = {}
        response, error = net.request(client, "tradingmonitor", reqParam)
        if response ~= nil then
            break
        end
        printLog("querySettings:ERROR" .. error.error.errmsg)
        sleep(3)
    end
    printLog("querySettings:SUCCESS")
    return response["settings"]
end

local function passMessage(type, strMsgm, accountm)
    local reqParam = {}
    reqParam["function"] = "sendAlarmMsg"
    reqParam.param = {eType = type, strMsg = strMsgm, account = accountm}
    printLog("passMessage " .. strMsgm)
    local response, error= net.request(client, "tradingmonitor", reqParam)
    if error ~= nil then
        printLog("passMessage:ERROR")
    end
    if response ~= nil then
        if response.success == false then
            printLog("passMessage:ERROR")
        end
    end
end

local function getPosition(accountm)
    local reqParam = {}
    reqParam["function"] = "queryData"    
    reqParam.param = {account = accountm, typeId = XT_CPositionDetail}
    response, error = net.request(client, "tradingmonitor", reqParam)
    if error ~= nil then
        printLog(accountm.m_strAccountID .. ":getPosition:ERROR")
    end
    return response, (error == nil)
end

local function getAccountStatus(accountm)
	local ret = -1
	local reqParam = {}
    reqParam["function"] = "queryData"    
    reqParam.param = {account = accountm, typeId = XT_CAccountDetail}
    response, error = net.request(client, "tradingmonitor", reqParam)
    if error ~= nil then
        printLog(accountm.m_strAccountID .. ":getPosition:ERROR")
    end
    if response ~= nil then
        for k, v in ipairs(response) do
            ret = v.m_accountInfo.m_iStatus
            printLog(k .. "," .. type(k))
        end

        --printLog(response)
		--ret = response[0].m_accountInfo.m_iStatus
    end
    return ret
end


local function getPositionCTP(accountm)
    local reqParam = {}
    reqParam["function"] = "queryRawPosition"
    reqParam.param = {account = accountm}
    response, error = net.request(client, "tradingmonitor", reqParam)
    if error ~= nil then
        printLog(accountm.m_strAccountID .. ":getPositionCTP:ERROR")
    end
    return response, (error == nil)
end

local function isSuperAccount(account)
    return account["m_strSubAccount"] == ""
end

local function getHashKeyParSub(position)
    local retStr = position["m_strInstrumentID"] .. KEY_SPLITTER .. position["m_nDirection"] .. KEY_SPLITTER .. 
            position["m_strExchangeID"]  .. KEY_SPLITTER .. position["m_nHedgeFlag"]
    return retStr
end

local function getDirAndIns(positionKey)
    local stPos, edPos = string.find(positionKey, KEY_SPLITTER)
    local strIns = string.sub(positionKey, 1, stPos-1)
    local st, ed = string.find(positionKey, KEY_SPLITTER, edPos)
    local dir = string.sub(positionKey, edPos+1, st-1)
    local strDir = "卖出"
    if dir == "48" then
        strDir = "买入"
    end
    return strIns, strDir
end

local function getHashKey(position)
    local retStr = position["m_strInstrumentID"] .. KEY_SPLITTER .. position["m_strTradeID"] .. KEY_SPLITTER .. position["m_nDirection"]
    return retStr
end

local function isSamePostion(vFtPosition, vPosition)
    local hashPosition = {}
    for k, v in ipairs(vFtPosition) do
        local hashKey = getHashKey(v)
        hashPosition[hashKey] = v
    end
    
    for k, v in ipairs(vPosition) do
        local hashKey = getHashKey(v)
        if hashPosition[hashKey] == nil then
            if v.m_nVolume > 0 then 
                printLog(hashKey .. " volume " .. v.m_nVolume)
                return false
            end
        else 
            if v.m_nVolume ~= hashPosition[hashKey].m_nVolume then
                printLog(hashKey .. " volume " .. v.m_nVolume .. " ftvolume" .. hashPosition[hashKey].m_nVolume)
                return false
            end
        end
        hashPosition[hashKey] = nil
    end
    
    for k, v in ipairs(hashPosition) do
        if v.m_nVolume > 0 then
            local hashKey = getHashKey(v)
            printLog(hashKey .. "ft volume more" .. v.m_nVolume)
            return false
        end
    end
    return true
end

local function checkPosition(account)
    local strAccountKey = genAccountKey(account)
    local vPosition , ret = getPositionCTP(account)
    local vFtPosition, ftret = getPosition(account)
    if ret and ftret then
        return isSamePostion(vFtPosition.content, vPosition.content)
    end
    return true
end

local function isSamePostionStatics(vFtPositionStatic, vvFtPositionStaticSub, isFuture )
    local parPositionNum = {}
    local subPositionNum = {}
    for k, parentStatics in ipairs(vFtPositionStatic.content) do
        if parentStatics["m_nVolume"] ~= 0 then
            local hashKey = getHashKeyParSub(parentStatics)
            if parPositionNum[hashKey] == nil then
                parPositionNum[hashKey] = 0
            end
            parPositionNum[hashKey] = parPositionNum[hashKey] + parentStatics["m_nVolume"] 
        end
    end
    
    for k, v in pairs(vvFtPositionStaticSub) do
        for k, subStatics in pairs(v.content) do
            if subStatics["m_nVolume"] ~= 0 then
                local hashKey = getHashKeyParSub(subStatics)
                if subPositionNum[hashKey] == nil then
                    subPositionNum[hashKey] = 0
                end
                subPositionNum[hashKey] = subPositionNum[hashKey] + subStatics["m_nVolume"]
                if parPositionNum[hashKey] == nil then
                    parPositionNum[hashKey] = 0
                end
            end
        end
    end
    
    local ret = true
    local errorLit = ""
    for k, v in pairs(parPositionNum) do
        local subNum = subPositionNum[k]
        if subNum == nil then
            subNum = 0
        end
        if subNum ~= v then
            ret = false
            local strIns, strDir = getDirAndIns(k)
            errorLit = errorLit .. strIns
            if isFuture then
                errorLit = errorLit .. " |" .. strDir
            end
            errorLit = errorLit .. ": " .. "主持仓量: " .. v .. ", " .. "子持仓量：" .. subNum .. "; "
        end
    end
    return ret, errorLit
end

local function checkPositionParAndChild(account, vAccounts)
    local vSubAccounts = {}
    local subIndex = 1
    for k, acc in ipairs(vAccounts) do
        if isSuperAccount(acc) == false then
            if acc.m_nPlatformID == account.m_nPlatformID and
               acc.m_nBrokerType == account.m_nBrokerType and
               acc.m_strBrokerID == account.m_strBrokerID and
               acc.m_strAccountID == account.m_strAccountID and
               acc.m_nAccountType == account.m_nAccountType then
                vSubAccounts[subIndex] = acc
                subIndex = subIndex + 1
            end
        end
    end
    if #vSubAccounts == 0 then
        return true, ""
    end
    local strAccountKey = genAccountKey(account)
    local vvFtPositionStaticSub = {}
    local vSubIndex = 1
    vFtPositionStatic, ret = getPosition(account)
    if ret == true then
        bCheckSubErr = true
        for k, subAcc in ipairs(vSubAccounts) do
            local vFtPositionStaticSub, ret = getPosition(subAcc)
            if ret == false then
                bCheckSubErr = false
                break
            end
            vvFtPositionStaticSub[vSubIndex] = vFtPositionStaticSub
            vSubIndex = vSubIndex + 1
        end
        if bCheckSubErr == true then
            local isFuture = account.m_nBrokerType == 1
            return isSamePostionStatics(vFtPositionStatic, vvFtPositionStaticSub, isFuture) 
        end
    end
    return true, ""
end

local function getVAcconts()
    local reqParam = {}
    reqParam["function"] = "queryAccounts"
    reqParam.param = {}
    response, error = net.request(client, "tradingmonitor", reqParam)
    return response
end

local function checkLastDealTime(accountc)
    local reqParam = {}
    local curTime = os.time()
    local strKey = genParAccountKey(accountc)
    if accountLastTime[strKey] ~= nil then
        if curTime - accountLastTime[strKey] < TIME_LIMIT then
            return false
        end
        return true
    end
    reqParam["function"] = "queryLastDealTime"
    reqParam.param = {account = accountc}
    timeTag, error = net.request(client, "tradingmonitor", reqParam)
    if error ~= nil then
        printLog("queryLastDealTime Error: ")
        return true
    end
    if timeTag == nil then
        return true
    end
    accountLastTime[strKey] = timeTag["timeTag"]
    if curTime - accountLastTime[strKey] < TIME_LIMIT then
        return false
    end
    return true
end
    
function checkAllPosition()
    --local vCTPPositionErrors = {}
    local parAndSubPositionErrors = {}
    local nMaxErrorTimes = 3
    while true do
        local abnMonitorSetting = loadM_tmsSetting()
        local mVAcconts = getVAcconts()
        for k, account in ipairs(mVAcconts.accounts) do
            account.m_addresses = nil
            account.m_strBrokerName = nil
            account.m_iStatus = nil
            account.m_strPassword = nil
            account.m_strAccountName = nil
        end
        printLog("account size:" .. #(mVAcconts.accounts))
        local curTime = os.time()
        for key, value in pairs(accountLastTime) do
            if curTime - value >= TIME_LIMIT then
                accountLastTime[key] = nil
            end
        end
        for k, account in ipairs(mVAcconts.accounts) do
            if isSuperAccount(account) and getAccountStatus(account) == 0 then
                if checkLastDealTime(account) then
                    local strKey = genAccountKey(account)
                    if parAndSubPositionErrors[strKey] == nil then
                        --vCTPPositionErrors[strKey] = 0
                        parAndSubPositionErrors[strKey] = 0
                    end
                    -- 不检查主账号持仓, C代码中检查, 仅检查主账号和子账号之间的异常
                    --if abnMonitorSetting.m_nPositionEnabled == 1 and checkPosition(account) == false then
                    --    vCTPPositionErrors[strKey] = vCTPPositionErrors[strKey] + 1
                    --end
                    local strErrorMsg = nil
                    local isSame = nil
                    if abnMonitorSetting.m_nPositionEnabledSub == 1 then
                        isSame, strErrorMsg = checkPositionParAndChild(account, mVAcconts.accounts)
                        if isSame == false then
                            parAndSubPositionErrors[strKey] = parAndSubPositionErrors[strKey] + 1
                        end
                    end
                    --[[
                    if vCTPPositionErrors[strKey] >= nMaxErrorTimes then
                        vCTPPositionErrors[strKey] = 0
                        local strMsg = "账号 [" .. getAccountID(account) .. "] 持仓发现异常, 正在进行自动校正"
                        passMessage(ALARMTYPE_POSITION, strMsg, account);
                    end
                    ]]--
                    if parAndSubPositionErrors[strKey] >= nMaxErrorTimes then
                        parAndSubPositionErrors[strKey] = 0
                        local strMsg = "主帐号 [" .. getAccountID(account) .. "] 持仓与子帐号持仓和不一致 ( " .. strErrorMsg .. " ), 请登录管理门户进行校正"
                        passMessage(ALARMTYPE_POSITION_SUB, strMsg, account);
                    end
                end
           end
        end
        sleep(CHECK_POSITION_INTERVAL)
    end
end

local function main()
    local file = "../config/config_position.ini"
    local engine = net.getRPCEngine()
    engine:init(file)
    client = engine:createClient("xtservice")
    local response, error = net.request(client, "connect", {})
    printLog("==============================")
    printLog("===========start==============")
    printLog("==============================")
    checkAllPosition()
    engine:join()
end

main()
