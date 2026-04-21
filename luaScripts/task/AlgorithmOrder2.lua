package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

function isMarketClose(account, market, code)
    if isCheckExchange() then
        local exchangeStatus = getAccountExchangeStatus(account, market, code)
        local bClose = false
        local ret = ""
        if EXCHANGE_STATUS_CONTINOUS ~= exchangeStatus then
            bClose = true
            ret = "交易所" .. market .. "当前非交易时间"
        end
        return bClose, ret
    else
        return false, ""
    end
end

function algorithm2_fixnum(market, code, optType, nNum, nTotal)
    local bSuccess = false
    local ret = ""
    local num = 0
    local nMin = getTradeMinUnit(market, code)
    if (nTotal < nMin) then
        ret = market .. code .. "剩余委托量" .. nTotal .. ", 小于最小委托单位" .. nMin
    else
        bSuccess = true
        num = math.max(nMin, math.floor(nNum / nMin) * nMin)
    end
    
    return bSuccess, ret, num
end

function algorithm2_dispatch(param, priceType, priceData, num, orders)
    --printLog("algorithm2_dispatch")
    
    if priceData == nil then
        --printLog("platform = " .. param.m_account.m_nPlatformID .. " market = " .. param.m_stock.m_strMarket .. " code = " .. param.m_stock.m_strCode)
    end

    local isBuy = getDirectionByOperation(param.m_eOperationType)
    local price, basePrice = getRealPrice(priceType, priceData, param.m_dFixPrice, isBuy, param.m_dSuperPrice)

    -- 转股和回售与价格无关
    if param.m_eOperationType ~= OPT_CONVERT_BONDS and param.m_eOperationType ~= OPT_SELL_BACK_BONDS then
       -- 价格是否有效
        if isInvalidDouble(price) then
            return ORDER_FATAL, param.m_stock.m_strCode .. "当前委托价格不是有效价格!"
        end
        if (isBuy and basePrice > param.m_dPriceLimit) or (not isBuy and basePrice < param.m_dPriceLimit) then
            -- 提示用户
            return ORDER_DELAY, param.m_stock.m_strCode .. "当前委托价格超出价格限制, 不进行委托!"
        end
        -- 判断是否大于涨停价或者小于跌停价
        local isUpToDate = isExchangeUpToDate()
        if isUpToDate then
            if not isInvalidDouble(priceData.m_dUpperLimitPrice) and basePrice > priceData.m_dUpperLimitPrice then
                --printLog("price " .. price .. " larger than upper bound " .. priceData.m_dUpperLimitPrice .. ", set to upper")
                basePrice = priceData.m_dUpperLimitPrice
            elseif (not isInvalidDouble(priceData.m_dLowerLimitPrice) and basePrice < priceData.m_dLowerLimitPrice) then
                --printLog("price " .. price .. " less than lower bound " .. priceData.;_dLowerLimitPrice .. ", set to lower")
                basePrice = priceData.m_dLowerLimitPrice
            end
        end
    end
    local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
    -- 剩余委托量
    local orderedNum = getOrderedNum(orders, param)
    local remain = param.m_nNum - orderedNum
    if remain >= nMin then
        -- 处理为nMin整数倍，且不能大于remain
        num = max(nMin, intpart(num / nMin + 0.5) * nMin)
        local maxremain = max(nMin, intpart(remain / nMin) * nMin)
        num = min(num, maxremain)
    else
        -- 卖出允许零股，买入停止下单
        if (param.m_eOperationType ~= OPT_SELL) then
            return ORDER_SUCCESS, param.m_stock.m_strCode .. "可委托量为" .. remain .. ", 小于最小委托单位" .. nMin .. ", 停止下单!"
        end
    end

    local nTotalNum = param.m_nNum
    param.m_nNum = num
    local ops, msg = getOperations(param, basePrice)
    param.m_nNum = nTotalNum
    if #ops == 0 then
        return ORDER_FATAL, msg
    end
    local nDirection = ops[1][1]
    local nOffsetFlag = ops[1][2]

    local orderInfo = COrderInfo()
    orderInfo.m_accountInfo = param.m_account
    orderInfo.m_strExchangeId = param.m_stock.m_strMarket
    orderInfo.m_strInstrumentId = param.m_stock.m_strCode
    orderInfo.m_strProductId = param.m_stock.m_strProduct
    orderInfo.m_eOperationType = param.m_eOperationType
    orderInfo.m_nHedgeFlag = param.m_nHedgeFlag
    orderInfo.m_nOrderNum = num
    orderInfo.m_nDirection = nDirection
    orderInfo.m_nOffsetFlag = nOffsetFlag
    orderInfo.m_dPrice = basePrice
    orderInfo.m_eBrokerPriceType = BROKER_PRICE_LIMIT
    orderInfo.m_dCancelInterval = 86400
    orderInfo.m_strCloseDealId = param.m_strDealId
    orderInfo.m_eOverFreqOrderMode = param.m_eOverFreqOrderMode
    local seq = task:order(orderInfo)
    if seq == -1 then
        return ORDER_FAIL, orderInfo.m_strErrorMsg
    else
        return ORDER_SUCCESS, param.m_stock.m_strCode .."价格" .. string.format('%.3f', price) .. "委托" .. num .. (isStock(param.m_stock.m_strMarket) and "股" or "手")
    end
