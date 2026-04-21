package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/OrdinaryOrder.lua")
dofile("../luaScripts/task/AlgorithmOrder.lua")

STATUS_RUNNING = 0
STATUS_ERROR = -1
STATUS_FINISH = 1

g_final_state_orders = {}

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParamList()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

local function dispatchStock(param, orders)
    if param.m_eOrderType == OTP_ORDINARY then
        return ordinaryDispatch(param, orders)
    else 
        return algorithmDispatch(param, orders)
    end
end

-- 委托状态检查
function checkBatchErrors(orders)
    local ret = ""
    local undealed = {}
    local id = 1

    for i = 0, orders:size() - 1, 1 do
        local order = orders:at(i)
        local key = order:getKey()
        if g_final_state_orders[key] == nil then
            if isGreater(order.m_dCompleteTime, 0) then
                g_final_state_orders[key] = true
                if order.m_nBusinessNum < order.m_nOrderNum and order.m_nErrorId == 0 and not order.m_bIsComplement then
                    undealed[id] = order
                    id = id + 1

                    if string.len(order.m_strErrorMsg) > 0 then
                        ret = order.m_strErrorMsg
                    end
                end
            end

--            if order.m_nErrorId ~= 0 then
--                local pid = order.m_accountInfo.m_nPlatformID
--                if g_trade_fatal_errors[pid] ~= nil and g_trade_fatal_errors[pid][order.m_nErrorId] ~= nil then
--                    return false, order.m_strErrorMsg, undealed
--                end
--            end
        end
    end

    return true, ret, undealed
end


-- 执行函数
function run(obj)
    local paramList = parseParam(obj)
    local params = paramList.m_params

    if params:size() == 0 then
        return "任务参数为空"
    end

    local timeMap = {}
    local statusMap = {}
    for i = 0, params:size() - 1, 1 do
        local param = params:at(i)
        local key = param.m_account.m_strAccountID .. ":" .. param.m_stock.m_strMarket .. param.m_stock.m_strCode
        timeMap[key] = 0
        statusMap[key] = STATUS_RUNNING
    end

    -- 初始化历史委托状态，避免因未成委托处理造成超单
    local allOrders = task:getOrders()
    for i = 0, params:size() - 1, 1 do
        local param = params:at(i)
        local key = param.m_account.m_strAccountID .. ":" .. param.m_stock.m_strMarket .. param.m_stock.m_strCode

        if statusMap[key] == STATUS_RUNNING then
            local orders = COrderInfoVec()
            for j = 0, allOrders:size() - 1, 1 do
                local order = allOrders:at(j)
                if key == order.m_accountInfo.m_strAccountID .. ":" .. order.m_strExchangeId .. order.m_strInstrumentId then
                    orders:push_back(order)
                end
            end

            local bContinue, msg, undealed = checkBatchErrors(orders)
            if not bContinue then
                statusMap[key] = STATUS_ERROR
            end
        end
    end

    local ret = ""

    while true do
        local bQuit = task:isCompleteOrCancel()
        if bQuit then break end

        local hasUndealed = false

        local allOrders = task:getOrders()
        for i = 0, params:size() - 1, 1 do
            local param = params:at(i)
            local key = param.m_account.m_strAccountID .. ":" .. param.m_stock.m_strMarket .. param.m_stock.m_strCode

            if statusMap[key] == STATUS_RUNNING then
                local orders = COrderInfoVec()
                for j = 0, allOrders:size() - 1, 1 do
                    local order = allOrders:at(j)
                    if key == order.m_accountInfo.m_strAccountID .. ":" .. order.m_strExchangeId .. order.m_strInstrumentId then
                        orders:push_back(order)
                    end
                end

                local bContinue, msg, undealed = checkBatchErrors(orders)
                if not bContinue then
                    statusMap[key] = STATUS_ERROR
                else
                    if param.m_eUndealtEntrustRule ~= PRTP_INVALID then
                        local orderCount = getOrderedTime(orders)
                        for j = 1, table.maxn(undealed), 1 do
                            local order = undealed[j]
                            if isInvalidInt(param.m_nMaxOrderCount) or orderCount < param.m_nMaxOrderCount then
                                local status, msg1 = dispatchUndealedStock(param, order)
                                if status == ORDER_SUCCESS or status == ORDER_FAIL then
                                    orderCount = orderCount + 1
                                    hasUndealed = true
                                end
                            end
                            order.m_bIsComplement = true
                        end
                    end
                end
            end

            bQuit = task:isCompleteOrCancel()
            if bQuit then break end
        end

        if bQuit then break end

        if hasUndealed then
            allOrders = task:getOrders()
        end

        for i = 0, params:size() - 1, 1 do
            local param = params:at(i)
            local key = param.m_account.m_strAccountID .. ":" .. param.m_stock.m_strMarket .. param.m_stock.m_strCode

            if statusMap[key] == STATUS_RUNNING then
                local orders = COrderInfoVec()
                for j = 0, allOrders:size() - 1, 1 do
                    local order = allOrders:at(j)
                    if key == order.m_accountInfo.m_strAccountID .. ":" .. order.m_strExchangeId .. order.m_strInstrumentId then
                        orders:push_back(order)
                    end
                end

                if getBusinessNum(orders) >= param.m_nNum then
                    statusMap[key] = STATUS_FINISH
                else
                    local now = os.time()
                    if now - timeMap[key] >= param.m_dPlaceOrderInterval then
                        local status, msg = dispatchStock(param, orders)
                        if status == ORDER_FATAL then
                            statusMap[key] = STATUS_ERROR
                        else
                            if status == ORDER_SUCCESS or status == ORDER_FAIL then
                                timeMap[key] = now
                            --elseif status == ORDER_DELAY then
                                --printLogLevel(2, "账号" .. param.m_account.m_strAccountID .. ", " .. msg)
                            end
                        end
                    end
                end
            end

            bQuit = task:isCompleteOrCancel()
            if bQuit then break end
        end

        if bQuit then break end

        task:report()

        bQuit = true
        local bError = false
        for k, v in pairs(statusMap) do
            if v == STATUS_RUNNING then
                bQuit = false
                break
            elseif v == STATUS_ERROR then
                bError = true
            end
        end

        if bQuit then
            if bError then
                ret = "任务结束，部分委托异常"
            end
            break
        end

        --local now = os.time()
        local bSleep = true
        --for i = 0, params:size() - 1, 1 do
        --    local param = params:at(i)
        --    local key = param.m_account.m_strAccountID .. ":" .. param.m_stock.m_strMarket .. param.m_stock.m_strCode
        --    if statusMap[key] == STATUS_RUNNING and now - timeMap[key] >= param.m_dPlaceOrderInterval then
        --        bSleep = false
        --        break;
        --    end
        --end

        if bSleep then sleep(1) end
    end

    return ret
end

