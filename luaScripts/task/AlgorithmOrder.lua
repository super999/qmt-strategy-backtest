package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

function dispatchUndealedStock(param, order)
    --printLog("Inside dispatchUndealedStock")
    if param.m_eOrderType == OTP_ORDINARY then
        return ORDER_FATAL, "普通交易不支持未成委托处理"
    else
        if param.m_eUndealtEntrustRule == PRTP_INVALID then
            return ORDER_FATAL, "未成委托处理方式非法"
        elseif order.m_accountInfo == CAccountInfo_NULL then
            return ORDER_FATAL, "账号数据为空"
        else
            local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
            if order.m_nOrderNum - order.m_nBusinessNum < nMin then
                return ORDER_FATAL, "委托剩余量小于单笔委托最小量"
            end
            tempParam = CCodeOrderParam()
            tempParam.m_account = param.m_account
            tempParam.m_nHedgeFlag = param.m_nHedgeFlag
            tempParam.m_eOperationType = param.m_eOperationType
            tempParam.m_eOrderType = param.m_eOrderType
            tempParam.m_eSplitType = param.m_eSplitType
            tempParam.m_stock = param.m_stock
            tempParam.m_ePriceType = param.m_eUndealtEntrustRule
            tempParam.m_dFixPrice = param.m_dFixPrice
            tempParam.m_dPlaceOrderInterval = param.m_dPlaceOrderInterval
            tempParam.m_dWithdrawOrderInterval = param.m_dWithdrawOrderInterval
            tempParam.m_nMaxOrderCount = param.m_nMaxOrderCount
            tempParam.m_nMaxWithdrawCount = param.m_nMaxWithdrawCount
            tempParam.m_nNum = order.m_nOrderNum - order.m_nBusinessNum
            tempParam.m_dFrozenNum = 0
            tempParam.m_dPriceRangeMin = 0
            tempParam.m_dPriceRangeMax = 9999999
            tempParam.m_dSuperPrice = 0
            tempParam.m_eSingleVolumeType = VOLUME_FIX
            tempParam.m_dSingleVolumeRate = 1
            tempParam.m_nSingleNumMin = param.m_nSingleNumMin
            tempParam.m_nSingleNumMax = param.m_nSingleNumMax
            tempParam.m_nValidTimeStart = param.m_nValidTimeStart
            tempParam.m_nValidTimeEnd = param.m_nValidTimeEnd
            tempParam.m_nSuperPriceStart = param.m_nSuperPriceStart
            tempParam.m_nLastVolumeMin = param.m_nLastVolumeMin
            tempParam.m_strSource = param.m_strSource
            tempParam.m_eTotalNumType = param.m_eTotalNumType
            tempParam.m_bIsAllOrder = param.m_bIsAllOrder
            tempParam.m_bIsLastPrice = param.m_bIsLastPrice
            tempParam.m_eUndealtEntrustRule = param.m_eUndealtEntrustRule
            tempParam.m_strDealId = param.m_strDealId
            --printLog("About to do undealt...")
            return algorithmDispatch(tempParam, COrderInfoVec())
        end
    end
end

