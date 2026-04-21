package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

g_param = nil
g_orders = {}
g_canceled = {}
g_priceData = nil
g_isOrdered = false
g_inPeriod = false

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

local function onOrderCallback(orderInfo, error)
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    --print('onOrderCallback')
    if orderInfo == nil then
        printLogLevel(2, string.format("[onOrderCallback] %s %s nil orderInfo, return.", task:logTag(), msgTag))
        return
    end
    if orderInfo.m_xtTag ~= nil then
        g_orders[orderInfo:getKey()] = orderInfo
    end

    if orderInfo.m_nErrorId ~= 0 then
        printLogLevel(2, string.format('[onOrderCallback] %s %s [%s] error_id = %d, error_msg = %s', task:logTag(), msgTag, orderInfo:getKey(), orderInfo.m_nErrorId, orderInfo.m_strErrorMsg))
        if string.len(orderInfo.m_strErrorMsg) > 0 then
            task:reportRunningStatus(orderInfo.m_strErrorMsg)
        end
    end
end

function onCancelCallback(orderInfo, error)
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    if orderInfo == nil then
        printLogLevel(2, string.format("[onCancelCallback] %s %s nil orderInfo, return.", task:logTag(), msgTag))
        return
    end

    if not error:isSuccess() then
        local interval = orderInfo.m_nCancelTimes * orderInfo.m_dCancelInterval
        if interval > 30 then
            interval = 30
        end
        if interval < 1 then
            interval = 1
        end
        local msgTag = string.format("[%s] [%s]", accountDisplayId(orderInfo.m_accountInfo), orderInfo.m_strInstrumentId)
        printLogLevel(2, string.format("[onCancelCallback] %s %s [%s] cancel error, retry after %d seconds : %s.", task:logTag(), msgTag, orderInfo:getKey(), interval, error:errorMsg()))
        task_helper.startTimer(interval * 1000, true, onCancelTimer, orderInfo:getKey())
    end
end

