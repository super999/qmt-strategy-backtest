package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Error.lua")

ORDER_FATAL = 0
ORDER_DELAY = 1
ORDER_FAIL = 2
ORDER_SUCCESS = 3

AT_FUTURE = 1
AT_STOCK = 2
AT_CREDIT = 3

FLOAT_ERROR = 1e-5 

function isZero(d)
    return abs(d) <= FLOAT_ERROR
end

function isEqual(d1, d2)
    return abs(d1 - d2) <= FLOAT_ERROR
end

function isGreater(d1, d2)
    return d1 - d2 > FLOAT_ERROR
end

function isLess(d1, d2)
    return d1 - d2 < -1 * FLOAT_ERROR
end

function isGreaterEqual(d1, d2)
    return d1 - d2 >= -1 * FLOAT_ERROR
end

function isLessEqual(d1, d2)
    return d1 - d2 <= FLOAT_ERROR
end

local function isPriceTypeShouldHintDelay(priceType)
    return (priceType >= PRTP_SALE5 and priceType <= PRTP_BUY5)
        or (priceType == PRTP_HANG)
        or (priceType == PRTP_COMPETE)
end

function formatDouble(d)
    if isInvalidDouble(d) then
        return '[invalid]'
    end
    return string.format('%.4f', d)
end

local function timeStringToInt(timeStr)
    local len = #timeStr
    if len >= 7 then
        local h = tonumber(string.sub(timeStr, 1, len - 6))
        local m = tonumber(string.sub(timeStr, len - 4, len - 3))
        local s = tonumber(string.sub(timeStr, len - 1, len))
        if nil ~= h and nil ~= m and nil ~= s then
            return 1e4 * h + 1e2 * m + s
        end
    end
    return -1
end

function accountDisplayId(accountInfo)
    if nil ~= accountInfo and CAccountInfo_NULL ~= accountInfo then
        if #accountInfo.m_strSubAccount > 0 then
            return accountInfo.m_strSubAccount
        end
        return accountInfo.m_strAccountID
    end
    return ""
end

g_final_state_orders = {}
g_not_final_state_order_start_id = 0

-- 委托状态检查
function checkErrors(orders)
    local ret = ""
    local undealed = {}
    local iUndealed = 1
    local id = orders:size() - 1

    for i = orders:size() - 1, g_not_final_state_order_start_id, -1 do -- 考查所有没有到终止状态的委托
        local order = orders:at(i)
        local key = order:getKey()
        if g_final_state_orders[key] == nil then -- 此委托还没有记录终止状态
            if isGreater(order.m_dCompleteTime, 0) then -- 已经结束的委托，需要记录终止状态，并判断错误消息
                g_final_state_orders[key] = 1
                if order.m_nBusinessNum < order.m_nOrderNum and order.m_nErrorId == 0 and not order.m_bIsComplement then
                    undealed[iUndealed] = order
                    iUndealed = iUndealed + 1

                    if string.len(order.m_strErrorMsg) > 0 then
                        ret = order.m_strErrorMsg
                    end
                end
            else -- 尚未结束的委托
                id = i
            end

            if order.m_nErrorId ~= 0 then -- 对于有错误的委托，判断是否为致命错误
                local pid = order.m_accountInfo.m_nPlatformID
                if g_trade_fatal_errors[pid] ~= nil and g_trade_fatal_errors[pid][order.m_nErrorId] ~= nil then
                    return false, order.m_strErrorMsg, undealed
                end
            end
        end
    end

    if id > g_not_final_state_order_start_id then
        g_not_final_state_order_start_id = id
    end

    return true, ret, undealed
end

-- 已完成的委托量
function getOrderedNum(orders, param)
    local ret = 0
    for i = 0, orders:size() - 1, 1 do
        local o = orders:at(i)
        if isGreater(o.m_dCompleteTime, 0) then
            if param.m_eUndealtEntrustRule ~= PRTP_INVALID and o.m_nErrorId == 0 and not o.m_bIsComplement then
                ret = ret + o.m_nOrderNum
            else
                ret = ret + o.m_nBusinessNum
            end
        else
            ret = ret + o.m_nOrderNum
        end
    end
    return ret
end

-- 已完成的委托量
function getOrderedNum2(orders, param)
    local ret = 0
    for k, o in pairs(orders) do
        if isGreater(o.m_dCompleteTime, 0) then
            if param.m_eUndealtEntrustRule ~= PRTP_INVALID and o.m_nErrorId == 0 and not o.m_bIsComplement then
                ret = ret + o.m_nOrderNum
            else
                ret = ret + o.m_nBusinessNum
            end
        else
            ret = ret + o.m_nOrderNum
        end
    end
    return ret
end

-- 已报出的委托次数
function getOrderedTime(orders)
    local ret = 0
    for i = 0, orders:size() - 1, 1 do
        local o = orders:at(i)
        if g_xt_not_sent_order_errors[o.m_nErrorId] == nil then
            ret = ret + 1
        end
    end
    return ret
end

-- 已报出的委托次数
function getOrderedTime2(orders)
    local ret = 0
    for k, o in pairs(orders) do
        if g_xt_not_sent_order_errors[o.m_nErrorId] == nil then
            ret = ret + 1
        end
    end
    return ret
end

-- 撤单次数
function getCancelTimes(orders)
    local ret = 0
    for i = 0, orders:size() - 1, 1 do
        local o = orders:at(i)
        ret = ret + o.m_nCancelTimes
    end
    return ret
end

function getCancelTimes2(orders)
    local ret = 0
    for k, o in pairs(orders) do
        ret = ret + o.m_nCancelTimes
    end
    return ret
end

-- 成交量
function getBusinessNum(orders)
    local ret = 0
    for i = 0, orders:size() - 1, 1 do
        local o = orders:at(i)
        ret = ret + o.m_nBusinessNum
    end
    return ret
end

-- 成交量
function getBusinessNum2(orders)
    local ret = 0
    for k, o in pairs(orders) do
        ret = ret + o.m_nBusinessNum
    end
    return ret
end

-- 是否是股票
function isStock(market)
    if market == "SH" or market == "SZ" then return true else return false end
end

-- 取资金
function getMoney(accountData, key, tag)
    local money = 0.0    
    if accountData ~= CAccountData_NULL then
        local accountDetail = accountData:getData(XT_CAccountDetail, key)
        if accountDetail ~= CAccountDetail_NULL then
            money = accountDetail:getDouble(tag)
            printLogLevel(2, string.format("[getMoney] account = %s, tag = %d, money = %d", key, tag, money))
        else
            printLogLevel(2, string.format("[getMoney] account = %s, tag = %d, money = %d, NULL accountDetail", key, tag, money))
        end
    else
        printLogLevel(2, string.format("[getMoney] account = %s, tag = %d, money = %d, NULL accountData", key, tag, money))
    end
    if isInvalidDouble(money) then money = 0.0 end
    return money
end

-- 取持仓
function getPosition(accountData, market, stock, hedgeFlag, direction, todayTag)
    local weight = 0
    local datas = accountData:getVector(XT_CPositionDetail)
    for i = 0, datas:size() - 1, 1 do
        local v = datas:at(i)
        if v:getString(CPositionDetail_m_strExchangeID) == market
            and v:getString(CPositionDetail_m_strInstrumentID) == stock
            and v:getInt(CPositionDetail_m_nDirection) == direction
        then
            if todayTag == nil or v:getBool(CPositionDetail_m_bIsToday) == todayTag then
                local t = v:getInt(CPositionDetail_m_nVolume)
                if not isInvalidInt(t) then weight = weight + t end
            end
        end -- if
    end -- for i
    return weight
end

-- 取市值
function getMarketValue(accountData, market, stock, hedgeFlag, direction, todayTag)
    local value = 0.0
    local datas = accountData:getVector(XT_CPositionDetail)
    for i = 0, datas:size() - 1, 1 do
        local v = datas:at(i)
        if v:getString(CPositionDetail_m_strExchangeID) == market
            and v:getString(CPositionDetail_m_strInstrumentID) == stock
            and v:getInt(CPositionDetail_m_nDirection) == direction
        then
            if todayTag == nil or v:getBool(CPositionDetail_m_bIsToday) == todayTag then
                local t = v:getDouble(CPositionDetail_m_dMarketValue)
                if not isInvalidDouble(t) then value = value + t end
            end
        end
    end -- for i
    return value
