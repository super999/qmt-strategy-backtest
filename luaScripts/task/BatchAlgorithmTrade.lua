package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

STATUS_RUNNING = 0
STATUS_ERROR = -1
STATUS_FINISH = 1

g_rawParam = nil
g_params = {}
g_orders = {}
g_canceled = {}
g_priceDatas = {}
g_statuses = {}
g_runningCount = 0
g_isOrdered = false

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

function onCancelCallback(orderInfo, error)
    if orderInfo == nil then
        printLogLevel(2, string.format("[onCancelCallback] %s nil orderInfo, return.", task:logTag()))
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
        task_helper.startTimer(interval * 1000, true, onCancelTimer, orderInfo)
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
        if STATUS_RUNNING == statuses[key] then
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
            if STATUS_RUNNING == statuses[key] then
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
    
    local key1 = string.format("%s%s", param.m_stock.m_strMarket, param.m_stock.m_strCode)
    local priceData = g_priceDatas[key1]

    if isLessEqual(orderInfo.m_dCompleteTime, 0) and isInvalidDouble(orderInfo.m_dCancelTime) and (nil == g_canceled[orderInfo:getKey()]) then
        printLogLevel(2, string.format("[onOrderInfo] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, about to cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime)))
        g_canceled[orderInfo:getKey()] = orderInfo
        local intervalMSec = (orderInfo.m_dOrderTime + orderInfo.m_dCancelInterval - now()) * 1000
        if intervalMSec < 10 then
            intervalMSec = 10
        end
        task_helper.startTimer(intervalMSec, true, onCancelTimer, orderInfo)
    else
        printLogLevel(2, string.format("[onOrderInfo] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, NOT about to cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime)))
    end

    if param.m_eUndealtEntrustRule ~= PRTP_INVALID and
        not orderInfo.m_bIsComplement and
        orderInfo.m_nBusinessNum < orderInfo.m_nOrderNum and
        isGreater(orderInfo.m_dCompleteTime, 0)
    then
        local orderCount = getOrderedTime2(orders)
        if isInvalidInt(param.m_nMaxOrderCount) or orderCount <= param.m_nMaxOrderCount then
            --local key1 = param.m_stock.m_strMarket .. param.m_stock.m_strCode
            local status, newOrder, msg = dispatchUndealed(param, orderInfo, priceData, onOrderCallback)
            if newOrder ~= nil and newOrder.m_xtTag ~= nil then
                orders[newOrder:getKey()] = newOrder
            end
        end
        orderInfo.m_bIsComplement = true
        --printLogLevel(2, "onOrderInfo " .. key .. " undealed")
    else
        --printLogLevel(2, "onOrderInfo " .. key .. " normal")
    end
end

local function onTimer()
    --printLog("onTimer")
    --printLogLevel(2, "onTimer start")
    local params = g_params
    local statuses = g_statuses

    local interval = 1
    for key, param in pairs(params) do
        local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
        if statuses[key] == STATUS_RUNNING then
            --printLogLevel(2, "onTimer " .. key .. " running")
            local orders = g_orders[key]
            --local key1 = param.m_stock.m_strMarket .. param.m_stock.m_strCode
            local key1 = string.format("%s%s", param.m_stock.m_strMarket, param.m_stock.m_strCode)
            local priceData = g_priceDatas[key1]
            local status, newOrder, msg = algorithmTrade(param, orders, priceData, onOrderCallback)
            if newOrder ~= nil and newOrder.m_xtTag ~= nil then
                orders[newOrder:getKey()] = newOrder
                g_isOrdered = true
            end

            if status == ORDER_FATAL then
                --printLogLevel(2, "onTimer " .. key .. " order fatal " .. msg)
                if STATUS_RUNNING == statuses[key] then
                    g_runningCount = g_runningCount - 1
                end
                statuses[key] = STATUS_ERROR
                --printLogLevel(2, "onTimer g_runningCount " .. g_runningCount)
            else
                if string.len(msg) > 0 then
                    task:appendParamInfo(msg, param:getKey())
                end
                --printLogLevel(2, "onTimer " .. key .. " order success")
            end
        else
            printLogLevel(2, string.format("[onTimer] %s %s finished or error.", task:logTag(), msgTag))
        end
        interval = param.m_dPlaceOrderInterval
    end

    if g_runningCount <= 0 then
        --printLogLevel(2, "onTimer task finish or over g_runningCount <= 0")
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
    else
        --printLogLevel(2, "onTimer start next timer")
        task:report()
        task_helper.startTimer(interval * 1000, true, onTimer)
    end

    --printLogLevel(2, "onTimer end")
end

function onCancelTimer(rawOrder)
    local key = string.format("%s%s%s", rawOrder.m_accountInfo.m_strAccountID, rawOrder.m_strExchangeId, rawOrder.m_strInstrumentId)
    local param = g_params[key]
    local orders = g_orders[key]
    local orderKey = rawOrder:getKey()
    local orderInfo = orders[orderKey]
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    local key1 = string.format("%s%s", param.m_stock.m_strMarket, param.m_stock.m_strCode)
    local priceData = g_priceDatas[key1]

    if isLessEqual(orderInfo.m_dCompleteTime, 0) then
        if shouldCancelOrder(orderInfo, param, orders, priceData) then
            -- 条件满足，现在就撤单
            printLogLevel(2, string.format("[onCancelTimer] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, m_dOrderTime = %.2f, m_dCancelInterval = %.2f, cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime), orderInfo.m_dOrderTime, orderInfo.m_dCancelInterval))
            task_helper.cancel_async(orderInfo, onCancelCallback)
        else
            -- 条件不满足，下次撤单间隔再说
            printLogLevel(2, string.format("[onCancelTimer] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, m_dOrderTime = %.2f, m_dCancelInterval = %.2f, NOT cancel.", task:logTag(), msgTag, orderInfo:getKey(), formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime), orderInfo.m_dOrderTime, orderInfo.m_dCancelInterval))
            task_helper.startTimer(orderInfo.m_dCancelInterval * 1000, true, onCancelTimer, orderInfo)
        end
    else
        -- 委托已经终止，不需要再定时检查撤单
        printLogLevel(2, string.format("[onCancelTimer] %s %s [%s] m_dCompleteTime = %s, m_dCancelTime = %s, m_dOrderTime = %.2f, m_dCancelInterval = %.2f, already ended.", task:logTag(), msgTag, orderInfo:getKey(),  formatDouble(orderInfo.m_dCompleteTime), formatDouble(orderInfo.m_dCancelTime), orderInfo.m_dOrderTime, orderInfo.m_dCancelInterval))
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

    --if not g_isOrdered then
    --    onTimer()
    --end
    --printLog("onPriceData begin")
end

function init(obj)
    --print("init")
    if #g_orders == 0 then
        local vOrders = task:getOrders()
        for i = 0, vOrders:size() - 1, 1 do
            local order = vOrders:at(i)
            --local key = order.m_accountInfo.m_strAccountID .. order.m_strExchangeId .. order.m_strInstrumentId
            local key = string.format("%s%s%s", order.m_accountInfo.m_strAccountID, order.m_strExchangeId, order.m_strInstrumentId)
            if g_orders[key] == nil then
                g_orders[key] = {}
            end
            g_orders[key][order:getKey()] = order
        end
    end

    g_rawParam = parseParam(obj)
    local vParams = g_rawParam.m_params

    if vParams:size() == 0 then
        printLogLevel(2, string.format("%s task params size is empty", task:logTag()))
        task:setCompleted(false, "")
        return
    end

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
            statuses[key] = STATUS_RUNNING
            g_runningCount = g_runningCount + 1

            --local key1 = param.m_stock.m_strMarket .. param.m_stock.m_strCode
            local key1 = string.format("%s%s", param.m_stock.m_strMarket, param.m_stock.m_strCode)
            task_helper.subscribePrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, onPriceData)
            priceDatas[key1] = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 5)
            done = false
        end
    end

    if done then
        printLogLevel(2, string.format("%s init task already done", task:logTag()))
        task:setCompleted(false, "")
        return
    end

    --printLogLevel(2, "init start task g_runningCount " .. g_runningCount)
    task_helper.subscribe(XT_COrderInfo, onOrderInfo)

    local param = vParams:at(0)
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
    onTimer()
end

function destroy()
    --printLog("destroy")
    -- do nothing
end
