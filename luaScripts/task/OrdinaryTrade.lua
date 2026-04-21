package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

g_param = nil
g_orders = {}
g_isOrdered = false
g_isLoggedOrdered = false

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

local function isTradingStatus(param)
    -- 交易所状态
    if isCheckExchange() then
        exchangeStatus = getAccountExchangeStatus(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
        if EXCHANGE_STATUS_CONTINOUS ~= exchangeStatus then
            return false
        end
    end
    return true
end

local function onOrderCallback(orderInfo, error)
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    if orderInfo == nil then
        printLogLevel(2, string.format("[onOrderCallback] %s %s nil orderInfo, return.", task:logTag(), msgTag))
        return
    end

    if orderInfo.m_xtTag ~= nil then
        g_orders[orderInfo:getKey()] = orderInfo
    end

    local errMsg = ""
    if orderInfo.m_nErrorId ~= 0 or string.len(orderInfo.m_strErrorMsg) > 0 then
        errMsg = orderInfo.m_strErrorMsg
    end

    local over = true
    for k, order in pairs(g_orders) do
        if isZero(order.m_dCompleteTime) then
            over = false
        end
        if string.len(errMsg) == 0 then
           if order.m_nErrorId ~= 0 or string.len(order.m_strErrorMsg) > 0 then
               errMsg = order.m_strErrorMsg
           end
        end
    end
    
    if over then
        local n = getBusinessNum2(g_orders)
        if n < g_param.m_nNum then
            if string.len(errMsg) > 0 then
                task:setCompleted(true, "任务结束, 部分委托异常, " .. errMsg)
            else
                task:setCompleted(false, "任务结束, 部分委托未全部完成!")
            end
        else
            task:setCompleted(false, "")
        end
    else
        if string.len(errMsg) > 0 then
            task:reportRunningStatus(errMsg)
        end
    end
end

local function onOrderInfo(orderInfo)
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    if orderInfo == nil then
        printLogLevel(2, string.format("[onOrderInfo] %s %s nil orderInfo, return.", task:logTag(), msgTag))
        return
    end

    g_orders[orderInfo:getKey()] = orderInfo

    local orders = g_orders
    local bizNum = getBusinessNum2(orders)

    if bizNum >= param.m_nNum then
        task:setCompleted(false, "")
        printLogLevel(2, string.format("[onOrderInfo] %s %s bizNum = %d, total = %d, return.", task:logTag(), msgTag, bizNum, param.m_nNum))
        return
    end

    local errMsg = ""
    if orderInfo.m_nErrorId ~= 0 or string.len(orderInfo.m_strErrorMsg) > 0 then
        errMsg = orderInfo.m_strErrorMsg
    end

    local over = true
    for k, order in pairs(orders) do
        if isZero(order.m_dCompleteTime) then
            over = false
        end
        if string.len(errMsg) == 0 then
           if order.m_nErrorId ~= 0 or string.len(order.m_strErrorMsg) > 0 then
               errMsg = order.m_strErrorMsg
           end
        end
    end

    if over then
        local n = getBusinessNum2(orders)
        if n < g_param.m_nNum then
            if string.len(errMsg) > 0 then
                task:setCompleted(true, "任务结束, 部分委托异常, " .. errMsg)
            else
                task:setCompleted(false, "任务结束, 部分委托未全部完成!")
            end
        else
            task:setCompleted(false, "")
        end
    else
        if string.len(errMsg) > 0 then
            task:reportRunningStatus(errMsg)
        end
    end
end

local function onPriceData(priceData)
    --printLog("onPriceData")
    if priceData == nil and g_param.m_ePriceType ~= PRTP_FIX then return end
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    if not g_isOrdered and #g_orders == 0 then
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
                g_orders[key] = order
                g_isOrdered = true
            end
            if string.len(msg) > 0 then
                task:reportRunningStatus(msg)
            end
        elseif orderStatus == 1 then --触价未到
            local triggerType = "向上"
            if param.m_eTriggerType == OTT_DOWN then
                triggerType = "向下"
            end
            if priceData ~= nil then 
                if isInvalidDouble(priceData.m_dLastPrice) then
                    task:reportRunningStatus(string.format("%s 最新价非法, %s触价%.4f未达到, 暂缓报单!", msgTag, triggerType, param.m_dTriggerPrice))
                else 
                    task:reportRunningStatus(string.format("%s 最新价%.4f, %s触价%.4f未达到, 暂缓报单!", msgTag, priceData.m_dLastPrice, triggerType, param.m_dTriggerPrice))
                end
            end
        elseif orderStatus == 2 then --到达触价，但交易所状态不是连续交易
            task:reportRunningStatus(string.format("%s 交易所状态不是连续交易, 暂缓报单!", msgTag))
        end
        if OTT_NONE ~= param.m_eTriggerType then
            if priceData ~= nil then
                printLogLevel(2, string.format("%s %s [ordinary_trade] trigger_type = %d, trigger_price = %f, last_price = %f, orderStatus = %d", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice, priceData.m_dLastPrice, orderStatus))
            end      
        else
            if priceData ~= nil then
                printLogLevel(2, string.format("%s %s [ordinary_trade] last_price = %f, orderStatus = %d", task:logTag(), msgTag, priceData.m_dLastPrice, orderStatus))
            end
        end
    else
        if not g_isLoggedOrdered then
            if OTT_NONE ~= param.m_eTriggerType then
                printLogLevel(2, string.format("%s %s [ordinary_trade] trigger_type = %d, trigger_price = %f, g_isOrdered = true", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice))
            else
                printLogLevel(2, string.format("%s %s [ordinary_trade] g_isOrdered = true", task:logTag(), msgTag))
            end
            g_isLoggedOrdered = true
        end
    end
end

function init(obj)
    printLogLevel(2, string.format("%s [ordinary_trade] init", task:logTag()))
    if #g_orders == 0 then
        local vOrders = task:getOrders()
        for i = 0, vOrders:size() - 1, 1 do
            local order = vOrders:at(i)
            g_orders[order:getKey()] = order
            g_isOrdered = true
        end
    end

    g_param = parseParam(obj)
    local param = g_param

    local orders = g_orders
    local bizNum = getBusinessNum2(orders)
    if bizNum >= param.m_nNum then
        task:setCompleted(false, "")
        return
    end

    task_helper.subscribe(XT_COrderInfo, onOrderInfo)

    if not g_isOrdered then
        task_helper.subscribePrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, onPriceData)        
        local priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 5)
        onPriceData(priceData)
    end
end

function destory()
    -- do nothing
end