end

-- 按照操作类型取资金或者持仓()
function getMoneyOrPosition(account, market, stock, operationType, hedgeFlag)
    local ret = getInvalidDouble()
    local isMoney = false
    local key = account:getKey()
    local dataCenter = g_traderCenter:getDataCenter()
    local accountData = dataCenter:getAccount(key)
    if accountData ~= CAccountData_NULL then
        local accountDetail = accountData:getData(XT_CAccountDetail, key)
        if accountDetail ~= CAccountDetail_NULL then
            if OPT_OPEN_LONG == operationType then
                ret = getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_CLOSE_LONG_HISTORY == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, false)
            elseif OPT_CLOSE_LONG_TODAY == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, true)
            elseif OPT_OPEN_SHORT == operationType then
                ret = getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_CLOSE_SHORT_HISTORY == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, false)
            elseif OPT_CLOSE_SHORT_TODAY == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, true)
            elseif OPT_CLOSE_LONG_TODAY_FIRST == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil)
            elseif OPT_CLOSE_LONG_HISTORY_FIRST == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil)
            elseif OPT_CLOSE_SHORT_TODAY_FIRST == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil)
            elseif OPT_CLOSE_SHORT_HISTORY_FIRST == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil)
            elseif OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT == operationType then
                ret = getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT == operationType then
                ret = getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG == operationType then
                ret = getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG == operationType then
                ret = getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_CLOSE_LONG == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil)
            elseif OPT_CLOSE_SHORT == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil)
            elseif OPT_BUY == operationType then
                ret = getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_SELL == operationType then
                if isStockMarket(market) and isGovernmentLoanRepurchase(stock) then
                    ret = getMoney(accountData, key, CAccountDetail_m_dAvailable)
                    isMoney = true
                else
                    ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil)
                end
            elseif OPT_FIN_BUY == operationType or OPT_FIN_BUY_SPECIAL == operationType then
                ret = getMoney(accountData, key, CCreditAccountDetail_m_dEnableBailBalance)
                isMoney = true
            elseif OPT_SLO_SELL == operationType or OPT_SLO_SELL_SPECIAL == operationType then
                ret = getMoney(accountData, key, CCreditAccountDetail_m_dEnableBailBalance)
                isMoney = true
            elseif OPT_BUY_SECU_REPAY == operationType or OPT_BUY_SECU_REPAY_SPECIAL == operationType then
                ret = getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            elseif OPT_DIRECT_SECU_REPAY == operationType or OPT_DIRECT_SECU_REPAY_SPECIAL == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil)
            elseif OPT_SELL_CASH_REPAY == operationType or OPT_SELL_CASH_REPAY_SPECIAL == operationType then
                ret = getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil)
            elseif OPT_DIRECT_CASH_REPAY == operationType or OPT_DIRECT_CASH_REPAY_SPECIAL == operationType or OPT_INTEREST_FEE == operationType then
                ret = getMoney(accountData, key, CAccountDetail_m_dAvailable)
                isMoney = true
            end

            if ret == nil then ret = getInvalidDouble() end
            --local funcMap = {
                -- 开多
            --    [OPT_OPEN_LONG] = {getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
                -- 平昨多
            --    [OPT_CLOSE_LONG_HISTORY] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, false), false},
                -- 平今多
            --    [OPT_CLOSE_LONG_TODAY]  = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, true), false},
                -- 开空
            --    [OPT_OPEN_SHORT] = {getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
                -- 平昨空
            --    [OPT_CLOSE_SHORT_HISTORY] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, false), false},
            --    [OPT_CLOSE_SHORT_TODAY] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, true), false},
            --    [OPT_CLOSE_LONG_TODAY_FIRST] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil), false},
            --    [OPT_CLOSE_LONG_HISTORY_FIRST] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil), false},
            --    [OPT_CLOSE_SHORT_TODAY_FIRST] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil), false},
            --    [OPT_CLOSE_SHORT_HISTORY_FIRST] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil), false},
            --    [OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT] = {getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
            --    [OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT] = {getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
            --    [OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG] = {getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
            --    [OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG] = {getMarketValue(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil) + getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
            --    [OPT_CLOSE_LONG] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil), false},
            --    [OPT_CLOSE_SHORT] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_SELL, nil), false},
                --[OPT_OPEN|买入,开仓,买入; //开仓
                --[OPT_CLOSE|卖出,平仓,卖出; //平仓 期货操作的最后1个，请保持此OPT在期货操作的第1个，否则客户端判断操作是期货还是股票的代码会有问题
                -- 股票买入
            --    [OPT_BUY] = {getMoney(accountData, key, CAccountDetail_m_dAvailable), true},
                -- 股票卖出,这里有问题,需要返回的是可卖量，而不是总量
            --    [OPT_SELL] = {getPosition(accountData, market, stock, hedgeFlag, DIRECTION_FLAG_BUY, nil), false},
            --}
            --local t = funcMap[operationType]
            --if t ~= nil then
            --    ret = t[1]
            --    isMoney = t[2]
            --end
        end -- accountDetail is valid
    end -- accountData is valid
    return ret, isMoney
end

-- 是否支持市价单, 返回包括下单类型
function isSupportMarketPrice(market, stock)
    --printLog(market..stock)
    local ret = false
    -- 中金所仅近月合约支持市价单, 上期所不支持, 大商所支持, 郑商所支持
    if market == "DCE" then ret = true printLog("market is DCE, support market price.")
    elseif market == "CZCE" then ret = true printLog("market is CZCE, support market price.")
    elseif market == "SHFE" then ret = false printLog("market is SHFE, NOT support market price.")
    elseif market == "CFFEX" then
        --printLog("market is CFFEX ... see if nearest instrument.")
        -- 判断是否是近月合约
        local dataCenter = g_traderCenter:getDataCenter()
        local instrument = dataCenter:getInstrument(market, stock)
        if instrument ~= CInstrumentDetail_NULL then
            ret = instrument.IsRecent
        end
        --if ret then printLog("is nearest instrument, support market price") else printLog("is NOT nearest instrument, NOT support market price") end
    end
    return ret
end

-- 取市价单价格类型
function getMarketPriceType(market)
    local ret = BROKER_PRICE_LIMIT
    -- 中金所仅近月合约支持市价单, 上期所不支持, 大商所支持, 郑商所支持
    if market == "CZCE" then ret = BROKER_PRICE_ANY
    elseif market == "DCE" then ret = BROKER_PRICE_ANY
    elseif market == "CFFEX" then ret = BROKER_PRICE_ANY
    end
    return ret
end

-- 按精度取价格
function getPriceByPrecision(market, stock, price)
    local ret = price
    if not isInvalidDouble(price) then
        local precision = getPricePrecisionByInstrumentDetail(market, stock)
        if not isZero(precision) then ret = floor(price / precision + 0.5) * precision end
    end
    return ret
end

-- 取价格
function getRealPrice(priceType, ptrPrice, rawPrice, isBuyDirection, singleFloat)

    local price = getInvalidDouble()    
    local basePrice = getInvalidDouble()
    if priceType == PRTP_FIX then
        basePrice = rawPrice
        price = rawPrice
        return price, basePrice
    else
        local eOptType = OPT_BUY
        if not isBuyDirection then
            eOptType = OPT_SELL
        end
        basePrice = getPrice(ptrPrice, priceType, eOptType)
    end
    price = basePrice

    -- 增加单笔超价 市价和指定价不需要超价
    if not (priceType == PRTP_MARKET or priceType == PRTP_FIX) then
        --printLog("price type is not fix or market, so about to add super price")
        if not isInvalidDouble(singleFloat) then
            if isBuyDirection then
                price = price + singleFloat
                --printLog("BUY operation, add single float " .. singleFloat .. ", new price = " .. price)
            else
                price = price - singleFloat
                --printLog("SELL operation, minus single float " .. singleFloat .. ", new price = " .. price)
            end
        end
    end
    if ptrPrice.m_strExchangeID ~= "HGT" then
        price = getPriceByPrecision(ptrPrice.m_strExchangeID, ptrPrice.m_strInstrumentID, price)
        basePrice = getPriceByPrecision(ptrPrice.m_strExchangeID, ptrPrice.m_strInstrumentID, basePrice)
    end
    --printLog("after precision fix, new price = " .. price)
    return price, basePrice
end

-- 判断看多还是看空
function getDirectionByOperation(nOperation)
    return (nOperation == OPT_OPEN_LONG)
        or (nOperation == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG)
        or (nOperation == OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG)
        or (nOperation == OPT_CLOSE_SHORT_TODAY)
        or (nOperation == OPT_CLOSE_SHORT_HISTORY)
        or (nOperation == OPT_CLOSE_SHORT_TODAY_FIRST)
        or (nOperation == OPT_CLOSE_SHORT_HISTORY_FIRST)
        or (nOperation == OPT_BUY)
        or (nOperation == OPT_FIN_BUY)
        or (nOperation == OPT_FIN_BUY_REPAY)
        or (nOperation == OPT_BUY_SECU_REPAY)
        or (nOperation == OPT_BUY_SECU_REPAY_SPECIAL)
        or (nOperation == OPT_FUND_SUBSCRIBE)
        or (nOperation == OPT_FUND_MERGE)
        or (nOperation == OPT_OPTION_BUY_OPEN)
        or (nOperation == OPT_OPTION_BUY_CLOSE)
        or (nOperation == OPT_OPTION_COVERED_CLOSE)
        or (nOperation == OPT_OPTION_CALL_EXERCISE)
        or (nOperation == OPT_N3B_PRICE_BUY)
        or (nOperation == OPT_N3B_LIMIT_PRICE_BUY)
        or (nOperation == OPT_N3B_CONFIRM_BUY)
        or (nOperation == OPT_N3B_REPORT_CONFIRM_BUY)
        or (nOperation == OPT_COLLATERAL_TRANSFER_IN)
        or (nOperation == OPT_ETF_PURCHASE)
end

-- 是否在有效时间
function isValidTime(timeStart, timeEnd)
    local ret = true
    local nowTime = now()
    if not isInvalidInt(timeStart) then
        ret = nowTime >= timeStart
    end
    if not isInvalidInt(timeEnd) then
        ret = nowTime <= timeEnd
    end
    return ret
end

function getTagItemVolume(priceInfo, isBuy, num)
    local ret = 0
    local strTag = isBuy and "m_nBidVolume" or "m_nAskVolume"
    --strTag = strTag .. num
    strTag = string.format("%s%d", strTag, num)
    ret = priceInfo[strTag]
    if isInvalidInt(ret) then
        ret = 0
    else
        if isStock(priceInfo.m_strExchangeID) then ret = ret * 100 end
    end
    return ret
end

function getTagVolume(priceInfo, isBuy, num)
    local ret = 0
    for i = 1, num, 1 do
        ret = ret + getTagItemVolume(priceInfo, isBuy, i)
    end
    return ret
end

function getPositionNum(param)
    local t, isMoney = getMoneyOrPosition(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_eOperationType, param.m_nHedgeFlag)
    if not isMoney then return t else 
        if param.m_eOperation == OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT or OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT then
            local key = param.m_account:getKey()
            local dataCenter = g_traderCenter:getDataCenter()
            local accountData = dataCenter:getAccount(key)
            if accountData ~= CAccountData_NULL then 
                return getPosition(accountData, param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_nHedgeFlag, DIRECTION_FLAG_BUY, nil)
            end
        elseif param.m_eOperation == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG or OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG then
            local key = param.m_account:getKey()
            local dataCenter = g_traderCenter:getDataCenter()
            local accountData = dataCenter:getAccount(key)
            if accountData ~= CAccountData_NULL then 
                return getPosition(accountData, param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_nHedgeFlag, DIRECTION_FLAG_SELL, nil)
            end
        end
        return getInvalidInt()
    end
end

function getOrderNum(param, priceInfo, volumeLeft, price)
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    local nDirection = nil
    local nOffsetFlag = nil
    if volumeLeft <= 0 then
        return nDirecton, nOffsetFlag, getInvalidInt(), msgTag .. " 剩余委托量为0!"
    end

    -- 根据“基准量类型”取出当时基准量的值
    local ret = getInvalidInt()
    local reason = ""
    if priceInfo ~= nil then
        if VOLUME_BUY1 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, true, 1)
        elseif VOLUME_BUY12 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, true, 2)
        elseif VOLUME_BUY123 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, true, 3)
        elseif VOLUME_BUY1234 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, true, 4)
        elseif VOLUME_BUY12345 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, true, 5)
        elseif VOLUME_SALE1 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, false, 1)
        elseif VOLUME_SALE12 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, false, 2)
        elseif VOLUME_SALE123 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, false, 3)
        elseif VOLUME_SALE1234 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, false, 4)
        elseif VOLUME_SALE12345 == param.m_eSingleVolumeType then
            ret = getTagVolume(priceInfo, false, 5)
        elseif VOLUME_FIX == param.m_eSingleVolumeType then
            ret = param.m_nNum
        elseif VOLUME_LEFT == param.m_eSingleVolumeType then
            ret = volumeLeft
        elseif VOLUME_POSITION == param.m_eSingleVolumeType then
            ret = getPositionNum(param)
        end
        --local m = {
        --    [VOLUME_BUY1] = getTagVolume(priceInfo, true, 1),
        --    [VOLUME_BUY12] = getTagVolume(priceInfo, true, 2),
        --    [VOLUME_BUY123] = getTagVolume(priceInfo, true, 3),
        --    [VOLUME_BUY1234] = getTagVolume(priceInfo, true, 4),
        --    [VOLUME_BUY12345] = getTagVolume(priceInfo, true, 5),
        --    [VOLUME_SALE1] = getTagVolume(priceInfo, false, 1),
        --    [VOLUME_SALE12] = getTagVolume(priceInfo, false, 2),
        --    [VOLUME_SALE123] = getTagVolume(priceInfo, false, 3),
        --    [VOLUME_SALE1234] = getTagVolume(priceInfo, false, 4),
        --    [VOLUME_SALE12345] = getTagVolume(priceInfo, false, 5),
        --    [VOLUME_FIX] = param.m_nNum,
        --    [VOLUME_LEFT] = volumeLeft,
        --    [VOLUME_POSITION] = (function ()
        --            local t, isMoney = getMoneyOrPosition(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_eOperationType, param.m_nHedgeFlag)
        --            if not isMoney then return t else 
        --                if param.m_eOperation == OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT or OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT then
        --                    local key = param.m_account:getKey()
        --                    local dataCenter = g_traderCenter:getDataCenter()
        --                    local accountData = dataCenter:getAccount(key)
        --                    if accountData ~= CAccountData_NULL then 
        --                        return getPosition(accountData, param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_nHedgeFlag, DIRECTION_FLAG_BUY, nil)
        --                    end
        --                elseif param.m_eOperation == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG or OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG then
        --                    local key = param.m_account:getKey()
        --                    local dataCenter = g_traderCenter:getDataCenter()
        --                    local accountData = dataCenter:getAccount(key)
        --                    if accountData ~= CAccountData_NULL then 
        --                        return getPosition(accountData, param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_nHedgeFlag, DIRECTION_FLAG_SELL, nil)
        --                    end
        --                end
        --                return getInvalidInt()
        --            end
        --        end
        --    )()
        --}
        --ret = m[param.m_eSingleVolumeType]
    end

    if ret == nil or isInvalidInt(ret) then
        return nDirecton, nOffsetFlag, getInvalidInt(), msgTag .. " 单笔委托数量非法!"
    end

    if not isInvalidDouble(param.m_dSingleVolumeRate) then
        ret = intpart(ret * param.m_dSingleVolumeRate + 0.5)
    end

    -- 四舍五入取整并且不能小于最小报价单位
    local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
    ret = max(nMin, intpart(ret * 1.0/ nMin + 0.5) * nMin)

    -- 不能小于尾单最小量
    if param.m_eSingleVolumeType == VOLUME_LEFT and not isInvalidInt(param.m_nLastVolumeMin) and ret < param.m_nLastVolumeMin then
        ret = param.m_nLastVolumeMin
    end

    -- 不能超过单笔最大量
    if not isInvalidInt(param.m_nSingleNumMax) and ret > param.m_nSingleNumMax then
        ret = param.m_nSingleNumMax
    end
    
    -- 不能小于单笔最小量
    if not isInvalidInt(param.m_nSingleNumMin) and ret < param.m_nSingleNumMin then
        ret = param.m_nSingleNumMin
    end

    -- 不能大于任务剩余量
    ret = min(ret, volumeLeft)

    -- 不能大于账号可下单量
    local ops, msg = getOperations(param, price)
    if #ops == 0 then
        return nDirection, nOffsetFlag, getInvalidInt(), msg
    end
    nDirection = ops[1][1]
    nOffsetFlag = ops[1][2]
    ret = min(ops[1][3], ret)

    -- 考虑最小报价单位
    if ret > nMin then
        -- 如果大于最小报价单位，按“不大于ret的最大的nMin的整数倍”去报
        -- 否则如果小于最小报价单位，照报无误，等系统自动打回终止任务
        ret = intpart(ret / nMin) * nMin
    end

    return nDirection, nOffsetFlag, ret, msgTag
