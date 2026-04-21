package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

STATUS_ERROR = -1
STATUS_NOT_ORDER = 0
STATUS_ORDERED = 1
STATUS_FINISH = 2

g_rawParam = nil
g_params = {}
g_orders = {}
g_priceDatas = {}
g_statuses = {}
g_runningCount = 0
g_isLoggedOrdered = {}

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParamList()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

local function onOrderCallback(orderInfo, error)
    --printLog("onOrderCallback")    
    if orderInfo == nil then
        printLogLevel(2, string.format("[onOrderCallback] %s nil orderInfo, return.", task:logTag()))
        return
    end

    local msgTag = string.format("[%s] [%s]", accountDisplayId(orderInfo.m_accountInfo), orderInfo.m_strInstrumentId)

    if orderInfo.m_xtTag ~= nil then
        --local key = orderInfo.m_accountInfo.m_strAccountID .. orderInfo.m_strExchangeId .. orderInfo.m_strInstrumentId
        local key = string.format("%s%s%s", orderInfo.m_accountInfo.m_strAccountID, orderInfo.m_strExchangeId, orderInfo.m_strInstrumentId)
        g_orders[key][orderInfo:getKey()] = orderInfo
    end

    if orderInfo.m_nErrorId ~= 0 then
        local key = string.format("%s%s%s", orderInfo.m_accountInfo.m_strAccountID, orderInfo.m_strExchangeId, orderInfo.m_strInstrumentId)
        printLogLevel(2, string.format('[onOrderCallback] %s %s [%s] key = %s, error_id = %d, error_msg = %s', task:logTag(), msgTag, orderInfo:getKey(), key, orderInfo.m_nErrorId, orderInfo.m_strErrorMsg))
        if string.len(orderInfo.m_strErrorMsg) > 0 then
            local param = g_params[key]
            task:appendParamInfo(orderInfo.m_strErrorMsg, param:getKey())
        end
    end
end

local function onOrderInfo(orderInfo)

    --print("onOrderInfo")
    if orderInfo == nil then
        printLogLevel(2, string.format("[onOrderInfo] %s nil orderInfo, return.", task:logTag()))
        return
    end

    local key = string.format("%s%s%s", orderInfo.m_accountInfo.m_strAccountID, orderInfo.m_strExchangeId, orderInfo.m_strInstrumentId)
    local param = g_params[key]
    local orders = g_orders[key]
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    
    orders[orderInfo:getKey()] = orderInfo

    local statuses = g_statuses
    local bReturn = false

    local bizNum = getBusinessNum2(orders)
    if bizNum >= param.m_nNum then
        if STATUS_FINISH ~= statuses[key] then
            g_runningCount = g_runningCount - 1
        end
        statuses[key] = STATUS_FINISH
        bReturn = true
    end
    
    if orderInfo.m_nErrorId ~= 0 then
        if string.len(orderInfo.m_strErrorMsg) > 0 then
            local param = g_params[key]
            task:appendParamInfo(orderInfo.m_strErrorMsg, param:getKey())
        end
        printLogLevel(2, string.format("[onOrderInfo] %s %s [%s] error_id = %d, error_msg = %s.", task:logTag(), msgTag, orderInfo:getKey(), orderInfo.m_nErrorId, orderInfo.m_strErrorMsg))
    end

    if not bReturn and orderInfo.m_nErrorId ~= 0 then
        local pid = orderInfo.m_accountInfo.m_nPlatformID
        if g_trade_fatal_errors[pid] ~= nil and g_trade_fatal_errors[pid][orderInfo.m_nErrorId] ~= nil then
            if STATUS_FINISH ~= statuses[key] and STATUS_ERROR ~= statuses[key] then
                g_runningCount = g_runningCount - 1
            end
            statuses[key] = STATUS_ERROR
            bReturn = true
        end
    end

    if bReturn then
        if g_runningCount <= 0 then
            local bError = false
            for k, s in pairs(statuses) do
                if s == STATUS_ERROR then
                    bError = true
                    break
                end
            end

            if bError then
                task:setCompleted(false, "任务结束, 部分交易异常, 未全部完成!")
            else
                task:setCompleted(false, "")
            end
        end
        printLogLevel(2, string.format("[onOrderInfo] %s %s bReturn = true, return.", task:logTag(), msgTag))
        return    
    end    
