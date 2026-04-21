package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

g_param = nil

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end
 
-- 单次报单
function directSecuRepayDispatch(param, orders)
    --printLog("Inside directSecuRepayDispatch ...")
    
    local orderInfo = COrderInfo()
    orderInfo.m_accountInfo = param.m_account
    orderInfo.m_strExchangeId = param.m_stock.m_strMarket
    orderInfo.m_strInstrumentId = param.m_stock.m_strCode
    orderInfo.m_strProductId = param.m_stock.m_strProduct
    orderInfo.m_eOperationType = param.m_eOperationType
    orderInfo.m_nDirection = ENTRUST_SELL
    orderInfo.m_nOffsetFlag = EOFF_THOST_FTDC_OF_Close
    orderInfo.m_nHedgeFlag = HEDGE_FLAG_SPECULATION
    orderInfo.m_nOrderNum = param.m_nNum
    orderInfo.m_dCancelInterval = 86400
    orderInfo.m_eEntrustType = param.m_eEntrustType
    orderInfo.m_ePayType = param.m_ePayType;
    orderInfo.m_eOverFreqOrderMode = param.m_eOverFreqOrderMode

	if param.m_eOperationType == OPT_DIRECT_CASH_REPAY or param.m_eOperationType == OPT_INTEREST_FEE or param.m_eOperationType == OPT_DIRECT_CASH_REPAY_SPECIAL then
        orderInfo.m_dOccurBalance = param.m_dOccurBalance
    end

    orderInfo.m_strCompactId = param.m_strCompactId
	
    local seq = task:order(orderInfo)
    if seq == -1 then
        return ORDER_FATAL, orderInfo.m_strErrorMsg
    end

    return ORDER_SUCCESS, "目标量已全部委托!"
end

local function onOrderInfo(orderInfo)
    printLogLevel(2, "go to onOrderInfo")
    local param = g_param
    local ret = ""
    local orders = task:getOrders()
    checkErrors(orders)
    local businessNum = getBusinessNum(orders)
    if businessNum >= param.m_nNum then
        printLogLevel(2, "bussiness num " .. businessNum .. " >= param num " .. param.m_nNum .. ", break")
        task:setCompleted(false, "")
        return ret
    end
    
    local bContinue, msg, undealed = checkErrors(orders)
    if not bContinue then
        ret = msg
        task:setCompleted(true, ret)
        return ret
    end

    if msg ~= nil and string.len(msg) > 0 then
        ret = msg
        task:setCompleted(true, ret)
        return ret
    end

    local bComplete = true
    for i = 0, orders:size() - 1, 1 do
        local v = orders:at(i)
        if not isGreater(v.m_dCompleteTime, 0) then
            bComplete = false
        end
    end

    if bComplete then
        ret = "已撤单"
        task:setCompleted(true, ret)
        return ret
    end
    
    --return ret
end

-- 函数执行
function init(obj)
    g_param = parseParam(obj)    
    local param = g_param
    local ret = ""
    
    task_helper.subscribe(XT_COrderInfo, onOrderInfo)
    
    -- 初始化历史委托状态，避免因未成委托处理造成超单
    local orders = task:getOrders()
    checkErrors(orders)
    
    if task:isCompleteOrCancel() then
        printLogLevel(2, "task canceled by user")
        return ret
    end

    if orders:size() == 0 then
        printLogLevel(2, "no orders yet, about to dispatch")
        local status, msg = directSecuRepayDispatch(param, orders)

        if status == ORDER_FATAL then
            task:reportRunningStatus(msg)
            ret = msg
            return ret
        else
            task:reportRunningStatus(msg)
        end
		
		if param.m_eOperationType == OPT_DIRECT_CASH_REPAY or param.m_eOperationType == OPT_INTEREST_FEE then
            if status == ORDER_SUCCESS then
                task:setCompleted(false, "")
            else
                task:setCompleted(true, msg)
            end
        end
    else
        printLogLevel(2, "has non-dealed orders")
        local orderInfo = COrderInfo()
        onOrderInfo(orderInfo)
    end    
end