end

function isInRegion(dValue, dStart, dEnd)
    if not isInvalidDouble(dStart) and isLess(dValue, dStart) then return false end
    if not isInvalidDouble(dEnd) and isGreater(dValue, dEnd) then return false end
    return true
end

function getOffsetFlagByOperation(eOperationType)
    if OPT_OPEN_LONG == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_OPEN_SHORT == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_BUY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_SELL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_CLOSE_LONG_HISTORY == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_CLOSE_LONG_TODAY == eOperationType then
        return EOFF_THOST_FTDC_OF_CloseToday
    elseif OPT_CLOSE_SHORT_HISTORY == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_CLOSE_SHORT_TODAY == eOperationType then
        return EOFF_THOST_FTDC_OF_CloseToday
    
    elseif OPT_FIN_BUY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_FIN_BUY_SPECIAL == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_SLO_SELL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_BUY_SECU_REPAY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
	elseif OPT_BUY_SECU_REPAY_SPECIAL == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
	elseif OPT_SLO_SELL_SPECIAL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
	elseif OPT_DIRECT_SECU_REPAY_SPECIAL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_DIRECT_SECU_REPAY == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_SELL_CASH_REPAY == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_SELL_CASH_REPAY_SPECIAL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_DIRECT_CASH_REPAY == eOperationType or OPT_INTEREST_FEE == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_DIRECT_CASH_REPAY_SPECIAL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
		
    elseif OPT_FUND_SUBSCRIBE == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_FUND_REDEMPTION == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_FUND_MERGE == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_FUND_SPLIT == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_PLEDGE_IN == eOperationType then
        return EOFF_THOST_FTDC_OF_PLEDGE_IN
    elseif OPT_PLEDGE_OUT == eOperationType then
        return EOFF_THOST_FTDC_OF_PLEDGE_OUT
    elseif OPT_OPTION_BUY_OPEN == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_OPTION_BUY_CLOSE == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_OPTION_SELL_OPEN == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_OPTION_SELL_CLOSE == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_OPTION_COVERED_CLOSE == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_OPTION_COVERED_OPEN == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_OPTION_CALL_EXERCISE == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_OPTION_PUT_EXERCISE == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_N3B_PRICE_BUY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_N3B_PRICE_SELL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_N3B_LIMIT_PRICE_BUY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_N3B_LIMIT_PRICE_SELL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_N3B_CONFIRM_BUY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_N3B_CONFIRM_SELL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_N3B_REPORT_CONFIRM_BUY == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_N3B_REPORT_CONFIRM_SELL == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_COLLATERAL_TRANSFER_IN == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_COLLATERAL_TRANSFER_OUT == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_CONVERT_BONDS == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_SELL_BACK_BONDS == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    elseif OPT_ETF_PURCHASE == eOperationType then
        return EOFF_THOST_FTDC_OF_Open
    elseif OPT_ETF_REDEMPTION == eOperationType then
        return EOFF_THOST_FTDC_OF_Close
    else
        return EOFF_THOST_FTDC_OF_INVALID
    end