local function onOrderInfo(orderInfo)
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    if orderInfo == nil then
        printLogLevel(2, string.format("[onOrderInfo] %s %s nil orderInfo, return.", task:logTag(), msgTag))
        return
    end

    local orders = g_orders
    orders[orderInfo:getKey()] = orderInfo

    local bizNum = getBusinessNum2(orders)
    if bizNum >= param.m_nNum then
        task:setCompleted(false, "")
        printLogLevel(2, string.format("[onOrderInfo] %s %s bizNum = %d, total = %d, return.", task:logTag(), msgTag, bizNum, param.m_nNum))
        return
    end

    -- 只有ErrorId不为0的时候才表示委托出现异常, 不再进行未成委托处理的判断
    if orderInfo.m_nErrorId ~= 0 then
        if  string.len(orderInfo.m_strErrorMsg) > 0 then
            local pid = orderInfo.m_accountInfo.m_nPlatformID
            if g_trade_fatal_errors[pid] ~= nil and g_trade_fatal_errors[pid][orderInfo.m_nErrorId] ~= nil then
                task:setCompleted(true, "任务结束, 部分委托异常, " .. orderInfo.m_strErrorMsg)
            else
                task:reportRunningStatus(orderInfo.m_strErrorMsg)
            end
        end
        printLogLevel(2, string.format("[onOrderInfo] %s %s [%s] error_id = %d, error_msg = %s, return.", task:logTag(), msgTag, orderInfo:getKey(), orderInfo.m_nErrorId, orderInfo.m_strErrorMsg))
        return
    end

    if isLessEqual(orderInfo.m_dCompleteTime, 0) and isInvalidDouble(orderInfo.m_dCancelTime) and (nil == g_canceled[orderInfo:getKey()]) then
        printLogLevel(2, string.format("[onOrderInfo] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, about to cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime)))
        g_canceled[orderInfo:getKey()] = orderInfo
        local intervalMSec = (orderInfo.m_dOrderTime + orderInfo.m_dCancelInterval - now()) * 1000
        if intervalMSec < 10 then
            intervalMSec = 10
        end
        task_helper.startTimer(intervalMSec, true, onCancelTimer, orderInfo:getKey())
    else
        printLogLevel(2, string.format("[onOrderInfo] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, NOT about to cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime)))
    end

    if param.m_eUndealtEntrustRule ~= PRTP_INVALID and
        not orderInfo.m_bIsComplement and
        orderInfo.m_nBusinessNum < orderInfo.m_nOrderNum and
        isGreater(orderInfo.m_dCompleteTime, 0)
    then
        local orderCount = getOrderedTime2(orders)
        if isInvalidInt(param.m_nMaxOrderCount) or orderCount < param.m_nMaxOrderCount then
            local status, newOrder, msg = dispatchUndealed(param, orderInfo, g_priceData, onOrderCallback)
            if newOrder ~= nil and newOrder.m_xtTag ~= nil then
                g_orders[newOrder:getKey()] = newOrder
            end
        end
        orderInfo.m_bIsComplement = true
    end
end

local function onTimer()
    --print('onTimer')
    local param = g_param
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    local priceData = g_priceData
    if (priceData == nil or priceData.m_dLastPrice == nil) and g_param.m_ePriceType ~= PRTP_FIX then
        task:reportRunningStatus(param.m_stock.m_strCode .. "当前价格无效!")
        if OTT_NONE ~= param.m_eTriggerType then
            printLogLevel(2, string.format("[onTimer] %s %s [algorithmTrade] trigger_type = %d, trigger_price = %f, last_price = nil, return.", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice))
        else
            printLogLevel(2, string.format("[onTimer] %s %s [algorithmTrade] last_price = nil, return.", task:logTag(), msgTag))
        end
        return
    end

    local canOrder = true
    if not g_isOrdered and priceData ~= nil then
        -- 触发单, 查看是否满足触发条件
        if isInvalidDouble(priceData.m_dLastPrice) then
            canOrder = false
        elseif param.m_eTriggerType == OTT_UP and isGreater(param.m_dTriggerPrice, priceData.m_dLastPrice) then
            canOrder = false
        elseif param.m_eTriggerType == OTT_DOWN and isGreater(priceData.m_dLastPrice, param.m_dTriggerPrice) then
            canOrder = false
        end
    end

    if not canOrder and priceData ~= nil then
        if param.m_eTriggerType ~= OTT_NONE then
            local triggerType = "向上"
            if param.m_eTriggerType == OTT_DOWN then
                triggerType = "向下"
            end
            if isInvalidDouble(priceData.m_dLastPrice) then
                task:reportRunningStatus(string.format("%s 最新价非法, %s触价%.4f未达到, 暂缓报单!", msgTag, triggerType, param.m_dTriggerPrice))
            else
                task:reportRunningStatus(string.format("%s 最新价%.4f, %s触价%.4f未达到, 暂缓报单!", msgTag, priceData.m_dLastPrice, triggerType, param.m_dTriggerPrice))
            end
        else
            task:reportRunningStatus(string.format("%s 行情异常或未更新, 暂缓报单!", msgTag))
        end
        if OTT_NONE ~= param.m_eTriggerType then
            printLogLevel(2, string.format("[onTimer] %s %s [algorithmTrade] trigger_type = %d, trigger_price = %f, last_price = %f, not reached, return.", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice, priceData.m_dLastPrice))
        else
            printLogLevel(2, string.format("[onTimer] %s %s [algorithmTrade] last_price = invalid, return.", task:logTag(), msgTag))
        end
        return
    end

    if OTT_NONE ~= param.m_eTriggerType and priceData ~= nil then
        printLogLevel(2, string.format("[onTimer] %s %s [algorithmTrade] trigger_type = %d, trigger_price = %f, last_price = %f, REACHED, order.", task:logTag(), msgTag, param.m_eTriggerType, param.m_dTriggerPrice, priceData.m_dLastPrice))
    end

    local status, newOrder, msg = algorithmTrade(param, g_orders, g_priceData, onOrderCallback)
    if newOrder ~= nil then
        if newOrder.m_xtTag ~= nil then
            g_orders[newOrder:getKey()] = newOrder
        end
        g_isOrdered = true
    end

    if status == ORDER_FATAL then
        task:setCompleted(false, "任务结束, " .. msg)
    else
        if string.len(msg) > 0 then
            task:reportRunningStatus(msg)
        end
    end
end

function onCancelTimer(orderKey)
    local param = g_param
    local orders = g_orders
    local orderInfo = g_orders[orderKey]
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    if isLessEqual(orderInfo.m_dCompleteTime, 0) then
        if shouldCancelOrder(orderInfo, param, orders, g_priceData) then
            -- 条件满足，现在就撤单
            printLogLevel(2, string.format("[onCancelTimer] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, m_dOrderTime = %.2f, m_dCancelInterval = %.2f, cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime), orderInfo.m_dOrderTime, orderInfo.m_dCancelInterval))
            task_helper.cancel_async(orderInfo, onCancelCallback)
        else
            -- 条件不满足，下次撤单间隔再说
            printLogLevel(2, string.format("[onCancelTimer] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, m_dOrderTime = %.2f, m_dCancelInterval = %.2f, NOT cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime), orderInfo.m_dOrderTime, orderInfo.m_dCancelInterval))
            task_helper.startTimer(orderInfo.m_dCancelInterval * 1000, true, onCancelTimer, orderInfo:getKey())
        end
    else
        -- 委托已经终止，不需要再定时检查撤单
        printLogLevel(2, string.format("[onCancelTimer] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, m_dOrderTime = %.2f, m_dCancelInterval = %.2f, already ended.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime), orderInfo.m_dOrderTime, orderInfo.m_dCancelInterval))
    end
end

local function onPriceData(priceData)
    --print('onPriceData')
    g_priceData = priceData

    if g_inPeriod and (not g_isOrdered) then
        local param = g_param
        if param.m_eTriggerType ~= OTT_NONE then
            onTimer()
        end
    end
end

function init(obj)
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
    
    task_helper.subscribePrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, onPriceData)
    g_priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 5)

    task_helper.subscribe(XT_COrderInfo, onOrderInfo)

    local nowMSec = nowMSec()
    if not isInvalidInt(param.m_nValidTimeStart) and nowMSec < param.m_nValidTimeStart * 1000 then
        task_helper.startTimer(param.m_nValidTimeStart * 1000 - nowMSec + 1, true, start)
        local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
        local msg = msgTag .. " 当前时间" .. secondToString(nowMSec / 1000) .. "不在有效时间范围[" .. secondToString(param.m_nValidTimeStart) .. "-" .. secondToString(param.m_nValidTimeEnd) .. "]!"
        task:reportRunningStatus(msg)
    else
        start()
    end
end

function start()
    g_inPeriod = true
    onTimer()
    local param = g_param
    task_helper.startTimer(param.m_dPlaceOrderInterval * 1000, false, onTimer)
end

function destory()
    -- do nothing
end
