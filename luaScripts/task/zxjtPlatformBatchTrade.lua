package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

STATUS_RUNNING = 0
STATUS_ERROR = -1
STATUS_FINISH = 1

g_rawParam = nil
g_params = {}
g_orders = {}
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

local function parseObj2Order(obj)
    local param = COrderInfo()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    
    return param
end

local function onOrderInfo(orderInfo)
    if orderInfo == nil then
        return
    end

    local key = string.format("%s%s%s", orderInfo.m_accountInfo.m_strAccountID, orderInfo.m_strExchangeId, orderInfo.m_strInstrumentId)
    local param = g_params[key]
    local orders = g_orders[key]
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
                task:setCompleted(false, "任务结束, 部分委托异常")
            else
                task:setCompleted(true, "")
            end
        end
        return
    end
end

local function zxjtOrdinaryTrade(orderParam)
    local isBuy = getDirectionByOperation(orderParam.m_eOperationType)
    
    if orderParam.m_eBrokerPriceType == BROKER_PRICE_ANY then
        if isSupportMarketPrice(orderParam.m_strExchangeID, orderParam.m_strInstrumentID) then
            orderParam.m_dPrice = 0.0
            orderParam.m_eBrokerPriceType = getMarketPriceType(orderParam.m_strExchangeId)
        else
            local dataCenter = g_traderCenter:getDataCenter()
            local instrument = dataCenter:getInstrument(orderParam.m_strExchangeId, orderParam.m_strInstrumentId)
            if instrument ~= CInstrumentDetail_NULL then
                orderParam.m_dPrice = (isBuy and instrument.UpStopPrice or instrument.DownStopPrice)
            else
                orderParam.m_strErrorMsg = "can not get instrument"
            end
        end
    end
    
    if orderParam.m_eOperationType == OPT_FUND_SUBSCRIBE or orderParam.m_eOperationType == OPT_FUND_REDEMPTION then
        orderParam.m_eBrokerPriceType = BROKER_PRICE_PROP_FUND_ENTRUST
    end
    
    if orderParam.m_eOperationType == OPT_FUND_MERGE or orderParam.m_eOperationType == OPT_FUND_SPLIT then
        orderParam.m_eBrokerPriceType = BROKER_PRICE_PROP_FUND_CHAIHE
    end
    
    return orderParam
end

function zxjtOrder(obj)
    orderParam = parseObj2Order(obj)
    local order = zxjtOrdinaryTrade(orderParam)
    
    return order
end

-- 函数执行
function init(obj)
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
    for i = 0, vParams:size() - 1, 1 do
        local param = vParams:at(i)
        local key = string.format("%s%s%s", param.m_account.m_strAccountID, param.m_stock.m_strMarket, param.m_stock.m_strCode)
        g_params[key] = param
    end

    local params = g_params
    local statuses = g_statuses
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
            done = false
        end
    end

    if not done then
        task_helper.subscribe(XT_COrderInfo, onOrderInfo)
    else
        --printLogLevel(2, "init task already done")
    end
end

function destroy()
    --printLog("destroy")
    -- do nothing
end