end

-- 取简单的操作, 如开多, 平今多, 六键式的
function getSimpleOperation(accountData, strExchangeId, strInstrumentId, eOperationType, nHedgeFlag, price, num, msgTag)
    local simpMsg = string.format("[getSimpleOperation : market = %s, code = %s, optType = %d, hedgeFlag = %d, price = %f, num = %d]", strExchangeId, strInstrumentId, eOperationType, nHedgeFlag, price, num)
    local ret = {}

    local nDirection = getDirectionByOperation(eOperationType) and DIRECTION_FLAG_BUY or DIRECTION_FLAG_SELL
    local nOffsetFlag = getOffsetFlagByOperation(eOperationType)
    local canOrder = accountData:getCanOrderVolume(strExchangeId, strInstrumentId, eOperationType, nHedgeFlag, price)

    if isInvalidDouble(canOrder) then
        --return ret, "账号" .. operationToString(eOperationType) .. strInstrumentId .. ", 可下单量为非法值!"
        local msg = string.format("%s [可下单量为非法值!]", msgTag)
        printLogLevel(2, string.format("%s %s [1] %s", task:logTag(), msg, simpMsg))
        return ret, msg
    end

    if canOrder <= 0 then
        --return ret, "账号" .. operationToString(eOperationType) .. strInstrumentId .. ", 可下单量为" .. canOrder .. "!"
        local msg = string.format("%s [可下单量为%d!]", msgTag, canOrder)
        printLogLevel(2, string.format("%s %s [2] %s", task:logTag(), msg, simpMsg))
        return ret, msg
    end

    canOrder = min(canOrder, num)
    if canOrder <= 0 then
        --return ret, "账号" .. operationToString(eOperationType) .. strInstrumentId .. ", 调整后的可下单量为" .. canOrder .. "!"
        local msg = string.format("%s [调整后的可下单量为%d!]", msgTag, canOrder)
        printLogLevel(2, string.format("%s %s [3] %s", task:logTag(), msg, simpMsg))
        return ret, msg
    end

    local msg = msgTag .. " [可下单量为"
    while canOrder > 0 do
        local singleOp = accountData:getSingleOpVolume(strExchangeId, strInstrumentId, eOperationType, nHedgeFlag, price, canOrder)
        msg = msg .. tostring(singleOp) .. "+"
        if isInvalidDouble(singleOp) or singleOp <= 0 then 
            break
        else
            canOrder = canOrder - singleOp
        end
        table.insert(ret, {nDirection, nOffsetFlag, singleOp})
    end
    msg = msg .. "]"

    printLogLevel(2, string.format("%s %s [0] %s", task:logTag(), msg, simpMsg))
    return ret, ""
end

function getOperations(param, price)
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    local ret = {}
    local retMsg = ""

    if CAccountInfo_NULL == param.m_account then
        return ret, msgTag .. " 参数账号为空！"
    end
    
    -- 取accountData
    local key = param.m_account:getKey()
    local dataCenter = g_traderCenter:getDataCenter()
    local accountData = dataCenter:getAccount(key) 
    if accountData == CAccountData_NULL then
        local msg = string.format("%s 账号未登录或未初始化!", msgTag)
        return ret, msg
    end
    
    local strExchangeId = param.m_stock.m_strMarket
    local strInstrumentId = param.m_stock.m_strCode
    local eOperationType = param.m_eOperationType
    local nHedgeFlag = param.m_nHedgeFlag
    local price = price
    local num = param.m_nNum
    
    local ops = {}
    if eOperationType == OPT_CLOSE_LONG_TODAY_FIRST then
        ops = {OPT_CLOSE_LONG_TODAY, OPT_CLOSE_LONG_HISTORY}
    elseif eOperationType == OPT_CLOSE_SHORT_TODAY_FIRST then
        ops = {OPT_CLOSE_SHORT_TODAY, OPT_CLOSE_SHORT_HISTORY}
    elseif eOperationType == OPT_CLOSE_LONG_HISTORY_FIRST then
        ops = {OPT_CLOSE_LONG_HISTORY, OPT_CLOSE_LONG_TODAY}
    elseif eOperationType == OPT_CLOSE_SHORT_HISTORY_FIRST then
        ops = {OPT_CLOSE_SHORT_HISTORY, OPT_CLOSE_SHORT_TODAY}
    elseif eOperationType == OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT then
        ops = {OPT_CLOSE_LONG_TODAY, OPT_CLOSE_LONG_HISTORY, OPT_OPEN_SHORT}
    elseif eOperationType == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG then
        ops = {OPT_CLOSE_SHORT_TODAY, OPT_CLOSE_SHORT_HISTORY, OPT_OPEN_LONG}
    elseif eOperationType == OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT then
        ops = {OPT_CLOSE_LONG_HISTORY, OPT_CLOSE_LONG_TODAY, OPT_OPEN_SHORT}
    elseif eOperationType == OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG then
        ops = {OPT_CLOSE_SHORT_HISTORY, OPT_CLOSE_SHORT_TODAY, OPT_OPEN_LONG}
    else
        ops = { eOperationType }
    end

    if ops ~= nil then
        for _, v in ipairs(ops) do
            --printLog("OneOps = " .. v)
            local oneOps, msg = getSimpleOperation(accountData, strExchangeId, strInstrumentId, v, nHedgeFlag, price, num, msgTag)
            if string.len(msg) > 0 then
                --retMsg = retMsg .. msg
                retMsg = string.format("%s%s", retMsg, msg)
            end
            for _, oneOp in ipairs(oneOps) do
                --printLog("Simple operation of oneOps , oneOp[3] = " .. oneOp[3])
                if oneOp[3] > 0 then
                    num = num - oneOp[3]
                    table.insert(ret, oneOp)
                end
            end
        end
    end

    return ret, retMsg
