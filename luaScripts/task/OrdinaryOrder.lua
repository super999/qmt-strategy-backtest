package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end
 
-- 单次报单
function ordinaryDispatch(param, orders)
    --printLog("Inside ordinary_dispatch ...")
    -- 取价格
    local priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 10000)
    local isBuy = getDirectionByOperation(param.m_eOperationType)

    local price = getInvalidDouble()
    local basePrice = getInvalidDouble()
    price, basePrice = getRealPrice(param.m_ePriceType, priceData, param.m_dFixPrice, isBuy, param.m_dSuperPrice)

    -- 对于普通交易，指定价不需要超价。
    if param.m_ePriceType == PRTP_FIX then
        price = basePrice
    end

    -- 转股和回售与价格无关
    if param.m_eOperationType ~= OPT_CONVERT_BONDS and param.m_eOperationType ~= OPT_SELL_BACK_BONDS then
        -- 价格是否有效
        if isInvalidDouble(price) and param.m_ePriceType ~= PRTP_FIX then
            return ORDER_FATAL, param.m_stock.m_strCode .. "当前委托价格不是有效价格!"
        end

        -- 判断是否大于涨停价或者小于跌停价
        if param.m_ePriceType == PRTP_MARKET then
            if isSupportMarketPrice(priceData.m_strExchangeID, priceData.m_strInstrumentID) then
                --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " support market price, set price to 0.")
                price = 0.0
            else
                --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " DOES NOT support market price, set price to " .. (isBuy and "upper bound" or "lower bound"))
                price = (isBuy and priceData.m_dUpperLimitPrice or priceData.m_dLowerLimitPrice)
            end
        end
    end

    local ops, msg = getOperations(param, price)
    if #ops == 0 then
        return ORDER_FATAL, msg
    end

    -- 下单价格类型
    local priceType = BROKER_PRICE_LIMIT
    if param.m_ePriceType == PRTP_MARKET then
        if isSupportMarketPrice(param.m_stock.m_strMarket, param.m_stock.m_strCode) then
            priceType = getMarketPriceType(param.m_stock.m_strMarket)
        end
    end

    --printLog(" *** final order price : " .. price)

    for _, v in ipairs(ops) do
        local orderInfo = COrderInfo()
        orderInfo.m_accountInfo = param.m_account;
        orderInfo.m_strExchangeId = param.m_stock.m_strMarket;
        orderInfo.m_strInstrumentId = param.m_stock.m_strCode;
        orderInfo.m_strProductId = param.m_stock.m_strProduct;
        orderInfo.m_eOperationType = param.m_eOperationType
        orderInfo.m_nHedgeFlag = param.m_nHedgeFlag;
        orderInfo.m_nDirection = v[1]
        orderInfo.m_nOffsetFlag = v[2]
        orderInfo.m_nOrderNum = v[3]
        orderInfo.m_dPrice = price
        orderInfo.m_eBrokerPriceType = priceType
        orderInfo.m_dCancelInterval = 86400
        orderInfo.m_eEntrustType = getEntrustType(param.m_account.m_nBrokerType, param.m_eOperationType)
        orderInfo.m_strCloseDealId = param.m_strDealId
        orderInfo.m_eOverFreqOrderMode = param.m_eOverFreqOrderMode
        local seq = task:order(orderInfo)
        if seq == -1 then
            return ORDER_FATAL, orderInfo.m_strErrorMsg
        end
    end

    return ORDER_SUCCESS, "目标量已按价格" .. price .. "全部委托!"
end

-- 函数执行
function run(obj)
    local param = parseParam(obj)    
    local ret = ""
    local lastOrderTime = 0

    -- 初始化历史委托状态，避免因未成委托处理造成超单
    local orders = task:getOrders()
    checkErrors(orders)

    while true do
        
        if task:isCompleteOrCancel() then
            --printLog("task canceled by user")
            break
        end

        local orders = task:getOrders()

        if orders:size() == 0 then
            --printLog("no orders yet, about to dispatch")

            local priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 10000)
            local status = ORDER_DELAY
            local msg = ""

            if priceData == nil then
                status = ORDER_DELAY
                msg = "行情没有取到，暂缓报单"
            else
                if param.m_eTriggerType == OTT_UP and (param.m_dTriggerPrice - priceData.m_dLastPrice > 0.001) then
                    status = ORDER_DELAY
                    msg = "最新价" .. tostring(paramData.m_dLastPrice) .. ", 触价" .. tostring(param.m_dTriggerPrice) .. "未达到，暂缓报单"
                elseif param.m_eTriggerType == OTT_DOWN and (priceData.m_dLastPrice - param.m_dTriggerPrice > 0.001) then
                    status = ORDER_DELAY
                    msg = "最新价" .. tostring(paramData.m_dLastPrice) .. ", 触价" .. tostring(param.m_dTriggerPrice) .. "未达到，暂缓报单"
                else
                    status, msg = ordinaryDispatch(param, orders)
                end
            end

            if status == ORDER_FATAL then
                --printLog("not continue 1, msg = " .. msg .. ", break")
                ret = msg
                break
            else
                --printLog("continue, report status, msg = " .. msg)
                task:reportRunningStatus(msg)
            end
        else
            local businessNum = getBusinessNum(orders)
            if businessNum >= param.m_nNum then
                --printLog("bussiness num " .. businessNum .. " >= param num " .. param.m_nNum .. ", break")
                break
            end

            local bContinue, msg, undealed = checkErrors(orders)
            if not bContinue then
                --printLog("not continue 2, msg = " .. msg .. ", break")
                ret = msg
                break
            end

            if msg ~= nil and string.len(msg) > 0 then
                --printLog("continue 2, but msg = " .. msg .. ", break")
                ret = msg
                break
            end

            local bComplete = true
            for i = 0, orders:size() - 1, 1 do
                local v = orders:at(i)
                if not isGreater(v.m_dCompleteTime, 0) then
                    bComplete = false
                    break
                end
            end

            if bComplete then
                ret = "已撤单"
                break
            end
        end

        sleep(1)
    end

    return ret
end