function algorithmDispatch(param, orders)
    --printLog("Inside algorithm_dispatch ...")
    -- 超过撤单次数上限
    if not isInvalidInt(param.m_nMaxWithdrawCount) and getCancelTimes(orders) >= param.m_nMaxWithdrawCount then
        --printLog("超过最大撤单次数限制" .. param.m_nMaxWithdrawCount .. "!")
        return ORDER_FATAL, "超过最大撤单次数限制" .. param.m_nMaxWithdrawCount .. "!"
    end

    if not isInvalidInt(param.m_nMaxOrderCount) then
        local orderCount = getOrderedTime(orders)
        if orderCount >= param.m_nMaxOrderCount then
            --printLog("超过最大委托次数限制" .. param.m_nMaxOrderCount .. "!")
            return ORDER_FATAL, "超过最大委托次数限制" .. param.m_nMaxOrderCount .. "!"
        end
    end

    -- 不在有效时间
    local now = now()
    if not isInvalidInt(param.m_nValidTimeEnd) and now > param.m_nValidTimeEnd then
        --printLog("当前时间超出有效时间范围!")
        return ORDER_FATAL, "当前时间超出有效时间范围!"
    end

    if not isInvalidInt(param.m_nValidTimeStart) and now < param.m_nValidTimeStart then
        --printLog("当前时间不在有效时间范围!")
        return ORDER_DELAY, "当前时间不在有效时间范围!"
    end

    -- 交易所状态
    if isCheckExchange() then
        exchangeStatus = getAccountExchangeStatus(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
        --printLog("Need to check exchange status, status = " .. exchangeStatus)
        if (EXCHANGE_STATUS_CONTINOUS ~= exchangeStatus) then
            --printLog("交易所" .. param.m_stock.m_strMarket .. "当前非交易时间, 暂缓报单!")
            return ORDER_DELAY, "交易所" .. param.m_stock.m_strMarket .. "当前非交易时间, 暂缓报单!"
        end
    --else
        --printLog("Need NOT to check exchange status.")
    end

    -- 是否全部委托已经处于完成状态
    -- 由于orders状态可能被C++程序修改
    -- 所以必须在获取委托剩余量之前判断
    local bAllComplete = true
    for i = 0, orders:size() - 1, 1 do
        local o = orders:at(i)
        if isZero(o.m_dCompleteTime) then
            bAllComplete = false
            break
        end
    end

    -- 剩余委托量
    local orderedNum = getOrderedNum(orders, param)
    local remain = param.m_nNum - orderedNum
    --printLog("total num = " .. param.m_nNum .. ", orderedNum = " .. orderedNum)
    if remain <= 0 then
        --printLog("目标量已全部委托!")
        return ORDER_DELAY, "目标量已全部委托!"
    end

    -- 取价格数据
    local priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 10000)

    local isBuy = getDirectionByOperation(param.m_eOperationType)

    -- 取下单基准价和调整价
    local price = getInvalidDouble()
    local basePrice = getInvalidDouble()
    price, basePrice = getRealPrice(param.m_ePriceType, priceData, param.m_dFixPrice, isBuy, param.m_dSuperPrice)

    -- 转股和回售与价格无关
    if param.m_eOperationType ~= OPT_CONVERT_BONDS and param.m_eOperationType ~= OPT_SELL_BACK_BONDS then
    -- 价格是否有效
        if isInvalidDouble(price) or isInvalidDouble(basePrice) then
            --printLog(param.m_stock.m_strCode .. "当前基准价不是有效价格!")
            return ORDER_DELAY, param.m_stock.m_strCode .. "当前基准价不是有效价格!"
        end

        -- 非市价, 判断是否在波动区间
        if param.m_ePriceType ~= PRTP_MARKET and not isInRegion(basePrice, param.m_dPriceRangeMin, param.m_dPriceRangeMax) then
            --printLog(param.m_stock.m_strCode .."当前基准价" .. price .. "不在波动区间(" .. param.m_dPriceRangeMin .. "~" .. param.m_dPriceRangeMax .. ")!")
            return ORDER_DELAY, param.m_stock.m_strCode .."当前基准价" .. price .. "不在波动区间(" .. param.m_dPriceRangeMin .. "~" .. param.m_dPriceRangeMax .. ")!"
        end
    end

    -- 判断是否使用超价
    if not isInvalidInt(param.m_nSuperPriceStart) and orders:size() < param.m_nSuperPriceStart - 1 then
        price = basePrice
    end

    -- 报价不能超过波动区间
    if param.m_ePriceType ~= PRTP_MARKET then
        if price > param.m_dPriceRangeMax then
            --printLog("price " .. price .. " larger than float range upper bound " .. param.m_dPriceRangeMax .. ", set to upper")
            price = param.m_dPriceRangeMax
        elseif price < param.m_dPriceRangeMin then
            --printLog("price " .. price .. " less than float range lower bound " .. param.m_dPriceRangeMin .. ", set to lower")
            price = param.m_dPriceRangeMin
        end
    end

    -- 判断是否大于涨停价或者小于跌停价
    local isUpToDate = isExchangeUpToDate()
    if param.m_ePriceType ~= PRTP_MARKET then
        if isUpToDate then
            if not isInvalidDouble(priceData.m_dUpperLimitPrice) and priceData.m_dUpperLimitPrice > 0 and price > priceData.m_dUpperLimitPrice then
                --printLog("price " .. price .. " larger than upper bound " .. priceData.m_dUpperLimitPrice .. ", set to upper")
                price = priceData.m_dUpperLimitPrice
            elseif (not isInvalidDouble(priceData.m_dLowerLimitPrice) and priceData.m_dLowerLimitPrice > 0 and price < priceData.m_dLowerLimitPrice) then
                --printLog("price " .. price .. " less than lower bound " .. priceData.m_dLowerLimitPrice .. ", set to lower")
                price = priceData.m_dLowerLimitPrice
            end
        end
    else
        if isSupportMarketPrice(priceData.m_strExchangeID, priceData.m_strInstrumentID) then
            --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " support market price, set price to 0.")
            price = 0.0
        else
            --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " DOES NOT support market price, set price to " .. (isBuy and "upper bound" or "lower bound"))
            price = (isBuy and priceData.m_dUpperLimitPrice or priceData.m_dLowerLimitPrice)
        end
    end

    -- 数量
    local nDirection, nOffsetFlag, num, msg = getOrderNum(param, priceData, remain, price)
    if isInvalidInt(num) then
        return ORDER_DELAY, msg
    end

    local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
    if num < nMin then
        if bAllComplete then
            if param.m_eOperationType ~= OPT_SELL then
                --printLogLevel(2, "账号" .. param.m_account.m_strAccountID .. ", " .. param.m_stock.m_strCode .. "可委托量为" .. num .. ", 停止下单!")
                return ORDER_FATAL, param.m_stock.m_strCode .. "可委托量为" .. num .. ", 小于最小委托单位" .. nMin .. ", 停止下单!"
            --else
                --printLogLevel(2, "账号" .. param.m_account.m_strAccountID .. ", " .. param.m_stock.m_strCode .. "可委托量为" .. num .. ", 等待其他委托状态更新!")
            end
        else
            --printLogLevel(2, "账号" .. param.m_account.m_strAccountID .. ", " .. param.m_stock.m_strCode .. "可委托量为" .. num .. ", 暂缓下单!")
            return ORDER_DELAY, param.m_stock.m_strCode .. "可委托量为" .. num .. ", 小于最小委托单位" .. nMin .. ", 暂缓下单!"
        end
    --else
        --printLogLevel(2, param.m_stock.m_strCode .. "委托量为" .. num)
    end

    -- 下单价格类型
    local priceType = BROKER_PRICE_LIMIT
    if param.m_ePriceType == PRTP_MARKET then
        if isSupportMarketPrice(param.m_stock.m_strMarket, param.m_stock.m_strCode) then
            priceType = getMarketPriceType(param.m_stock.m_strMarket)
        end
    end

    --printLog(" *** final order price : " .. price .. ", num : " .. num)

    local orderInfo = COrderInfo()
    orderInfo.m_accountInfo = param.m_account;
    orderInfo.m_strExchangeId = param.m_stock.m_strMarket;
    orderInfo.m_strInstrumentId = param.m_stock.m_strCode;
    orderInfo.m_strProductId = param.m_stock.m_strProduct;
    orderInfo.m_eOperationType = param.m_eOperationType
    orderInfo.m_nHedgeFlag = param.m_nHedgeFlag;
    orderInfo.m_nOrderNum = num
    orderInfo.m_nDirection = nDirection
    orderInfo.m_nOffsetFlag = nOffsetFlag
    orderInfo.m_dPrice = price
    orderInfo.m_eBrokerPriceType = priceType
    orderInfo.m_dCancelInterval = param.m_dWithdrawOrderInterval
    orderInfo.m_eEntrustType = getEntrustType(param.m_account.m_nBrokerType, param.m_eOperationType)
    orderInfo.m_strCloseDealId = param.m_strDealId
    orderInfo.m_eOverFreqOrderMode = param.m_eOverFreqOrderMode
    local seq = task:order(orderInfo)
    if seq == -1 then
        return ORDER_FAIL, orderInfo.m_strErrorMsg
    else
        return ORDER_SUCCESS, param.m_stock.m_strCode .."价格" .. string.format('%.3f', price) .. "委托" .. num .. (isStock(param.m_stock.m_strMarket) and "股" or "手")
    end
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

        local wait = false
        local triggerMsg = ""
        if orders:size() == 0 then
            --printLog("check trigger")
            local priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 10000)
            if priceData == nil then
                wait = true
                triggerMsg = "行情没有取到，暂缓报单"
            else
                if param.m_eTriggerType == OTT_UP and (param.m_dTriggerPrice - priceData.m_dLastPrice > 0.001) then
                    wait = true
                    msg = "最新价" .. tostring(paramData.m_dLastPrice) .. ", 触价" .. tostring(param.m_dTriggerPrice) .. "未达到，暂缓报单"
                elseif param.m_eTriggerType == OTT_DOWN and (priceData.m_dLastPrice - param.m_dTriggerPrice > 0.001) then
                    wait = true
                    triggerMsg = "最新价" .. tostring(paramData.m_dLastPrice) .. ", 触价" .. tostring(param.m_dTriggerPrice) .. "未达到，暂缓报单"
                else
                    wait = false
                end
            end
        end

        if wait then
            task:reportRunningStatus(triggerMsg)
        else
            local businessNum = getBusinessNum(orders)
            if businessNum >= param.m_nNum then
                --printLog("bussiness num " .. businessNum .. " >= param num " .. param.m_nNum .. ", break")
                break
            end

            --local hasUndealed = false

            local bContinue, msg, undealed = checkErrors(orders)
            if not bContinue then
                --printLog("not continue 2, msg = " .. msg .. ", break")
                ret = msg
                break
            else
                if param.m_eUndealtEntrustRule ~= PRTP_INVALID then
                    local orderCount = getOrderedTime(orders)
                    for i = 1, table.maxn(undealed), 1 do
                        local order = undealed[i]
                        if isInvalidInt(param.m_nMaxOrderCount) or orderCount < param.m_nMaxOrderCount then
                            local status, msg1 = dispatchUndealedStock(param, order)
                            if status == ORDER_SUCCESS or status == ORDER_FAIL then
                                orders = task:getOrders()
                                orderCount = getOrderedTime(orders)
                                --hasUndealed = true
                            end
                        end
                        order.m_bIsComplement = true
                    end
                end

                if msg ~= nil and string.len(msg) > 0 then
                    task:reportRunningStatus(msg)
                end
            end

            --if hasUndealed then
            --    orders = task:getOrders()
            --end

            local now = os.time()
            if now - lastOrderTime >= param.m_dPlaceOrderInterval then
                local status, msg = algorithmDispatch(param, orders)
                if status == ORDER_FATAL then
                    --printLog("not continue 1, msg = " .. msg .. ", break")
                    ret = msg
                    break
                else
                    if status == ORDER_SUCCESS or status == ORDER_FAIL then
                        lastOrderTime = now
                    end

                    if msg ~= nil and string.len(msg) > 0 then
                        task:reportRunningStatus(msg)
                    end
                end
            end
        end

        sleep(0.1)
    end

    return ret
end