end

function cancelOrders(task, orders)
    local ret = 0
    for i = 0, orders:size() - 1, 1 do
        local order = orders:at(i)
        if order.m_nBusinessNum < order.m_nOrderNum and order.m_nErrorId == 0 and not order.m_bIsComplement then
            task:cancel(order)
            ret = ret + 1
        end
    end
   
    return ret
end

function getUndealtOrders(orders)
    local undealt = {}
    local undealtNum = 0
    for i = 0, orders:size() - 1, 1 do
        local order = orders:at(i)
        if order.m_nBusinessNum < order.m_nOrderNum then
            table.insert(undealt, order)
            undealtNum = undealtNum + (order.m_nOrderNum - order.m_nBusinessNum)
        end
    end
  
    return undealt, undealtNum
end

function run(obj)
    local param = parseParam(obj)

    local totalRound = math.floor(param.m_dTimeTotal / param.m_dTimeInterval)
    if  totalRound <= 0 then
        return "总下单量为0"
    end
    local singleRoundNum = param.m_nNum / totalRound
    local currentRound = 0
    local lastRoundTime = 0
    local lastOrderTime = 0
    
    -- 总体逻辑是，从0到n-1次，报单
    -- 第n-1次，先撤，再报剩下的，保证不超
    -- 第n次，不报，只终止任务
    local ret = ""
    while true do
        -- 检查任务状态
        if task:isCompleteOrCancel() then
            ret = ""
            break
        end
        
        -- 检查成交量
        local orders = task:getOrders()
        local businessNum = getBusinessNum(orders) 
        if businessNum >= param.m_nNum then
            ret = ""
            break
        end
        
        -- 检查暂停
        local bPaused = task:isPaused()
        
        -- 检查时间间隔
        local bPassTimeCheck = false
        local now = os.time()
        if currentRound == 0 or now - lastOrderTime >= param.m_dTimeInterval then
            bPassTimeCheck = true
        end    
    
        if not bPaused and bPassTimeCheck then
            if currentRound >= totalRound then
                -- 第n次，撤委托走人
                cancelOrders(task, orders)
                ret = "超过总时间限制"
                break
                
            else
                -- 取交易所状态
                local bClose, closemsg = isMarketClose(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
                if bClose then
                    task:reportRunningStatus(closemsg .. ", 暂缓报单!")
                end
                local priceData = task:getPrice(param.m_account.m_nPlatformID, param.m_stock.m_strMarket, param.m_stock.m_strCode, 10000)
                if nil == priceData then
                    task:reportRunningStatus("当前无法获取行情, 暂缓报单!")
                end
                if nil ~= priceData and not bClose then
                    if currentRound == totalRound - 1 then
                        -- 第n-1次，先撤所有未成，并等待撤完，再一次性挂出剩余
                        -- 撤不光委托绝不报单，如果超出了timeInterval则放弃
                        while true do
                            orders = task:getOrders()
                            local cancelingNum = cancelOrders(task, orders)
                            now = os.time()
                            if cancelingNum == 0 or now - lastOrderTime >= (2 * param.m_dTimeInterval) then
                                break
                            end
                                                                   
                            sleep(0.25)
                        end
                        now = os.time()
                        if lastOrderTime ~= 0 and now - lastOrderTime >= (2 * param.m_dTimeInterval) then
                            ret = "超出总时间限制"
                            break
                        end
                        
                        -- 重新取是因为上面可能循环很久了
                        orders = task:getOrders()
                        businessNum = getBusinessNum(orders)
                        if businessNum < param.m_nNum then
                            local status, msg = algorithm2_dispatch(param, param.m_ePriceTypeOrigin, priceData, param.m_nNum - businessNum, orders)
                            if status == ORDER_FATAL then
                                ret = msg
                                break
                            else
                                if msg ~= nil and string.len(msg) > 0 then
                                    task:reportRunningStatus(msg)
                                end
                            end
                        end
                    else
                        -- 中间环节
                        -- 1. 获取未成委托和未成量
                        local undealtOrders, undealtNum = getUndealtOrders(orders)
                        -- 2. 计算未成处理上限
                        local undealtMax = undealtNum
                        -- 3. 计算正常挂单上限
                        local currentMax = singleRoundNum - undealtMax
                        -- 4. 根据价格进行未成撤单判断
                        local isBuy = getDirectionByOperation(param.m_eOperationType)
                        local price, basePrice = getRealPrice(param.m_ePriceTypeOrigin, priceData, param.m_dFixPrice, isBuy, param.m_dSuperPrice)
                        local canceledCount = 0
                        for i = 1, table.maxn(undealtOrders), 1 do 
                            local undealt = undealtOrders[i]
                            if (isBuy and undealt.m_dPrice < basePrice) or ((not isBuy) and undealt.m_dPrice > basePrice) then
                                task:cancel(undealt)
                                canceledCount = canceledCount + 1
                            end
                        end
                        -- 5. 如果有撤单的等0.5秒回报
                        if canceledCount > 0 then
                            sleep(0.5)
                            -- 5.1. 再次获取委托、成交和未成委托
                            orders = task:getOrders()
                            businessNum = getBusinessNum(orders)
                            undealtOrders, undealtNum = getUndealtOrders(orders)
                        end
                        -- 6. 计算不超单前提下真实未成处理量
                        local undealtReal = math.min(param.m_nNum - businessNum - undealtNum, undealtMax)
                        undealtReal = math.max(undealtReal, 0)
                        -- 7. 计算不超单前提下真实正常挂单量
                        local currentReal = math.min(param.m_nNum - businessNum - undealtNum - undealtReal, currentMax)
                        currentReal = math.max(currentReal, 0)
                        -- 8. 挂强吃单
                        if undealtReal > 0 then
                            -- 未成强吃
                            local status, msg = algorithm2_dispatch(param, param.m_ePriceTypeUndealt, priceData, undealtReal, orders)
                            if status == ORDER_FATAL then
                                ret = msg
                                break
                            else
                                if msg ~= nil and string.len(msg) > 0 then
                                    task:reportRunningStatus(msg)
                                end
                            end
                        end
                        -- 9. 挂正常单(为0也走dispatch，为了避免故意设成每轮报0.x的情况)
                        if currentReal > 0 then
                            -- 当前新增
                            local status, msg = algorithm2_dispatch(param, param.m_ePriceTypeOrigin, priceData, currentReal, orders)
                            if status == ORDER_FATAL then
                                ret = msg
                                break
                            else
                                if msg ~= nil and string.len(msg) > 0 then
                                    task:reportRunningStatus(msg)
                                end
                            end
                        end
                    end
                end
                
                lastOrderTime = os.time()
                currentRound = currentRound + 1
            end    
        end

        sleep(0.25)
    end
    
    return ret
end
