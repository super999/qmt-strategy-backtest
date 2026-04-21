package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

g_param = nil
g_orders = {}
g_isOrdered = false

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
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

    g_orders[orderInfo:getKey()] = orderInfo
    local param = g_param
    local orders = g_orders
    local bizNum = getBusinessNum2(orders)
    if bizNum >= param.m_nNum then
        task:setCompleted(true, "")
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
            break
        end
    end

    if over then
        task:reportRunningStatus("所报委托已全部终结")
    else
        if string.len(errMsg) > 0 then
            task:reportRunningStatus(errMsg)
        end
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
            g_orders[order:getKey()] = order
            g_isOrdered = true
        end
    end
    
    g_param = parseParam(obj)
    local param = g_param

    local orders = g_orders
    local bizNum = getBusinessNum2(orders)
    if bizNum >= param.m_nNum then
        task:setCompleted(true, "")
        return
    end

    task_helper.subscribe(XT_COrderInfo, onOrderInfo)
end

function destory()
    -- do nothing
end