end

function getEntrustType(brokerType, eOperationType)
    if AT_CREDIT == brokerType then
        if OPT_FIN_BUY == eOperationType or OPT_SELL_CASH_REPAY == eOperationType or OPT_DIRECT_CASH_REPAY == eOperationType or OPT_INTEREST_FEE == eOperationType or
            OPT_FIN_BUY_SPECIAL == eOperationType or OPT_SELL_CASH_REPAY_SPECIAL == eOperationType or OPT_DIRECT_CASH_REPAY_SPECIAL == eOperationType then
            return ENTRUST_FIN
        elseif OPT_SLO_SELL == eOperationType or OPT_BUY_SECU_REPAY == eOperationType or OPT_DIRECT_SECU_REPAY == eOperationType or OPT_SLO_SELL_SPECIAL == eOperationType or OPT_BUY_SECU_REPAY_SPECIAL == eOperationType or OPT_DIRECT_SECU_REPAY_SPECIAL == eOperationType then
            return ENTRUST_SLO
        else
            return ENTRUST_CREDIT_NORMAL
        end
    elseif AT_STOCK_OPTION == brokerType then
        if OPT_OPTION_CALL_EXERCISE == eOperationType or OPT_OPTION_PUT_EXERCISE == eOperationType then
            return ENTRUST_TYPE_OPTION_EXERCISE
        elseif OPT_OPTION_SECU_LOCK == eOperationType then
            return ENTRUST_TYPE_OPTION_SECU_LOCK
        elseif OPT_OPTION_SECU_UNLOCK == eOperationType then
            return ENTRUST_TYPE_OPTION_SECU_UNLOCK
        else
            return ENTRUST_BUY_SELL
        end
    else
        return ENTRUST_BUY_SELL
    end
end

local function logAndDealWithPriceTime(param, priceData, orderInfo, msg, msgTag)
    local retMsg = msg
    local accountId = accountDisplayId(orderInfo.m_accountInfo)
    local localInfo = ""
    if nil ~= orderInfo.m_xtTag and "string" == type(orderInfo.m_xtTag.m_strLocalInfo) then
        localInfo = orderInfo.m_xtTag.m_strLocalInfo
    end
    
    if priceData == nil or orderInfo == nil then
        printLogLevel(2, string.format("[logAndDealWithPriceTime] %s %s [order_async] : %f, %d, %s.", task:logTag(), msgTag, orderInfo.m_dPrice, orderInfo.m_nOrderNum, localInfo))
        return retMsg
    end
    
    if isPriceTypeShouldHintDelay(param.m_ePriceType) then
        local nUpdateTime = timeStringToInt(priceData.m_strUpdateTime)
        if nUpdateTime > 0 then
            local t = now()
            local delta = getAccountExchangeTimeDelta(param.m_account, param.m_stock.m_strMarket)
            local nExchangeSecond = t + delta
            local nExchangeDate = d8_secondToDate(nExchangeSecond)
            local nExchangeTime = d8_secondToTime(nExchangeSecond)
            local nUpdateSecond = d8_datetimeToSecond(nExchangeDate, nUpdateTime)
            local nDelay = 0
            if nUpdateSecond - nExchangeSecond > 43200 then
                -- zhangyi:
                -- 只考虑交易所时间大于行情更新时间
                -- 因此如果nUpdateSecond大于nExchangeSecond，原则上认为是正好跨日导致的：
                -- 即nExchangeDate刚过0点，而行情更新时间还未过0点，
                -- 按上述算法算出来的nUpdateSecond会比实际行情更新时间多一整天，需要减去这一整天
                --
                -- 但是要同时注意一种可能，即我们没取到交易所时间，这时候delta=0，
                -- 此时取到的“交易所时间”实际只是资管服务器时间
                -- 这时候如果服务器时间慢半拍，是可能nUpdateSecond > nExchangeSecond的，但是只差半拍而已
                -- 因此，用这么一个中庸的办法来判断
                nUpdateSecond = nUpdateSecond - 86400
                nDelay = nExchangeSecond - nUpdateSecond
                printLogLevel(2, string.format("[logAndDealWithPriceTime] %s %s [order_async] : %f, %d, %s. delay = %d : exchange second = %d (date_%d, time_%d + %d), price update second = %d (date_%d, time_%d - 86400).",
                    task:logTag(), msgTag, orderInfo.m_dPrice, orderInfo.m_nOrderNum, localInfo, nDelay,
                    nExchangeSecond, nExchangeDate, nExchangeTime, delta, nUpdateSecond, nExchangeDate, nUpdateTime))
            else
                nDelay = nExchangeSecond - nUpdateSecond
                printLogLevel(2, string.format("[logAndDealWithPriceTime] %s %s [order_async] : %f, %d, %s. delay = %d : exchange second = %d (date_%d, time_%d + %d), price update second = %d (date_%d, time_%d).",
                    task:logTag(), msgTag, orderInfo.m_dPrice, orderInfo.m_nOrderNum, localInfo, nDelay,
                    nExchangeSecond, nExchangeDate, nExchangeTime, delta, nUpdateSecond, nExchangeDate, nUpdateTime))
            end
            if nDelay > 30 then
                retMsg = retMsg .. " 但报价所用行情已" .. tostring(nDelay) .. "秒未更新!"
            end
        else
            printLogLevel(2, string.format("[logAndDealWithPriceTime] %s %s [order_async] : %f, %d, %s. price update = %s.", task:logTag(), msgTag, orderInfo.m_dPrice, orderInfo.m_nOrderNum, localInfo, priceData.m_strUpdateTime))
        end
    else
        printLogLevel(2, string.format("[logAndDealWithPriceTime] %s %s [order_async] : %f, %d, %s.", task:logTag(), msgTag, orderInfo.m_dPrice, orderInfo.m_nOrderNum, localInfo))
    end
    return retMsg
end

local function fixPriceForAlgorithmTrade(price, basePrice, priceData, param, orders, isBuy, isUseExchangeMarketPrice)
    -- 判断是否使用超价
    if not isInvalidInt(param.m_nSuperPriceStart) and getOrderedTime2(orders) < param.m_nSuperPriceStart - 1 then
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
    if  priceData ~= nil then
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
            if isSupportMarketPrice(priceData.m_strExchangeID, priceData.m_strInstrumentID) and isUseExchangeMarketPrice then
                --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " support market price, set price to 0.")
                price = 0.0
            else
                --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " DOES NOT support market price, set price to " .. (isBuy and "upper bound" or "lower bound"))
                price = (isBuy and priceData.m_dUpperLimitPrice or priceData.m_dLowerLimitPrice)
                if isInvalidDouble(price) then
                    local dataCenter = g_traderCenter:getDataCenter()
                    local instrument = dataCenter:getInstrument(param.m_stock.m_strMarket, param.m_stock.m_strCode)
                    if instrument ~= CInstrumentDetail_NULL then
                         price = (isBuy and instrument.UpStopPrice or instrument.DownStopPrice)
                    end
                end
            end
        end
    end

    return price