end

local function doOneOrder(priceData, oneCodeParam, oneStatus, oneIsLoggedOrdered, oneOrders)
    --printLog("onPriceData")
    if priceData == nil and codeParam.m_ePriceType ~= PRTP_FIX then return g_isOrdered, g_isLoggedOrdered, g_orders end
    local param = oneCodeParam
    local isOrdered = oneStatus
    local isLoggedOrdered = oneIsLoggedOrdered
    local orders = oneOrders
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    local isReport = false

    if isOrdered == STATUS_NOT_ORDER and #orders == 0 then
        local orderStatus = 0
        -- 触发单, 查看是否满足触发条件
        if param.m_eTriggerType == OTT_UP then
            if priceData ~= nil and (isInvalidDouble(priceData.m_dLastPrice) or isGreater(param.m_dTriggerPrice, priceData.m_dLastPrice)) then
                orderStatus = 1
            elseif not isTradingStatus(param) then
                orderStatus = 2
            end
        elseif param.m_eTriggerType == OTT_DOWN then
            if priceData ~= nil and (isInvalidDouble(priceData.m_dLastPrice) or isGreater(priceData.m_dLastPrice, param.m_dTriggerPrice)) then
                orderStatus = 1
            elseif not isTradingStatus(param) then
                orderStatus = 2
            end
        end

        if orderStatus == 0 then --可交易
            local orders, msg = ordinaryTrade(param, priceData, onOrderCallback)
            for key, order in pairs(orders) do
                orders[key] = order
                isOrdered = STATUS_ORDERED
            end
            if string.len(msg) > 0 then
                task:appendParamInfo(msg, param:getKey())
                isReport = true
            end
        elseif orderStatus == 1 then --触价未到
            local triggerType = "向上"
            if param.m_eTriggerType == OTT_DOWN then
                triggerType = "向下"
            end
            if priceData ~= nil then 
                if isInvalidDouble(priceData.m_dLastPrice) then
                    local msg = string.format("%s 最新价非法, %s触价%.4f未达到, 暂缓报单!", msgTag, triggerType, param.m_dTriggerPrice)                
                    task:appendParamInfo(msg, param:getKey())
                    isReport = true
                else 
                    local msg = string.format("%s 最新价%.4f, %s触价%.4f未达到, 暂缓报单!", msgTag, priceData.m_dLastPrice, triggerType, param.m_dTriggerPrice)
                    task:appendParamInfo(msg, param:getKey())
                    isReport = true
                end
            end
        elseif orderStatus == 2 then --到达触价，但交易所状态不是连续交易
            local msg = string.format("%s 交易所状态不是连续交易, 暂缓报单!", msgTag)
            task:appendParamInfo(msg, param:getKey())
            isReport = true
        end
        if OTT_NONE ~= param.m_eTriggerType then
            if priceData ~= nil then
                printLogLevel(2, string.format("%s %s [batch_ordinary_trade] trigger_type = %d, trigger_price = %f, last_price = %f, orderStatus = %d", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice, priceData.m_dLastPrice, orderStatus))
            end      
        else
            if priceData ~= nil then
                printLogLevel(2, string.format("%s %s [batch_ordinary_trade] last_price = %f, orderStatus = %d", task:logTag(), msgTag, priceData.m_dLastPrice, orderStatus))
            end
        end
    else
        if not isLoggedOrdered then
            if OTT_NONE ~= param.m_eTriggerType then
                printLogLevel(2, string.format("%s %s [batch_ordinary_trade] trigger_type = %d, trigger_price = %f, isOrdered = true", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice))
            else
                printLogLevel(2, string.format("%s %s [batch_ordinary_trade] isOrdered = true", task:logTag(), msgTag))
            end
            isLoggedOrdered = true
        end
    end
    return isOrdered, isLoggedOrdered, orders, isReport
end