end

local function genUndealtparam(param, orderInfo)
    local tempParam = CCodeOrderParam()
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
    tempParam.m_nNum = orderInfo.m_nOrderNum - orderInfo.m_nBusinessNum
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
    tempParam.m_eUndealtEntrustRule = param.m_eUndealtEntrustRule
    tempParam.m_strDealId = param.m_strDealId
    return tempParam
end

function shouldCancelOrder(order, param, orders, priceData)
    -- 老板要求，再次调整：都按撤了报是否能更优处理    
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)

    local orderCount = getOrderedTime2(orders)
    if (not isInvalidInt(param.m_nMaxOrderCount)) and orderCount >= param.m_nMaxOrderCount then
        printLogLevel(2, string.format("[shouldCancelOrder] %s %s [%s] order_count = %d, max_order_count = %d, reached, false", task:logTag(), msgTag, order:getKey(), orderCount, param.m_nMaxOrderCount))
        return false
    end
    
    if isCheckExchange() then
        local tradeStatus = getAccountMarketTradeStatus(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
        if (MARKET_TRADE_STATUS_FLAG_CANCEL ~= tradeStatus) and (MARKET_TRADE_STATUS_FLAG_TRADE ~= tradeStatus) then
            printLogLevel(2, string.format("[shouldCancelOrder] %s %s [%s] trade_status = %d, can not cancel, false", task:logTag(), msgTag, order:getKey(), tradeStatus))
            return false
        end
    end

    -- local orderedNum = getOrderedNum2(orders, param)
    -- if orderedNum >= param.m_nNum then
    if true then
        -- 已经报完委托量，撤单原则：撤委托重下价格有利于成交
        local tParam = param
        local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
        if PRTP_INVALID ~= param.m_eUndealtEntrustRule and OTP_ALGORITHM == param.m_eOrderType and order.m_nOrderNum - order.m_nBusinessNum >= nMin then
            tParam = genUndealtparam(param, order)
        end
        local isBuy = getDirectionByOperation(tParam.m_eOperationType)
        local price, basePrice = getRealPrice(tParam.m_ePriceType, priceData, tParam.m_dFixPrice, isBuy, tParam.m_dSuperPrice)
        price = fixPriceForAlgorithmTrade(price, basePrice, priceData, tParam, orders, isBuy, false)
        if not isInvalidDouble(price) then
            if (isBuy and isGreater(price, order.m_dPrice)) or ((not isBuy) and isLess(price, order.m_dPrice)) then
                printLogLevel(2, string.format("[shouldCancelOrder] %s %s [%s] finished : order_price = %.4f, new_price = %.4f, isBuy = %s, true", task:logTag(), msgTag, order:getKey(), order.m_dPrice, price, tostring(isBuy)))
                return true
            else
                printLogLevel(2, string.format("[shouldCancelOrder] %s %s [%s] finished : order_price = %.4f, new_price = %.4f, isBuy = %s, false", task:logTag(), msgTag, order:getKey(), order.m_dPrice, price, tostring(isBuy)))
            end
        else
            printLogLevel(2, string.format("[shouldCancelOrder] %s %s [%s] finished : order_price = %.4f, new_price = invalid, false", task:logTag(), msgTag, order:getKey(), order.m_dPrice))
        end
    -- else
        -- local isBuy = getDirectionByOperation(param.m_eOperationType)
        -- local price = getPrice(priceData, PRTP_HANG, param.m_eOperationType)
        -- if isInvalidDouble(price)
            -- or (isBuy and isLess(order.m_dPrice, price))
            -- or ((not isBuy) and isGreater(order.m_dPrice, price)) then
            -- printLogLevel(2, string.format("%s %s not finished : order_price = %.4f, hang_price = %.4f, isBuy = %s, true", task:logTag(), msgTag, order.m_dPrice, price, tostring(isBuy)))
            -- return true
        -- else
            -- printLogLevel(2, string.format("%s %s not finished : order_price = %.4f, hang_price = %.4f, isBuy = %s, false", task:logTag(), msgTag, order.m_dPrice, price, tostring(isBuy)))
        -- end
    end
    return false
end

-- 单次报单
function ordinaryTrade(param, priceData, callback)

    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    local orders = {}

    if priceData == nil and param.m_ePriceType ~= PRTP_FIX then
        local msg = string.format("%s 当前价格无效!", msgTag)
        printLogLevel(2, string.format("[ordinaryTrade] %s %s", task:logTag(), msg))
        return orders, msg
    end

    local isBuy = getDirectionByOperation(param.m_eOperationType)

    local price = getInvalidDouble()
    local basePrice = getInvalidDouble()
    if param.m_ePriceType == PRTP_FIX then
        price = getPriceByPrecision(param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_dFixPrice);
        basePrice = price;
    else
        price, basePrice = getRealPrice(param.m_ePriceType, priceData, param.m_dFixPrice, isBuy, param.m_dSuperPrice)
    end

    -- 对于普通交易，指定价不需要超价
    if param.m_ePriceType == PRTP_FIX then
        price = basePrice
    end
    
    local isJudgePrice = true
    if param.m_eOperationType == OPT_COLLATERAL_TRANSFER_IN
        or param.m_eOperationType == OPT_COLLATERAL_TRANSFER_OUT
        or param.m_eOperationType == OPT_OPTION_SECU_LOCK
        or param.m_eOperationType == OPT_OPTION_SECU_UNLOCK
        or param.m_eOperationType == OPT_FUND_SUBSCRIBE
        or param.m_eOperationType == OPT_FUND_REDEMPTION
        or param.m_eOperationType == OPT_FUND_MERGE
        or param.m_eOperationType == OPT_FUND_SPLIT
        or param.m_eOperationType == OPT_ETF_PURCHASE
        or param.m_eOperationType == OPT_ETF_REDEMPTION then
        isJudgePrice = false
    end

    -- 价格是否有效
    if isInvalidDouble(price) and isJudgePrice then
        local msg = string.format("%s 当前委托价格不是有效价格!", msgTag)
        printLogLevel(2, string.format("[ordinaryTrade] %s %s", task:logTag(), msg))
        return orders, msg
    end

    -- 判断是否大于涨停价或者小于跌停价
    if param.m_ePriceType == PRTP_MARKET then
        if isSupportMarketPrice(priceData.m_strExchangeID, priceData.m_strInstrumentID) then
            --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " support market price, set price to 0.")
            price = 0.0
        else
            --printLog("current market " .. priceData.m_strExchangeID .. " code " .. priceData.m_strInstrumentID .. " DOES NOT support market price, set price to " .. (isBuy and "upper bound" or "lower bound"))
            price = (isBuy and priceData.m_dUpperLimitPrice or priceData.m_dLowerLimitPrice)
            if isInvalidDouble(price) then
                local dataCenter = g_traderCenter:getDataCenter()
                local instrument = dataCenter:getInstrument(param.m_stock.m_strMarket, param.m_stock.m_strCode)
                if instrument ~= CInstrumentDetail_NULL then
                     price = (isBuy and instrument.UpStopPrice or instrument.DownStopPrice)
                end
            end
        end
    end

    local ops, msg = getOperations(param, price)
    if #ops == 0 then
        printLogLevel(2, string.format("[ordinaryTrade] %s %s", task:logTag(), msg))
        return orders, msg
    end

    -- 下单价格类型
    local priceType = BROKER_PRICE_LIMIT
    if param.m_ePriceType == PRTP_MARKET then
        if isSupportMarketPrice(param.m_stock.m_strMarket, param.m_stock.m_strCode) then
            priceType = getMarketPriceType(param.m_stock.m_strMarket)
        end
    end

    if param.m_eOperationType == OPT_FUND_SUBSCRIBE or param.m_eOperationType == OPT_FUND_REDEMPTION then
        priceType = BROKER_PRICE_PROP_FUND_ENTRUST
    end
    
    if param.m_eOperationType == OPT_FUND_MERGE or param.m_eOperationType == OPT_FUND_SPLIT then
        priceType = BROKER_PRICE_PROP_FUND_CHAIHE
    end
    
    if param.m_eOperationType == OPT_N3B_LIMIT_PRICE_BUY or param.m_eOperationType == OPT_N3B_LIMIT_PRICE_SELL then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_MARKET_MAKE_LIMIT_PRICE
    end
    
    if param.m_eOperationType == OPT_N3B_REPORT_CONFIRM_SELL or param.m_eOperationType == OPT_N3B_REPORT_CONFIRM_BUY then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_REPORT_DEAL_CONFIRM
    end
    
    if param.m_eOperationType == OPT_N3B_CONFIRM_SELL or param.m_eOperationType == OPT_N3B_CONFIRM_BUY then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_DEAL_CONFIRM
    end
    
    if param.m_eOperationType == OPT_N3B_PRICE_BUY or param.m_eOperationType == OPT_N3B_PRICE_SELL then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_PRICE
    end

    if param.m_eOperationType == OPT_COLLATERAL_TRANSFER_IN or param.m_eOperationType == OPT_COLLATERAL_TRANSFER_OUT then
        priceType = BROKER_PRICE_PROP_COLLATERAL_TRANSFER
    end

    if param.m_eOperationType == OPT_CONVERT_BONDS then
        priceType = BROKER_PRICE_PROP_EQUITY
    end
    

    if param.m_eOperationType == OPT_SELL_BACK_BONDS then
        priceType = BROKER_PRICE_PROP_SELLBACK
    end

    if param.m_eOperationType == OPT_ETF_PURCHASE or param.m_eOperationType == OPT_ETF_REDEMPTION then
        priceType = BROKER_PRICE_PROP_ETF
    end
    
    local exchangeStatus = getAccountExchangeStatus(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
    if param.m_account.m_nBrokerType == AT_HUGANGTONG then
        if EXCHANGE_STATUS_CONTINOUS ~= exchangeStatus then
            priceType = BROKER_PRICE_BID_LIMIT
        else
            priceType = BROKER_PRICE_ENHANCED_LIMIT
        end
    end

    local msg = ""
    for _, v in ipairs(ops) do
        local orderInfo = COrderInfo()
        orderInfo.m_accountInfo = param.m_account;
        orderInfo.m_strExchangeId = param.m_stock.m_strMarket;
        orderInfo.m_strInstrumentId = param.m_stock.m_strCode;
        orderInfo.m_strProductId = param.m_stock.m_strProduct;
        orderInfo.m_eOperationType = param.m_eOperationType
        orderInfo.m_nHedgeFlag = param.m_nHedgeFlag;
        orderInfo.m_strCompactId = param.m_strCompactId
        orderInfo.m_nDirection = v[1]
        orderInfo.m_nOffsetFlag = v[2]
        orderInfo.m_nOrderNum = v[3]
        local dataCenter = g_traderCenter:getDataCenter()
        local instrument = dataCenter:getInstrument(param.m_stock.m_strMarket, param.m_stock.m_strCode)
        if param.m_account.m_nBrokerType == AT_HUGANGTONG and param.m_eOperationType == OPT_SELL and instrument ~= CInstrumentDetail_NULL and v[3] < instrument.VolumeMultiple then
            priceType = BROKER_PRICE_RETAIL_LIMIT
        end
        orderInfo.m_dPrice = price
        orderInfo.m_eBrokerPriceType = priceType
        orderInfo.m_dCancelInterval = 86400
        orderInfo.m_eEntrustType = getEntrustType(param.m_account.m_nBrokerType, param.m_eOperationType)
        orderInfo.m_strCloseDealId = param.m_strDealId
        if param.m_eOperationType == OPT_OPTION_COVERED_OPEN or param.m_eOperationType == OPT_OPTION_COVERED_CLOSE then
            orderInfo.m_eCoveredFlag = XT_COVERED_FLAG_TRUE
        else
            orderInfo.m_eCoveredFlag = XT_COVERED_FLAG_FALSE
        end
        orderInfo.m_strTargetSeat = param.m_strTargetSeat
        orderInfo.m_strTargetStockAccount = param.m_strTargetStockAccount
        orderInfo.m_nConferNo = param.m_nConferNo
        orderInfo.m_eOverFreqOrderMode = param.m_eOverFreqOrderMode

        task_helper.order_async(orderInfo, callback)

        if orderInfo.m_xtTag ~= nil then
            orders[orderInfo:getKey()] = orderInfo
            g_orders[orderInfo:getKey()] = orderInfo
            g_isOrdered = true
        end

        -- 如果行情更新不及时，报警
        if not isJudgePrice then
            msg = logAndDealWithPriceTime(param, priceData, orderInfo, string.format("%s 目标量已全部委托!", msgTag), msgTag)
        else
            msg = logAndDealWithPriceTime(param, priceData, orderInfo, string.format("%s 目标量已按价格%.4f全部委托!", msgTag, price), msgTag)
        end
    end

    return orders, msg
end

function algorithmTrade(param, orders, priceData, callback)
    local msgTag = string.format("[%s] [%s]", accountDisplayId(param.m_account), param.m_stock.m_strCode)
    if not isInvalidInt(param.m_nMaxWithdrawCount) and getCancelTimes2(orders) >= param.m_nMaxWithdrawCount then
        local msg = string.format("%s 超过最大撤单次数限制%d!", msgTag, param.m_nMaxWithdrawCount)
        printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
        return ORDER_FATAL, nil, msg
    end

    if not isInvalidInt(param.m_nMaxOrderCount) then
        local orderCount = getOrderedTime2(orders)
        if orderCount >= param.m_nMaxOrderCount then
            local msg = string.format("%s 超过最大委托次数限制%d!", msgTag, param.m_nMaxOrderCount)
            printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
            return ORDER_FATAL, nil, msg
        end
    end

    -- 不在有效时间
    local nowTime = now()
    if not isInvalidInt(param.m_nValidTimeEnd) and nowTime > param.m_nValidTimeEnd then
        local msg = msgTag .. " 当前时间" .. secondToString(nowTime) .. "超出有效时间范围[" .. secondToString(param.m_nValidTimeStart) .. "-" .. secondToString(param.m_nValidTimeEnd) .. "]!"
        printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
        return ORDER_FATAL, nil, msg
    end

    if not isInvalidInt(param.m_nValidTimeStart) and nowTime < param.m_nValidTimeStart then
        local msg = msgTag .. " 当前时间" .. secondToString(nowTime) .. "不在有效时间范围[" .. secondToString(param.m_nValidTimeStart) .. "-" .. secondToString(param.m_nValidTimeEnd) .. "]!"
        printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
        return ORDER_DELAY, nil, msg
    end

    -- 交易所状态
    if isCheckExchange() then
        local tradeStatus = getAccountMarketTradeStatus(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
        if (MARKET_TRADE_STATUS_FLAG_ORDER ~= tradeStatus) and (MARKET_TRADE_STATUS_FLAG_TRADE ~= tradeStatus) then
            local msg = msgTag .. " 交易所" .. param.m_stock.m_strMarket .. "当前状态(" .. getAccountMarketTradeStatusString(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode) .. ")不接受委托申报, 暂缓报单!"
            printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
            return ORDER_DELAY, nil, msg
        end
    end

    -- 是否全部委托已经处于完成状态
    -- 由于orders状态可能被C++程序修改
    -- 所以必须在获取委托剩余量之前判断
    local bAllComplete = true
    local oNum = 0
    for k, o in pairs(orders) do
        oNum = oNum + 1
        if isZero(o.m_dCompleteTime) then
            printLogLevel(1, string.format("[algorithmTrade] %s %s all complete = false, complete time zero order : %s", task:logTag(), msgTag, o:getKey()))
            bAllComplete = false
            break
        end
    end
    if bAllComplete then
        printLogLevel(1, string.format("[algorithmTrade] %s %s all complete = true, order num : %d", task:logTag(), msgTag, oNum))
    end

    -- 剩余委托量
    local orderedNum = getOrderedNum2(orders, param)
    local remain = param.m_nNum - orderedNum
    --printLog("total num = " .. param.m_nNum .. ", orderedNum = " .. orderedNum)
    if remain <= 0 then
        local msg = msgTag .. " 目标量" .. tostring(param.m_nNum) .. "已全部委托!"
        printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
        return ORDER_DELAY, nil, msg
    end

    -- 取价格数据
    if priceData == nil and param.m_ePriceType ~= PRTP_FIX then
        --return ORDER_DELAY, nil, param.m_stock.m_strCode .. "当前价格无效!"
        local msg = string.format("%s 当前价格无效!", msgTag)
        printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
        return ORDER_DELAY, nil, msg
    end


    local isBuy = getDirectionByOperation(param.m_eOperationType)

    -- 取下单基准价和调整价
    local price = getInvalidDouble()
    local basePrice = getInvalidDouble()
    if param.m_ePriceType == PRTP_FIX then
        price = getPriceByPrecision(param.m_stock.m_strMarket, param.m_stock.m_strCode, param.m_dFixPrice);
        basePrice = price;
    else
        price, basePrice = getRealPrice(param.m_ePriceType, priceData, param.m_dFixPrice, isBuy, param.m_dSuperPrice)                
    end

    -- 转股和回售与价格无关
    if param.m_eOperationType ~= OPT_CONVERT_BONDS and param.m_eOperationType ~= OPT_SELL_BACK_BONDS then
    -- 价格是否有效
        if isInvalidDouble(price) or isInvalidDouble(basePrice) then
            local msg = string.format("%s 当前基准价不是有效价格!", msgTag)
            printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
            return ORDER_DELAY, nil, msg
        end

        -- 非市价, 判断是否在波动区间
        if param.m_ePriceType ~= PRTP_MARKET and not isInRegion(basePrice, param.m_dPriceRangeMin, param.m_dPriceRangeMax) then
            local msg = string.format("%s 当前基准价%.4f不在波动区间(%.4f~%.4f)!", msgTag, basePrice, param.m_dPriceRangeMin, param.m_dPriceRangeMax)
            printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
            return ORDER_DELAY, nil, msg
        end

        if param.m_ePriceType ~= PRTP_FIX then
            price = fixPriceForAlgorithmTrade(price, basePrice, priceData, param, orders, isBuy, true)
        end
    end
    -- 数量
    local nDirection, nOffsetFlag, num, msg = getOrderNum(param, priceData, remain, price)
    if isInvalidInt(num) then
        printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
        return ORDER_DELAY, nil, msg
    end

    local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
    if num < nMin then
        -- 如果小于最小报价单位
        if bAllComplete then
            -- 如果之前所有的委托已经终结，那么此时是本算法交易最后一次报单
            if param.m_eOperationType ~= OPT_SELL or isZero(num) then
                -- 如果是股票的卖出，且量不为0，则继续报单
                -- 否则应该停止下单（如果股票卖出且量为0，此时nDirection和nOffsetFlag实际上未经getOrderNum赋值，还只是初值，不能下单）
                local msg = string.format("%s 可委托量为%d, 小于最小委托单位%d, 停止下单!", msgTag, num, nMin)
                printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
                return ORDER_FATAL, nil, msg
            end
        else
            -- 如果之前的委托有未终结的，那么可能下次循环算出来的下单量还能再变多，所以只是暂缓，不停止
            local msg = string.format("%s 可委托量为%d, 小于最小委托单位%d, 暂缓下单!", msgTag, num, nMin)
            printLogLevel(2, string.format("[algorithmTrade] %s %s", task:logTag(), msg))
            return ORDER_DELAY, nil, msg
        end
    end

    -- 下单价格类型
    local priceType = BROKER_PRICE_LIMIT
    if param.m_ePriceType == PRTP_MARKET then
        if isSupportMarketPrice(param.m_stock.m_strMarket, param.m_stock.m_strCode) then
            priceType = getMarketPriceType(param.m_stock.m_strMarket)
        end
    end
    
    if param.m_eOperationType == OPT_FUND_SUBSCRIBE or param.m_eOperationType == OPT_FUND_REDEMPTION then
        priceType = BROKER_PRICE_PROP_FUND_ENTRUST
    end
    
    if param.m_eOperationType == OPT_FUND_MERGE or param.m_eOperationType == OPT_FUND_SPLIT then
        priceType = BROKER_PRICE_PROP_FUND_CHAIHE
    end
    
    if param.m_eOperationType == OPT_N3B_LIMIT_PRICE_BUY or param.m_eOperationType == OPT_N3B_LIMIT_PRICE_SELL then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_MARKET_MAKE_LIMIT_PRICE
    end
    
    if param.m_eOperationType == OPT_N3B_REPORT_CONFIRM_SELL or param.m_eOperationType == OPT_N3B_REPORT_CONFIRM_BUY then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_REPORT_DEAL_CONFIRM
    end
    
    if param.m_eOperationType == OPT_N3B_CONFIRM_SELL or param.m_eOperationType == OPT_N3B_CONFIRM_BUY then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_DEAL_CONFIRM
    end
    
    if param.m_eOperationType == OPT_N3B_PRICE_BUY or param.m_eOperationType == OPT_N3B_PRICE_SELL then
        priceType = BROKER_PRICE_PROP_NEW3BOARD_PRICE
    end
    
    if param.m_eOperationType == OPT_CONVERT_BONDS then
        priceType = BROKER_PRICE_PROP_EQUITY
    end
    
    if param.m_eOperationType == OPT_SELL_BACK_BONDS then
        priceType = BROKER_PRICE_PROP_SELLBACK
    end

    if param.m_eOperationType == OPT_ETF_REDEMPTION or param.m_eOperationType == OPT_ETF_PURCHASE then
        priceType = BROKER_PRICE_PROP_ETF
    end
    
    local exchangeStatus = getAccountExchangeStatus(param.m_account, param.m_stock.m_strMarket, param.m_stock.m_strCode)
    if param.m_account.m_nBrokerType == AT_HUGANGTONG then
        if EXCHANGE_STATUS_CONTINOUS ~= exchangeStatus then
            priceType = BROKER_PRICE_BID_LIMIT
        else
            priceType = BROKER_PRICE_ENHANCED_LIMIT
        end
    end
    
    local dataCenter = g_traderCenter:getDataCenter()
    local instrument = dataCenter:getInstrument(param.m_stock.m_strMarket, param.m_stock.m_strCode)
    if param.m_account.m_nBrokerType == AT_HUGANGTONG and param.m_eOperationType == OPT_SELL and instrument ~= CInstrumentDetail_NULL and num < instrument.VolumeMultiple then
        priceType = BROKER_PRICE_RETAIL_LIMIT
    end

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
    orderInfo.m_strCompactId = param.m_strCompactId
    if param.m_eOperationType == OPT_OPTION_COVERED_OPEN or param.m_eOperationType == OPT_OPTION_COVERED_CLOSE then
        orderInfo.m_eCoveredFlag = XT_COVERED_FLAG_TRUE
    else
        orderInfo.m_eCoveredFlag = XT_COVERED_FLAG_FALSE
    end
    orderInfo.m_strTargetSeat = param.m_strTargetSeat
    orderInfo.m_strTargetStockAccount = param.m_strTargetStockAccount
    orderInfo.m_nConferNo = param.m_nConferNo

    task_helper.order_async(orderInfo, callback)

    -- 如果行情更新不及时，报警
    msg = logAndDealWithPriceTime(param, priceData, orderInfo, string.format("%s 价格%.4f委托%d%s", msgTag, price, num, (isStock(param.m_stock.m_strMarket) and "" or "手")), msgTag)

    return ORDER_SUCCESS, orderInfo, msg
end

function dispatchUndealed(param, orderInfo, priceData, callback)
    --print("dispatchUndealed")
    if param.m_eOrderType == OTP_ORDINARY then
        return ORDER_FATAL, nil, "普通交易不支持未成委托处理"
    else
        if param.m_eUndealtEntrustRule == PRTP_INVALID then
            return ORDER_FATAL, nil, "未成委托处理方式非法"
        elseif orderInfo.m_accountInfo == CAccountInfo_NULL then
            return ORDER_FATAL, nil, "账号数据为空"
        else
            local nMin = getTradeMinUnit(param.m_stock.m_strMarket, param.m_stock.m_strCode)
            if orderInfo.m_nOrderNum - orderInfo.m_nBusinessNum < nMin then
                return ORDER_FATAL, nil, "委托剩余量小于单笔委托最小量"
            end
            local tempParam = genUndealtparam(param, orderInfo)
            return algorithmTrade(tempParam, {}, priceData, callback)
        end
    end
end