local function doOrder(priceData)
    local params = g_params
    local statuses = g_statuses
    local isLoggedOrdered = g_isLoggedOrdered
    local orders = g_orders
    local needReport = false

    local interval = 1
    for key, param in pairs(params) do
        local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
        if priceData == CPriceData_NULL then
            local key1 = string.format("%s%s", param.m_stock.m_strMarket, param.m_stock.m_strCode)
            local localPrice = g_priceDatas[key1]
            statuses[key], isLoggedOrdered[key], orders[key], isReport = doOneOrder(localPrice, param, statuses[key], isLoggedOrdered[key], orders[key])
            if isReport then
                needReport = true
            end 
        else        
            if priceData.m_strExchangeID == param.m_stock.m_strMarket and priceData.m_strInstrumentID == param.m_stock.m_strCode then            
                statuses[key], isLoggedOrdered[key], orders[key], isReport = doOneOrder(priceData, param, statuses[key], isLoggedOrdered[key], orders[key])
                if isReport then
                    needReport = true
                end 
            end            
        end
    end
    
    if needReport then
        task:reportComposeRunningStatus()
    end
end

local function onPriceData(priceData)
    --printLog("onPriceData")
    if priceData == nil then
        return
    end

    --local key = priceData.m_strExchangeID .. priceData.m_strInstrumentID
    local key = string.format("%s%s", priceData.m_strExchangeID, priceData.m_strInstrumentID)
    g_priceDatas[key] = priceData

    doOrder(priceData)

    --if not g_isOrdered then
    --    onTimer()
    --end
    --printLog("onPriceData begin")
end

function init(obj)
    --print("init")
    local orderTimes = {}
    if #g_orders == 0 then
        local vOrders = task:getOrders()
        for i = 0, vOrders:size() - 1, 1 do
            local order = vOrders:at(i)
            --local key = order.m_accountInfo.m_strAccountID .. order.m_strExchangeId .. order.m_strInstrumentId
            local key = string.format("%s%s%s", order.m_accountInfo.m_strAccountID, order.m_strExchangeId, order.m_strInstrumentId)
            if g_orders[key] == nil then
                g_orders[key] = {}
            end
            if orderTimes[key] == nil then
                orderTimes[key] = 0
            end
            orderTimes[key] = orderTimes[key] + 1
            g_orders[key][order:getKey()] = order
        end
    end

    g_rawParam = parseParam(obj)
    local vParams = g_rawParam.m_params
    for i = 0, vParams:size() - 1, 1 do
        local param = vParams:at(i)
        --local key = param.m_account.m_strAccountID .. param.m_stock.m_strMarket .. param.m_stock.m_strCode
        local key = string.format("%s%s%s", param.m_account.m_strAccountID, param.m_stock.m_strMarket, param.m_stock.m_strCode)
        g_params[key] = param
    end

    local params = g_params
    local statuses = g_statuses
    local priceDatas = g_priceDatas

    local done = true
    for key, param in pairs(params) do
        if g_orders[key] == nil then
            g_orders[key] = {}
        end
        local orders = g_orders[key]
        local bizNum = getBusinessNum2(orders)
        if bizNum >= param.m_nNum then
            statuses[key] = STATUS_FINISH
        else
            local times = orderTimes[key]
            if times == nil then times = 0 end
            if  times == 0 then
                statuses[key] = STATUS_NOT_ORDER
            else
                statuses[key] = STATUS_ORDERED
            end
                
            g_runningCount = g_runningCount + 1

            --local key1 = param.m_stock.m_strMarket .. param.m_stock.m_strCode
            local key1 = string.format("%s%s", param.m_stock.m_strMarket, param.m_stock.m_strCode)
            task_helper.subscribePrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, onPriceData)
            priceDatas[key1] = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 5)
            done = false
        end
    end

    if not done then
        --printLogLevel(2, "init start task g_runningCount " .. g_runningCount)
        task_helper.subscribe(XT_COrderInfo, onOrderInfo)

        doOrder(CPriceData_NULL)
    else
        printLogLevel(2, string.format("%s init task already done", task:logTag()))
        task:setCompleted(false, "")
    end
end

function destroy()
    --printLog("destroy")
    -- do nothing
end
