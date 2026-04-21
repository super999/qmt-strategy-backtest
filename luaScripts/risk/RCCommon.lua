package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCUtils.lua")
require('bit')

-- 定义一些常量
TRADING_DAY_MID   = 1  --日中
TRADING_DAY_END   = 2  --日末
TRADING_NIGHT_MID = 3  --夜中
TRADING_NIGHT_END = 4  --夜末

CONFIG_TYPE_PRODUCT_ASSETS = 1
CONFIG_TYPE_PRODUCT_PROPERTY = 2
CONFIG_TYPE_SINGLE_STOCK = 3
CONFIG_TYPE_SINGLE_PRODUCT = 4
CONFIG_TYPE_SINGLE_FACTORY = 5

A_FUND = true    -- 母基金
B_FUND = false   -- B基金，当产品为分级基金时，会有B基金

POSITIVE_DEAL_ERROR = 1e-6
POSITIVE_ASSETSRATE_EPSILON = 1e-10

XT_BLACKWHITE_RC_CHECK_ACCOUNT = 0
XT_BLACKWHITE_RC_CHECK_GLOBAL = 1
XT_BLACKWHITE_RC_CHECK_INSTITUTION = 2
--------------------------------------------获取账号配置-----------------------------------------


-- @brief 生成数学区间，例如 3.23% ≤ var < 9.12%
function genRangeMsg(leftValue, leftClosed, var, rightClosed, rightValue, isAbs)
    local ret
    if isAbs then   -- abslute
        if leftValue == -1.7e+300 then
            ret = string.format('%s %s %.4f', var, rightClosed and '≤' or '<', rightValue)
        elseif rightValue == 1.7e+300 then
            ret = string.format('%s %s %.4f', var, leftClosed and '≥' or '>', leftValue)
        else
            ret = string.format('%.4f %s %s %s %.4f', leftValue, leftClosed and '≤' or '<', var, rightClosed and '≤' or '<', rightValue)
        end
    else    -- percent
        if leftValue == -1.7e+300 then
            ret = string.format('%s %s %.4f%%', var, rightClosed and '≤' or '<', rightValue * 100)
        elseif rightValue == 1.7e+300 then
            ret = string.format('%s %s %.4f%%', var, leftClosed and '≥' or '>', leftValue * 100)
        else
            ret = string.format('%.4f%% %s %s %s %.4f%%', leftValue * 100, leftClosed and '≤' or '<', var, rightClosed and '≤' or '<', rightValue * 100)
        end
    end
    return ret
end

function genUnInitedAccountsMsg(productName, accounts)
    local size = accounts:size()
    if size < 1 then
        return ''
    end

    local msg = '产品 ' .. productName .. ' 账号 '
    for i = 0, size - 1, 1 do
        msg = msg .. accounts:at(i)
        if i >= 2 then
            if i < size -1 then
                msg = msg .. "..."
            end
            break
        end
        if i < size - 1 then
            msg = msg .. ","
        end
    end
    msg = msg .. ' 尚未登录'
    return msg
end

function isMyAccount(accountInfo, codeOrderParam)
    return nil == accountInfo
        or CAccountInfo_NULL == accountInfo
        or CAccountInfo_NULL == codeOrderParam.m_account
        or accountInfo:getKey() == codeOrderParam.m_account:getKey()
        or accountInfo:getKey() == rcGetParentAccountKey(codeOrderParam.m_account)
end

function isMyAccountOrder(accountInfo, orderInfo)
    return nil == accountInfo
        or CAccountInfo_NULL == accountInfo
        or CAccountInfo_NULL == orderInfo.m_accountInfo
        or accountInfo:getKey() == orderInfo.m_accountInfo:getKey()
        or accountInfo:getKey() == rcGetParentAccountKey(orderInfo.m_accountInfo)
end

function isSkipCheck(dDealPrice, eOptType, eBrokerPriceType)
    if eOptType == OPT_DIRECT_SECU_REPAY        or
       eOptType == OPT_DIRECT_CASH_REPAY        or
       eOptType == OPT_CONVERT_BONDS            or
       eOptType == OPT_SELL_BACK_BONDS          or
       eOptType == OPT_COLLATERAL_TRANSFER_IN   or
       eOptType == OPT_COLLATERAL_TRANSFER_OUT  or
       eOptType == OPT_FUND_REDEMPTION          or
       eOptType == OPT_FUND_MERGE               or
       eOptType == OPT_FUND_SPLIT               or
       eOptType == OPT_OPTION_SECU_LOCK         or
       eOptType == OPT_OPTION_SECU_UNLOCK       then
       
        if isInvalidDouble(dDealPrice) then
            return true
        end
    elseif eOptType == OPT_OPTION_SECU_UNLOCK then
        if isZero(dDealPrice - 1) then
            return true
        end
    end
    
    if eBrokerPriceType == BROKER_PRICE_PROP_ETF and isZero(dDealPrice - 1) then
        return true
    end
    
    return false
end

-- 检查交易价格
function checkPriceTypeLimit(param, isOrderInfo, orderLimit, msgHeader)
    rcprintDebugLog(m_strLogTag .. 'RCCommon: checkPriceTypeLimit')
    local res = TTError()
    local strMsg = ""

    -- 参数合法性检查
    if not param or not orderLimit then
        rcprintDebugLog('RCCommon: checkPriceTypeLimit 传入参数为空')
        return res
    end

    local strMarket = nil
    local strCode = nil
    local strCodeName = nil
    local platformId = nil
    local accountInfoPtr = nil

    local priceType = nil -- 报价方式
    local dDealPrice = nil -- 下单价
    local singleOrderNum = nil -- 单笔委托量
    
    local nDirection = nil
    local nOffsetFlag = nil
    local nHedgeFlag = nil
    local eOperationType = nil
    -- 根据param类型初始化变量
    if isOrderInfo then
        strMarket = param.m_strExchangeId
        strCode = param.m_strInstrumentId
        strCodeName = param.m_strInstrumentName
        if nil ~= param.m_accountInfo then
            platformId = param.m_accountInfo.m_nPlatformID
            accountInfoPtr = param.m_accountInfo
        end
        priceType = param.m_eBrokerPriceType
        dDealPrice = param.m_dPrice
        singleOrderNum = param.m_nOrderNum
        if isSkipCheck(dDealPrice, param.m_eOperationType, priceType) then
            return res
        end
        
        nDirection = param.m_nDirection
        nOffsetFlag = param.m_nOffsetFlag
        nHedgeFlag = param.m_nHedgeFlag
        eOperationType = param.m_eOperationType
    else
        if nil ~= param.m_stock then
            strMarket = param.m_stock.m_strMarket
            strCode = param.m_stock.m_strCode
            strCodeName = param.m_stock.m_strName
        end
        if nil ~= param.m_account then
            platformId = param.m_account.m_nPlatformID
        end
        priceType = param.m_ePriceType
        dDealPrice = rcGetPriceAndFix(param)
        if getDirectionByOperation(param.m_eOperationType) then
            dDealPrice = dDealPrice + param.m_dSuperPrice
        else
            dDealPrice = dDealPrice - param.m_dSuperPrice
        end
    end

    local size = table.getn(orderLimit)
    for index = 1, size, 1 do
        -- 检查分类
        local isInCategory = rcIsStockInCategory(strMarket, strCode, strCodeName, orderLimit[index].m_nCategoryId)

        -- 检查有效时间和风控条件
        local isInValidTimeCondition = isSubFundRuleInTimeRange(orderLimit[index]) and passCondition(orderLimit[index].m_condition, nil)

        if isInCategory and isInValidTimeCondition then
            -- 检查市价
            if orderLimit[index].m_limit.m_bMarketPriceForbid then
            rcprintDebugLog(m_strLogTag .. 'RCCommon: checkPriceTypeLimit: 检查市价')
                if priceType == PRTP_MARKET or priceType == BROKER_PRICE_ANY then
                    strMsg = msgHeader .. orderLimit[index].m_strCategoryName .. ', 禁止以市价买入或卖出!'
                    res:setErrorId(-1)
                    res:setErrorMsg(strMsg)
                    return res
                end
            end

            -- 检查涨跌停价格限制
            local dLimitPrice = nil
            if singleOrderNum and orderLimit[index].m_limit.m_bUpStopPriceForbid then
                dLimitPrice = rcGetLimitPrice(platformId, strMarket, strCode, PRTP_UPPRICE_FLAG)
                rcprintDebugLog(m_strLogTag .. 'RCCommon: checkPriceTypeLimit: 检查涨停价' .. tostring(dLimitPrice))
                if not isZero(dLimitPrice) and isGreaterEqual(dDealPrice, dLimitPrice) then
                    strMsg = msgHeader .. orderLimit[index].m_strCategoryName .. ', 禁止以涨停价下单!'
                    res:setErrorId(-1)
                    res:setErrorMsg(strMsg)
                    return res
                end
            end
            if singleOrderNum and orderLimit[index].m_limit.m_bDownStopPriceForbid then
                dLimitPrice = rcGetLimitPrice(platformId, strMarket, strCode, PRTP_DOWNPRICE_FLAG)
                rcprintDebugLog(m_strLogTag .. 'RCCommon: checkPriceTypeLimit: 检查跌停价' .. tostring(dLimitPrice))
                if not isZero(dLimitPrice) and isLessEqual(dDealPrice, dLimitPrice) then
                    strMsg = msgHeader .. orderLimit[index].m_strCategoryName .. ', 禁止以跌停价下单!'
                    res:setErrorId(-1)
                    res:setErrorMsg(strMsg)
                    return res
                end
            end

            -- 检查当前价偏离限制
            if singleOrderNum and orderLimit[index].m_limit.m_bCurPriceForbid then
                local curPriceRate = orderLimit[index].m_limit.m_dCurPriceDeviateRate
                dLimitPrice = rcGetLimitPrice(platformId, strMarket, strCode, PRTP_LASTPRICE_FLAG)
                rcprintDebugLog(m_strLogTag .. string.format('RCCommon: checkPriceTypeLimit: 检查当前价偏离率 当前价：%f, 限制价：%f, 范围: %f', dDealPrice, dLimitPrice, curPriceRate))
                if not isZero(dLimitPrice) then
                    local rate = 0.0
                    if orderLimit[index].m_limit.m_bLimtiCurPriceDifCheck then
                        if getDirectionByOperation(param.m_eOperationType) then
                            rate = ( dDealPrice - dLimitPrice ) / dLimitPrice
                        else
                            rate = ( dLimitPrice - dDealPrice ) / dLimitPrice
                        end
                    else
                       rate = abs(dDealPrice - dLimitPrice) / dLimitPrice
                    end
                    if isGreater(rate, curPriceRate) then
                        strMsg = string.format(msgHeader .. orderLimit[index].m_strCategoryName .. ', 报单价偏离最新价%.2f%%, 超过%.2f%%, 禁止交易!', rate * 100, curPriceRate * 100)
                        res:setErrorId(-1)
                        res:setErrorMsg(strMsg)
                        return res
                    end
                end
            end

            -- 检查昨日收盘价偏离限制
            if singleOrderNum and orderLimit[index].m_limit.m_bPreCloseForbid then
                local preCloseRate = orderLimit[index].m_limit.m_dPreCloseDeviateRate
                dLimitPrice = rcGetLimitPrice(platformId, strMarket, strCode, PRTP_PRECLOSE_FLAG)
                rcprintDebugLog(m_strLogTag .. string.format('RCCommon: checkPriceTypeLimit: 检查昨日收盘价偏离率 当前价：%f, 限制价：%f, 范围: %f', dDealPrice, dLimitPrice, preCloseRate))
                if not isZero(dLimitPrice) then
                    local rate = 0.0
                    if orderLimit[index].m_limit.m_bLimtiYesPriceDifCheck then
                        if getDirectionByOperation(param.m_eOperationType) then
                            rate = ( dDealPrice - dLimitPrice ) / dLimitPrice
                        else
                            rate = ( dLimitPrice - dDealPrice ) / dLimitPrice
                        end
                    else
                       rate = abs(dDealPrice - dLimitPrice) / dLimitPrice
                    end
                    if isGreater(rate, preCloseRate) then
                        strMsg = string.format(msgHeader .. orderLimit[index].m_strCategoryName .. ', 报单价偏离昨收盘价%.2f%%, 超过%.2f%%, 禁止交易!', rate * 100, preCloseRate * 100)
                        res:setErrorId(-1)
                        res:setErrorMsg(strMsg)
                        return res
                    end
                end
            end
            
            -- 检查单笔委托最大量限制
            if singleOrderNum and orderLimit[index].m_limit.m_bSingleOrderMaxNumForbid then
                local singleOrderMaxNum = orderLimit[index].m_limit.m_nSingleOrderMaxNum
                rcprintDebugLog(m_strLogTag .. string.format('RCCommon: checkPriceTypeLimit: 检查单笔委托量 当前委托量: %d, 单笔委托量阈值: %d', singleOrderNum, singleOrderMaxNum))
                if singleOrderMaxNum > 0 and singleOrderNum > singleOrderMaxNum then
                    strMsg = string.format(msgHeader .. orderLimit[index].m_strCategoryName .. ', 单笔委托数量%d超过阈值%d!', singleOrderNum, singleOrderMaxNum)
                    res:setErrorId(-1)
                    res:setErrorMsg(strMsg)
                    return res
                end
            end
            -- 检查单笔委托最大金额限制
            if singleOrderNum and orderLimit[index].m_limit.m_bSingleOrderMaxAmountForbid and accountInfoPtr ~= nil and OPT_DIRECT_SECU_REPAY ~= eOperationType then
                local singleOrderMaxAmt = orderLimit[index].m_limit.m_dSingleOrderMaxAmount
                local thisOrderAmount = rcCalcOrderAmount(accountInfoPtr, strMarket, strCode, dDealPrice, singleOrderNum, nDirection, nHedgeFlag, nOffsetFlag)
                rcprintLog(m_strLogTag .. string.format('RCCommon: checkPriceTypeLimit: check orderInfo amount: %d, threshold: %d', thisOrderAmount, singleOrderMaxAmt))
                if isGreater(singleOrderMaxAmt, 0) and isGreater(thisOrderAmount, singleOrderMaxAmt) then
                    strMsg = string.format(msgHeader .. orderLimit[index].m_strCategoryName .. ', 单笔交易额达到%.2f, 超过单笔委托金额限制%.2f, 禁止交易！', thisOrderAmount, singleOrderMaxAmt)
                    res:setErrorId(-1)
                    res:setErrorMsg(strMsg)
                    return res
                end
            end
        end
    end

    return res
end

-- @param[in] range1 range2 区间,格式见C++的CValueRange结构
function isSameRange(range1, range2)
    if not range1 or not range1 or
        not range1.m_compMinType or not range2.m_compMinType or
        not range1.m_compMaxType or not range2.m_compMaxType or
        not range1.m_min or not range2.m_min or
        not range1.m_max or not range2.m_max then
        return false
    end
    if  range1.m_compMinType == range2.m_compMinType and
        range1.m_compMaxType == range2.m_compMaxType and
        isInvalidDouble(range1.m_min) and isInvalidDouble(range2.m_min) and
        isInvalidDouble(range1.m_max) and isInvalidDouble(range2.m_max) then
        return true

    elseif  range1.m_compMinType == range2.m_compMinType and
        range1.m_compMaxType == range2.m_compMaxType and
        isInvalidDouble(range1.m_min) and isInvalidDouble(range2.m_min) and
        range1.m_max == range2.m_max then
        return true

    elseif  range1.m_compMinType == range2.m_compMinType and
        range1.m_compMaxType == range2.m_compMaxType and
        range1.m_min == range2.m_min and
        isInvalidDouble(range1.m_max) and isInvalidDouble(range2.m_max) then
        return true

    elseif  range1.m_compMinType == range2.m_compMinType and
        range1.m_compMaxType == range2.m_compMaxType and
        abs(range1.m_min - range2.m_min) <= 1e-6 and
        abs(range1.m_max - range2.m_max) <= 1e-6 then
        return true
    else
        return false
    end
end

-- @brief 判断一个数值是否属于一个数学区间内
-- @param[in] curVal 当前数值
-- @param[in] range  区间,格式见C++的CValueRange结构
-- @note range.m_min 最小值
-- @note range.m_compMinType 为XT_RLT_EX_INVALID(-1)时，表示没有最小值，此时minVal无意义
-- @note range.m_max 最大值
-- @note range.m_compMaxType 为XT_RLT_EX_INVALID(-1)时，表示没有最大值，此时maxVal无意义
function isValueInRange(curVal, range)
    local ret = true
    local minVal  = range.m_min
    local minType = range.m_compMinType
    local maxVal  = range.m_max
    local maxType = range.m_compMaxType

    --不等于的逻辑
    --协议约定
    if XT_RLT_EX_NOT_EQUAL == minType then
        return curVal ~= minVal
    end

    local minNumber = -1.7e+300   --标记无穷小
    local maxNumber = 1.7e+300    --标记无穷大
    local minLimit = minVal
    local maxLimit = maxVal
    if XT_RLT_EX_INVALID == minType then minLimit = minNumber end
    if XT_RLT_EX_INVALID == maxType then maxLimit = maxNumber end
    --assert(minLimit<=maxLimit)
    local leftClosed  = false --左区间是否闭合
    local rightClosed = false --右区间是否闭合
    if XT_RLT_EX_SMALLER_EQUAL == minType then leftClosed  = true end
    if XT_RLT_EX_SMALLER_EQUAL == maxType then rightClosed = true end

    if type(minLimit) ~= "number" then
        rcprintLog(m_strLogTag .. string.format("isValueInRange: the config of m_min(type = %s) is invalid, set to infinitely small.", type(minLimit)))
        minLimit = minNumber
    end
    
    if type(maxLimit) ~= "number" then
        rcprintLog(m_strLogTag .. string.format("isValueInRange: the config of m_max(type = %s) is invalid, set to infinitely big.", type(maxLimit)))
        maxLimit = maxNumber
    end

    if  (    leftClosed  and curVal <   minLimit) or
        (not leftClosed  and curVal <=  minLimit) or
        (    rightClosed and curVal >   maxLimit) or
        (not rightClosed and curVal >=  maxLimit) then
            --不在区间
            ret = false
    end
    --rcprintLog(m_strLogTag .. string.format("isValueInRange: range = %s, ret = %s", table2jsonOld(range), tostring(ret)))
    return ret
end

-- @brief 判断当前交易日+系统时间是否在指定时间区间内
-- @param[in] range 时间区间,格式为C++的CTimeRangeLimit
-- @note range.m_endDate 可能为空字符串,表示没有日期限制的上限
-- @retval true   在区间内
-- @retval false  不在区间内
function nowInTimeRange(range)
    if range then
        if range.m_bDateEnabled then
            local curDate = rcGetTradeDate()
            if curDate == '' then
                -- 这个函数还有明显问题吗？没有的话先不打日志了，太多了
                -- rcprintDebugLog(m_strLogTag .. string.format('get the trading date failed, startDate=%s, endDate=%s', range.m_startDate, range.m_endDate))
                return false
            end
            local validStart = string.gsub(range.m_startDate, '-', '')
            local validEnd = string.gsub(range.m_endDate, '-', '')
            if curDate < validStart or
               (validEnd ~= '' and curDate > validEnd) then    --validEnd不为空，表示日期没有上限
                -- rcprintDebugLog(m_strLogTag .. string.format('curr date %s not in the date range : %s - %s, pass', curDate, validStart, validEnd))
                return false
            end
        end
        if range.m_bTimeEnabled then
            local curTime = os.date('%H:%M:%S', os.time())
            local validStart = range.m_startTime
            local validEnd = range.m_endTime
            if validStart <= validEnd then
                if curTime < validStart or curTime > validEnd then
                    -- rcprintDebugLog(m_strLogTag .. string.format('curr time %s not in the time range : %s - %s, pass', curTime, validStart, validEnd))
                    return false
                end
            else
                if curTime < validStart and curTime > validEnd then
                    -- rcprintDebugLog(m_strLogTag .. string.format('curr time %s not in the time range : 00:00:00 - %s, %s - 23:59:59, pass', curTime, validEnd, validStart))
                    return false
                end
            end
        end
    end
    return true
end

-- 取品种对应的合规配置
function getAccountCompliance(config, m_strProductId)
    if not config then return nil end
    local m_compliances = config.m_compliances
    if m_compliances then
        -- 账号风控合规项排序
        m_compliances = reorderAssetsRCs(config.m_compliances)

        -- 返回与m_strProductId对应的合规配置
        local size = table.getn(m_compliances)
        for iCompliance = 1, size, 1 do
            if m_compliances[iCompliance].m_strProductID == m_strProductId then
                return m_compliances[iCompliance]
            end
           -- rcprintLog(m_strLogTag .. string.format('没有找到与 %s 对应的合规配置 return nil ', m_strProductId))
           -- return nil
        end
        rcprintLog(m_strLogTag .. string.format('合规配置为空, 没有找到与 %s 对应的合规配置 return nil ', m_strProductId))
        return nil
    end
end

-- 取合约对应的止损配置
function getAccountStopLoss(config, instrument)
    if not config or not config.m_bEnable then return nil end
    local m_stopLoss = config.m_stopLoss
    if m_stopLoss then
        local m_instrumentStopLossMap = m_stopLoss.m_instrumentStopLossMap
        return getTableFromMap(m_instrumentStopLossMap, instrument)
    end
    return nil
end

--取合约对应的止盈止损配置
function getAccountStop(config, instrumentID)
    if not config then
        -- rcprintDebugLog(m_strLogTag .. 'getAccountStop: config == nil, return nil ')
        return nil
    end

    local m_stops = config.m_stops
    if m_stops then
        -- 账号风控止盈止损项排序
        m_stops = reorderAssetsRCs(config.m_stops)

        -- 返回与instrumentID对应的止盈止损配置
        local size = table.getn(m_stops)
        for iStop = 1, size, 1 do
            if m_stops[iStop].m_strInstrumentID == instrumentID then
                -- rcprintDebugLog(m_strLogTag .. string.format('m_stops[%d].m_strInstrumentID = %s', iStop, m_stops[iStop].m_strInstrumentID))
                return m_stops[iStop]
            end
        end
        -- rcprintDebugLog(m_strLogTag .. 'getAccountStop: 没有找到与 %s 对应的止盈止损配置 return nil ')
        return nil
    else
        -- rcprintDebugLog(m_strLogTag .. 'getAccountStop: config.m_stops == nil, return nil ')
        return nil
    end
end

--检查证券账号黑白名单,当账号黑名单为空，跳过黑名单检查;当白名单为空，跳过白名单检查
function checkBlackWhite(whiteList, whiteCate, blackList, blackCate, strMarket, strCode, checkType, bIsPolling)
    local bInWhiteList = false
    local bInWhiteCate = false
    local strmsg = ""
    local typeName = ""
    if XT_BLACKWHITE_RC_CHECK_ACCOUNT == checkType then
        typeName = "账号"
    elseif XT_BLACKWHITE_RC_CHECK_INSTITUTION == checkType then
        typeName = "机构"
    elseif XT_BLACKWHITE_RC_CHECK_GLOBAL == checkType then
        typeName = "全局"
    end
    -- rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite: Begin to check white List ..."))
    if (XT_BLACKWHITE_RC_CHECK_ACCOUNT == checkType or XT_BLACKWHITE_RC_CHECK_INSTITUTION == checkType) and (whiteList and #(whiteList) == 0) and (whiteCate and #(whiteCate) == 0) then
       --当账号/机构白名单为空，跳过白名单检查
        rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite for account: The white list and white cate is unset, 跳过%s白名单检查。checkType = %s", typeName, tostring(checkType)))
        bInWhiteList = true
        bInWhiteCate = true
    else
        if whiteList and #(whiteList) > 0 then
            for i = 1, #(whiteList) do
                -- zhangyi : 2014-11-18
                -- 黑白名单判断加入市场代码
                -- 为兼容旧DB数据仍然保留只有代码判断的逻辑
                if (whiteList[i] == strCode) or (whiteList[i] == strMarket .. strCode) then
                    bInWhiteList = true
                    break
                end
            end
        end

        if not bInWhiteList then   --如果bInWhiteList为true, 则没有必要检查whiteCate
            -- rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite: Begin to check white Category ..."))
            if whiteCate and #(whiteCate) > 0 then
                for i = 1, #(whiteCate) do
                    local cate = whiteCate[i]
                    -- 容错：portal传过来的有时候是string有时候是int
                    if "string" == type(cate) then
                        cate = tonumber(cate)
                    end
                    -- rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite: strCode = %s, cate = %s", tostring(strCode), tostring(cate)))
                    if rcIsStockInCategoryWithoutName(strMarket, strCode, cate) then
                        bInWhiteCate = true
                        break
                    end
                end
            end
        end
    end

    if not (bInWhiteList or bInWhiteCate) then
        strmsg = string.format("代码%s不在%s风控白名单中, 无法交易!", strCode, typeName)
        if not bIsPolling then
            rcprintLog(m_strLogTag .. strmsg)
        end
        return false, strmsg
    end

    local bInBlackList = false
    local bInBlackCate = false

    if (XT_BLACKWHITE_RC_CHECK_ACCOUNT == checkType or XT_BLACKWHITE_RC_CHECK_INSTITUTION == checkType) and (blackList and #(blackList) == 0) and (blackCate and #(blackCate) == 0) then
        --当账号/机构黑名单为空，跳过黑名单检查
        rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite for account: The black list and black cate is unset. 跳过%s黑名单检查。checkType = %s", typeName, tostring(checkType)))
        bInBlackList = false
        bInBlackCate = false
    else
        if blackList and #(blackList) > 0 then
            for i = 1, #(blackList) do
                -- zhangyi : 2014-11-18
                -- 黑白名单判断加入市场代码
                -- 为兼容旧DB数据仍然保留只有代码判断的逻辑
                if (blackList[i] == strCode) or (blackList[i] == strMarket .. strCode) then
                    bInBlackList = true
                    strmsg = string.format("代码%s在%s风控黑名单%s中, 无法交易!", strCode, typeName, blackList[i])
                    if not bIsPolling then
                        rcprintLog(m_strLogTag .. strmsg)
                    end
                    break
                end
            end
        end

        if not bInBlackList then   --如果bInBlackList为true,则无必要检查blackCate
            -- rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite: Begin to check black list ..."))
            if blackCate and #(blackCate) > 0 then
                for i = 1, #(blackCate) do
                    local cate = blackCate[i]
                    -- 容错：portal传过来的有时候是string有时候是int
                    if "string" == type(cate) then
                        cate = tonumber(cate)
                    end
                    local strCateName = rcGetCategoryName(cate)
                    -- rcprintDebugLog(m_strLogTag .. string.format("checkBlackWhite: strCode = %s, cate = %s", tostring(strCode), tostring(cate)))
                    if rcIsStockInCategoryWithoutName(strMarket, strCode, cate) then
                        bInBlackCate = true
                        strmsg = string.format("代码%s在%s风控黑名单%s中, 无法交易!", strCode, typeName, strCateName)
                        if not bIsPolling then
                            rcprintLog(m_strLogTag .. strmsg)
                        end
                        break
                    end
                end
            end
        end
    end

    if bInBlackList or bInBlackCate then
        return false, strmsg
    end

    return true, strmsg
end

function needCheckBlackWhite(eOperationType, bNoSellLimit)
    if bNoSellLimit then
        if 
            -- 期货
            eOperationType == OPT_CLOSE_LONG_HISTORY --平昨多
            or eOperationType == OPT_CLOSE_LONG_TODAY --平今多
            or eOperationType == OPT_CLOSE_SHORT_HISTORY --平昨空
            or eOperationType == OPT_CLOSE_SHORT_TODAY --平今空
            or eOperationType == OPT_CLOSE_LONG_TODAY_FIRST --平多，优先平今
            or eOperationType == OPT_CLOSE_LONG_HISTORY_FIRST --平多，优先平昨
            or eOperationType == OPT_CLOSE_SHORT_TODAY_FIRST --平空，优先平今
            or eOperationType == OPT_CLOSE_SHORT_HISTORY_FIRST --平空，优先平昨
            or eOperationType == OPT_CLOSE_LONG --平多
            or eOperationType == OPT_CLOSE_SHORT --平空
            or eOperationType == OPT_CLOSE --平仓

            --证券类
            or eOperationType == OPT_SELL --卖出

            --融资融券
            or eOperationType == OPT_BUY_SECU_REPAY --买券还券
            or eOperationType == OPT_DIRECT_SECU_REPAY --直接还券

            --新三板
            or eOperationType == OPT_N3B_PRICE_SELL --协议转让-定价卖出
            or eOperationType == OPT_N3B_CONFIRM_SELL --协议转让-成交确认卖出
            or eOperationType == OPT_N3B_REPORT_CONFIRM_SELL --协议转让-互报成交确认卖出
            or eOperationType == OPT_N3B_LIMIT_PRICE_SELL --做市转让-限价卖出

            --ETF
            or eOperationType == OPT_ETF_REDEMPTION --ETF赎回
            then
            
            -- 卖出、平仓且不限制，不检查
            return false;
        end
    end
    
    return true;
end

--检查证券账号黑白名单
function checkAccountBlackWhite(nBrokerType, config, strMarket, strCode, bIsPolling, eOperationType)
    if (not config) or ((not config.stocks) and (not config.category)) then
        if config ~= nil then 
            rcprintLog(string.format("checkAccountBlackWhite configuration error: %s", table2jsonOld(config)))
            if m_bCheckFutureProduct and AT_FUTURE == nBrokerType then
                return true
            end
        end 
        local strAcc = getAccountDisplayID(m_accountInfo)
        rcprintLog(string.format("checkAccountBlackWhite configuration error, account = %s, strMarket = %s, strCode = %s", strAcc, strMarket, strCode))
        return false, "账号黑白名单配置错误"
    end

    -- 不限制卖出处理
    local bNoSellLimit = config.m_bNoSellLimit
    if not needCheckBlackWhite(eOperationType, bNoSellLimit) then
        return true
    end
    
    local stockWhite = {}
    local stockBlack = {}
    local categoryWhite = {}
    local categoryBlack = {}
    if nil ~= config.stocks then
        stockWhite = config.stocks.white
        stockBlack = config.stocks.black
    end
    if nil ~= config.category then
        categoryWhite = config.category.white
        categoryBlack = config.category.black
    end
    local res, strmsg = checkBlackWhite(stockWhite, categoryWhite, stockBlack, categoryBlack, strMarket, strCode, XT_BLACKWHITE_RC_CHECK_ACCOUNT, bIsPolling)
    return res, strmsg
end

--检查证券全局风控黑白名单
function checkGlobalBlackWhite(nBrokerType, s_config, strMarket, strCode, bIsPolling, eOperationType)
    local typeIndex = nil
    if nBrokerType == AT_STOCK or nBrokerType == AT_CREDIT then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_STOCK
    elseif nBrokerType == AT_NEW3BOARD then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_NEW3BOARD
    elseif nBrokerType == AT_HUGANGTONG then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_HGT
    elseif nBrokerType == AT_STOCK_OPTION then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_STOCKOPTION
    elseif nBrokerType == AT_FUTURE then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_FUTURE
    end
    
    if (not typeIndex) or (not s_config) or (not s_config[typeIndex]) or ((not s_config[typeIndex].stocks) and (not s_config[typeIndex].category)) then
        if s_config ~= nil then 
            rcprintLog(string.format("checkGlobalBlackWhite configuration error: %s", table2jsonOld(s_config)))
            if m_bCheckFutureProduct and AT_FUTURE == nBrokerType then
                return true
            end
        end 
        rcprintLog(string.format("checkGlobalBlackWhite configuration error, nBrokerType = %d, strMarket = %s, strCode = %s", nBrokerType, strMarket, strCode))
        return false, "全局黑白名单配置错误"
    end

    local bNoSellLimit = s_config[typeIndex].m_bNoSellLimit
    if not needCheckBlackWhite(eOperationType, bNoSellLimit) then
        return true, ""
    end
    
    local stockWhite = {}
    local stockBlack = {}
    local categoryWhite = {}
    local categoryBlack = {}
    if nil ~= s_config[typeIndex].stocks then
        stockWhite = s_config[typeIndex].stocks.white
        stockBlack = s_config[typeIndex].stocks.black
    end
    if nil ~= s_config[typeIndex].category then
        categoryWhite = s_config[typeIndex].category.white
        categoryBlack = s_config[typeIndex].category.black
    end
    
    --local res, strmsg = checkBlackWhite(s_config[typeIndex].stocks.white, s_config[typeIndex].category.white, s_config[typeIndex].stocks.black, s_config[typeIndex].category.black, strMarket, strCode, false, bIsPolling)
    local res, strmsg = checkBlackWhite(stockWhite, categoryWhite, stockBlack, categoryBlack, strMarket, strCode, XT_BLACKWHITE_RC_CHECK_GLOBAL, bIsPolling)
    return res, strmsg
end
function checkInstitutionBlackWhite(nBrokerType, config, strMarket, strCode, bIsPolling)
    if config == nil then 
        -- 没配置机构黑白名单的先放过，不能因为添加新功能阻碍客户下单
        return true, ""
    end
    
    local stockWhite = {}
    local stockBlack = {}
    local categoryWhite = {}
    local categoryBlack = {}
    if nBrokerType == AT_STOCK or nBrokerType == AT_CREDIT then
        if config.m_stockBW == nil then
            return true, ""
        end
        if nil ~= config.m_stockBW.stocks then
            stockWhite = config.m_stockBW.stocks.white
            stockBlack = config.m_stockBW.stocks.black
        end
        if nil ~= config.m_stockBW.category then
            categoryWhite = config.m_stockBW.category.white
            categoryBlack = config.m_stockBW.category.black
        end
    elseif nBrokerType == AT_HUGANGTONG then
        if config.m_hgtConfig == nil then
            return true, ""
        end
        
        if nil ~= config.m_hgtConfig.stocks then
            stockWhite = config.m_hgtConfig.stocks.white
            stockBlack = config.m_hgtConfig.stocks.black
        end
        if nil ~= config.m_hgtConfig.category then
            categoryWhite = config.m_hgtConfig.category.white
            categoryBlack = config.m_hgtConfig.category.black
        end
    elseif nBrokerType == AT_NEW3BOARD then 
        if config.m_new3BoardConfig == nil then
            return true, ""
        end
        if nil ~= config.m_new3BoardConfig.stocks then
            stockWhite = config.m_new3BoardConfig.stocks.white
            stockBlack = config.m_new3BoardConfig.stocks.black
        end
        if nil ~= config.m_new3BoardConfig.category then
            categoryWhite = config.m_new3BoardConfig.category.white
            categoryBlack = config.m_new3BoardConfig.category.black
        end
    elseif nBrokerType == AT_STOCK_OPTION then
        if config.m_stockOptionConfig == nil then
            return true, ""
        end
        if nil ~= config.m_stockOptionConfig.stocks then
            stockWhite = config.m_stockOptionConfig.stocks.white
            stockBlack = config.m_stockOptionConfig.stocks.black
        end
        if nil ~= config.m_stockOptionConfig.category then
            categoryWhite = config.m_stockOptionConfig.category.white
            categoryBlack = config.m_stockOptionConfig.category.black
        end
    elseif nBrokerType == AT_FUTURE then
        if config.m_futureBW == nil then
            return true, ""
        end
        if nil ~= config.m_futureBW.stocks then
            stockWhite = config.m_futureBW.stocks.white
            stockBlack = config.m_futureBW.stocks.black
        end
        if nil ~= config.m_futureBW.category then
            categoryWhite = config.m_futureBW.category.white
            categoryBlack = config.m_futureBW.category.black
        end
    elseif nBrokerType == AT_FUTURE_OPTION then
        if config.m_futureOptionConfig == nil then
            return true, ""
        end
        if nil ~= config.m_futureOptionConfig.stocks then
            stockWhite = config.m_futureOptionConfig.stocks.white
            stockBlack = config.m_futureOptionConfig.stocks.black
        end
        if nil ~= config.m_futureOptionConfig.category then
            categoryWhite = config.m_futureOptionConfig.category.white
            categoryBlack = config.m_futureOptionConfig.category.black
        end
    end
    local res, strmsg = checkBlackWhite(stockWhite, categoryWhite, stockBlack, categoryBlack, strMarket, strCode, XT_BLACKWHITE_RC_CHECK_INSTITUTION, bIsPolling)
    return res, strmsg
end
--------------------------------------------检查交易品种-----------------------------------------

function checkSingleProduct(config, strInstrumentId, strProductId)
    if nil ~= m_bCheckFutureProduct and not m_bCheckFutureProduct then 
        rcprintDebugLog("checkFutureProduct is disabled!")
        return true 
    end
    if not config or not config.m_bEnable then return false end
    local m_mapSingleProduct = config.m_compliance.m_mapSingleProduct
    if not m_mapSingleProduct or table.getn(m_mapSingleProduct) == 0 then   --当用户没有设置任何交易限制，投机交易限制品种表为空表，则不允许任何品种交易
        return false
    end
    local vInstrumentId = getTableFromMap(m_mapSingleProduct, strProductId)
    if not vInstrumentId then return false end
    local size = table.getn(vInstrumentId)
    if  size ~= 0 then
        for i=1, size, 1 do
            if vInstrumentId[i] == strInstrumentId then return true end
        end
        return false
    else
        return true
    end
end

local function checkMultiProduct(config, strProductIdA, strInstrumentIdA, eOp1, strProductIdB, strInstrumentIdB, eOp2)
    if not config or not config.m_bEnable then return false end
    local m_vMultiProduct = config.m_compliance.m_vMultiProduct
    local nDirection1 = getDirectionByOperation(eOp1);
    local nDirection2 = getDirectionByOperation(eOp2);
    -- rcprintLog(m_strLogTag .. "checkMultiProduct, strProductIdA:"..strProductIdA.." eOp1:"..eOp1.." strProductIdB:"..strProductIdB.." eOp2:"..eOp2)
    if strProductIdA ~=  strProductIdB then
        for i=1, table.getn(m_vMultiProduct), 1 do
            if ( m_vMultiProduct[i].m_strCode1 == strProductIdA and m_vMultiProduct[i].m_strCode2 == strProductIdB ) or ( m_vMultiProduct[i].m_strCode1 == strProductIdB and m_vMultiProduct[i].m_strCode2 == strProductIdA ) then
                if m_vMultiProduct[i].m_eRestriction == CBD_POSITIVE then return nDirection1 ~= nDirection2 end
                if m_vMultiProduct[i].m_eRestriction == CBD_NEGATIVE then return nDirection1 == nDirection2 end
            end
        end
    elseif strProductIdA == strProductIdB then
        if not checkSingleProduct(config, strInstrumentIdA, strProductIdA) then return false end
        if not checkSingleProduct(config, strInstrumentIdB, strProductIdB) then return false end
        return true
    end
    return false
end

function checkAccountOrderProduct(stockParams, config)
    for i = 0, stockParams:size() - 1, 1 do
        local stockparam  = stockParams:at(i)
        if isFtOpen(stockparam.m_eOperationType) and not checkSingleProduct(config, stockparam.m_stock.m_strCode, stockparam.m_stock.m_strProduct) then
            -- rcprintDebugLog(m_strLogTag .. string.format("checkAccountOrderProduct: config = %s", table2json(config)))
            strmsg =  string.format("合约"..stockparam.m_stock.m_strCode .. "不符合投机交易限制!")
            return false, strmsg
        else
            return true, ""
        end
    end
    -- RCAccountChecker中的getCodeOrderParms函数处理了stockParam与m_accountInfo对应关系，
    -- 因此这里可能由于stockParam与m_accountInfo不匹配，拿到的stockParams为空，为了不影响
    -- 后续下单，这里返回true放行
    --return false, "参数不正确"
    return true, ""
end

--------------------------------------------账号数据计算-----------------------------------------

-- 给分母用：如果资产比例风控项没有调仓优先级就随便给一个
local function getFrozenCommandIndex(accounts, factors, stock, scope)
    if nil == factors then
        return 0
    end
    local factorNum = table.getn(factors)
    local curMaxPriority = 1
    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        if nil ~= factor.m_nAdjustPriority and factor.m_nAdjustPriority > curMaxPriority then
            curMaxPriority = factor.m_nAdjustPriority
        end
    end
    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        if nil == factor.m_nAdjustPriority then
            curMaxPriority = curMaxPriority + 1
            factor.m_nAdjustPriority = curMaxPriority
        end
    end
    return rcGetFrozenCommandIndex(accounts, factors, stock, scope)
end

--------------------------------------------取产品风控配置-----------------------------------------
-- 去掉B基金的设置，都用一样的配置
-- 参数1 config  产品风控配置
function getProductRCConfig(config)
    if not config then return nil end
    -- 去掉B基金的设置，都用一样的配置
    -- 支持原来的配置文件
    if nil ~= config.m_fundParent then
        return config.m_fundParent
    end

    return config
end

-- 去掉B基金的设置，都用一样的配置
function getProductFundType(productInfo)
    --识别产品属于普通基金，还是分级基金的母基金，还是分级基金的B基金
    local fundType = 0   --0表示普通基金，1表示母基金，2表示B基金

    if productInfo.m_nTypes == 2 then
        fundType = 1
    else
        fundType = 0
    end

    return fundType
end

-- 取单位净值分档对应的比例限制
-- @param[in] netValueConfig  参考C++中CNetValueRCConfig的定义
-- @param[in] netValue 当前单位净值
-- @return v1,v2
-- @retval v1=false,    没有比例限制，此时v2为0.0
-- @retval v1=true ,    取到对应的比例限制，此时v2为一个table,格式参考C++中CNetValueRate的定义
function getLimitRateByNetValue(netValueConfig, netValue)
    rcprintDebugLog(m_strLogTag .. 'netValuConfig = ' .. table2jsonOld(netValueConfig))
    local netValueRates = netValueConfig.m_valueRates
    local size = table.getn(netValueRates)
    if size == 0 then
        rcprintDebugLog(m_strLogTag .. 'getLimitRateByNetValue: net value size is 0, return false')
        return false, 0.0, -1
    end

    for i = 1, size, 1 do
        if not netValueRates[i].m_enableGrade then
            -- 1. 未分档,无需根据当前净值找对应档位的限制区间，直接返回此时的限制徐建
            rcprintDebugLog(m_strLogTag .. string.format("getLimitRateByNetValue: net value is last, return rate %s, %s.", tostring(netValueRates[i].m_valueRange.m_min), tostring(netValueRates[i].m_valueRange.m_max)))
            return true, netValueRates[i].m_limitRange, i
        end

        if isValueInRange(netValue, netValueRates[i].m_valueRange) then
            rcprintDebugLog(m_strLogTag .. string.format("getLimitRateByNetValue: net value %s 在区间 %s,%s", tostring(netValue), tostring(netValueRates[i].m_valueRange.m_min), tostring(netValueRates[i].m_valueRange.m_max)))
            return true, netValueRates[i].m_limitRange, i
        end
    end

    rcprintDebugLog(m_strLogTag .. 'getLimitRateByNetValue: net value ....... end, return false')
    return false, 0.0, -1
end

-- 判断产品单位净值或产品单位净值跌幅处于哪一个分档区间
function getLimitRateByNetValueStopLoss(netValueStopLoss, reference)
    local stopLossRate = netValueStopLoss.m_rates
    if not stopLossRate then
        --rcprintLog(m_strLogTag .. "getLimitRateByNetValueStopLoss: 用户没有设置净值分档, 返回 nil")
        return false, nil
    end
    local size = table.getn(stopLossRate)
    if size == 0 then
        --rcprintLog(m_strLogTag .. "getLimitRateByNetValueStopLoss: stopLossRate size is 0, return false")
        return false, nil
    end

    for i = 1, size, 1 do
        if stopLossRate[i].m_valueRange and isValueInRange(reference, stopLossRate[i].m_valueRange) == true then
            --rcprintLog(m_strLogTag .. string.format("getLimitRateByNetValueStopLoss: stopLossRate 在区间 rate [%s, %s] 内, return true.", tostring(stopLossRate[i].m_valueRange.m_min), tostring(stopLossRate[i].m_valueRange.m_max)))
            return true, stopLossRate[i]
        end
    end

    --rcprintDebugLog(m_strLogTag .. 'getLimitRateByNetValueStopLoss: ....... end, return false')
    return false, nil
end

function isDelayStopLossRateConfig(rate)
    local delayDays = 0
    if rate and rate.m_nDelayDays and type(rate.m_nDelayDays) == "number" then
        delayDays = rate.m_nDelayDays
    end

    local delaySeconds = 0
    if rate and rate.m_nDelaySeconds and type(rate.m_nDelaySeconds) == "number" then
        delaySeconds = rate.m_nDelaySeconds
    end

    rcprintDebugLog(m_strLogTag .. string.format("rate.nDelayDays = %s, rate.nDelaySeconds = %s", tostring(delayDays), tostring(delaySeconds)))

    if delayDays > 0 then
        return true
    elseif delaySeconds > 0 then
        return true
    else
        return false
    end

    return false
end

--生成产品tag，用于风控提示
function genProductTag(productInfo)
    local strProductTag='产品"'.. productInfo.m_strName ..'"'
    return strProductTag
end

--生成账号tag，用于风控提示
function genAccountTag(m_accountInfo, isSelf)
    local strAccountTag='账号"'..m_accountInfo.m_strAccountName..'"'
    return strAccountTag
end

-----------------------------------------------产品持仓组合计算---------------------------------------
local function sortByExpireDate(a, b)
    return a["ExpireDate"] < b["ExpireDate"]
end

-- 获取产品当前净值
-- 返回3个值，分别为 母基金单位净值、B基金单位净值、产品净值
function getProductNetValue(product)
    if nil == product or nil == product.m_nId then
        return 0.0, 0.0, 0.0
    end

    local netValue = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_NAV)
    local bNetValue = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_B_NAV)
    local totalNetValue = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_NET_VALUE)
    return netValue, bNetValue, totalNetValue
end

----------------------------来自RCProductChecker.lua------------------------------------------------
-- 生成产品风控级别的消息头
function genProductMsgTag(nId)
    local strPd = genProductTag(m_productInfo)
    local strMsgTag = ""
    if nId == XT_COrderCommand then
        strMsgTag = string.format("[指令风控检查] %s", strPd)
    elseif nId == XT_CCreateTaskReq then
        strMsgTag = string.format("[任务风控检查] %s", strPd)
    elseif nId == XT_COrderInfo then
        strMsgTag = string.format("[委托风控检查] %s", strPd)
    else
        strMsgTag = string.format("[风控检查] %s", strPd)
    end
    return strMsgTag
end

function genAccountMsgTag(nId)
    local strAcc = getAccountDisplayID(m_accountInfo)
    local strMsgTag = ""
    if nId == XT_COrderCommand then
        strMsgTag = string.format("[指令风控] 账号\"%s\", ", strAcc)
    elseif nId == XT_CCreateTaskReq then
        strMsgTag = string.format("[任务风控] 账号\"%s\", ", strAcc)
    elseif nId == XT_COrderInfo then
        strMsgTag = string.format("[委托风控] 账号\"%s\", ", strAcc)
    else
        strMsgTag = string.format("[风控] 账号\"%s\", ", strAcc)
    end
    return strMsgTag
end

function isGroupedIndexID(indexID)
    return indexID >= XT_RCF_GROUP_BEGIN and indexID < XT_RCF_CODE_BEGIN
end

function reorderAssetsRCs(assetsRCs)
    local tbl = {}
    local N = 4
    for i = 1, N, 1 do
        tbl[i] = {}
    end
    for i = 1, table.getn(assetsRCs), 1 do
        local rc = assetsRCs[i]
        if XT_ASSETS_RC_TYPE_LAW == rc.m_type then
            table.insert(tbl[1], rc)
        elseif XT_ASSETS_RC_TYPE_CONTRACT == rc.m_type then
            table.insert(tbl[2], rc)
        elseif XT_ASSETS_RC_TYPE_OPERATION == rc.m_type then
            table.insert(tbl[3], rc)
        else
            table.insert(tbl[4], rc)      -- 容错
        end
    end
    local res = {}
    for i = 1, N, 1 do
        for j = 1, table.getn(tbl[i]), 1 do
            table.insert(res, tbl[i][j])
        end
    end
    return res
end

function isParamContributeToFactors(factors, param, isOrderInfo)
    for i = 1, table.getn(factors), 1 do
        local factor = factors[i]
        if isOrderInfo then
            if rcIsStockInCategory(param.m_strExchangeId, param.m_strInstrumentId, param.m_strInstrumentName, factor.m_nID) then
                rcprintDebugLog(m_strLogTag .. string.format('isParamContributeToFactors : market = %s, code = %s, name = %s, factor_id = %d, return true.', param.m_strExchangeId, param.m_strInstrumentId, param.m_strInstrumentName, factor.m_nID))
                return true
            end
        elseif XT_RCF_CODE_FLOAT_VOLUME ~= factor.m_nIndexID and XT_RCF_CODE_TOTAL_VOLUME ~= factor.m_nIndexID
            and XT_RCF_CODE_FLOAT_AMOUNT ~= factor.m_nIndexID and XT_RCF_CODE_TOTAL_AMOUNT ~= factor.m_nIndexID then
            -- 下指令或任务时的check，统计每一个CCOdeOrderParam
            for iParam = 0, param:size() - 1, 1 do
                local p = param:at(iParam)
                if p.m_stock and rcIsStockInCategory(p.m_stock.m_strMarket, p.m_stock.m_strCode, p.m_stock.m_strName, factor.m_nID) then
                    rcprintDebugLog(m_strLogTag .. string.format('isParamContributeToFactors : market = %s, code = %s, name = %s, factor_id = %d, return true.', p.m_stock.m_strMarket, p.m_stock.m_strCode, p.m_stock.m_strName, factor.m_nID))
                    return true
                end
            end
        end
    end
    rcprintDebugLog(m_strLogTag .. 'isParamContributeToFactors : return false.')
    return false
end

-- 判断分子的一个因子是否是在一个绝对值组里
function isAbsFactor(factorGroupId)
    --如果没有配置绝对值groupId，则返回false
    --如果groupId == -1，表示不在任何绝对值组
    --如果groupId > 0 才认为在一个绝对值组里
    if nil == factorGroupId or -1 == factorGroupId or factorGroupId <= 0 then
        return false
    end

    return true
end

local function isExposureAssetsFactors(factors)
    local factorNum = table.getn(factors)
    local hasPositive = false
    local hasNegative = false
    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        if factor.m_dWeight == nil then
            factor.m_dWeight = 1
        end
        if factor.m_dWeight > 0 then
            hasPositive = true
        elseif factor.m_dWeight < 0 then
            hasNegative = true
        end
    end
    return hasPositive and hasNegative
end


-- 计算在一个绝对值组里面所有的因子的和，也可以计算不再任何绝对值组里的数据，所以在该函数中不会计算绝对值
-- 返回值 double, double 后者是本次下单所产生的未计算权重的值，两个返回值都不会计算绝对值
-- factors为资产范围为全部的 处于同一个绝对值组（也可以不在任何绝对值组里）的资产类型指标 数组
local function getWeightedSum_allStocks_group(factors, param, isOrderInfo, isHedge)
    local sum = 0
    local thisSum = 0
    local preSum = 0    --未下单时的和,在绝对值组中用，在非绝对值组时不需要

    local factorNum = table.getn(factors)
    local isExposure = isExposureAssetsFactors(factors)

    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        local factorSum = 0
        local factorThisSum = 0
        local factorPreSum = 0
        local nExcludeCmdId = 0
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags 
        end
        if m_bPollingRC then
            nExcludeCmdId = -1
        end
        if factor.m_nIndexID == XT_RCF_POSITION_MARGIN_SINGLE and   --指定的资产类型才考虑单边保证金,而且目前只考虑资产范围为全部的情况
            (factor.m_nID >= XT_RCC_SYSTEM_CODE_FUTURES_START and
             factor.m_nID <=  XT_RCC_SYSTEM_CODE_FUTURES_END) then
             -- 期货单边保证金
            local singleMargin = 0   --单边保证金
            local singleMarginThis = 0
            local singleMarginPre = 0
            local paramList = CCodeOrderParamList()
            local isPolling = true
            if not m_bPollingRC then
               isPolling = false
            end


            if isOrderInfo then
                if param ~= nil and param.m_xtTag ~= nil and param.m_xtTag.m_nCommandID ~= nil then
                    nExcludeCmdId = param.m_xtTag.m_nCommandID
                end
                local marginRes = rcGetSingleMargin(m_accountInfos, paramList, param, factor.m_nID, nExcludeCmdId)   --param是OrderInfo
                singleMargin = marginRes.m_dParamRes
                singleMarginThis = marginRes.m_dThisRes
                singleMarginPre = marginRes.m_dPreRes
                rcprintLog(m_strLogTag .. string.format("rcGetSingleMargin 0 : singleMargin=%f, singleMarginThis=%f, singleMarginPre=%f", singleMargin, singleMarginThis, singleMarginPre))
            else
                paramList.m_params = param
                local marginRes = rcGetSingleMargin(m_accountInfos, paramList, COrderInfo(), factor.m_nID, nExcludeCmdId)   --param是CCodeOrderParamList,把账号和下单参数传入，以求出持仓和委托中的单边保证金
                singleMargin = marginRes.m_dParamRes
                singleMarginThis = marginRes.m_dThisRes
                singleMarginPre = marginRes.m_dPreRes
                rcprintLog(m_strLogTag .. string.format("rcGetSingleMargin 1 : singleMargin=%f, singleMarginThis=%f, singleMarginPre=%f", singleMargin, singleMarginThis, singleMarginPre))
            end

            if not isInvalidDouble(singleMargin) then
                factorSum = singleMargin   --用于后面的sum, thisSum累加
            end
            if not isInvalidDouble(singleMarginThis) then
                factorThisSum = singleMarginThis
            end
            if not isInvalidDouble(singleMarginPre) then
                factorPreSum = singleMarginPre      -- 为了计算绝对值组的thisSum，需要保留未考虑下单的权重和
            end
        elseif factor.m_nIndexID == XT_RCF_POSITION_STOCK_NUM and not isOrderInfo then
            local paramList = CCodeOrderParamList()
            paramList.m_params = param
            local vStockNumRes = rcGetPositionStockNum(m_accountInfos, paramList, factor.m_nID, nExcludeCmdId)
            if vStockNumRes:size() >= 1 and not isInvalidInt(vStockNumRes:at(0)) then
                factorSum = vStockNumRes:at(0)
            end
            if vStockNumRes:size() >= 2 and not isInvalidInt(vStockNumRes:at(1)) then
                factorThisSum = vStockNumRes:at(1)
            end
            if vStockNumRes:size() >= 3 and not isInvalidInt(vStockNumRes:at(2)) then
                factorPreSum = vStockNumRes:at(2)
            end
        elseif factor.m_nIndexID == XT_RCF_POSITION_FUTURE_PRODUCT_NUM and not isOrderInfo then 
            local paramList = CCodeOrderParamList()
            paramList.m_params = param
            local vFutrueNumRes = rcGetPositionFutureProductNum(m_accountInfos, paramList, factor.m_nID, hedgeFlags, nExcludeCmdId)
            if vFutrueNumRes:size() >= 1 and not isInvalidInt(vFutrueNumRes:at(0)) then 
                factorSum = vFutrueNumRes:at(0)
            end  
            if vFutrueNumRes:size() >= 2 and not isInvalidInt(vFutrueNumRes:at(1)) then 
                factorThisSum = vFutrueNumRes:at(1)
            end  
            if vFutrueNumRes:size() >= 3 and not isInvalidInt(vFutrueNumRes:at(2)) then 
                factorPreSum = vFutrueNumRes:at(2)
            end
        else
            -- 1. 现有数据值
            if XT_RCC_SYSTEM_SPECIAL_PRODUCT == factor.m_nID then
                if XT_RCF_PRODUCT_SECURITIES_VALUE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_FUTURES_VALUE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_SECURITIES_AVAILABLE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_FUTURES_AVAILABLE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_NEEQ_VALUE == factor.m_nIndexID or 
                   XT_RCF_PRODUCT_STOCKOPTION_VALUE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_HGT_VALUE == factor.m_nIndexID or 
                   XT_RCF_PRODUCT_NEEQ_AVAILABLE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_STOCKOPTION_AVAILABLE == factor.m_nIndexID or
                   XT_RCF_PRODUCT_HGT_AVAILABLE == factor.m_nIndexID or 
                   XT_RCF_PRODUCT_GOLD_VALUE == factor.m_nIndexID or 
                   XT_RCF_PRODUCT_GOLD_AVAILABLE == factor.m_nIndexID then
                   -- 期货证券总权益、可用资金， 可以通过account求和得到. 账号、产品、账号组、产品组、全局都用这个逻辑分支
                    if m_accountInfos ~= nil then
                        factorSum = rcGetAccountGroupIndex(m_accountInfos, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                    end
                else
                    -- “产品属性”类因子
                    factorSum = rcGetProductBasicIndex(m_nProductId, factor.m_nIndexID)
                end
            elseif XT_RCC_SYSTEM_SPECIAL_ACCOUNT_FUTURES == factor.m_nID then
                local nExcludeCmdId = 0
                if m_bPollingRC then
                    nExcludeCmdId = -1
                end
                -- 期货账号属性类因子
                factorSum = rcGetAccountsIndex(m_accountInfos, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
            elseif m_bProductGroupRC and XT_RCC_SYSTEM_SPECIAL_PRODUCTGROUP == factor.m_nID then
                factorSum = rcGetProductGroupBasicIndex(m_nGroupId, factor.m_nIndexID)
            else
                if isOrderInfo then
                    if param ~= nil and param.m_xtTag ~= nil and param.m_xtTag.m_nCommandID ~= nil then
                        nExcludeCmdId = param.m_xtTag.m_nCommandID
                    end
                end

                if m_bAccountRC and m_accountInfo ~= nil then
                    -- 账号风控走这里
                    factorSum = rcGetAccountAllStockIndex(m_accountInfo, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                elseif (m_bAccountGroupRC or m_bProductGroupRC)and m_accountInfos ~= nil then
                    factorSum = rcGetAccountGroupIndex(m_accountInfos, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                    rcprintLog(m_strLogTag .. string.format("0814test: cata_id = %d, index_id = %d, factorSum = %f", factor.m_nID, factor.m_nIndexID, factorSum))
                else
                    -- “持仓比例”类因子，考虑联合风控
                    factorSum = rcGetProductStockIndex(m_nProductId, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                    rcprintDebugLog(m_strLogTag .. string.format("0814test: cata_id = %d, index_id = %d, factorSum = %f", factor.m_nID, factor.m_nIndexID, factorSum))
                end
            end

            factorPreSum = factorSum
            -- 2. 下单参数对现有数据的贡献
            local v = 0
            if isOrderInfo then
                v = rcGetEntrustIndex(param, factor.m_nID, factor.m_nIndexID, hedgeFlags)
            else
                for iParam = 0, param:size() - 1, 1 do
                    local tempV = rcGetCommandIndex(param:at(iParam), factor.m_nID, factor.m_nIndexID, hedgeFlags)
                    rcprintDebugLog(m_strLogTag .. string.format("factor = %d, index = %d, v = %f", factor.m_nID, factor.m_nIndexID, tempV))
                    if not isInvalidDouble(tempV) then
                        v = v + tempV
                    end
                end
            end

            if not isInvalidDouble(v) then
                if not (isExposure and isHedge) then
                    factorSum = factorSum + v
                end
                factorThisSum = factorThisSum + v
            end
        end

        preSum = preSum + factorPreSum * factor.m_dWeight
        sum = sum + factorSum * factor.m_dWeight
        rcprintDebugLog(m_strLogTag .. string.format("0814test: factorSum = %f, factorThisSum = %f, m_dWeight = %d, new sum = %f", factorSum, factorThisSum, factor.m_dWeight, sum))
        thisSum = thisSum + factorThisSum * factor.m_dWeight
    end
    return sum, thisSum, preSum
end


-- 计算“产品在股票池内所有股票的XXXX资产”
-- 返回值 double，double  后者是本次下单所产生的未计算权重的值
-- factors为资产范围为全部的 资产类型指标 数组
function getWeightedSum_allStocks(factors, param, isOrderInfo, isHedge)

    local sum = 0
    local thisSum = 0
    local factorNum = table.getn(factors)

    -- 将factor分组：需要按组同时计算的，不和需要的
    groupedFactors = {}    --将需要一起计算的分子单独列出来，如组合持仓的锁定单，组合持仓的趋势多头等
    absFactors = {}        --将属于同一绝对值组的分子列出来,现在绝对值组目前只支持资产范围为全部，并且不在按组同时计算的因子中
    otherFactors = {}
    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        if isGroupedIndexID(factor.m_nIndexID) then
            table.insert(groupedFactors, factor)
        elseif isAbsFactor(factor.m_nFactorGroupId) then
            local groupId = factor.m_nFactorGroupId
            if nil == absFactors[groupId] or table.getn(absFactors[groupId]) == 0 then
                absFactors[groupId] = {}
                table.insert(absFactors[groupId], factor)
            else
                table.insert(absFactors[groupId], factor)
            end
        else
            table.insert(otherFactors, factor)
        end
    end


    -- 先计算需要按组同时计算的
    if table.getn(groupedFactors) > 0 then
        if isOrderInfo then
            sum = rcGetProductIndexForOrder(m_accountInfos, groupedFactors, param)
        else
            sum = rcGetProductIndexForParams(m_accountInfos, groupedFactors, param)
        end
    end

    -- 缓存组合持仓市值
    local groupedVal = sum

    -- 计算在绝对值组里的因子的和
    local absGroupNum = table.getn(absFactors)
    for groupId, groupFactors in pairs(absFactors) do
        -- 在绝对值组中thisAbsSum没有意义，需要下面在单独计算thisAbsSum
        local absSum, thisAbsSum, preAbsSum = getWeightedSum_allStocks_group(groupFactors, param, isOrderInfo, isHedge)
        absSum = abs(absSum)
        preAbsSum = abs(preAbsSum)
        thisAbsSum = absSum - preAbsSum     -- 在绝对值组中计算属于一个绝对值组的thisSum = 下单后 - 下单前

        sum = sum + absSum
        thisSum = thisSum + thisAbsSum
    end

    -- 计算其他的factor
    local otherSum, thisOtherSum = getWeightedSum_allStocks_group(otherFactors, param, isOrderInfo, isHedge)

    sum = sum + otherSum
    thisSum = thisSum + thisOtherSum

    if groupedVal > 0 and thisSum == 0 then
        thisSum = groupedVal --特殊处理，当风控只设置了组合持仓价值比例限制 的情况
    end

    rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum_allStocks : sum = %f, thisSum = %f', sum, thisSum))
    return sum, thisSum
end

-- 计算“产品在合约池内单一发行方的XXXX资产”
-- factors为资产范围为单一发行方的 资产类型指标 数组
-- 返回{发行方1，发行方2，...，发行方n}，
--     {发行方1的值，发行方2的值，...，发行方n的值}（已经将多个指标进行加权）,
--     {发行方1的本次贡献的加权后的值，发行方2的本次贡献的加权后的值，...，发行方n的本次贡献的加权后的值}
function getWeightedSum_singleIssuer(factors, param, isOrderInfo, fakeParams, isHedge)
    local factorNum = table.getn(factors)
    local acKeyToAccounts = {}
    local acKeyToParams = {}
    local keyToStock = {}

    local nExcludeCmdId = 0
    if m_bPollingRC then
        nExcludeCmdId = -1
    end
    --rcprintLog(m_strLogTag .. string.format('getWeightedSum_singleIssuer : param:%s, isorder:%s, ispolling:%s', param:size(), tostring(isOrderInfo), tostring(m_bPollingRC)))
    if isOrderInfo then
        if param ~= nil and param.m_xtTag ~= nil and not m_bPollingRC and param.m_xtTag.m_nCommandID ~= nil then
            nExcludeCmdId = param.m_xtTag.m_nCommandID
        end

        local accounts = {}
        if CAccountInfo_NULL == param.m_accountInfo or nil == param.m_accountInfo then
            -- 对于轮询，应该用所有账号
            for i = 0, m_accountInfos:size() - 1, 1 do
                table.insert(accounts, m_accountInfos:at(i))
            end
        else
            table.insert(accounts, param.m_accountInfo)
        end

        for k, account in pairs(accounts) do
            local strAccountKey = account:getKey()
            if nil == acKeyToAccounts[strAccountKey] then
                acKeyToAccounts[strAccountKey] = account
                acKeyToParams[strAccountKey] = CStockInfoVec()
            end

            local stk = CStockInfo()
            stk.m_strMarket = param.m_strExchangeId
            stk.m_strProduct = param.m_strProductId
            stk.m_strCode = param.m_strInstrumentId
            stk.m_strName = param.m_strInstrumentName
            if m_bPollingRC then
                acKeyToParams[strAccountKey]:push_back(stk)
            end
            keyToStock[stk:getKey()] = stk
        end
    else
        for iParam = 0, param:size() - 1, 1 do
            local account = param:at(iParam).m_account
            local strAccountKey = account:getKey()
            if nil == acKeyToAccounts[strAccountKey] then
                acKeyToAccounts[strAccountKey] = account
                acKeyToParams[strAccountKey] = CStockInfoVec()
            end
            
            local stk = CStockInfo()
            stk.m_strMarket = param:at(iParam).m_stock.m_strMarket
            stk.m_strProduct = param:at(iParam).m_stock.m_strProduct
            stk.m_strCode = param:at(iParam).m_stock.m_strCode
            stk.m_strName = param:at(iParam).m_stock.m_strName
            if m_bPollingRC then
                acKeyToParams[strAccountKey]:push_back(stk)
            end
            keyToStock[stk:getKey()] = stk
            --rcprintLog(m_strLogTag .. string.format('getWeightedSum_singleIssuer : acKey:%s, market=%s, code=%s', strAccountKey, stk.m_strMarket, stk.m_strCode))
        end
    end

    if fakeParams ~= nil and not m_bPollingRC then
        for iParam = 0, fakeParams:size() - 1, 1 do
            local account = fakeParams:at(iParam).m_account
            local stk = CStockInfo()
            stk.m_strMarket = fakeParams:at(iParam).m_stock.m_strMarket
            stk.m_strProduct = fakeParams:at(iParam).m_stock.m_strProduct
            stk.m_strCode = fakeParams:at(iParam).m_stock.m_strCode
            stk.m_strName = fakeParams:at(iParam).m_stock.m_strName
            keyToStock[stk:getKey()] = stk
        end
    end

    if not m_bPollingRC then
        local stockInfos = CStockInfoVec()

        for k, v in pairs(keyToStock) do
            stockInfos:push_back(v)
        end

        for iAccount = 0, m_accountInfos:size() - 1, 1 do
            local accountInfo = m_accountInfos:at(iAccount)
            if (nil ~= accountInfo) and (isStockAccount(accountInfo) or (AT_HUGANGTONG == accountInfo.m_nBrokerType)) then
                acKeyToParams[accountInfo:getKey()] = stockInfos
            end
        end
    end
    --rcprintLog(m_strLogTag .. string.format('getWeightedSum_singleIssuer : acKeyToParams:%s', table2jsonOld(acKeyToParams) ))
    local factorSum = {}

    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags 
        end
        factorSum[iFactor] = {}

        local oneBreak = (XT_RCF_CODE_FLOAT_VOLUME == factor.m_nIndexID or XT_RCF_CODE_TOTAL_VOLUME == factor.m_nIndexID or XT_RCF_CODE_TODAY_DEAL_VOLUME == factor.m_nIndexID or XT_RCF_CODE_FLOAT_AMOUNT == factor.m_nIndexID or XT_RCF_CODE_TOTAL_AMOUNT == factor.m_nIndexID)

        for iAccount = 0, m_accountInfos:size() - 1, 1 do
            local account = m_accountInfos:at(iAccount)
            local stocks = acKeyToParams[account:getKey()]
            if nil ~= stocks then
                local valueRes = rcGetAccountSingleIssuerIndexes(account, stocks, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                
                rcprintLog(m_strLogTag .. string.format('getWeightedSum_singleIssuer : valueRes size = %d', valueRes:size()))
                for iIssuer = 0, valueRes:size() -1, 1 do
                    local res = valueRes:at(iIssuer)
                    local issuerId = res.m_strName
                    local oneValueRes = res.m_dParamRes
                    
                    if not isInvalidDouble(oneValueRes) then
                        if nil == factorSum[iFactor][issuerId] then
                            factorSum[iFactor][issuerId] = 0
                        end
                        factorSum[iFactor][issuerId] = factorSum[iFactor][issuerId] + oneValueRes
                    end
                end
            end
        end
    end

    local factorThisSum = {}

    local isExposure = isExposureAssetsFactors(factors)

    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags
        end
        factorThisSum[iFactor] = {}

        if XT_RCF_CODE_FLOAT_VOLUME ~= factor.m_nIndexID and XT_RCF_CODE_TOTAL_VOLUME ~= factor.m_nIndexID then
            if isOrderInfo then
                local v = rcGetEntrustIndex(param, factor.m_nID, factor.m_nIndexID, hedgeFlags)
                if not isInvalidDouble(v) then
                    local issuerId = rcGetIssuerId(param.m_strExchangeId, param.m_strInstrumentID)
                    factorThisSum[iFactor][issuerId] = v
                end
            else
                for iParam = 0, param:size() - 1, 1 do
                    local p = param:at(iParam)
                    local v = rcGetCommandIndex(p, factor.m_nID, factor.m_nIndexID, hedgeFlags)
                    if not isInvalidDouble(v) and p.m_stock ~= nil and p.m_stock.m_strCode ~= nil then
                        local issuerId = rcGetIssuerId(p.m_stock.m_strMarket, p.m_stock.m_strCode)
                        if nil == factorThisSum[iFactor][issuerId] then
                            factorThisSum[iFactor][issuerId] = 0
                        end
                        factorThisSum[iFactor][issuerId] = factorThisSum[iFactor][issuerId] + v
                    end
                end
            end
        end
    end

    --rcprintLog(m_strLogTag .. string.format('getWeightedSum_singleIssuer : factorSum = %s, factorThisSum = %s', table2jsonOld(factorSum), table2jsonOld(factorThisSum)))
    
    local res = {}
    local thisRes = {}
    for iFactor, factoryRes in pairs(factorSum) do
        for factoryId, factoryValue in pairs(factoryRes) do
            if nil == res[factoryId] then
                res[factoryId] = 0
            end
            res[factoryId] = res[factoryId] + factoryValue * factors[iFactor].m_dWeight
            if nil == thisRes[factoryId] then
                thisRes[factoryId] = 0
            end
        end
    end
    for iFactor, factoryRes in pairs(factorThisSum) do
        for factoryId,factoryValue in pairs(factoryRes) do
            if not (isExposure and isHedge) then
                if nil == res[factoryId] then
                    res[factoryId] = 0
                end
                res[factoryId] = res[factoryId] + factoryValue * factors[iFactor].m_dWeight
            end
            if nil == thisRes[factoryId] then
                thisRes[factoryId] = 0
            end
            thisRes[factoryId] = thisRes[factoryId] + factoryValue * factors[iFactor].m_dWeight
        end
    end

    local resIssuerId = {}
    local resValues = {}
    local resThisValues = {}
    for k, v in pairs(res) do
        if k ~= "" then
            --local issuerName = rcGetIssuerNameById(k)   -- issuerId 2 issuerName
            table.insert(resIssuerId, k)
            table.insert(resValues, v)
            table.insert(resThisValues, thisRes[k])
        end
    end

    rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum_singleIssuer : resValues = %s, resThisValues = %s, resFactorysLog = %s', table2jsonOld(resValues), table2jsonOld(resThisValues), table2jsonOld(resIssuerId)))
    return resIssuerId, resValues, resThisValues
end

-- 计算“产品在合约池内单品种的XXXX资产”
-- factors为资产范围为单品种的 资产类型指标 数组
-- 返回{品种1，品种2，...，品种n}，
--     {品种1的值，品种2的值，...，品种n的值}（已经将多个指标进行加权）,
--     {品种1的本次贡献的加权后的值，品种2的本次贡献的加权后的值，...，品种n的本次贡献的加权后的值}
function getWeightedSum_singleProduct(factors, param, isOrderInfo, fakeParams, isHedge)

    local factorNum = table.getn(factors)

    local acKeyToAccounts = {}
    local acKeyToParams = {}
    local keyToStock = {}

    local nExcludeCmdId = 0
    if m_bPollingRC then
        nExcludeCmdId = -1
    end
    -- 0. 把所有参数按account - vector<CStockInfoPtr>拆开
    if isOrderInfo then
        if param ~= nil and param.m_xtTag ~= nil and not m_bPollingRC and param.m_xtTag.m_nCommandID ~= nil then
            nExcludeCmdId = param.m_xtTag.m_nCommandID
        end

        local accounts = {}
        if CAccountInfo_NULL == param.m_accountInfo or nil == param.m_accountInfo then
            -- 对于轮询，应该用所有账号
            for i = 0, m_accountInfos:size() - 1, 1 do
                table.insert(accounts, m_accountInfos:at(i))
            end
        else
            table.insert(accounts, param.m_accountInfo)
        end

        for k, account in pairs(accounts) do
            local strAccountKey = account:getKey()
            if nil == acKeyToAccounts[strAccountKey] then
                acKeyToAccounts[strAccountKey] = account
                acKeyToParams[strAccountKey] = CStockInfoVec()
            end

            local stk = CStockInfo()
            stk.m_strMarket = param.m_strExchangeId
            stk.m_strProduct = param.m_strProductId
            stk.m_strCode = param.m_strInstrumentId
            stk.m_strName = param.m_strInstrumentName
            if m_bPollingRC then
                acKeyToParams[strAccountKey]:push_back(stk)
            end
            keyToStock[stk:getKey()] = stk
        end
    else
        for iParam = 0, param:size() - 1, 1 do
            local account = param:at(iParam).m_account
            local strAccountKey = account:getKey()
            if nil == acKeyToAccounts[strAccountKey] then
                acKeyToAccounts[strAccountKey] = account
                acKeyToParams[strAccountKey] = CStockInfoVec()
            end

            local stk = CStockInfo()
            stk.m_strMarket = param:at(iParam).m_stock.m_strMarket
            stk.m_strProduct = param:at(iParam).m_stock.m_strProduct
            stk.m_strCode = param:at(iParam).m_stock.m_strCode
            stk.m_strName = param:at(iParam).m_stock.m_strName
            if m_bPollingRC then
                acKeyToParams[strAccountKey]:push_back(stk)
            end
            keyToStock[stk:getKey()] = stk
        end
    end

    if fakeParams ~= nil and not m_bPollingRC then
        for iParam = 0, fakeParams:size() - 1, 1 do
            local account = fakeParams:at(iParam).m_account
            local stk = CStockInfo()
            stk.m_strMarket = fakeParams:at(iParam).m_stock.m_strMarket
            stk.m_strProduct = fakeParams:at(iParam).m_stock.m_strProduct
            stk.m_strCode = fakeParams:at(iParam).m_stock.m_strCode
            stk.m_strName = fakeParams:at(iParam).m_stock.m_strName
            keyToStock[stk:getKey()] = stk
        end
    end

    if not m_bPollingRC then
        local futureInfos = CStockInfoVec()
        local goldInfos = CStockInfoVec()

        for k, v in pairs(keyToStock) do
            if isGoldMarket(v.m_strMarket) then
                goldInfos:push_back(v)
            else
                futureInfos:push_back(v)
            end
        end

        for iAccount = 0, m_accountInfos:size() - 1, 1 do
            local accountInfo = m_accountInfos:at(iAccount)
            if (nil ~= accountInfo) and accountInfo.m_nBrokerType == AT_FUTURE then
                acKeyToParams[accountInfo:getKey()] = futureInfos
            elseif (nil ~= accountInfo) and accountInfo.m_nBrokerType == AT_GOLD then
                acKeyToParams[accountInfo:getKey()] = goldInfos
            elseif (nil ~= accountInfo) and (isStockAccount(accountInfo) or (AT_HUGANGTONG == accountInfo.m_nBrokerType))  then
                acKeyToParams[accountInfo:getKey()] = CStockInfoVec()
            end
        end
    end

    -- 1. 根据现有持仓或账号数据得到的结果
    local factorSum = {}
    local factorThisSum = {}

    for iFactor = 1, factorNum, 1 do

        local factor = factors[iFactor]
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags 
        end
        factorSum[iFactor] = {}
        factorThisSum[iFactor] = {}

        for iAccount = 0, m_accountInfos:size() - 1, 1 do
            local account = m_accountInfos:at(iAccount)
            local stocks = acKeyToParams[account:getKey()]
            if nil ~= stocks then
                if XT_RCF_POSITION_MARGIN_SINGLE ~= factor.m_nIndexID then
                    local valueRes = rcGetAccountSingleProductIndexes(account, stocks, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                    for iProduct = 0, valueRes:size() - 1, 1 do
                        local res = valueRes:at(iProduct)
                        local strProductId = res.m_strName
                        local oneValueRes = res.m_dParamRes
                        if not isInvalidDouble(oneValueRes) then
                            if nil == factorSum[iFactor][strProductId] then
                                factorSum[iFactor][strProductId] = 0
                            end
                            factorSum[iFactor][strProductId] = factorSum[iFactor][strProductId] + oneValueRes
                        end
                    end
                elseif XT_RCF_POSITION_MARGIN_SINGLE == factor.m_nIndexID then     -- 单边保证金的下单影响特殊处理，在这里计算
                    local paramList = createParamList(0)
                    if isOrderInfo then
                        --local valueRes = rcGetAccountSingleMarginEachProduct(account, stocks, factor.m_nID, paramList, param, nExcludeCmdId)
                        local valueRes = rcGetAccountParamSingleMarginEachProduct(account, stocks, factor.m_nID, paramList, param, nExcludeCmdId)

                        for iProduct = 0, valueRes:size() - 1, 1 do
                            local res = valueRes:at(iProduct)
                            local productId = res.m_strName
                            local oneValueRes = res.m_dParamRes
                            local oneValueThis = res.m_dThisRes

                            if not isInvalidDouble(oneValueRes) then
                                if nil == factorSum[iFactor][productId] then
                                    factorSum[iFactor][productId] = 0
                                end
                                factorSum[iFactor][productId] = factorSum[iFactor][productId] + oneValueRes
                            end
                            if not isInvalidDouble(oneValueThis) then
                                if nil == factorThisSum[iFactor][productId] then
                                    factorThisSum[iFactor][productId] = 0
                                end
                                factorThisSum[iFactor][productId] = factorThisSum[iFactor][productId] + oneValueThis
                            end
                        end
                    else
                        --paramList.m_params = param
                        local valueRes = rcGetAccountParamSingleMarginEachProduct(account, stocks, factor.m_nID, param, COrderInfo(), nExcludeCmdId)

                        for iProduct = 0, valueRes:size() - 1, 1 do
                            local res = valueRes:at(iProduct)
                            local productId = res.m_strName
                            local oneValueRes = res.m_dParamRes
                            local oneValueThis = res.m_dThisRes

                            if not isInvalidDouble(oneValueRes) then
                                if nil == factorSum[iFactor][productId] then
                                    factorSum[iFactor][productId] = 0
                                end
                                factorSum[iFactor][productId] = factorSum[iFactor][productId] + oneValueRes
                            end
                            if not isInvalidDouble(oneValueThis) then
                                if nil == factorThisSum[iFactor][productId] then
                                    factorThisSum[iFactor][productId] = 0
                                end
                                factorThisSum[iFactor][productId] = factorThisSum[iFactor][productId] + oneValueThis
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. 根据下单参数得到的结果
    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags
        end

        if XT_RCF_POSITION_MARGIN_SINGLE ~= factor.m_nIndexID then  -- 单边保证金在上边特殊处理了
            factorThisSum[iFactor] = {}

            if XT_RCF_CODE_FLOAT_VOLUME ~= factor.m_nIndexID and
                XT_RCF_CODE_TOTAL_VOLUME ~= factor.m_nIndexID and
                XT_RCF_CODE_FLOAT_AMOUNT ~= factor.m_nIndexID and
                XT_RCF_CODE_TOTAL_AMOUNT ~= factor.m_nIndexID then
                if isOrderInfo then
                    -- 委托对指标的贡献
                    if rcIsStockInCategory(param.m_strExchangeId, param.m_strInstrumentId, param.m_strInstrumentName, factor.m_nID) then
                        local v = rcGetEntrustIndex(param, factor.m_nID, factor.m_nIndexID, hedgeFlags)
                        if not isInvalidDouble(v) then
                            factorThisSum[iFactor][param.m_strProductId] = v
                        end
                    end
                else
                    -- 指令对指标的贡献
                    for iParam = 0, param:size() - 1, 1 do
                        local p = param:at(iParam)
                        if rcIsStockInCategory(p.m_stock.m_strMarket, p.m_stock.m_strCode, p.m_stock.m_strName, factor.m_nID) then
                            local v = rcGetCommandIndex(p, factor.m_nID, factor.m_nIndexID, hedgeFlags)
                            if not isInvalidDouble(v) then
                                local productId = param:at(iParam).m_stock.m_strProduct
                                if nil == factorThisSum[iFactor][productId] then
                                    factorThisSum[iFactor][productId] = 0
                                end
                                factorThisSum[iFactor][productId] = factorThisSum[iFactor][productId] + v
                            end
                        end
                    end
                end
            end
        end
    end

    -- 汇总
    local isExposure = isExposureAssetsFactors(factors)
    local res = {}
    local thisRes = {}
    for iFactor, productRes in pairs(factorSum) do
        for productId, productValue in pairs(productRes) do
            if nil == res[productId] then
                res[productId] = 0
            end
            res[productId] = res[productId] + productValue * factors[iFactor].m_dWeight
            if nil == thisRes[productId] then
                thisRes[productId] = 0
            end
        end
    end
    for iFactor, productRes in pairs(factorThisSum) do
        for productId, productValue in pairs(productRes) do
            if not (isExposure and isHedge) then
                if nil == res[productId] then
                    res[productId] = 0
                end
                if XT_RCF_POSITION_MARGIN_SINGLE ~= factors[iFactor].m_nIndexID then
                    res[productId] = res[productId] + productValue * factors[iFactor].m_dWeight
                end
            end

            if nil == thisRes[productId] then
                thisRes[productId] = 0
            end
            thisRes[productId] = thisRes[productId] + productValue * factors[iFactor].m_dWeight
        end
    end

    local resProducts = {}
    local resValues = {}
    local resThisValues = {}
    for k, v in pairs(res) do
        if k ~= "" then
            table.insert(resProducts, k)
            table.insert(resValues, v)
            table.insert(resThisValues, thisRes[k])
        end
    end

    rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum_singleProduct : resValues = %s, resThisValues = %s, resProductsLog = %s', table2jsonOld(resValues), table2jsonOld(resThisValues), table2jsonOld(resProducts)))
    return resProducts, resValues, resThisValues
end

-- 计算“产品在股票池内单支股票的XXXX资产”
-- factors为资产范围为单只的 资产类型指标 数组
-- 返回{合约1，合约2，...，合约n}，
--     {合约1的值，合约2的值，...，合约n的值}（已经将多个指标进行加权）,
--     {合约1的本次贡献的加权后的值，合约2的本次贡献的加权后的值，...，合约n的本次贡献的加权后的值}
function getWeightedSum_singleStock(factors, param, isOrderInfo, fakeParams, isHedge)
    local d0 = clockMSec()
    local factorNum = table.getn(factors)

    local acKeyToAccounts = {}
    local acKeyToParams = {}
    local keyToStock = {}

    local nExcludeCmdId = 0
    if m_bPollingRC then
        nExcludeCmdId = -1
    end
    -- 0. 把所有参数按account - vector<CStockInfoPtr>拆开
    if isOrderInfo then
        if param ~= nil and param.m_xtTag ~= nil and not m_bPollingRC and param.m_xtTag.m_nCommandID ~= nil then
            nExcludeCmdId = param.m_xtTag.m_nCommandID
        end

        local accounts = {}
        if CAccountInfo_NULL == param.m_accountInfo or nil == param.m_accountInfo then
            -- 对于轮询，应该用所有账号
            for i = 0, m_accountInfos:size() - 1, 1 do
                table.insert(accounts, m_accountInfos:at(i))
            end
        else
            table.insert(accounts, param.m_accountInfo)
        end

        for k, account in pairs(accounts) do
            local strAccountKey = account:getKey()
            if nil == acKeyToAccounts[strAccountKey] then
                acKeyToAccounts[strAccountKey] = account
                acKeyToParams[strAccountKey] = CStockInfoVec()
            end

            local stk = CStockInfo()
            stk.m_strMarket = param.m_strExchangeId
            stk.m_strProduct = param.m_strProductId
            stk.m_strCode = param.m_strInstrumentId
            stk.m_strName = param.m_strInstrumentName
            if m_bPollingRC then
                acKeyToParams[strAccountKey]:push_back(stk)
            end
            keyToStock[stk:getKey()] = stk
        end
    else
        for iParam = 0, param:size() - 1, 1 do
            local account = param:at(iParam).m_account
            local strAccountKey = account:getKey()
            if nil == acKeyToAccounts[strAccountKey] then
                acKeyToAccounts[strAccountKey] = account
                acKeyToParams[strAccountKey] = CStockInfoVec()
            end

            local stk = CStockInfo()
            stk.m_strMarket = param:at(iParam).m_stock.m_strMarket
            stk.m_strProduct = param:at(iParam).m_stock.m_strProduct
            stk.m_strCode = param:at(iParam).m_stock.m_strCode
            stk.m_strName = param:at(iParam).m_stock.m_strName
            if m_bPollingRC then
                acKeyToParams[strAccountKey]:push_back(stk)
            end
            keyToStock[stk:getKey()] = stk
        end
    end

    local d1 = clockMSec()

    if fakeParams ~= nil and fakeParams:size() > 1 and not m_bPollingRC then
        for iParam = 0, fakeParams:size() - 1, 1 do
            local account = fakeParams:at(iParam).m_account
            local stk = CStockInfo()
            stk.m_strMarket = fakeParams:at(iParam).m_stock.m_strMarket
            stk.m_strProduct = fakeParams:at(iParam).m_stock.m_strProduct
            stk.m_strCode = fakeParams:at(iParam).m_stock.m_strCode
            stk.m_strName = fakeParams:at(iParam).m_stock.m_strName
            keyToStock[stk:getKey()] = stk
        end
    end

    local d2 = clockMSec()

    if not m_bPollingRC then
        local stockInfos = CStockInfoVec()
        local futureInfos = CStockInfoVec()
        local goldInfos = CStockInfoVec()

        for k, v in pairs(keyToStock) do
            if isStockMarket(v.m_strMarket) or isNew3BoardMarket(v.m_strMarket) or isStockOptionMarket(v.m_strMarket) or isHGTMarket(v.m_strMarket) then
                stockInfos:push_back(v)
            elseif isGoldMarket(v.m_strMarket) then
                goldInfos:push_back(v)
            else
                futureInfos:push_back(v)
            end
        end

        for iAccount = 0, m_accountInfos:size() - 1, 1 do
            local accountInfo = m_accountInfos:at(iAccount)
            if (nil ~= accountInfo) and accountInfo.m_nBrokerType == AT_FUTURE then
                acKeyToParams[accountInfo:getKey()] = futureInfos
            elseif (nil ~= accountInfo) and accountInfo.m_nBrokerType == AT_GOLD then
                acKeyToParams[accountInfo:getKey()] = goldInfos
            elseif (nil ~= accountInfo) and (isStockAccount(accountInfo) or (AT_HUGANGTONG == accountInfo.m_nBrokerType)) then
                acKeyToParams[accountInfo:getKey()] = stockInfos
            end
        end
    end

    local d3 = clockMSec()

    -- 1. 根据现有持仓或账号数据得到的结果
    local factorSum = {}
    local factorThisSum = {}

    for iFactor = 1, factorNum, 1 do

        local factor = factors[iFactor]
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags
        end
        factorSum[iFactor] = {}
        factorThisSum[iFactor] = {}

        local oneBreak = (XT_RCF_CODE_FLOAT_VOLUME == factor.m_nIndexID
                            or XT_RCF_CODE_TOTAL_VOLUME == factor.m_nIndexID
                            or XT_RCF_CODE_TODAY_DEAL_VOLUME == factor.m_nIndexID
                            or XT_RCF_CODE_FLOAT_AMOUNT == factor.m_nIndexID
                            or XT_RCF_CODE_TOTAL_AMOUNT == factor.m_nIndexID
                            or XT_RCF_POSITION_STOCK_NUM == factor.m_nIndexID
                            or XT_RCF_CODE_OPEN_INTEREST == factor.m_nIndexID)

        if XT_RCF_POSITION_MARGIN_SINGLE ~= factor.m_nIndexID then
            if PRODUCT_ID_SPECIAL_ALL == m_nProductId and (not isOrderInfo) then
                -- 针对全局资产比较风控进行特殊优化，不遍历账号了
                local valueRes = rcGetGlobalSingleStockIndexes(param, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                for iInstrument = 0, valueRes:size() - 1, 1 do
                    local res = valueRes:at(iInstrument)
                    local strInstrumentId = res.m_strName
                    local oneValueRes = res.m_dParamRes
                    -- 只统计非“非法值”的结果
                    -- 并且对于类似“流通盘”之类的数据，每支股票只统计一次，不能相加
                    if (not isInvalidDouble(oneValueRes)) and (nil == factorSum[iFactor][strInstrumentId] or (not oneBreak)) then
                        if nil == factorSum[iFactor][strInstrumentId] then
                            factorSum[iFactor][strInstrumentId] = 0
                        end
                        factorSum[iFactor][strInstrumentId] = factorSum[iFactor][strInstrumentId] + oneValueRes
                    end
                end
            else
                for iAccount = 0, m_accountInfos:size() - 1, 1 do
                    local account = m_accountInfos:at(iAccount)
                    local stocks = acKeyToParams[account:getKey()]
                    if nil ~= stocks and stocks:size() > 0 then
                        local valueRes = rcGetAccountSingleStockIndexes(account, stocks, factor.m_nID, factor.m_nIndexID, hedgeFlags, nExcludeCmdId)
                        for iInstrument = 0, valueRes:size() - 1, 1 do
                            local res = valueRes:at(iInstrument)
                            local strInstrumentId = res.m_strName
                            local oneValueRes = res.m_dParamRes
                            local stkPtr = res.m_stockInfoPtr
                            -- 只统计非“非法值”的结果
                            -- 并且对于类似“流通盘”之类的数据，每支股票只统计一次，不能相加
                            if nil == factorSum[iFactor][strInstrumentId] then
                                factorSum[iFactor][strInstrumentId] = 0
                                if nil ~= stkPtr and CStockInfo_NULL ~= stkPtr then
                                    keyToStock[stkPtr:getKey()] = stkPtr
                                end
                            end
                            if (nil ~= oneValueRes and not isInvalidDouble(oneValueRes)) and ((not oneBreak) or (oneBreak and (not isZero(oneValueRes) and isZero(factorSum[iFactor][strInstrumentId])))) then
                                
                                factorSum[iFactor][strInstrumentId] = factorSum[iFactor][strInstrumentId] + oneValueRes
                                if nil ~= stkPtr and CStockInfo_NULL ~= stkPtr then
                                    keyToStock[stkPtr:getKey()] = stkPtr
                                end
                            end
                        end
                    end
                end
            end
        elseif XT_RCF_POSITION_MARGIN_SINGLE == factor.m_nIndexID then     -- 单边保证金的下单影响特殊处理，在这里计算                for iAccount = 0, m_accountInfos:size() - 1, 1 do
            for iAccount = 0, m_accountInfos:size() - 1, 1 do
                local account = m_accountInfos:at(iAccount)
                local stocks = acKeyToParams[account:getKey()]
                if nil ~= stocks and stocks:size() > 0 then
                    local paramList = createParamList(0)
                    if isOrderInfo then
                        local valueRes = rcGetAccountParamSingleMarginEachInstrument(account, stocks, factor.m_nID, paramList, param, nExcludeCmdId)

                        for iInstrument = 0, valueRes:size() - 1, 1 do
                            local res = valueRes:at(iInstrument)
                            local strInstrumentId = res.m_strName
                            local oneValueRes = res.m_dParamRes
                            local oneValueThis = res.m_dThisRes

                            if not isInvalidDouble(oneValueRes) then
                                if nil == factorSum[iFactor][strInstrumentId] then
                                    factorSum[iFactor][strInstrumentId] = 0
                                end
                                factorSum[iFactor][strInstrumentId] = factorSum[iFactor][strInstrumentId] + oneValueRes
                            end
                            if not isInvalidDouble(oneValueThis) then
                                if nil == factorThisSum[iFactor][strInstrumentId] then
                                    factorThisSum[iFactor][strInstrumentId] = 0
                                end
                                factorThisSum[iFactor][strInstrumentId] = factorThisSum[iFactor][strInstrumentId] + oneValueThis
                            end
                        end
                    else
                        local valueRes = rcGetAccountParamSingleMarginEachInstrument(account, stocks, factor.m_nID, param, COrderInfo(), nExcludeCmdId)

                        for iInstrument = 0, valueRes:size() - 1, 1 do
                            local res = valueRes:at(iInstrument)
                            local strInstrumentId = res.m_strName
                            local oneValueRes = res.m_dParamRes
                            local oneValueThis = res.m_dThisRes

                            if not isInvalidDouble(oneValueRes) then
                                if nil == factorSum[iFactor][strInstrumentId] then
                                    factorSum[iFactor][strInstrumentId] = 0
                                end
                                factorSum[iFactor][strInstrumentId] = factorSum[iFactor][strInstrumentId] + oneValueRes
                            end
                            if not isInvalidDouble(oneValueThis) then
                                if nil == factorThisSum[iFactor][strInstrumentId] then
                                    factorThisSum[iFactor][strInstrumentId] = 0
                                end
                                factorThisSum[iFactor][strInstrumentId] = factorThisSum[iFactor][strInstrumentId] + oneValueThis
                            end
                        end
                    end
                end
            end
        end
    end

    local d4 = clockMSec()

    -- 2. 根据下单参数得到的结果
    for iFactor = 1, factorNum, 1 do

        local factor = factors[iFactor]
        local hedgeFlags = {HEDGE_FLAG_SPECULATION, HEDGE_FLAG_ARBITRAGE, HEDGE_FLAG_HEDGE}
        if factor.m_hedgeFlags ~= nil and table.maxn(factor.m_hedgeFlags) ~= 0 then
            hedgeFlags = factor.m_hedgeFlags
        end

        if XT_RCF_POSITION_MARGIN_SINGLE ~= factor.m_nIndexID then  -- 单边保证金在上边特殊处理了
            factorThisSum[iFactor] = {}

            if XT_RCF_CODE_FLOAT_VOLUME ~= factor.m_nIndexID and
                XT_RCF_CODE_TOTAL_VOLUME ~= factor.m_nIndexID and
                XT_RCF_CODE_FLOAT_AMOUNT ~= factor.m_nIndexID and
                XT_RCF_CODE_TOTAL_AMOUNT ~= factor.m_nIndexID then
                if isOrderInfo then
                    -- 委托对指标的贡献
                    local stk = CStockInfo()
                    stk.m_strMarket = param.m_strExchangeId
                    stk.m_strProduct = param.m_strProductId
                    stk.m_strCode = param.m_strInstrumentId
                    stk.m_strName = param.m_strInstrumentName
                    if nil ~= keyToStock[stk:getKey()] and
                        isMyAccountOrder(m_accountInfo, param) and
                        rcIsStockInCategory(stk.m_strMarket, stk.m_strCode, stk.m_strName, factor.m_nID) then -- 如果为nil表示getOperation判断没过，比如平仓单
                        local v = rcGetEntrustIndex(param, factor.m_nID, factor.m_nIndexID, hedgeFlags)
                        if not isInvalidDouble(v) then
                            factorThisSum[iFactor][stk:getKey()] = v
                        end
                    end
                else
                    -- 指令对指标的贡献
                    for iParam = 0, param:size() - 1, 1 do
                        local p = param:at(iParam)
                        local stk = CStockInfo()
                        stk.m_strMarket = p.m_stock.m_strMarket
                        stk.m_strProduct = p.m_stock.m_strProduct
                        stk.m_strCode = p.m_stock.m_strCode
                        stk.m_strName = p.m_stock.m_strName
                        local strStockKey = stk:getKey()
                        if nil ~= keyToStock[strStockKey] and
                            isMyAccount(m_accountInfo, p) and
                            rcIsStockInCategory(stk.m_strMarket, stk.m_strCode, stk.m_strName, factor.m_nID) then -- 如果为nil表示getOperation判断没过，比如平仓单
                            local v = rcGetCommandIndex(p, factor.m_nID, factor.m_nIndexID, hedgeFlags)
                            if not isInvalidDouble(v) then
                                if nil == factorThisSum[iFactor][strStockKey] then
                                    factorThisSum[iFactor][strStockKey] = 0
                                end
                                factorThisSum[iFactor][strStockKey] = factorThisSum[iFactor][strStockKey] + v
                            end
                        end
                    end
                end
            end
        end
    end

    local d5 = clockMSec()
    local isExposure = isExposureAssetsFactors(factors)
    -- 汇总
    local res = {}
    local thisRes = {}
    for iFactor, stkRes in pairs(factorSum) do
        for stkKey, stkValue in pairs(stkRes) do
            if nil == res[stkKey] then
                res[stkKey] = 0
            end
            res[stkKey] = res[stkKey] + stkValue * factors[iFactor].m_dWeight
            if nil == thisRes[stkKey] then
                thisRes[stkKey] = 0
            end
        end
    end
    for iFactor, stkRes in pairs(factorThisSum) do
        for stkKey, stkValue in pairs(stkRes) do
            if not (isExposure and isHedge) then
                if nil == res[stkKey] then
                    res[stkKey] = 0
                end
                if XT_RCF_POSITION_MARGIN_SINGLE ~= factors[iFactor].m_nIndexID then
                    res[stkKey] = res[stkKey] + stkValue * factors[iFactor].m_dWeight
                end
            end

            if nil == thisRes[stkKey] then
                thisRes[stkKey] = 0
            end
            thisRes[stkKey] = thisRes[stkKey] + stkValue * factors[iFactor].m_dWeight
        end
    end

    local d6 = clockMSec()

    local resStocksLog = {}
    local resStocks = {}
    local resStocksReal = {}
    local resValues = {}
    local resThisValues = {}
    -- rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum_singleStock : Begin to enter the loop'))
    for k, v in pairs(res) do
        -- rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum_singleStock : getWeightedSum_singleStock : sum = %d ', sum))
        -- if sum > 0 then -- 解决bug：配“所有证券+单支期货”时，只有期货IF1401有持仓无证券持仓，结果提示“对于IF1401”……
        -- 但是会导致对“单支XXX成交量”调仓，量为0的code不输出，
        -- 则调仓函数时传入的market code为空，会当成“全部”去调仓，一直调不对。
        table.insert(resStocksLog, k)
        if nil ~= keyToStock[k] then        -- 理论上 if nil ~= keyToStock[stk:getKey()] 的判断已经解决问题了，为了保证下午大华系数投资不再出错，再作一个容错
            table.insert(resStocks, keyToStock[k].m_strCode)
            table.insert(resStocksReal, keyToStock[k])
        else
            table.insert(resStocks, "")
            table.insert(resStocksReal, CStockInfo())
        end
        table.insert(resValues, v)
        table.insert(resThisValues, thisRes[k])
        -- end
    end

    local d7 = clockMSec()

    rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum_singleStock : resValues = %s, resThisValues = %s, resStocksLog = %s', table2jsonOld(resValues), table2jsonOld(resThisValues), table2jsonOld(resStocksLog)))
    if not m_bPollingRC and not isOrderInfo then
        rcprintLog(m_strLogTag .. string.format('getWeightedSum_singleStock : time = %f (01=%f 12=%f 23=%f 34=%f 45=%f 56=%f 67=%f), account_num = %f, factor_num = %f, param_num = %f', (d7 - d0), (d1 - d0), (d2 - d1), (d3 - d2), (d4 - d3), (d5 - d4), (d6 - d5), (d7 - d6), m_accountInfos:size(), factorNum, param:size()))
    end
    return resStocks, resValues, resThisValues, resStocksReal
end

function passCondition(triggerCondition, description)
    if triggerCondition and triggerCondition.m_bEnabled then
        if triggerCondition.m_value ~= nil and table.getn(triggerCondition.m_value) ~= 0 then
            local condValue, thisCond = getWeightedSum_allStocks(triggerCondition.m_value, CCodeOrderParamList().m_params, false, false)
            if isInvalidDouble(condValue) then
                return false
            else
                return isValueInRange(condValue, triggerCondition.m_limitRange)
            end
        elseif triggerCondition.m_limitType ~= nil then     -- 兼容国金0508旧的止损风控配置
            local dNetValue = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_NAV)
            if isInvalidDouble(dNetValue) then
                return false
            else
                return isValueInRange(dNetValue, triggerCondition.m_limitRange)
            end
        end
    end
    return true
end

function getFactorType(factor)
    if XT_RIR_CODE == factor.m_nScope then
        return CONFIG_TYPE_SINGLE_STOCK
    elseif XT_RIR_PRODUCT == factor.m_nScope then
        return CONFIG_TYPE_SINGLE_PRODUCT
    elseif factor.m_nID == XT_RCC_SYSTEM_SPECIAL_PRODUCT then
        return CONFIG_TYPE_PRODUCT_PROPERTY
    elseif XT_RIR_FACTORY == factor.m_nScope then
        return CONFIG_TYPE_SINGLE_FACTORY
    else
        return CONFIG_TYPE_PRODUCT_ASSETS
    end
end

function getWeightedSum(factors, param, isOrderInfo, isHedge)

    local factorNum = table.getn(factors)

    -- 将因子分类
    local allStockFactors = {}
    local singleStockFactors = {}
    local singleProductFactors = {}
    local singleFactoryFactors = {}

    for iFactor = 1, factorNum, 1 do
        local factor = factors[iFactor]
        local factorType = getFactorType(factor)
        if CONFIG_TYPE_PRODUCT_ASSETS == factorType or CONFIG_TYPE_PRODUCT_PROPERTY == factorType then
            table.insert(allStockFactors, factor)
        elseif CONFIG_TYPE_SINGLE_STOCK == factorType then
            table.insert(singleStockFactors, factor)
        elseif CONFIG_TYPE_SINGLE_PRODUCT == factorType then
            table.insert(singleProductFactors, factor)
        elseif CONFIG_TYPE_SINGLE_FACTORY == factorType then
            table.insert(singleFactoryFactors, factor)
        end
    end

    -- 分别计算
    local allStock_res = 0.0
    local allStock_thisRes = 0.0
    if next(allStockFactors) ~= nil then
        allStock_res, allStock_thisRes = getWeightedSum_allStocks(allStockFactors, param, isOrderInfo, isHedge)  -- 得到一个number
    end

    local fakeParams = nil
    if not m_bPollingRC and allStock_thisRes ~= 0 and ( table.getn(singleStockFactors) > 0 or table.getn(singleProductFactors) > 0 or table.getn(singleFactoryFactors) > 0 ) then
        fakeParams = position2FakeParam(m_accountInfos, factors, param, isOrderInfo)
    end

    local singleStock_stocks, singleStock_res, singleStock_thisRes, singleStock_stocksReal = getWeightedSum_singleStock(singleStockFactors, param, isOrderInfo, fakeParams, isHedge)
    local singleProduct_products, singleProduct_res, singleProduct_thisRes = getWeightedSum_singleProduct(singleProductFactors, param, isOrderInfo, fakeParams, isHedge)
    local singleFactory_factorys, singleFactory_res, singleFactory_thisRes = getWeightedSum_singleIssuer(singleFactoryFactors, param, isOrderInfo, fakeParams, isHedge)

    -- 两类结果加乘
    local stockNum = table.getn(singleStock_res)
    local productNum = table.getn(singleProduct_res)
    local factoryNum = table.getn(singleFactory_res)

    if 0 == stockNum and 0 == productNum and 0 == factoryNum then
        rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum : use ALL : allStock_res = %f, allStock_thisRes = %f', allStock_res, allStock_thisRes))
        return { nil }, { allStock_res }, { allStock_thisRes }, { nil }, CONFIG_TYPE_PRODUCT_ASSETS
    elseif stockNum > 0 then
        for i = 1, stockNum, 1 do
            singleStock_res[i] = singleStock_res[i] + allStock_res
            singleStock_thisRes[i] = singleStock_thisRes[i] + allStock_thisRes
        end
        rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum : use SINGLE STOCK : singleStock_res = %s, singleStock_thisRes = %s', table2jsonOld(singleStock_res), table2jsonOld(singleStock_thisRes)))
        return singleStock_stocks, singleStock_res, singleStock_thisRes, singleStock_stocksReal, CONFIG_TYPE_SINGLE_STOCK
    elseif productNum > 0 then
        for i = 1, productNum, 1 do
            singleProduct_res[i] = singleProduct_res[i] + allStock_res
            singleProduct_thisRes[i] = singleProduct_thisRes[i] + allStock_thisRes
        end
        rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum : use SINGLE PRODUCT : singleProduct_res = %s, singleProduct_thisRes = %s', table2jsonOld(singleProduct_res), table2jsonOld(singleProduct_thisRes)))
        return singleProduct_products, singleProduct_res, singleProduct_thisRes, singleProduct_products, CONFIG_TYPE_SINGLE_PRODUCT
    elseif factoryNum > 0 then
        for i = 1, factoryNum, 1 do
            singleFactory_res[i] = singleFactory_res[i] + allStock_res
            singleFactory_thisRes[i] = singleFactory_thisRes[i] + allStock_thisRes
        end
        rcprintLog(m_strLogTag .. string.format('getWeightedSum : use SINGLE ISSUER : singleFactory_res = %s, singleFactory_thisRes = %s', table2jsonOld(singleFactory_res), table2jsonOld(singleFactory_thisRes)))
        return singleFactory_factorys, singleFactory_res, singleFactory_thisRes, singleFactory_factorys, CONFIG_TYPE_SINGLE_FACTORY
    else
        rcprintDebugLog(m_strLogTag .. string.format('getWeightedSum : use ALL 2 : allStock_res = %f, allStock_thisRes = %f', allStock_res, allStock_thisRes))
        return { nil }, { allStock_res }, { allStock_thisRes }, { nil }, CONFIG_TYPE_PRODUCT_ASSETS
    end
end

-- @brief 生成资产比例风控的警告或调仓消息
-- @param[in] msgOption 消息生成选项table
-- @note msgOption.isProportion 是否按照占比显示警告消息
-- @note msgOption.isMultipled 是否按照倍率显示警告消息
-- @note msgOption.isPolling 是否在轮询中生成警告消息
-- @note msgOption.isPositiveTrend 指令是否使占比或值向预设区间改变
-- @note msgOption.netValueDisplay 是否显示产品单位净值
-- @node msgOption.typeName 以什么类型分档（单位净值，产品可用资金等等）
-- @note msgOption.isSingle        是否属于单只或单品种
-- @note msgOption.nProductId      产品ID
-- @note msgOption.nAssetsRcId     风控项ID
-- @note msgOption.key             单只或单品种的key
-- @param[in] msgHeader 消息首部
-- @param[in] rcType 风控项类型
-- @param[in] rcName 风控项名称
-- @param[in] strUnit 单只内容
-- @param[in] rate_value 比例或值
-- @param[in] multiple 乘数因子
-- @param[in] netValue 产品单位净值
-- @param[in] rangeMsg 范围字符串
-- @return 警告信息
local function genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, rate_value, multiple, netValue, rangeMsg)
    local commonHeader = msgHeader .. ' 风控规则 ' .. rcType .. rcName
    local rateOrValue = ''
    local multipleFactor = ''
    local tense = ''
    local target = ''
    local positiveMsg = ''
    local netValueMsg = ''
    local conclusion = ''
    local uninitedMsg = ''

    if not msgOption then
        return ''
    end

    if msgOption.isProportion then
        rateOrValue = string.format('%s占比', strUnit)
        target = string.format('%.4f%%', rate_value * 100)
        retType = '占比'
    else
        rateOrValue = string.format('%s资产组合', strUnit)
        target = string.format('%.4f', rate_value)
        retType = '资产组合'
        msgOption.isProportion = false  -- 消灭nil
    end

    if msgOption.isPolling then
        tense = '已'
    else
        tense = '将'
        conclusion = ', 禁止交易!'
    end

    if msgOption.isMultipled then
        multipleFactor = string.format('的%.4f倍', multiple)
        conclusion = ', 警告提示!'
    end

    if msgOption.isPositiveTrend then
        positiveMsg = '超限部分减少, 仍'
        conclusion = ''
    end

    if msgOption.netValueDisplay then
        if msgOption.typeName and string.len(msgOption.typeName) ~= 0 then
            netValueMsg = string.format('当前%s%.4f',msgOption.typeName,netValue)
        else
            netValueMsg = string.format('当前单位净值%.4f', netValue)
        end
    end

    if PRODUCT_ID_SPECIAL_ALL == m_nProductId then
        local uninitedAccounts = rcGetProductUnInitedAccounts(m_nProductId)
        if 0 ~= uninitedAccounts:size() then
            uninitedMsg = genUnInitedAccountsMsg('全局', uninitedAccounts) .. ', 估算'
        end
    end

    if msgOption.isPolling and msgOption.isSingle and msgOption.nProductId and msgOption.nAssetsRcId and msgOption.key and msgOption.key ~= '' then
        local strHeader = string.format('%s%s', commonHeader, uninitedMsg)
        local strMiddle = string.format('%s%s%s', retType, multipleFactor, tense)
        local strTail = string.format(', %s不在%s允许范围%s%s', positiveMsg, netValueMsg, rangeMsg, conclusion)
        local isMultipled = false
        if msgOption.isMultipled then isMultipled = true end
        if m_accountInfo ~= nil then
            rcUpdateAssetsSingleMsg(msgOption.nProductId, msgOption.nAssetsRcId, msgOption.isProportion, msgOption.key, strHeader, strMiddle, strTail, multiple, m_accountInfo, isMultipled)
        else
            rcUpdateAssetsSingleMsg(msgOption.nProductId, msgOption.nAssetsRcId, msgOption.isProportion, msgOption.key, strHeader, strMiddle, strTail, multiple, CAccountInfo(), isMultipled)
        end
    end

    strmsg = string.format('%s%s%s%s%s达到%s, %s不在%s允许范围%s%s', commonHeader, uninitedMsg, rateOrValue, multipleFactor, tense, target, positiveMsg, netValueMsg, rangeMsg, conclusion)
    return strmsg
end

local function assetsRcTypeString(rcType)
    if XT_ASSETS_RC_TYPE_LAW == rcType then
        return '[法规]'
    elseif XT_ASSETS_RC_TYPE_CONTRACT == rcType then
        return '[合同]'
    elseif XT_ASSETS_RC_TYPE_OPERATION == rcType then
        return '[操作]'
    else
        return '[其它类型]'
    end
end


local function isValidAssetsRate(rate, leftValid, leftClosed, minLimit, rightValid, rightClosed, maxLimit)

    if not leftValid and not rightValid then
        return true
    elseif not rightValid then
        if (leftClosed     and isLess(rate, minLimit)) or
           (not leftClosed and isLessEqual(rate, minLimit)) then
            return false
        else
            return true
        end
    elseif not leftValid then
        if (rightClosed     and isGreater(rate, maxLimit)) or
           (not rightClosed and isGreaterEqual(rate, maxLimit)) then
            return false
        else
            return true
        end
    else
        if (leftClosed      and isLess(rate, minLimit)) or
           (not leftClosed  and isLessEqual(rate, minLimit)) or
           (rightClosed     and isGreater(rate, maxLimit)) or
           (not rightClosed and isGreaterEqual(rate, maxLimit)) then
            return false
        else
            return true
        end
    end
end

local function isPositiveAssetsRateChange(prevRate, rate, leftValid, minLimit, rightValid, maxLimit)
    if not leftValid and not rightValid then
        return true
    elseif not rightValid then
        return isGreaterTick(rate, prevRate, POSITIVE_ASSETSRATE_EPSILON)
    elseif not leftValid then
        return isLessTick(rate, prevRate, POSITIVE_ASSETSRATE_EPSILON)
    else
        if isLessEqualTick(prevRate, minLimit, POSITIVE_ASSETSRATE_EPSILON) and isLessEqualTick(rate, minLimit, POSITIVE_ASSETSRATE_EPSILON) and isLessTick(prevRate, rate, POSITIVE_ASSETSRATE_EPSILON) then
            return true
        elseif isGreaterEqualTick(prevRate, maxLimit, POSITIVE_ASSETSRATE_EPSILON) and isGreaterEqualTick(rate, maxLimit, POSITIVE_ASSETSRATE_EPSILON) and isLessTick(rate, prevRate, POSITIVE_ASSETSRATE_EPSILON) then
            return true
        elseif isLessEqualTick(prevRate, minLimit, POSITIVE_ASSETSRATE_EPSILON) and isGreaterEqualTick(rate, maxLimit, POSITIVE_ASSETSRATE_EPSILON) and isLessTick(rate - maxLimit, minLimit - prevRate, POSITIVE_ASSETSRATE_EPSILON) then
            return true
        elseif isGreaterEqualTick(prevRate, maxLimit, POSITIVE_ASSETSRATE_EPSILON) and isLessEqualTick(rate, minLimit, POSITIVE_ASSETSRATE_EPSILON) and isLessTick(minLimit - rate, prevRate - maxLimit, POSITIVE_ASSETSRATE_EPSILON) then
            return true
        else
            return false
        end
    end
end

function getControlItemValue(netValueConfig)
    if netValueConfig then
        if netValueConfig.m_value ~= nil and table.getn(netValueConfig.m_value) ~= 0 then   -- 自定义分档
            local configValue ,thisCond = getWeightedSum_allStocks(netValueConfig.m_value, CCodeOrderParamList().m_params, false, false)
            if isInvalidDouble(configValue) then
                --todo  OK?
                rcprintDebugLog(m_strLogTag .. 'getControlItemValue : isInvalidDouble')
                return false,0
            else
                rcprintDebugLog(m_strLogTag .. 'getControlItemValue : configValue : ' .. tostring(configValue))
                return true,configValue
            end
            --支持默认单位净值的配置
        elseif m_bProductGroupRC then
            local net = rcGetProductGroupBasicIndex(m_nGroupId, XT_RCF_PRODUCTGROUP_NAV)
            return true,net
        else
            local netValue, bNetValue, totalNetValue = getProductNetValue(m_productInfo)
            rcprintDebugLog(m_strLogTag .. string.format('netValue = %s,bNetValue = %s,totalNetValue = %s',tostring(netValue),tostring(bNetValue),tostring(totalNetValue)))
            if PRODUCT_ID_SPECIAL_ALL ~= m_nProductId and PRODUCT_ID_PARENT_ACCOUNT ~= m_nProductId and PRODUCT_ID_ACCOUNT_GROUP ~= m_nProductId then
                if isZero(netValue) or isInvalidDouble(netValue) or isZero(totalNetValue) or isInvalidDouble(totalNetValue) then
                    return false,0
                end
            end
            local net = netValue
            return true,net
        end
    else
        return false,0
    end
end

function isPositiveDealWithWeightedSums(assetsRC, net, netValueRate, iRange, rate, prevRate, unit, msgHeader, enableDenominator)
    local strmsg = ''
    local enableWarn = assetsRC.m_netValueConfig.m_bEnableWarn
    local warnMultiple = assetsRC.m_netValueConfig.m_dWarn
    local rcName = assetsRC.m_description
    local rcType = assetsRcTypeString(assetsRC.m_type)

    local netValueRateStr = "{}"
    if type(netValueRate) == "table" then
        netValueRateStr = table2jsonOld(netValueRate)
    end

    local leftValid  = (XT_RLT_EX_INVALID ~= netValueRate.m_compMinType)
    local rightValid = (XT_RLT_EX_INVALID ~= netValueRate.m_compMaxType)
    local leftClosed  = (XT_RLT_EX_SMALLER_EQUAL == netValueRate.m_compMinType) --左区间是否闭合
    local rightClosed = (XT_RLT_EX_SMALLER_EQUAL == netValueRate.m_compMaxType) --右区间是否闭合
    local minLimit = -1.7e+300
    if leftValid then minLimit = netValueRate.m_min end
    local maxLimit = 1.7e+300
    if rightValid then maxLimit = netValueRate.m_max end

    rcprintDebugLog(m_strLogTag .. string.format('isPositiveDealWithWeightedSums: net_value = %f, rate = %f, prevRate = %f, netValueRate = %s', net, rate, prevRate, netValueRateStr))

    local prevRateValid = isValidAssetsRate(prevRate, leftValid, leftClosed, minLimit, rightValid, rightClosed, maxLimit)
    local rateValid = isValidAssetsRate(rate, leftValid, leftClosed, minLimit, rightValid, rightClosed, maxLimit)

    local strUnit = ', '
    if unit then
        strUnit = ', 对于' .. unit
        
        for iWeight = 1, table.getn(assetsRC.m_numerator), 1 do
            local wInfo = assetsRC.m_numerator[iWeight]
            if nil ~= wInfo and XT_RIR_FACTORY == wInfo.m_nScope then
                local issuerName = rcGetIssuerNameById(unit)
                strUnit = ', 对于发行方为' .. issuerName .. "的证券"
                break
            end
        end
    end

    local msgOption = {}
    msgOption.isProportion = enableDenominator
    msgOption.isMultipled = false
    msgOption.isPolling = false     -- 目前这个函数只在指令检查里调用
    msgOption.isPositiveTrend = false
    if PRODUCT_ID_SPECIAL_ALL == m_nProductId or PRODUCT_ID_PARENT_ACCOUNT == m_nProductId or PRODUCT_ID_ACCOUNT_GROUP == m_nProductId then
        msgOption.netValueDisplay = false
    else
        msgOption.netValueDisplay = true
    end

    local netValueConfigValue = assetsRC.m_netValueConfig.m_value
    if netValueConfigValue ~= nil and table.getn(netValueConfigValue) > 0 then
        if netValueConfigValue[1].name ~= nil and string.len(netValueConfigValue[1].name) ~= 0 then
            msgOption.typeName = netValueConfigValue[1].name
        else
            msgOption.typeName = '单位净值'
        end
    else
        msgOption.typeName = '单位净值'
    end

    local rangeMsg = ''
    if enableDenominator then
        if isZero(rate * 100) then
            rate = 0.0000
        end
        rangeMsg = genRangeMsg(minLimit, leftClosed, '占比', rightClosed, maxLimit, false)
    else
        if isZero(rate) then
            rate = 0.0000
        end
        rangeMsg = genRangeMsg(minLimit, leftClosed, '资产组合', rightClosed, maxLimit, true)
    end

    if prevRateValid and not rateValid then
        strmsg = genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, rate, 1, net, rangeMsg)
        -- rcprintDebugLog(m_strLogTag .. 'isPositiveDealWithWeightedSums: ' .. strmsg)
        return false, strmsg, 0, 0
    elseif not prevRateValid and not rateValid then
        if isPositiveAssetsRateChange(prevRate, rate, leftValid, minLimit, rightValid, maxLimit) then
            msgOption.isPositiveTrend = true
            strmsg = genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, rate, 1, net, rangeMsg)
            -- rcprintDebugLog(m_strLogTag .. 'isPositiveDealWithWeightedSums: ' .. strmsg)
            return true, strmsg, 0, 0
        else
            strmsg = genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, rate, 1, net, rangeMsg)
            -- rcprintDebugLog(m_strLogTag .. 'isPositiveDealWithWeightedSums: ' .. strmsg)
            return false, strmsg, 0, 0
        end
    else
        if enableWarn and (not isInvalidDouble(warnMultiple)) and warnMultiple ~= 0 then
            local warnRate = warnMultiple * rate
            if not isValidAssetsRate(warnRate, leftValid, leftClosed, minLimit, rightValid, rightClose, maxLimit) then
                --将实际比例进行警告倍数处理后，在区间之外，触发报警
                --todo,gui显示时，处理一下精度
                msgOption.isMultipled = true
                strmsg = genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, warnRate, warnMultiple, net, rangeMsg)
                -- rcprintDebugLog(m_strLogTag .. 'isPositiveDealWithWeightedSums: ' .. strmsg)
                -- zhangyi:
                -- 本函数只出现于check中，check的报警不走rcReport接口
                if m_bAccountRC then   --m_bAccountRC为true时，表示正在进行账号风控, 只针对该账号进行报警
                    rcReport(m_nProductId, m_accountInfo, strmsg)    -- 账号风控轮询
                else
                    rcReport(m_nProductId, CAccountInfo(), strmsg)    -- 产品风控轮询
                end
                return true, strmsg, 0, 0
            end
        else
            rcprintDebugLog(m_strLogTag .. 'not enableWarn or warnMultiple invalid, return true.')
        end
    end

    rcprintDebugLog(m_strLogTag .. '.... end, return success.')
    return true, strmsg, 0, 0
end

-- @param[in] unit 合约信息
function dealWithWeightedSums(param, isOrderInfo, assetsRC, net, netValueRate, iRange, rate, unit, msgHeader, isPolling, enableDenominator)
    local strmsg = ''
    local interval = assetsRC.m_randomDeduceInterval
    local enableWarn = assetsRC.m_netValueConfig.m_bEnableWarn
    local warnMultiple = assetsRC.m_netValueConfig.m_dWarn
    local rcName = assetsRC.m_description
    local rcType = assetsRcTypeString(assetsRC.m_type)

    local minNetValueStr = "{}"
    if type(minNetValue) == "table" then
        minNetValueStr = table2jsonOld(minNetValue)
    end

    local minNumber = -1.7e+300   --标记无穷小
    local maxNumber = 1.7e+300    --标记无穷大
    local netValueRate = minNetValue
    local leftValid  = (XT_RLT_EX_INVALID ~= netValueRate.m_compMinType)
    local rightValid = (XT_RLT_EX_INVALID ~= netValueRate.m_compMaxType)
    local minLimit = netValueRate.m_min
    local maxLimit = netValueRate.m_max
    if XT_RLT_EX_INVALID == netValueRate.m_compMinType then minLimit = minNumber end
    if XT_RLT_EX_INVALID == netValueRate.m_compMaxType then maxLimit = maxNumber end
    --assert(minLimit<=maxLimit)
    local leftClosed  = false --左区间是否闭合
    local rightClosed = false --右区间是否闭合
    if XT_RLT_EX_SMALLER_EQUAL == netValueRate.m_compMinType then leftClosed  = true end
    if XT_RLT_EX_SMALLER_EQUAL == netValueRate.m_compMaxType then rightClosed = true end

    local msgOption = {}
    msgOption.isProportion = enableDenominator
    msgOption.isMultipled = false
    msgOption.isPolling = isPolling
    msgOption.isPositiveTrend = false
    msgOption.nProductId = m_nProductId
    msgOption.nAssetsRcId = assetsRC.m_nID
    if PRODUCT_ID_SPECIAL_ALL == m_nProductId or PRODUCT_ID_PARENT_ACCOUNT == m_nProductId or PRODUCT_ID_ACCOUNT_GROUP == m_nProductId then
        msgOption.netValueDisplay = false
    else
        msgOption.netValueDisplay = true
    end

    local netValueConfigValue = assetsRC.m_netValueConfig.m_value
    if netValueConfigValue ~= nil and table.getn(netValueConfigValue) > 0 then
        if netValueConfigValue[1].name ~= nil and string.len(netValueConfigValue[1].name) ~= 0 then
            msgOption.typeName = netValueConfigValue[1].name
        else
            msgOption.typeName = '单位净值'
        end
    else
        msgOption.typeName = '单位净值'
    end

    local rangeMsg = ''
    if enableDenominator then
        if isZero(rate * 100) then
            rate = 0.0000
        end
        rangeMsg = genRangeMsg(minLimit, leftClosed, '占比', rightClosed, maxLimit, false)
    else
        if isZero(rate) then
            rate = 0.0000
        end
        rangeMsg = genRangeMsg(minLimit, leftClosed, '资产组合', rightClosed, maxLimit, true)
    end

    if not isValidAssetsRate(rate, leftValid, leftClosed, minLimit, rightValid, rightClosed, maxLimit) then
        rcprintDebugLog(m_strLogTag .. string.format('dealWithWeightedSums: inner 1: net_value = %f, rate = %f, minLimit = %f, maxLimit = %f, left_closed = %s, right_closed = %s, enableWarn = %s, warnMultiple = %f', net, rate, minLimit, maxLimit, tostring(leftClosed), tostring(rightClosed), tostring(enableWarn), warnMultiple))
        --在区间之外，触发报警或禁止开仓
        local strUnit = ', '
        if unit then
            strUnit = ', 对于' .. unit
            msgOption.isSingle = true
            msgOption.key = unit
        else
            msgOption.isSingle = false
        end
        strmsg = genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, rate, 1, net, rangeMsg)
        if (not isPolling) then
            -- 下单check：禁止开仓，客户端报警
            -- strmsg = strmsg .. ', 禁止开仓!'
            rcprintDebugLog(m_strLogTag .. strmsg)
            if unit == nil then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, strmsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), strmsg)
                end
            end

            return false, strmsg, 0, 0, iRange, false
        end
        if isPolling and assetsRC.m_randomDeduce then
            -- 轮询：设置并触发减仓，在C++里报警
            local timeout = -1
            if assetsRC.m_randomDeduceInterval == nil or assetsRC.m_randomDeduceInterval == "" then
                timeout = -1   -- -1表示一直等待执行
            else
                if type(assetsRC.m_randomDeduceInterval) == 'string' then
                    timeout = tonumber(assetsRC.m_randomDeduceInterval)
                else
                    timeout = assetsRC.m_randomDeduceInterval
                end
            end

            rcprintDebugLog(m_strLogTag .. strmsg)
            if (leftClosed and rate < minLimit) or (not leftClosed  and rate <= minLimit) then
                return false, strmsg, minLimit, 1, iRange, false
            else
                return false, strmsg, maxLimit, -1, iRange, false
            end
        else
            strmsg = strmsg .. '!'
        end
        -- 轮询：未设置减仓，报警
        rcprintDebugLog(m_strLogTag .. strmsg)
        if unit == nil then
            if m_accountInfo then
                rcReport(m_nProductId, m_accountInfo, strmsg)
            else
                rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
            end
        elseif m_nGroupId then
            rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
        end
        return false, strmsg, 0, 0, iRange, false
    else
        rcprintDebugLog(m_strLogTag .. string.format('dealWithWeightedSums: inner 2: net_value = %f, rate = %f, minLimit = %f, maxLimit = %f, left_closed = %s, right_closed = %s, enableWarn = %s, warnMultiple = %f', net, rate, minLimit, maxLimit, tostring(leftClosed), tostring(rightClosed), tostring(enableWarn), warnMultiple))
        if enableWarn and (not isInvalidDouble(warnMultiple)) and warnMultiple ~= 0 then
            local warnRate = warnMultiple * rate

            if not isValidAssetsRate(warnRate, leftValid, leftClosed, minLimit, rightValid, rightClosed, maxLimit) then
                --将实际比例进行警告倍数处理后，在区间之外，触发报警
                local strUnit = ', '
                if unit then
                    strUnit = ', 对于' .. unit
                    msgOption.isSingle = true
                    msgOption.key = unit
                else
                    msgOption.isSingle = false
                end

                msgOption.isMultipled = true
                strmsg = genAssetsWarnMsg(msgOption, msgHeader, rcType, rcName, strUnit, warnRate, warnMultiple, net, rangeMsg)

                rcprintDebugLog(m_strLogTag .. strmsg)
                if unit == nil then
                    if m_accountInfo then
                        rcReport(m_nProductId, m_accountInfo, strmsg)
                    else
                        rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
                    end
                elseif m_nGroupId then
                    rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
                end
                return true, strmsg, 0, 0, iRange, false
            else
                rcprintDebugLog(m_strLogTag .. 'enableWarn and warnMultiple valid, but not in range, return true.')
            end
        else
            rcprintDebugLog(m_strLogTag .. 'not enableWarn or warnMultiple invalid, return true.')
        end
    end

    return true, strmsg, 0, 0, iRange, true
end

function isSubFundRuleInTimeRange(assetsRC)
    if assetsRC.m_validTimeRange then
        if assetsRC.m_validTimeRange.m_bDateEnabled then
            local curDate = rcGetTradeDate()
            local validStart = string.gsub(assetsRC.m_validTimeRange.m_startDate, '-', '')
            local validEnd = string.gsub(assetsRC.m_validTimeRange.m_endDate, '-', '')
            -- 同时设置了开始日期和截止日期
            if validStart ~= "" and validEnd ~= "" and (curDate < validStart or curDate > validEnd) then
                -- rcprintDebugLog(m_strLogTag .. string.format('curr date %s not in rc %s date range : %s - %s, pass', curDate, assetsRC.m_description, validStart, validEnd))
                return false
            -- 没有设置截止日期
            elseif validStart ~= "" and validEnd == "" and (curDate < validStart) then
                -- rcprintDebugLog(m_strLogTag .. string.format('endDate is not set. curr date %s not in rc %s date range : %s - %s, pass', curDate, assetsRC.m_description, validStart, validEnd))
                return false
            -- 没有设置开始日期
            elseif validStart == "" and validEnd ~= "" and (curDate > validEnd) then
                -- rcprintDebugLog(m_strLogTag .. string.format('startDate is not set. curr date %s not in rc %s date range : %s - %s, pass', curDate, assetsRC.m_description, validStart, validEnd))
                return false
            end
        end
        if assetsRC.m_validTimeRange.m_bTimeEnabled then
            local curTime = os.date('%H:%M:%S', os.time())
            local validStart = assetsRC.m_validTimeRange.m_startTime
            local validEnd = assetsRC.m_validTimeRange.m_endTime
            if validStart <= validEnd then
                if curTime < validStart or curTime > validEnd then
                    -- rcprintDebugLog(m_strLogTag .. string.format('curr time %s not in rc %s time range : %s - %s, pass', curTime, assetsRC.m_description, validStart, validEnd))
                    return false
                end
            else
                if curTime < validStart and curTime > validEnd then
                    -- rcprintDebugLog(m_strLogTag .. string.format('curr time %s not in rc %s time range : 00:00:00 - %s, %s - 23:59:59, pass', curTime, assetsRC.m_description, validEnd, validStart))
                    return false
                end
            end
        end
    end
    return true
end

-- 检查一个具体的风控项
function checkSubFundRule(param, isOrderInfo, assetsRC, msgHeader, isHedge, testInfo)
    -- rcprintDebugLog(m_strLogTag .. string.format('checkSubFundRule : rule = %s', table2jsonOld(assetsRC)))
    -- 检查风控设置是否完整
    if not assetsRC.m_netValueConfig                      or
       not assetsRC.m_netValueConfig.m_valueRates         or
       table.getn(assetsRC.m_netValueConfig.m_valueRates) == 0 then
        --净值档位未设置，无需再计算，默认通过
        return true, ''
    end

    -- 计算得到净值档位
    local net = nil
    if assetsRC ~= nil then
        if assetsRC.m_netValueConfig ~= nil then
            local getItemSuccess,configValue = getControlItemValue(assetsRC.m_netValueConfig)
            if getItemSuccess then
                net = configValue
            else
                net = nil
            end
        end
    end

    if not net then
        local description = ''
        if assetsRC.m_description ~= nil then
            description = assetsRC.m_description
        end
        rcprintLog(m_strLogTag .. string.format('风控规则 %s 配置有误或者没有配置风控规则!', description))
        return true, ''
    end
    local success, netValueRate, iRange = getLimitRateByNetValue(assetsRC.m_netValueConfig, net)
    if not success then
        -- 比例设置有误
        -- 测试建议放行：mantis 5193
        rcprintDebugLog(m_strLogTag .. string.format('checkSubFundRule: net_value = %f', net))
        return true, ''
    end

    -- 检查风控有效时间
    local isInTimeRange = isSubFundRuleInTimeRange(assetsRC)
    if not isInTimeRange then
        return true, ''
    end

    -- 检查风控条件
    if not passCondition(assetsRC.m_condition, assetsRC.m_description) then
        return true, ''
    end

    for iFactor = 1, table.getn(assetsRC.m_numerator) do
        --当数据库中没有m_nFactorGroupId字段时，默认为没有绝对值
        if assetsRC.m_numerator[iFactor].m_nFactorGroupId == getInvalidInt() then
            assetsRC.m_numerator[iFactor].m_nFactorGroupId = -1
        end
    end

    -- 计算
    local dn1 = clockMSec()
    local units1, numerator, thisNumerator, unitsReal1, numeratorType = getWeightedSum(assetsRC.m_numerator, param, isOrderInfo, isHedge)
    local dn2 = clockMSec()
    local units2 = {}
    local denominator = {}
    local thisDenominator = {}
    local bDenomiatorEnabled = assetsRC.m_denominator[1].m_bEnabled
    if nil == bDenomiatorEnabled then
        bDenomiatorEnabled = true -- 为了兼容老的bsonrisk，这里把nil也当成true，怪怪的
    end
    local dd1 = clockMSec()
    local dd2 = clockMSec()
    if bDenomiatorEnabled then
        units2, denominator, thisDenominator, unitsReal2, denominatorType = getWeightedSum(assetsRC.m_denominator, param, isOrderInfo, isHedge)
        dd2 = clockMSec()
    else
        units2[1] = nil
        denominator[1] = 1
        thisDenominator[1] = 0
    end
    local resMsg = ''
    local dcomp1 = clockMSec()
    local stockToMsg = {}
    local productToMsg = {}
    local issuerToMsg = {}
    local overallMsg = {}

    for i1 = 1, table.getn(numerator), 1 do
        local t = thisNumerator[i1]
        if not isZero(t) then  -- 如果本次下单对分子的贡献完全为0，则无条件通过
            local n = numerator[i1]
            local u = units1[i1]
            for i2 = 1, table.getn(denominator), 1 do
                local t1 = thisDenominator[i2]
                local du = units2[i2]
                if (not du) or du == u then
                    local d = denominator[i2]
                    if (not isZero(d)) and (not isInvalidDouble(n)) and (not isInvalidDouble(d)) then  -- 分母为0时暂时放过
                        local prevRate = (n - t) / (d - t1)
                        if d == t1 then
                            -- zhangyi : 20140423
                            -- 目前d == t1只考虑一种情形：分母为类似“总股本”这种不存下单变化而变化的指标
                            prevRate = (n - t) / d
                        end
                        local res, msg, limitRate = isPositiveDealWithWeightedSums(assetsRC, net, netValueRate, iRange, n / d, prevRate, u, msgHeader, bDenomiatorEnabled)
                        if not res then
                            local strUnit = u
                            if nil == strUnit then strUnit = '' end
                            if nil ~= testInfo then
                                -- 风险试算
                                if CONFIG_TYPE_SINGLE_STOCK == numeratorType then
                                    stockToMsg[strUnit] = msg
                                elseif CONFIG_TYPE_SINGLE_PRODUCT == numeratorType then
                                    productToMsg[strUnit] = msg
                                elseif CONFIG_TYPE_SINGLE_FACTORY == numeratorType then
                                    issuerToMsg[strUnit] = msg
                                else
                                    table.insert(overallMsg, msg)
                                end
                            else
                                -- 下单检查
                                rcprintLog(m_strLogTag .. string.format("forbid_trade: assets_id=%d, unit=%s, rate=%f ((%f + %f =) %f / %f), res=%s, msg=%s", assetsRC.m_nID, strUnit, n / d, (n - t), t, n, d, tostring(res), msg))

                                return res, msg     -- 如果触发禁止开仓，只提示这一条
                            end
                        end
                        if string.len(msg) > 0 then
                            if string.len(resMsg) > 0 then
                                resMsg = resMsg .. '\n'
                            end
                            resMsg = resMsg .. msg
                        end
                    end
                end
            end
        else
            rcprintDebugLog(m_strLogTag .. string.format('本次下单对分子的贡献完全为0，无条件通过'))
        end
    end
    local dcomp2 = clockMSec()
    rcprintLog(m_strLogTag .. string.format("checkSubFundRule assets_id = %d, numerator_size = %d, denominator_size = %d, time = %f + %f + %f", assetsRC.m_nID, table.getn(numerator), table.getn(denominator), (dn2 - dn1), (dd2 - dd1), (dcomp2 - dcomp1)))
    if nil ~= testInfo then
        for i = 0, param:size() - 1, 1 do
            local p = param:at(i)
            if isMyAccount(m_accountInfo, p) then
                local stockMsg = stockToMsg[p.m_stock.m_strCode]
                local productMsg = productToMsg[p.m_stock.m_strProduct]
                local issuerMsg = issuerToMsg[rcGetIssuerId(p.m_stock.m_strMarket, p.m_stock.m_strCode)]
                if nil ~= stockMsg then
                    setTTError(testInfo, i, -1, stockMsg)
                elseif nil ~= productMsg then
                    setTTError(testInfo, i, -1, productMsg)
                elseif nil ~= issuerMsg then
                    setTTError(testInfo, i, -1, issuerMsg)
                end
            end
        end
        for k, v in pairs(overallMsg) do
            appendTTError(testInfo, -1, v)
        end
    end

    return true, resMsg
end


local function pollingSubFundRule_allStock(assetsRC, net, netValueRate, iRange, nRCScopeType, param, isOrderInfo, msgHeader, scope, strObjID)
    local units1, numerator, thisNumerator = getWeightedSum(assetsRC.m_numerator, param, isOrderInfo, false)
    local units2 = {}
    local denominator = {}
    local thisDenominator = {}
    local bDenomiatorEnabled = assetsRC.m_denominator[1].m_bEnabled
    if nil == bDenomiatorEnabled then
        bDenomiatorEnabled = true -- 为了兼容老的bsonrisk，这里把nil也当成true，怪怪的
    end
    if bDenomiatorEnabled then
        units2, denominator, thisDenominator = getWeightedSum(assetsRC.m_denominator, param, isOrderInfo, false)
    else
        units2[1] = nil
        denominator[1] = 1
        thisDenominator[1] = 0
    end
    --rcprintLog(m_strLogTag .. string.format("unit1:%s, numerator:%s, thisNumerator:%s", table2json(units1), table2json(numerator), table2json(thisNumerator)))
    
    local stockCodeVec = {}
    local numeraDataVec = {}   --不合规的分子数据
    local denomiDataVec = {}
    local isBreakVec = {}
    for i1 = 1, table.getn(numerator), 1 do
        local n = numerator[i1]
        local u = units1[i1]
        for i2 = 1, table.getn(denominator), 1 do
            local d = denominator[i2]
            local timeout = -1
            if type(assetsRC.m_randomDeduceInterval) == "number" then
                timeout = tonumber(assetsRC.m_randomDeduceInterval)
            else
                timeout = -1   --默认等待为-1
            end
            if (not isZero(d))  and (not isInvalidDouble(n)) and (not isInvalidDouble(d)) then  -- 分母为0时暂时放过
                local res, msg, limitRate, direction, iRange, validRate = dealWithWeightedSums(param, isOrderInfo, assetsRC, net, netValueRate, iRange, n / d, u, msgHeader, true, bDenomiatorEnabled)
                
                table.insert(stockCodeVec, tostring(XT_ASSETS_INDEX_SCOPE_ALL))
                table.insert(numeraDataVec, n)
                table.insert(denomiDataVec, d)
                table.insert(isBreakVec, not validRate)
                
                if iRange == nil then
                    iRange = 0
                end
                
                rcprintLog(m_strLogTag .. string.format("all_stock: assets_id=%d, rate=%f (%f / %f), iRange=%d, res=%s, msg=%s", assetsRC.m_nID, n / d, n, d, iRange, tostring(res), msg))
                if not res then
                    if assetsRC.m_randomDeduce and 0 ~= direction then
                        local frozenN = getFrozenCommandIndex(m_accountInfos, assetsRC.m_numerator, CStockInfo(), XT_RIR_ALL)
                        local frozenD = getFrozenCommandIndex(m_accountInfos, assetsRC.m_denominator, CStockInfo(), XT_RIR_ALL)
                        --rcprintLog(m_strLogTag .. string.format("polling_allstock to Adjust %s %s %s %s %s %s", tostring(res), msg, tostring(limitRate), tostring(direction), tostring(iRange), tostring(validRate)))
                        --向C++传入nProductId, 然后求出对应的账号组传给randomAppendOrDeduce
                        if ((d + frozenD) * limitRate - (n + frozenN)) * (d * limitRate - n) > 0 then   -- 考虑了冻结指令的影响后，不应该改变调仓方向
                            rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, '', '', '', n + frozenN, (d + frozenD)* limitRate, assetsRC.m_randomAppend, msg, timeout)
                        else
                            strmsg = strmsg .. "."
                            if m_accountInfo then
                                rcReport(m_nProductId, m_accountInfo, strmsg)
                            else     
                                rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
                            end   
                            end
                        end
                    end
                if nil == m_accountInfo then    -- 靠这个来识别是在进行产品polling
                    local fundType = getProductFundType(m_productInfo)   -- 获取产品基金类型
                    rcUpdateAssetsData(m_productInfo.m_nId, assetsRC.m_nID, scope, n, d, iRange - 1, validRate, fundType, "", CAccountInfo())
                else                            -- 不只是推送产品，同时也推送账号
                    local fundType = getProductFundType(m_productInfo)   -- 获取产品基金类型
                    if validRate == nil then
                        validRate = false
                    end
                    rcUpdateAssetsData(m_productInfo.m_nId, assetsRC.m_nID, scope,  n, d, iRange - 1, validRate, fundType, "", m_accountInfo)
                end
            else
                -- 分母为0时
                rcprintLog(m_strLogTag .. string.format("all_stock: assets_id=%d, rate=(%f / %f)", assetsRC.m_nID, n, d))
                
                table.insert(stockCodeVec, tostring(XT_ASSETS_INDEX_SCOPE_ALL))
                table.insert(numeraDataVec, n)
                table.insert(denomiDataVec, d)
                table.insert(isBreakVec, false)
                
                if nil == m_accountInfo then    -- 靠这个来识别是在进行产品polling
                    local fundType = getProductFundType(m_productInfo)   -- 获取产品基金类型
                    rcUpdateAssetsData(m_productInfo.m_nId, assetsRC.m_nID, scope,  n, d, -1, true, fundType, "" , CAccountInfo())
                else                            -- 不只是推送产品，同时也推送账号
                    local fundType = getProductFundType(m_productInfo)   -- 获取产品基金类型
                    rcUpdateAssetsData(m_productInfo.m_nId, assetsRC.m_nID, scope,  n, d, -1, true, fundType, "", m_accountInfo)
                end
            end
        end
    end
    
    -- 静态风控数据更新
    local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
    if table.getn(stockCodeVec) > 0 then
        rcUpdateAssetsRCData(m_nProductId, strKeys, bDenomiatorEnabled, stockCodeVec, numeraDataVec, denomiDataVec, isBreakVec, true)
    end
end


function pollingSubFundRule_singleStock(assetsRC, net, netValueRate, iRange, singleFactorId, nRCScopeType, param, isOrderInfo, msgHeader, strObjID)
    -- 根据挂单和持仓，全遍历
    -- todo 优化，根据具体的风控规则遍历对应的持仓和挂单，例如只有股票持仓就无需check期货保证金比例限制
    local stockMap = {}    --
    local keyToAccount = {}
    for i = 0, m_accountInfos:size()-1, 1 do
        local accountInfo = m_accountInfos:at(i)
        local accountData = getAccountData(accountInfo)
        if accountData ~= CAccountData_NULL then
            -- 统计持仓大于0的仓位
            local positions = accountData:getVector(XT_CPositionStatics)
            for j = 0, positions:size()-1, 1 do
                local position = positions:at(j)
                local market = position:getString(CPositionStatics_m_strExchangeID)
                local stock  = position:getString(CPositionStatics_m_strInstrumentID)
                local name   = position:getString(CPositionStatics_m_strInstrumentName)
                local hedgeFlag = position:getInt(CPositionStatics_m_nHedgeFlag)
                if rcIsStockInCategory(market, stock, name, singleFactorId) and position:getInt(CPositionStatics_m_nPosition) > 0 then
                    local acKey = accountInfo:getKey()
                    if not keyToAccount[acKey] then
                        keyToAccount[acKey] = accountInfo
                    end
                    if not stockMap[acKey] then
                        stockMap[acKey] = {}
                    end
                    if not stockMap[acKey][hedgeFlag] then
                        stockMap[acKey][hedgeFlag] = {}
                    end
                    if not stockMap[acKey][hedgeFlag][market] then
                        stockMap[acKey][hedgeFlag][market] = {}
                    end
                    stockMap[acKey][hedgeFlag][market][stock] = name
                end
            end
            
            if AT_GOLD == accountInfo.m_nBrokerType then
                local goldStorage = accountData:getVector(XT_GoldQueryStorageResp)
                for j = 0, goldStorage:size()-1, 1 do
                    local gold = goldStorage:at(j)
                    local stock = gold:getString(GoldQueryStorageResp_code)
                    local name = ""
                    local market = "SHGE"
                    local totalStorage = gold:getDouble(GoldQueryStorageResp_totalStorage)
                    if rcIsStockInCategory(market, stock, name, singleFactorId) and totalStorage > 0 then
                        local acKey = accountInfo:getKey()
                        if not keyToAccount[acKey] then
                            keyToAccount[acKey] = accountInfo
                        end
                        if not stockMap[acKey] then
                            stockMap[acKey] = {}
                        end
                        if not stockMap[acKey][HEDGE_FLAG_SPECULATION] then
                            stockMap[acKey][HEDGE_FLAG_SPECULATION] = {}
                        end
                        if not stockMap[acKey][HEDGE_FLAG_SPECULATION][market] then
                            stockMap[acKey][HEDGE_FLAG_SPECULATION][market] = {}
                        end
                        stockMap[acKey][HEDGE_FLAG_SPECULATION][market][stock] = name
                    end
                end
            end

            -- 统计股票未完成的买单
            local orders = accountData:getVector(XT_COrderDetail)
            for j = 0, orders:size()-1, 1 do
                local order = orders:at(j)
                local nOffsetFlag = order:getInt(COrderDetail_m_nOffsetFlag)
                local nOrderStatus = order:getInt(COrderDetail_m_nOrderStatus)
                if nOffsetFlag == EOFF_THOST_FTDC_OF_Open     and
                   nOrderStatus ~= ENTRUST_STATUS_CANCELED    and
                   nOrderStatus ~= ENTRUST_STATUS_PART_CANCEL and
                   nOrderStatus ~= ENTRUST_STATUS_SUCCEEDED   and
                   nOrderStatus ~= ENTRUST_STATUS_JUNK        then
                    local market = order:getString(COrderDetail_m_strExchangeID)
                    local stock  = order:getString(COrderDetail_m_strInstrumentID)
                    local name   = order:getString(COrderDetail_m_strInstrumentName)
                    local hedgeFlag = order:getInt(COrderDetail_m_nHedgeFlag)
                    local remain = order:getInt(COrderDetail_m_nVolumeTotalOriginal) - order:getInt(COrderDetail_m_nVolumeTraded)
                    if rcIsStockInCategory(market, stock, name, singleFactorId) and remain > 0 then
                        local acKey = accountInfo:getKey()
                        if not keyToAccount[acKey] then
                            keyToAccount[acKey] = accountInfo
                        end
                        if not stockMap[acKey] then
                            stockMap[acKey] = {}
                        end
                        if not stockMap[acKey][hedgeFlag] then
                            stockMap[acKey][hedgeFlag] = {}
                        end
                        if not stockMap[acKey][hedgeFlag][market] then
                            stockMap[acKey][hedgeFlag][market] = {}
                        end
                        stockMap[acKey][hedgeFlag][market][stock] = name
                    end
                end
            end

            if AT_CREDIT == accountInfo.m_nBrokerType then
                vStocks = rcGetUncompleteCreditCompactStocks(accountData)
                for iStock = 0, vStocks:size() - 1, 1 do
                    local stk = vStocks:at(iStock)
                    local market = stk.m_strMarket
                    local stock = stk.m_strCode
                    local name = stk.m_strName
                    if rcIsStockInCategory(market, stock, name, singleFactorId) then
                        local acKey = accountInfo:getKey()
                        if not keyToAccount[acKey] then
                            keyToAccount[acKey] = accountInfo
                        end
                        if not stockMap[acKey] then
                            stockMap[acKey] = {}
                        end
                        if not stockMap[acKey][HEDGE_FLAG_SPECULATION] then
                            stockMap[acKey][HEDGE_FLAG_SPECULATION] = {}
                        end
                        if not stockMap[acKey][HEDGE_FLAG_SPECULATION][market] then
                            stockMap[acKey][HEDGE_FLAG_SPECULATION][market] = {}
                        end
                        stockMap[acKey][HEDGE_FLAG_SPECULATION][market][stock] = name
                    end
                end
            end
        end
    end
    
    if m_bIsProduct then
        local productNsData = getProductNsData(nProductId)
        if CProductNSData_NULL ~= productNsData then
            local nsPositions = productNsData:getVector(XT_CNSPositionDetail)
            local nsProductKey = tostring(nProductId)
            for j = 0, nsPositions:size() - 1 , 1 do
                local nspos = nsPositions:at(i)
                local market = nspos:getString(CNSPositionDetail_m_strExchangeID)
                local stock = nspos:getString(CNSPositionDetail_m_strInstrumentID)
                local name = nspos:getString(CNSPositionDetail_m_strInstrumentName)
                local hedgeFlag = nspos:getInt(CNSPositionDetail_m_nHedgeFlag)
                if rcIsStockInCategory(market, stock, name, singleFactorId) and nspos:getInt(CNSPositionDetail_m_nVolume) > 0 then
                    if not stockMap[nsProductKey] then
                        stockMap[nsProductKey] = {}
                    end
                    if  not stockMap[nsProductKey][hedgeFlag] then
                        stockMap[nsProductKey][hedgeFlag] = {}
                    end
                    if not stockMap[nsProductKey][hedgeFlag][market] then
                        stockMap[nsProductKey][market] = {}
                    end
                    stockMap[nsProductKey][hedgeFlag][market][stock] = name
                end
            end
        end
    end
    
    if next(stockMap) == nil then
        -- 配了单支但是没有相应持仓
        pollingSubFundRule_allStock(assetsRC, net, netValueRate, iRange, nRCScopeType, param, isOrderInfo, msgHeader, XT_RIR_CODE, strObjID)
    else
        local bBreakRule = false
        if m_accountInfo ~= nil then
            rcInitAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo)
        else
            rcInitAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo())
        end

        local totalNum = 0
        for acKey, m in pairs(stockMap) do
            for k, v in pairs(m) do
                for k1, v1 in pairs(v) do
                    for k2, v2 in pairs(v1) do
                        totalNum = totalNum + 1
                    end
                end
            end
        end
        local fakeParams = createParamList(totalNum)
        local i = 0
        for acKey, m in pairs(stockMap) do
            local account = keyToAccount[acKey]
            for k, v in pairs(m) do
                for k1, v1 in pairs(v) do
                    for k2, v2 in pairs(v1) do
                        fakeParams:at(i).m_nNum = 0
                        fakeParams:at(i).m_account = account
                        fakeParams:at(i).m_stock.m_strMarket = k1
                        fakeParams:at(i).m_stock.m_strCode = k2
                        fakeParams:at(i).m_stock.m_strName = v2
                        fakeParams:at(i).m_nHedgeFlag = k
                        if isStockMarket(k1) or isHGTMarket(k1)  then
                            fakeParams:at(i).m_eOperationType = OPT_BUY
                        elseif isNew3BoardMarket(k1) then
                            local accountData = getAccountData(account)
                            if rcIsNew3BoardLimitPriceType(accountData, k1, k2) then
                                fakeParams:at(i).m_eOperationType = OPT_N3B_LIMIT_PRICE_BUY
                            else
                                fakeParams:at(i).m_eOperationType = OPT_BUY
                            end
                        elseif isStockOptionMarket(k1) then
                            fakeParams:at(i).m_eOperationType = OPT_OPTION_BUY_OPEN
                        else
                            fakeParams:at(i).m_eOperationType = OPT_OPEN_LONG
                        end
                        i = i + 1
                    end
                end
            end
        end

        local units1, numerator, thisNumerator, units1Real = getWeightedSum(assetsRC.m_numerator, fakeParams, false, false)
        local units2 = {}
        local denominator = {}
        local thisDenominator = {}
        local bDenomiatorEnabled = assetsRC.m_denominator[1].m_bEnabled
        if bDenomiatorEnabled == true or bDenomiatorEnabled == nil then -- 为了兼容老的bsonrisk，这里怪怪的
            units2, denominator, thisDenominator = getWeightedSum(assetsRC.m_denominator, fakeParams, false, false)
            bDenomiatorEnabled = true
        else
            units2[1] = nil
            denominator[1] = 1
            thisDenominator[1] = 0
        end

        -- 分子分母按units对应
        local iNumerator2iDenominator = {}
        if 1 == table.getn(denominator) then
            for i1 = 1, table.getn(numerator), 1 do
                iNumerator2iDenominator[i1] = 1
            end
        else
            local dUnitToIdx = {}
            for i2 = 1, table.getn(denominator), 1 do
                local u2 = units2[i2]
                dUnitToIdx[u2] = i2
            end
            for i1 = 1, table.getn(numerator), 1 do
                local u1 = units1[i1]
                iNumerator2iDenominator[i1] = dUnitToIdx[u1]
            end
        end

        local timeout = -1
        if type(assetsRC.m_randomDeduceInterval) == "number" then
            timeout = tonumber(assetsRC.m_randomDeduceInterval)
        else
            timeout = -1   --默认等待为-1
        end

        local stockCodeVec = {}
        local numeraDataVec = {}   --不合规的分子数据
        local denomiDataVec = {}
        local isBreakVec = {}
        for i1 = 1, table.getn(numerator), 1 do
            local n = numerator[i1]
            local u = units1[i1]
            local stockInfo = units1Real[i1]
            local i2 = iNumerator2iDenominator[i1]
            if nil ~= i2 then
                local d = denominator[i2]
                if (not isZero(d)) and (not isInvalidDouble(n)) and (not isInvalidDouble(d)) then  -- 分母为0时暂时放过
                    local res, msg, limitRate, direction, iRange, validRate = dealWithWeightedSums(orderInfo, true, assetsRC, net, netValueRate, iRange, n / d, u, msgHeader, true, bDenomiatorEnabled)
                    
                    table.insert(stockCodeVec, stockInfo.m_strMarket .. stockInfo.m_strCode)
                    table.insert(numeraDataVec, n)
                    table.insert(denomiDataVec, d)
                    table.insert(isBreakVec, not validRate)
                    
                    if iRange == nil then
                        iRange = 0
                    end
                    
                    if not validRate then
                        bBreakRule = true
                        rcprintLog(m_strLogTag .. string.format("single_stock: assets_id=%d, stock=%s, rate=%f (%f / %f), iRange=%d, res=%s, msg=%s", assetsRC.m_nID, u, n / d, n, d, iRange, tostring(res), msg))
                    end
                    local fundType = getProductFundType(m_productInfo, isParent)   -- 获取产品基金类型
                    if u then
                        if nil == m_accountInfo then
                            rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_CODE, n, d, iRange - 1, validRate, fundType, u, CAccountInfo())   --当该单只触发风控比例时，更新推送的数据
                        else
                            rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_CODE, n, d, iRange - 1, validRate, fundType, u, m_accountInfo)   --当该单只触发风控比例时，更新推送的数据
                        end
                    end
                    if not res then
                        if assetsRC.m_randomDeduce and 0 ~= direction then
                            local frozenN = getFrozenCommandIndex(m_accountInfos, assetsRC.m_numerator, stockInfo, XT_RIR_CODE)
                            local frozenD = getFrozenCommandIndex(m_accountInfos, assetsRC.m_denominator, stockInfo, XT_RIR_CODE)
                            --rcprintLog(m_strLogTag .. ' ' .. stockInfo.m_strMarket .. stockInfo.m_strCode .. ' frozenN = ' .. tostring(frozenN) .. ' frozenD = ' .. tostring(frozenD))
                            if ((d + frozenD) * limitRate - (n + frozenN)) * (d * limitRate - n) > 0 then   -- 考虑了冻结指令的影响后，不应该改变调仓方向
                                if nil == stockInfo then
                                    -- 容错，其实不应该走到：配了单支，但是实际上单支的没有仓位
                                    rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, '', '', '', (n + frozenN), (d + frozenD) * limitRate, assetsRC.m_randomAppend, msg, timeout)
                                else
                                    -- 配了单支，实际上单支的也有仓位
                                    rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, '', stockInfo.m_strMarket, stockInfo.m_strCode, (n + frozenN), (d + frozenD) * limitRate, assetsRC.m_randomAppend, msg, timeout)
                                end
                            end
                        end
                    end
                else
                    rcprintDebugLog(m_strLogTag .. string.format("single_stock: assets_id=%d, stock=%s, rate=(%f / %f)", assetsRC.m_nID, u, n, d))
                    if nil == m_accountInfo and u then
                        local fundType = getProductFundType(m_productInfo) -- 获取产品基金类型
                        rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_CODE, n, d, -1, true, fundType, u, CAccountInfo())
                    elseif nil ~= m_accountInfo and u then
                        local fundType = getProductFundType(m_productInfo) -- 获取产品基金类型
                        rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_CODE, n, d, -1, true, fundType, u, m_accountInfo)
                    end
                end
            end
        end
        
        -- 静态风控数据更新
        local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
        if table.getn(stockCodeVec) > 0 then
            rcUpdateAssetsRCData(m_nProductId, strKeys, bDenomiatorEnabled, stockCodeVec, numeraDataVec, denomiDataVec, isBreakVec, true)
        end

        if bBreakRule then
            local warnMsg = ''
            local warnMultipleMsg = ''   --倍数告警信息
            if m_accountInfo ~= nil then
                warnMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo, false)
                warnMultipleMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo, true)
            else
                warnMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo(), false)
                warnMultipleMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo(), true)
            end
            if warnMsg ~= '' then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, warnMsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), warnMsg)
                end
            end
            if warnMultipleMsg ~= '' then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, warnMultipleMsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), warnMultipleMsg)
                end
            end
        end
    end
end

function pollingSubFundRule_singleProduct(assetsRC, net, netValueRate, iRange, singleFactorId, nRCScopeType, param, isOrderInfo, msgHeader, strObjID)
    --单品种只处理期货账号
    local productMap = {}    --
    local product2stockname = {}
    local keyToAccount = {}
    for i = 0, m_accountInfos:size()-1, 1 do
        local accountInfo = m_accountInfos:at(i)
        local accountData = getAccountData(accountInfo)
        if accountInfo.m_nBrokerType == AT_FUTURE and accountData ~= CAccountData_NULL then
            -- 统计持仓大于0的仓位
            local positions = accountData:getVector(XT_CPositionStatics)
            for j = 0, positions:size()-1, 1 do
                local position = positions:at(j)
                local market  = position:getString(CPositionStatics_m_strExchangeID)
                local stock   = position:getString(CPositionStatics_m_strInstrumentID)
                local name    = position:getString(CPositionStatics_m_strInstrumentName)
                local product = position:getString(CPositionStatics_m_strProductID)
                local hedgeFlag = position:getInt(CPositionStatics_m_nHedgeFlag)
                if rcIsStockInCategory(market, stock, name, singleFactorId) and position:getInt(CPositionStatics_m_nPosition) > 0 then
                    local acKey = accountInfo:getKey()
                    if not keyToAccount[acKey] then
                        keyToAccount[acKey] = accountInfo
                    end
                    if not productMap[acKey] then
                        productMap[acKey] = {}
                    end
                    if not productMap[acKey][hedgeFlag] then
                        productMap[acKey][hedgeFlag] = {}
                    end
                    if not productMap[acKey][hedgeFlag][market] then
                        productMap[acKey][hedgeFlag][market] = {}
                    end
                    productMap[acKey][hedgeFlag][market][product] = stock
                    if not product2stockname[product] then
                        product2stockname[product] = name
                    end
                end
            end

            -- 统计未成交的开仓单
            local orders = accountData:getVector(XT_COrderDetail)
            for j = 0, orders:size()-1, 1 do
                local order = orders:at(j)
                local nOffsetFlag = order:getInt(COrderDetail_m_nOffsetFlag)
                local nOrderStatus = order:getInt(COrderDetail_m_nOrderStatus)
                if nOffsetFlag == EOFF_THOST_FTDC_OF_Open     and
                   nOrderStatus ~= ENTRUST_STATUS_CANCELED    and
                   nOrderStatus ~= ENTRUST_STATUS_PART_CANCEL and
                   nOrderStatus ~= ENTRUST_STATUS_SUCCEEDED   and
                   nOrderStatus ~= ENTRUST_STATUS_JUNK        then
                    local market = order:getString(COrderDetail_m_strExchangeID)
                    local stock  = order:getString(COrderDetail_m_strInstrumentID)
                    local product= order:getString(COrderDetail_m_strProductID)
                    local name   = order:getString(COrderDetail_m_strInstrumentName)
                    local hedgeFlag = order:getInt(COrderDetail_m_nHedgeFlag)
                    local remain = order:getInt(COrderDetail_m_nVolumeTotalOriginal) - order:getInt(COrderDetail_m_nVolumeTraded)
                    if rcIsStockInCategory(market, stock, name, singleFactorId) and remain > 0 then
                        local acKey = accountInfo:getKey()
                        if not keyToAccount[acKey] then
                            keyToAccount[acKey] = accountInfo
                        end
                        if not productMap[acKey] then
                            productMap[acKey] = {}
                        end
                        if not productMap[acKey][hedgeFlag] then
                            productMap[acKey][hedgeFlag] = {}
                        end
                        if not productMap[acKey][hedgeFlag][market] then
                            productMap[acKey][hedgeFlag][market] = {}
                        end
                        productMap[acKey][hedgeFlag][market][product] = stock
                        if not product2stockname[product] then
                            product2stockname[product] = name
                        end
                    end
                end
            end
        end
    end

    if next(productMap) == nil then
        -- 配了单品种，但没有相应持仓
        pollingSubFundRule_allStock(assetsRC, net, netValueRate, iRange, nRCScopeType, param, isOrderInfo, msgHeader, XT_RIR_PRODUCT, strObjID)
    else
        local bBreakRule = false
        if m_accountInfo ~= nil then
            rcInitAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo)
        else
            rcInitAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo())
        end

        local totalNum = 0

        local totalNum = 0
        for acKey, m in pairs(productMap) do
            for market, p in pairs(m) do
                for k, v in pairs(p) do
                    for k1, v1 in pairs(v) do
                        totalNum = totalNum + 1
                    end
                end
            end
        end
        local fakeParams = createParamList(totalNum)
        local i = 0
        for acKey, m in pairs(productMap) do
            local account = keyToAccount[acKey]
            for hflag, p in pairs(m) do
                for market, v in pairs(p) do
                    for k1, v1 in pairs(v) do
                        fakeParams:at(i).m_nNum = 0
                        fakeParams:at(i).m_account = account
                        fakeParams:at(i).m_stock.m_strMarket = market
                        fakeParams:at(i).m_stock.m_strCode = v1
                        fakeParams:at(i).m_stock.m_strName = product2stockname[k1]
                        fakeParams:at(i).m_stock.m_strProduct = k1
                        fakeParams:at(i).m_nHedgeFlag = hflag
                        if isStockMarket(market) or isHGTMarket(k) then
                            fakeParams:at(i).m_eOperationType = OPT_BUY
                        elseif isNew3BoardMarket(market) then
                            local accountData = getAccountData(account)
                            if rcIsNew3BoardLimitPriceType(accountData, market, v1) then
                                fakeParams:at(i).m_eOperationType = OPT_N3B_LIMIT_PRICE_BUY
                            else
                                fakeParams:at(i).m_eOperationType = OPT_BUY
                            end
                        elseif isStockOptionMarket(market) then
                            fakeParams:at(i).m_eOperationType = OPT_OPTION_BUY_OPEN
                        else
                            fakeParams:at(i).m_eOperationType = OPT_OPEN_LONG
                        end
                        i = i + 1
                    end
                end
            end
        end

        local units1, numerator, thisNumerator, units1Real = getWeightedSum(assetsRC.m_numerator, fakeParams, false, false)
        local units2 = {}
        local denominator = {}
        local thisDenominator = {}
        local bDenomiatorEnabled = assetsRC.m_denominator[1].m_bEnabled
        if bDenomiatorEnabled == true or bDenomiatorEnabled == nil then -- 为了兼容老的bsonrisk，这里怪怪的
            units2, denominator, thisDenominator = getWeightedSum(assetsRC.m_denominator, fakeParams, false, false)
            bDenomiatorEnabled = true
        else
            units2[1] = nil
            denominator[1] = 1
            thisDenominator[1] = 0
        end

        -- 分子分母按units对应
        local iNumerator2iDenominator = {}
        if 1 == table.getn(denominator) then
            for i1 = 1, table.getn(numerator), 1 do
                iNumerator2iDenominator[i1] = 1
            end
        else
            local dUnitToIdx = {}
            for i2 = 1, table.getn(denominator), 1 do
                local u2 = units2[i2]
                dUnitToIdx[u2] = i2
            end
            for i1 = 1, table.getn(numerator), 1 do
                local u1 = units1[i1]
                iNumerator2iDenominator[i1] = dUnitToIdx[u1]
            end
        end

        local timeout = -1
        if type(assetsRC.m_randomDeduceInterval) == "number" then
            timeout = tonumber(assetsRC.m_randomDeduceInterval)
        else
            timeout = -1   --默认等待为-1
        end
        
        local stockCodeVec = {}
        local numeraDataVec = {}   --不合规的分子数据
        local denomiDataVec = {}
        local isBreakVec = {}
        for i1 = 1, table.getn(numerator), 1 do
            local n = numerator[i1]
            local u = units1[i1]
            local product_id = units1Real[i1]
            local i2 = iNumerator2iDenominator[i1]
            if nil ~= i2 then
                local d = denominator[i2]
                if (not isZero(d)) and (not isInvalidDouble(n)) and (not isInvalidDouble(d)) then  -- 分母为0时暂时放过
                    local res, msg, limitRate, direction, iRange, validRate = dealWithWeightedSums(orderInfo, true, assetsRC, net, netValueRate, iRange, n / d, u, msgHeader, true, bDenomiatorEnabled)
                    
                    table.insert(stockCodeVec, product_id)
                    table.insert(numeraDataVec, n)
                    table.insert(denomiDataVec, d)
                    table.insert(isBreakVec, not validRate)
                    
                    if iRange == nil then
                        iRange = 0
                    end
                    
                    if not validRate then
                        bBreakRule = true
                        rcprintLog(m_strLogTag .. string.format("single_product: assets_id=%d, product=%s, rate=%f (%f / %f), iRange=%d, res=%s, msg=%s", assetsRC.m_nID, u, n / d, n, d, iRange, tostring(res), msg))
                    end
                    
                    local fundType = getProductFundType(m_productInfo, isParent)   -- 获取产品基金类型
                    if u then
                        if nil == m_accountInfo then
                            rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_PRODUCT, n, d, iRange - 1, validRate, fundType, u, CAccountInfo())  --当该单品种触发风控项时，更新推送的风控项数据
                        else
                            rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_PRODUCT, n, d, iRange - 1, validRate, fundType, u, m_accountInfo)   --当该单品种触发风控项时，更新推送的风控项数据
                        end
                    end

                    if not res then
                        if assetsRC.m_randomDeduce and 0 ~= direction then
                            local frozenN = getFrozenCommandIndex(m_accountInfos, assetsRC.m_numerator, CStockInfo(), XT_RIR_PRODUCT)
                            local frozenD = getFrozenCommandIndex(m_accountInfos, assetsRC.m_denominator, CStockInfo(), XT_RIR_PRODUCT)
                            if ((d + frozenD) * limitRate - (n + frozenN)) * (d * limitRate - n) > 0 then   -- 考虑了冻结指令的影响后，不应该改变调仓方向
                                if nil == product_id then
                                    -- 容错，实际不应该走到：配了单品种，但是某品种没有仓位
                                    rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, '', '', '', (n + frozenN), (d + frozenD)* limitRate, assetsRC.m_randomAppend, msg, timeout)
                                else
                                    -- 配了单品种，某品种也有仓位
                                    rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, product_id, '', '', (n + frozenN), (d + frozenD) * limitRate, assetsRC.m_randomAppend, msg, timeout)
                                end
                            end
                        end
                    end
                else
                    rcprintDebugLog(m_strLogTag .. string.format("single_product: assets_id=%d, product=%s, rate=(%f / %f)", assetsRC.m_nID, u, n, d))
                    if nil == m_accountInfo and u then
                        local fundType = getProductFundType(m_productInfo) -- 获取产品基金类型
                        rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_PRODUCT, n, d, -1, true, fundType, u, CAccountInfo())
                    elseif nil ~= m_accountInfo and u then
                        local fundType = getProductFundType(m_productInfo) -- 获取产品基金类型
                        rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_PRODUCT, n, d, -1, true, fundType, u, m_accountInfo)
                    end
                end
            end
        end
        
        -- 静态风控数据更新
        local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
        if table.getn(stockCodeVec) > 0 then
            rcUpdateAssetsRCData(m_nProductId, strKeys, bDenomiatorEnabled, stockCodeVec, numeraDataVec, denomiDataVec, isBreakVec, true)
        end

        if bBreakRule then
            local warnMsg = ''
            local warnMultipleMsg = ''   --倍数告警信息
            if m_accountInfo ~= nil then
                warnMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo, false)
                warnMultipleMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo, true)
            else
                warnMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo(), false)
                warnMultipleMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo(), true)
            end
            if warnMsg ~= '' then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, warnMsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), warnMsg)
                end
            end
            if warnMultipleMsg ~= '' then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, warnMultipleMsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), warnMultipleMsg)
                end
            end
        end
    end
end

function pollingSubFundRule_singleIssuer(assetsRC, net, netValueRate, iRange, singleFactorId, nRCScopeType, param, isOrderInfo, msgHeader, strObjID)
    --单一机构只处理股票账号中的债券
    local issuerMap = {}
    local issuer2stockname = {}
    local keyToAccount = {}

    for i = 0, m_accountInfos:size()-1, 1 do
        local accountInfo = m_accountInfos:at(i)
        local accountData = getAccountData(accountInfo)
        if isStockAccount(accountInfo) and accountData ~= CAccountData_NULL then
            -- 统计持仓大于0的仓位
            local positions = accountData:getVector(XT_CPositionStatics)
            for j = 0, positions:size()-1, 1 do
                local position = positions:at(j)
                local market  = position:getString(CPositionStatics_m_strExchangeID)
                local stock   = position:getString(CPositionStatics_m_strInstrumentID)
                local name    = position:getString(CPositionStatics_m_strInstrumentName)
                local hedgeFlag = position:getInt(CPositionStatics_m_nHedgeFlag)
                local issuerId = rcGetIssuerId(market, stock);
                if rcIsStockInCategory(market, stock, name, singleFactorId) and position:getInt(CPositionStatics_m_nPosition) > 0 and issuerId ~= '' then
                    local acKey = accountInfo:getKey()
                    if not keyToAccount[acKey] then
                        keyToAccount[acKey] = accountInfo
                    end
                    if not issuerMap[acKey] then
                        issuerMap[acKey] = {}
                    end
                    if not issuerMap[acKey][hedgeFlag] then
                        issuerMap[acKey][hedgeFlag] = {}
                    end
                    if not issuerMap[acKey][hedgeFlag][market] then
                        issuerMap[acKey][hedgeFlag][market] = {}
                    end
                    issuerMap[acKey][hedgeFlag][market][issuerId] = stock
                    if not issuer2stockname[issuerId]  then
                        issuer2stockname[issuerId] = name
                    end
                end
            end

            local orders = accountData:getVector(XT_COrderDetail)
            for j = 0, orders:size()-1, 1 do
                local order = orders:at(j)
                local nOffsetFlag = order:getInt(COrderDetail_m_nOffsetFlag)
                local nOrderStatus = order:getInt(COrderDetail_m_nOrderStatus)
                if nOffsetFlag == EOFF_THOST_FTDC_OF_Open     and
                    nOrderStatus ~= ENTRUST_STATUS_CANCELED    and
                    nOrderStatus ~= ENTRUST_STATUS_PART_CANCEL and
                    nOrderStatus ~= ENTRUST_STATUS_SUCCEEDED   and
                    nOrderStatus ~= ENTRUST_STATUS_JUNK        then
                    local market = order:getString(COrderDetail_m_strExchangeID)
                    local stock  = order:getString(COrderDetail_m_strInstrumentID)
                    local name   = order:getString(COrderDetail_m_strInstrumentName)
                    local hedgeFlag = order:getInt(COrderDetail_m_nHedgeFlag)
                    --local factory = rcGetFactoryCode(stock)
                    local issuerId = getIssuerId(market, stock);
                    local remain = order:getInt(COrderDetail_m_nVolumeTotalOriginal) - order:getInt(COrderDetail_m_nVolumeTraded)
                    if rcIsStockInCategory(market, stock, name, singleFactorId) and remain > 0 and issuerId ~= '' then
                        local acKey = accountInfo:getKey()
                        if not keyToAccount[acKey] then
                            keyToAccount[acKey] = accountInfo
                        end
                        if not issuerMap[acKey] then
                            issuerMap[acKey] = {}
                        end
                        if not issuerMap[acKey][hedgeFlag] then
                            issuerMap[acKey][hedgeFlag] = {}
                        end
                        if not issuerMap[acKey][hedgeFlag][market] then
                            issuerMap[acKey][hedgeFlag][market] = {}
                        end
                        issuerMap[acKey][hedgeFlag][market][issuerId] = stock
                        if not issuer2stockname[issuerId]  then
                            issuer2stockname[issuerId] = name
                        end
                    end
                end
            end
        end
    end

    if next(issuerMap) == nil then
        -- 配了单一发行方，但没有相应持仓
        pollingSubFundRule_allStock(assetsRC, net, netValueRate, iRange, nRCScopeType, param, isOrderInfo, msgHeader, XT_RIR_FACTORY, strObjID)
    else
        local bBreakRule = false
        if m_accountInfo ~= nil then
            rcInitAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo)
        else
            rcInitAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo())
        end

        local totalNum = 0
        for acKey, m in pairs(issuerMap) do
            for k, v in pairs(m) do
                for k1, v1 in pairs(v) do
                    for k2, v2 in pairs(v1) do
                        totalNum = totalNum + 1
                    end
                end
            end
        end
        local fakeParams = createParamList(totalNum)
        local i = 0
        for acKey, m in pairs(issuerMap) do
            local account = keyToAccount[acKey]
            for k, v in pairs(m) do
                for k1, v1 in pairs(v) do
                    for k2, v2 in pairs(v1) do
                        fakeParams:at(i).m_nNum = 0
                        fakeParams:at(i).m_account = account
                        fakeParams:at(i).m_stock.m_strMarket = k1
                        fakeParams:at(i).m_stock.m_strCode = v2
                        fakeParams:at(i).m_stock.m_strName = v2
                        fakeParams:at(i).m_eOperationType = OPT_BUY
                        fakeParams:at(i).m_nHedgeFlag = k
                        i = i + 1
                        --rcprintLog(m_strLogTag .. string.format("fkParam size: %s %s %s", k1, k2, v2))
                    end
                end
            end
        end
        --rcprintLog(m_strLogTag .. string.format("param size:%d, fkParam size:%d", param:size(), fakeParams:size()))
        local units1, numerator, thisNumerator, units1Real = getWeightedSum(assetsRC.m_numerator, fakeParams, false, false)
        local units2 = {}
        local denominator = {}
        local thisDenominator = {}
        local bDenomiatorEnabled = assetsRC.m_denominator[1].m_bEnabled
        if bDenomiatorEnabled == true or bDenomiatorEnabled == nil then -- 为了兼容老的bsonrisk，这里怪怪的
            units2, denominator, thisDenominator = getWeightedSum(assetsRC.m_denominator, fakeParams, false, false)
            bDenomiatorEnabled = true
        else
            units2[1] = nil
            denominator[1] = 1
            thisDenominator[1] = 0
        end

        -- 分子分母按units对应
        local iNumerator2iDenominator = {}
        if 1 == table.getn(denominator) then
            for i1 = 1, table.getn(numerator), 1 do
                iNumerator2iDenominator[i1] = 1
            end
        else
            local dUnitToIdx = {}
            for i2 = 1, table.getn(denominator), 1 do
                local u2 = units2[i2]
                dUnitToIdx[u2] = i2
            end
            for i1 = 1, table.getn(numerator), 1 do
                local u1 = units1[i1]
                iNumerator2iDenominator[i1] = dUnitToIdx[u1]
            end
        end

        local timeout = -1
        if type(assetsRC.m_randomDeduceInterval) == "number" then
            timeout = tonumber(assetsRC.m_randomDeduceInterval)
        else
            timeout = -1   --默认等待为-1
        end

        local stockCodeVec = {}
        local numeraDataVec = {}   --不合规的分子数据
        local denomiDataVec = {}
        local isBreakVec = {}
        for i1 = 1, table.getn(numerator), 1 do
            local n = numerator[i1]
            local u = units1[i1]
            local issuerId = units1Real[i1]
            local i2 = iNumerator2iDenominator[i1]
            if nil ~= i2 then
                local d = denominator[i2]
                if (not isZero(d)) and (not isInvalidDouble(n)) and (not isInvalidDouble(d)) then  -- 分母为0时暂时放过
                    local res, msg, limitRate, direction, iRange, validRate = dealWithWeightedSums(orderInfo, true, assetsRC, net, netValueRate, iRange, n / d, u, msgHeader, true, bDenomiatorEnabled)
                    
                    table.insert(stockCodeVec, issuerId)
                    table.insert(numeraDataVec, n)
                    table.insert(denomiDataVec, d)
                    table.insert(isBreakVec, not validRate)
                    
                    if iRange == nil then
                        iRange = 0
                    end
                    if not validRate then
                        bBreakRule = true
                    end
                    rcprintLog(m_strLogTag .. string.format("single_issuer: assets_id=%d, issuer=%s, rate=%f (%f / %f), iRange=%d, res=%s, msg=%s", assetsRC.m_nID, u, n / d, n, d, iRange, tostring(res), msg))
                    local fundType = getProductFundType(m_productInfo, isParent)   -- 获取产品基金类型
                    if u then
                        if nil == m_accountInfo then
                            rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_FACTORY, n, d, iRange - 1, validRate, fundType, u, CAccountInfo())   --当该单只触发风控比例时，更新推送的数据
                        else
                            rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_FACTORY, n, d, iRange - 1, validRate, fundType, u, m_accountInfo)   --当该单只触发风控比例时，更新推送的数据
                        end
                    end
                    if not res then
                        if assetsRC.m_randomDeduce and 0 ~= direction then
                            local frozenN = getFrozenCommandIndex(m_accountInfos, assetsRC.m_numerator, CStockInfo(), XT_RIR_FACTORY)
                            local frozenD = getFrozenCommandIndex(m_accountInfos, assetsRC.m_denominator, CStockInfo(), XT_RIR_FACTORY)
                            if ((d + frozenD) * limitRate - (n + frozenN)) * (d * limitRate - n) > 0 then   -- 考虑了冻结指令的影响后，不应该改变调仓方向
                                if nil == stockInfo then
                                    -- 容错，其实不应该走到：配了单支，但是实际上单支的没有仓位
                                    rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, '', '', '', (n + frozenN), (d + frozenD) * limitRate, assetsRC.m_randomAppend, msg, timeout)
                                else
                                    -- 配了单支，实际上单支的也有仓位
                                    rcRandomAdjustAccounts(m_accountInfos, assetsRC.m_numerator, '', stockInfo.m_strMarket, stockInfo.m_strCode, (n + frozenN), (d + frozenD) * limitRate, assetsRC.m_randomAppend, msg, timeout)
                                end
                            end
                        end
                    end
                else
                    rcprintDebugLog(m_strLogTag .. string.format("single_issuer: assets_id=%d, stock=%s, rate=(%f / %f)", assetsRC.m_nID, u, n, d))
                    if nil == m_accountInfo and u then
                        local fundType = getProductFundType(m_productInfo) -- 获取产品基金类型
                        rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_FACTORY, n, d, -1, true, fundType, u, CAccountInfo())
                    elseif nil ~= m_accountInfo and u then
                        local fundType = getProductFundType(m_productInfo) -- 获取产品基金类型
                        rcUpdateAssetsData(m_nProductId, assetsRC.m_nID, XT_RIR_FACTORY, n, d, -1, true, fundType, u, m_accountInfo)
                    end
                end
            end
        end

        -- 静态风控数据更新
        local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
        if table.getn(stockCodeVec) > 0 then
            rcUpdateAssetsRCData(m_nProductId, strKeys, bDenomiatorEnabled, stockCodeVec, numeraDataVec, denomiDataVec, isBreakVec, true)
        end
        
        if bBreakRule then
            local warnMsg = ''
            local warnMultipleMsg = ''   --倍数告警信息
            if m_accountInfo ~= nil then
                warnMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo, false)
                warnMultipleMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, m_accountInfo, true)
            else
                warnMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo(), false)
                warnMultipleMsg = rcGetAssetsSingleMsg(m_nProductId, assetsRC.m_nID, CAccountInfo(), true)
            end
            if warnMsg ~= '' then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, warnMsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), warnMsg)
                end
            end
            if warnMultipleMsg ~= '' then
                if m_accountInfo then
                    rcReport(m_nProductId, m_accountInfo, warnMultipleMsg)
                else
                    rcReport(m_nProductId, CAccountInfo(), warnMultipleMsg)
                end
            end
        end
    end
end

-- 轮询一个具体的风控项
function pollingSubFundRule(nRCScopeType, param, isOrderInfo, assetsRC, msgHeader, strObjID)
    -- rcprintLog(m_strLogTag .. string.format('pollingSubFundRule : rule = %s', table2jsonOld(assetsRC)))

    -- 判断分子中是否有单只或者单品种的指标项，分母目前暂时不考虑
    local factorType = nil
    local singleFactorId = nil
    for iFactor = 1, table.getn(assetsRC.m_numerator) do
        local factor = assetsRC.m_numerator[iFactor]

        --当数据库中没有m_nFactorGroupId字段时，默认为没有绝对值
        if factor.m_nFactorGroupId == getInvalidInt() then
            factor.m_nFactorGroupId = -1
        end

        factorType = getFactorType(factor)
        --发现有单只或者单品种之后，跳过之后的赋值
        if singleFactorId == nil and (CONFIG_TYPE_SINGLE_STOCK == factorType or CONFIG_TYPE_SINGLE_PRODUCT == factorType  or CONFIG_TYPE_SINGLE_FACTORY == factorType) then
            singleFactorId = factor.m_nID
            break
        end
    end

    -- 检查风控有效时间
    local isInTimeRange = isSubFundRuleInTimeRange(assetsRC)
    if not isInTimeRange then
        rcprintDebugLog(m_strLogTag .. 'Time not in range, pass')
        local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
        rcUpdateAssetsRCData(m_nProductId, strKeys, false, {}, {}, {}, {}, false)
        return true, ''
    end

    -- 检查风控条件
    if assetsRC.m_condition and assetsRC.m_condition.m_bEnabled then
        local condValue, thisCond = getWeightedSum_allStocks(assetsRC.m_condition.m_value, CCodeOrderParamList().m_params, false, false)
        if not isValueInRange(condValue, assetsRC.m_condition.m_limitRange) then
            rcprintDebugLog(m_strLogTag .. string.format('cond %s curr condition value %f not in range, pass', assetsRC.m_description, condValue))
            local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
            rcUpdateAssetsRCData(m_nProductId, strKeys, false, {}, {}, {}, {}, false)
            return true, ''
        end
    end

    -- 检查风控设置是否完整
    if not assetsRC.m_netValueConfig                      or
        not assetsRC.m_netValueConfig.m_valueRates         or
        table.getn(assetsRC.m_netValueConfig.m_valueRates) == 0 then
        rcprintDebugLog(m_strLogTag .. 'no net value rate set, psss')
        --净值档位未设置，无需再计算，默认通过
        local strKeys = tostring(nRCScopeType) .. ":" .. tostring(XT_RC_ST_ASSETS) .. ":" .. strObjID .. ":" ..tostring(assetsRC.m_nID)
        rcUpdateAssetsRCData(m_nProductId, strKeys, false, {}, {}, {}, {}, true)
        return true, ''
    end

    -- 计算得到净值档位
    local net = nil
    if assetsRC ~= nil then
        if assetsRC.m_netValueConfig ~= nil then
            local getItemSuccess,configValue = getControlItemValue(assetsRC.m_netValueConfig)
            if getItemSuccess then
                net = configValue
            else
                net = nil
            end
        end
    end

    if not net then
        local description = ''
        if assetsRC.m_description ~= nil then
            description = assetsRC.m_description
        end
        rcprintLog(m_strLogTag .. string.format('风控规则 %s 配置有误或者没有配置风控规则!', description))
        return true, ''
    end
    local success, netValueRate, iRange = getLimitRateByNetValue(assetsRC.m_netValueConfig, net)
    if not success then
        -- 比例设置有误
        -- 测试建议放行：mantis 5193
        rcprintDebugLog(m_strLogTag .. string.format('checkSubFundRule: net_value = %f', net))
        return true, ''
    end

    -- 暂时不考虑单只和单品种同时存在的情况
    if CONFIG_TYPE_SINGLE_STOCK == factorType then
        pollingSubFundRule_singleStock(assetsRC, net, netValueRate, iRange, singleFactorId, nRCScopeType, param, isOrderInfo, msgHeader, strObjID)
    elseif CONFIG_TYPE_SINGLE_PRODUCT == factorType then
        pollingSubFundRule_singleProduct(assetsRC, net, netValueRate, iRange, singleFactorId, nRCScopeType, param, isOrderInfo, msgHeader, strObjID)
    elseif CONFIG_TYPE_SINGLE_FACTORY == factorType then
        pollingSubFundRule_singleIssuer(assetsRC, net, netValueRate, iRange, singleFactorId, nRCScopeType, param, isOrderInfo, msgHeader, strObjID)
    else
        pollingSubFundRule_allStock(assetsRC, net, netValueRate, iRange, nRCScopeType, param, isOrderInfo, msgHeader, XT_RIR_ALL, strObjID)
    end

    return true, ''
end

function checkAccountOpenPositionWithDrawImpl(accountData, accountConfig, m_strProductId, m_strExchangeId, m_strInstrumentId, m_nNum, nId, optType, m_nHedgeFlag, orderInfo)
    -- rcprintLog(m_strLogTag .. "checkAccountOpenPositionWithDrawImpl, m_strProductId:"..m_strProductId.." m_strExchangeId:"..m_strExchangeId.." m_strInstrumentId:"..m_strInstrumentId)
    local accountRCConfig = accountConfig.m_riskControl
    local config = getAccountCompliance(accountRCConfig, m_strProductId)
    local strmsg = ""

    if not accountRCConfig then
        rcprintLog(m_strLogTag .. "accountRCConfig is nil, return true, 合规检查通过")
        return true, strmsg
    end

    if not config then
        rcprintLog(m_strLogTag .. "account compliance config is nil, return true, 合规检查通过")
        return true, strmsg
    end

    if accountData == CAccountData_NULL then
        return true, strmsg
    end

    if (config.m_nWarnOpen == 0 and config.m_nMaxOpen == 0) and
        (config.m_nWarnWithdraw == 0 and config.m_nMaxWithdraw == 0) and
        (config.m_nWarnPosition == 0 and config.m_nMaxPosition == 0) then
        rcprintLog(m_strLogTag .. string.format("用户对品种%s未作任何设置，合规检查直接通过", m_strProductId))
        return true, strmsg
    end

    local strAccountDisplayID = getAccountDisplayID(m_accountInfo)
    local m_bForbidTrade = true  --这个字段原来配置在accountConfig.m_compliance中，但现在被移除，仍保留一个开关来调试
    local eHedgeFlags = config.m_nHedgeFlags
    
    if eHedgeFlags == nil then
        eHedgeFlags = XT_RC_CHECK_HEDGE_FLAG_ALL
    end
    
    if m_nHedgeFlag == nil then
        m_nHedgeFlag = HEDGE_FLAG_SPECULATION
    end
    
    if m_nHedgeFlag == HEDGE_FLAG_SPECULATION and bit.band(eHedgeFlags, XT_RC_CHECK_HEDGE_FLAG_SPECULATION) ~= XT_RC_CHECK_HEDGE_FLAG_SPECULATION then
        return true, strmsg
    elseif m_nHedgeFlag == HEDGE_FLAG_ARBITRAGE and bit.band(eHedgeFlags, XT_RC_CHECK_HEDGE_FLAG_ARBITRAGE) ~= XT_RC_CHECK_HEDGE_FLAG_ARBITRAGE then
        return true, strmsg
    elseif m_nHedgeFlag == HEDGE_FLAG_HEDGE and bit.band(eHedgeFlags, XT_RC_CHECK_HEDGE_FLAG_HEDGE) ~= XT_RC_CHECK_HEDGE_FLAG_HEDGE then
        return true, strmsg
    end
    
    --检查合约最大持仓量
    local now = 0
    if isFtOpen(optType) then
        now = rcGetAccountPosition(accountData, m_strInstrumentId, eHedgeFlags, -1, m_strProductId, m_strExchangeId, orderInfo, nId)
        rcprintDebugLog(m_strLogTag .. "check maxposition, "..m_strInstrumentId.." now:"..now..", open:"..m_nNum..", max:"..config.m_nMaxPosition..", warn:"..config.m_nWarnPosition)
        now = now + m_nNum --加上开仓量
        if not isInvalidInt(config.m_nMaxPosition) and config.m_nMaxPosition > 0  and now >= config.m_nMaxPosition then
            --检查禁止值
            if m_bForbidTrade == true then
                strmsg = string.format("合约%s当前持仓为%d手, 开仓%d手, 将大于等于最大允许持仓量%d手, 禁止开仓!", m_strInstrumentId, now-m_nNum, m_nNum, config.m_nMaxPosition)
                rcprintLog(m_strLogTag .. strmsg)
                return false, strmsg
            else
                strmsg = string.format("合约%s当前持仓为%d手, 开仓%d手, 将大于等于最大允许持仓量%d手!", m_strInstrumentId, now-m_nNum, m_nNum, config.m_nMaxPosition)
                rcprintLog(m_strLogTag .. strmsg)
                local errMsg = genAccountMsgTag(nId)..strmsg
                rcReport(m_nProductId, m_accountInfo, errMsg)
            end
        else
            --检查报警值
            if not m_bTester then
                if not isInvalidInt(config.m_nWarnPosition) and config.m_nWarnPosition > 0  and now >= config.m_nWarnPosition then
                    strmsg = string.format("合约%s当前持仓为%d手, 开仓%d手, 将大于等于持仓量报警阈值%d手!", m_strInstrumentId, now-m_nNum, m_nNum, config.m_nWarnPosition)
                    rcprintLog(m_strLogTag .. strmsg)
                    local errMsg = genAccountMsgTag(nId)..strmsg
                    rcReport(m_nProductId, m_accountInfo, errMsg)
                end
            end
        end
    end

    --检查品种最大开仓手数
    if isFtOpen(optType) then
        now = rcGetAccountOpen(accountData, m_strProductId, eHedgeFlags, -1, m_strExchangeId, orderInfo, nId)
        rcprintDebugLog(m_strLogTag .. "check maxopen, "..m_strProductId.." now:"..now..", open:"..m_nNum..", max:"..config.m_nMaxOpen..", warn:"..config.m_nWarnOpen)
        now = now + m_nNum --加上开仓量
        if not isInvalidInt(config.m_nMaxOpen) and config.m_nMaxOpen > 0 and now >= config.m_nMaxOpen then
            if m_bForbidTrade == true then
                strmsg = string.format("品种%s当前开仓量为%d手, 开仓%d手, 将大于等于最大允许开仓量%d手, 禁止开仓!", m_strProductId, now-m_nNum, m_nNum, config.m_nMaxOpen)
                rcprintLog(m_strLogTag .. strmsg)
                return false, strmsg
            else
                strmsg = string.format("品种%s当前开仓量为%d手, 开仓%d手, 将大于等于最大允许开仓量%d手!",m_strProductId, now-m_nNum, m_nNum, config.m_nMaxOpen)
                rcprintLog(m_strLogTag .. strmsg)
                local errMsg = genAccountMsgTag(nId)..strmsg
                rcReport(m_nProductId, m_accountInfo, errMsg)
            end
        else
            --检查报警值
            if not m_bTester then
                if not isInvalidInt(config.m_nWarnOpen) and config.m_nWarnOpen > 0  and now >= config.m_nWarnOpen then
                    strmsg = string.format("品种%s当前开仓量为%d手, 开仓%d手, 将大于等于开仓量报警阈值%d!", m_strProductId, now-m_nNum, m_nNum, config.m_nWarnOpen)
                    rcprintLog(m_strLogTag .. strmsg)
                    local errMsg = genAccountMsgTag(nId)..strmsg
                    rcReport(m_nProductId, m_accountInfo, errMsg)
                end
            end
        end
    end

    --检查最大撤单次数(针对合约)
    now = rcGetAccountWithDraw(accountData, m_strInstrumentId, eHedgeFlags, -1, m_strProductId, m_strExchangeId, orderInfo, nId)
    rcprintDebugLog(m_strLogTag .. "Checking Maxwithdraw, "..m_strInstrumentId.." now:"..now..", max:"..config.m_nMaxWithdraw..", warn:"..config.m_nWarnWithdraw)
    if not isInvalidInt(config.m_nMaxWithdraw) and config.m_nMaxWithdraw > 0 and now >= config.m_nMaxWithdraw then
        if m_bForbidTrade == true then
            if isFtOpen(optType) then
                strmsg = string.format("合约%s当前撤单次数已达%d, 大于等于最大允许撤单次数%d, 禁止开仓!", m_strInstrumentId, now, config.m_nMaxWithdraw)
            else
                strmsg = string.format("合约%s当前撤单次数已达%d, 大于等于最大允许撤单次数%d, 禁止平仓!", m_strInstrumentId, now, config.m_nMaxWithdraw)
            end
            rcprintLog(m_strLogTag .. strmsg)
            return false, strmsg
        else
            strmsg = string.format("合约%s当前撤单次数已达%d, 大于等于最大允许撤单次数%d!", m_strInstrumentId, now, config.m_nMaxWithdraw)
            rcprintLog(m_strLogTag .. strmsg)
            local errMsg = genAccountMsgTag(nId)..strmsg
            rcReport(m_nProductId, m_accountInfo, errMsg)
        end
    else
        if not m_bTester then
            if not isInvalidInt(config.m_nWarnWithdraw) and config.m_nWarnWithdraw > 0  and now >= config.m_nWarnWithdraw then
                strmsg = string.format("合约%s当前撤单次数已达%d, 大于等于撤单次数报警阈值%d!", m_strInstrumentId, now, config.m_nWarnWithdraw)
                rcprintLog(m_strLogTag .. strmsg)
                local errMsg = genAccountMsgTag(nId)..strmsg
                rcReport(m_nProductId, m_accountInfo, errMsg)
            end
        end
    end

    return true, ""
end

function checkAccountOpenPositionWithDraw(accountData, accountConfig, m_strProductId, m_strExchangeId, m_strInstrumentId, m_nNum, nId, optType, m_nHedgeFlag, param)
    local isArbitrage = rcIsArbitrage(m_strExchangeId, m_strInstrumentId)
    if isArbitrage then
        local code1 = rcGetArbitrageCode1(m_strExchangeId, m_strInstrumentId)
        local res1, msg1 = checkAccountOpenPositionWithDrawImpl(accountData, accountConfig, m_strProductId, m_strExchangeId, code1, m_nNum, nId, optType, m_nHedgeFlag, param)
        if not res1 then
            return res1, msg1
        end
        local code2 = rcGetArbitrageCode2(m_strExchangeId, m_strInstrumentId)
        local res2, msg2 = checkAccountOpenPositionWithDrawImpl(accountData, accountConfig, m_strProductId, m_strExchangeId, code2, m_nNum, nId, optType, m_nHedgeFlag, param)
        return res2, msg2
    else
        return checkAccountOpenPositionWithDrawImpl(accountData, accountConfig, m_strProductId, m_strExchangeId, m_strInstrumentId, m_nNum, nId, optType, m_nHedgeFlag, param)
    end
end

local function genTradeTypeMsg(operation, accountType)
    if accountType == AT_NEW3BOARD then -- 新三板类型
        if operation == XT_TRADE_LIMIT_N3B_PRICE_BUY then
            return '禁止定价买入! '
        elseif operation == XT_TRADE_LIMIT_N3B_PRICE_SELL then
            return '禁止定价卖出! '
        elseif operation == XT_TRADE_LIMIT_N3B_LIMIT_PRICE_BUY then
            return '禁止限价买入! '
        elseif operation == XT_TRADE_LIMIT_N3B_LIMIT_PRICE_SELL then
            return '禁止限价卖出! '
        end
    elseif AT_STOCK_OPTION == accountType then -- 期权类型
        if operation == XT_TRADE_LIMIT_OPTION_BUY_OPEN then
            return '禁止买入开仓！'
        elseif operation == XT_TRADE_LIMIT_OPTION_SELL_CLOSE then
            return '禁止卖出平仓！'
        elseif operation == XT_TRADE_LIMIT_OPTION_SELL_OPEN then
            return '禁止卖出开仓！'
        elseif operation == XT_TRADE_LIMIT_OPTION_BUY_CLOSE then
            return '禁止买入平仓！'
        elseif operation == XT_TRADE_LIMIT_OPTION_COVERED_OPEN then
            return '禁止备兑开仓！'
        elseif operation == XT_TRADE_LIMIT_OPTION_COVERED_CLOSE then
            return '禁止备兑平仓！'
        elseif operation == XT_TRADE_LIMIT_OPTION_EXERCISE then
            return '禁止行权！'
        elseif operation == XT_TRADE_LIMIT_OPTION_SECU_LOCK then
            return '禁止锁定！'
        end
    elseif AT_FUTURE == accountType or AT_FUTURE_OPTION == accountType then -- 期货类型
        if operation == XT_TRADE_LIMIT_BUY then
            return '禁止开仓! '
        elseif operation == XT_TRADE_LIMIT_SELL then
            return '禁止平仓! '
        end
    elseif AT_STOCK == accountType then -- 股票类型
        if operation == XT_TRADE_LIMIT_BUY then
            return '禁止买入! '
        elseif operation == XT_TRADE_LIMIT_FIN_BUY then
            return '禁止融资买入! '
        elseif operation == XT_TRADE_LIMIT_SLO_SELL then
            return '禁止融券卖出! '
        elseif operation == XT_TRADE_LIMIT_SELL then
            return '禁止卖出! '
        end
    elseif AT_HUGANGTONG == accountType then
        if operation == XT_TRADE_LIMIT_BUY then
            return '禁止买入! '
        elseif operation == XT_TRADE_LIMIT_SELL then
            return '禁止卖出! '
        end
    end

    --不可能走此分支
    return '禁止此操作! '
end

-- @brief 检查交易限制
-- @param[in] limits 限制条件，格式为C++的COperationTypedStockRC结构的数组
-- @param[in] accountType  账号类型
-- @param[in] exchangeID   交易所ID
-- @param[in] instrumentID 合约ID
-- @param[in] operation    1,开仓或买入  2,融资买入   4,融券卖出
function checkTradeLimit(limits, accountType, exchangeID, instrumentID, operation)
    local bInConditions = false
    if 0 == operation then
        return true, bInConditions
    end

    if not limits then
        return false, bInConditions
    end

    local limitType = XT_BROKER_TYPE_TRADELIMIT_STOCK
    if AT_FUTURE == accountType then
        limitType = XT_BROKER_TYPE_TRADELIMIT_FUTURE
    elseif AT_STOCK_OPTION == accountType then
        limitType = XT_BROKER_TYPE_TRADELIMIT_STOCK_OPTION
    elseif AT_NEW3BOARD == accountType then -- 新三板类型
        limitType = XT_BROKER_TYPE_TRADELIMIT_NEW3BOARD
    elseif AT_HUGANGTONG == accountType then
        limitType = XT_BROKER_TYPE_TRADELIMIT_HGT
    elseif AT_FUTURE_OPTION == accountType then
        limitType = XT_BROKER_TYPE_TRADELIMIT_FUTURE_OPTION
    end

    local productCheckRes = ""
    for iLimit = 1, table.getn(limits) do
        local v = limits[iLimit]

        --assert(table.getn(v.m_nCatalogID) == table.getn(v.m_logicalOperation))
        if v.m_nType == limitType then
            local pass = true
            local limitCheckRes = ""    -- 代码位于于分类内则添加1，否则添加0，针对其他交易类型特殊处理
            
            -- 针对期权的锁定操作单独判断，因为锁定备兑持仓的判断不同于期权合约的判断逻辑
            if limitType == 3 and operation == XT_TRADE_LIMIT_OPTION_SECU_LOCK then
                if not rcIsStockInOption(exchangeID, instrumentID) then
                    pass = false
                    limitCheckRes = limitCheckRes .. "3"    -- 特殊处理
                end
            else
                for i = 1, table.getn(v.m_nCatalogID) do
                    local logicalOpt = v.m_logicalOperation[i]  -- 1:非运算，其他:无操作
                    if logicalOpt == 1 and not rcIsStockInCategoryWithoutName(exchangeID, instrumentID, v.m_nCatalogID[i])  then
                        --do nothing
                        limitCheckRes = limitCheckRes .. "0"
                    elseif logicalOpt ~= 1 and rcIsStockInCategoryWithoutName(exchangeID, instrumentID, v.m_nCatalogID[i]) then
                        --do nothing
                        limitCheckRes = limitCheckRes .. "1"
                    else
                        if limitType == 4 and operation == 15 then -- 对于新三板轮询由于也可能存在证券分类，再检查一遍所有证券
                            if logicalOpt == 1 and not rcIsStockInCategoryWithoutName(exchangeID, instrumentID, 1001)  then
                                --do nothing
                                limitCheckRes = limitCheckRes .. "4"    -- 特殊处理
                            elseif logicalOpt ~= 1 and rcIsStockInCategoryWithoutName(exchangeID, instrumentID, 1001) then
                                --do nothing
                                limitCheckRes = limitCheckRes .. "4"    -- 特殊处理
                            else
                                if rcIsStockInCategoryWithoutName(exchangeID, instrumentID, v.m_nCatalogID[i]) then
                                    limitCheckRes = limitCheckRes .. "1"
                                else
                                    limitCheckRes = limitCheckRes .. "0"
                                end
                                pass = false
                                break
                            end
                        else
                            if rcIsStockInCategoryWithoutName(exchangeID, instrumentID, v.m_nCatalogID[i]) then
                                limitCheckRes = limitCheckRes .. "1"
                            else
                                limitCheckRes = limitCheckRes .. "0"
                            end
                            pass = false
                            break
                        end
                    end
                end
            end
            
            if iLimit == 1 then
                productCheckRes = limitCheckRes
            else
                productCheckRes = string.format("%s|%s", productCheckRes, limitCheckRes)
            end
            
            if pass then
                bInConditions = true
                local res = bit.band(v.m_nOperation, operation)
                if res ~= 0 then
                    return true, bInConditions, productCheckRes
                end
            end
        else
            -- 类型对不上，不检查
            if iLimit == 1 then
                productCheckRes = "_"
            else
                productCheckRes = string.format("%s|_", productCheckRes)
            end
        end
    end

    return false, bInConditions, productCheckRes
end

function isMyProduct(accountInfos, codeOrderParam)
    for i = 0, accountInfos:size() - 1 do
        if isMyAccount(accountInfos:at(i), codeOrderParam) then
            return true
        end
    end
    return false
end

-- 产品交易限制
-- @param[in] param       下单信息，格式为COrderInfoPtr 或者 std::vector<ttservice::CCodeOrderParam>
-- @param[in] fundConfig  基金配置信息，格式为CSubFundRCConfig
-- @param[in] isOrderInfo 确定param的格式
-- @param[in] fundType    A基金或B基金
-- @return v1, v2
-- @retval v1=true  通过
-- @retval v1=false 拒绝，v2为string，拒绝的原因
-- @note 检查基本原则，只要显性的说明允许交易，则交易之，否则拒单
function checkSubFundTradeType(param, fundConfig, isOrderInfo, results)
    if not param  or
       (not isOrderInfo and 0 == param:size()) then
        -- 下单参数非法,
        return true, ''
    end

    -- 未设置产品交易限制,默认允许交易
    if not fundConfig.m_operationRCs               or
        0 == table.getn(fundConfig.m_operationRCs)  then
        return true, ''
    end
    
    local bEnableDefaultSell = true
    if nil ~= fundConfig.m_bDefaultEnableSell then
        bEnableDefaultSell = fundConfig.m_bDefaultEnableSell
    end

    -- 执行到此, table.getn(fundConfig.m_operationRCs)一定大于0
    assert(table.getn(fundConfig.m_operationRCs) > 0)
    -- 筛选出需要check的COperationRC
    local validOperationRCs = {}
    for i = 1, table.getn(fundConfig.m_operationRCs) do
        local operationRC = fundConfig.m_operationRCs[i]
        if operationRC.m_operations                        and
            table.getn(operationRC.m_operations) >0         and
            nowInTimeRange(operationRC.m_validTimeRange)    and
            passCondition(operationRC.m_condition, operationRC.m_description)    then
            table.insert(validOperationRCs, operationRC)
        end
    end


    if 0 == table.getn(validOperationRCs) then
        if isOrderInfo then
            local operation = getOperation(param.m_eOperationType, param.m_accountInfo.m_nBrokerType)
            assert(operation ~= 0)   --前面的判断已经过滤
            if bEnableDefaultSell and operation == XT_TRADE_LIMIT_SELL then
                return true, ''
            end
            local strmsg = string.format(' 当前没有有效的交易限制,对%s,%s', param.m_strInstrumentId, genTradeTypeMsg(operation, param.m_accountInfo.m_nBrokerType))
            return false, strmsg
        else
            --遍历所有的订单
            for i = 0, param:size()-1 do
                local p = param:at(i)
                local operation = getOperation(p.m_eOperationType, p.m_account.m_nBrokerType)      
                if 0 ~= operation and not (bEnableDefaultSell and operation == XT_TRADE_LIMIT_SELL) then
                    local strmsg = string.format(' 当前没有有效的交易限制,对%s,%s', p.m_stock.m_strCode, genTradeTypeMsg(operation, p.m_account.m_nBrokerType))
                    if nil ~= results then
                        -- test
                        if i < results:size() and results:at(i):isSuccess() then
                            results:at(i):setErrorId(-1)
                            results:at(i):setErrorMsg(strmsg)
                        end
                    else
                        return false, strmsg
                    end
                end
            end
            return true, ''    --全部为平仓操作的单,放行
        end
    end

    local exchangeID   = ''
    local instrumentID = ''
    local operation    = 0
    local accountType  = 0
    local bPassCheck = false
    local bInConditions = false
    local bInACondition = false
    if isOrderInfo then
        exchangeID   = param.m_strExchangeId
        instrumentID = param.m_strInstrumentId
        accountType  = param.m_accountInfo.m_nBrokerType
        operation    = getOperation(param.m_eOperationType, accountType)
        assert(operation ~= 0)   --前面的判断已经过滤
        local operationCheckRes = ""
        for i=1, table.getn(validOperationRCs) do
            local operationRC = validOperationRCs[i]
            bPassCheck, bInACondition, paramCheckRes = checkTradeLimit(operationRC.m_operations, accountType, exchangeID, instrumentID, operation)
            --operationCheckRes = string.format("%s[%s]", operationCheckRes, paramCheckRes)
            if bPassCheck then
                return true, ''
            end
            if bInACondition then 
                bInConditions = true
            end
        end
        --rcprintLog(m_strLogTag .. string.format("checkTradeLimit res %s%s op:%s order check result:%s", exchangeID, instrumentID, p.m_eOperationType, operationCheckRes))
        if bEnableDefaultSell and (operation == XT_TRADE_LIMIT_SELL) and (not bInConditions) then
            return true, ''
        end 
        -- 未找到可以放行的条件， 默认拒绝
        strmsg = string.format('在有效的交易限制中没有找到对%s允许通过的条件,对%s,%s', instrumentID, instrumentID, genTradeTypeMsg(operation, accountType))
        return false, strmsg
    else
        --指令或任务
        for i = 0, param:size() - 1 do
            local p = param:at(i)
            if isMyProduct(m_accountInfos, p) then
                exchangeID   = p.m_stock.m_strMarket
                instrumentID = p.m_stock.m_strCode
                accountType  = p.m_account.m_nBrokerType
                operation    = getOperation(p.m_eOperationType, accountType)
                if operation ~= 0 and operation ~= OPT_OPTION_NS_WITHDRAW and operation ~= OPT_OPTION_NS_DEPOSIT then
                    local passThisOrder = false
                    bInConditions = false
                    
                    local operationCheckRes = ""
                    for i = 1, table.getn(validOperationRCs) do
                        local operationRC = validOperationRCs[i]
                        bPassCheck, bInACondition, paramCheckRes = checkTradeLimit(operationRC.m_operations, accountType, exchangeID, instrumentID, operation)
                        operationCheckRes = string.format("%s[%s]", operationCheckRes, paramCheckRes)
                        if bPassCheck then
                            passThisOrder = true
                            break --check next order
                        end
                        if bInACondition then
                            bInConditions = true
                        end
                    end
                    if not passThisOrder or param:size() < 10 then
                        rcprintLog(m_strLogTag .. string.format("checkTradeLimit res %s%s op:%s param check result:%s, %s", exchangeID, instrumentID, p.m_eOperationType, tostring(bPassCheck), operationCheckRes))
                    end
                    if not passThisOrder then
                        if not (bEnableDefaultSell and (operation == XT_TRADE_LIMIT_SELL) and (not bInConditions)) then
                            -- 未找到可以放行的条件， 默认拒绝
                            strmsg = string.format('在有效的交易限制中没有找到对%s允许通过的条件,对%s,%s', instrumentID, instrumentID, genTradeTypeMsg(operation, accountType))
                            if nil ~= results then
                                -- test
                                if i < results:size() and results:at(i):isSuccess() then
                                    results:at(i):setErrorId(-1)
                                    results:at(i):setErrorMsg(strmsg)
                                end
                            else
                                -- check
                                return false, strmsg
                            end
                        end
                    end
                end
            end
        end

        return true, ''   --全部为平仓操作或者交易限制允许其操作,放行
    end
end

function isStopLossForbidenOpenPosition(fundConfig, param, isOrderInfo, testInfo, msgHeader)
    local is_open = false
    if not isOrderInfo then
        if param then
            for i = 0, param:size() - 1 , 1 do
                local stock = param:at(i)
                if isStkOpen(stock.m_eOperationType) or isFtOpen(stock.m_eOperationType) then
                    is_open = true
                end
                if is_open then
                    break
                end
            end
        end
    end

    if not is_open then
        return false, ''
    end

    local stopLossTypeVec = rcGetStopLoss(m_nProductId)
    local size = stopLossTypeVec:size()
    if 0 == size then
        return false, ''
    end

    local cont = true
    for i = 0, size - 1, 1 do
        local stopLossType = stopLossTypeVec:at(i)
        local stopLossConfig = nil
        if XT_NETVALUE_STOPLOSS == stopLossType then
            stopLossConfig = fundConfig.m_netValueStoploss
        elseif XT_NETVALUE_LOSS_STOPLOSS == stopLossType then
            stopLossConfig = fundConfig.m_netValueLossStopLoss
        elseif XT_MAX_RETRACE_STOPLOSS == stopLossType then
            stopLossConfig = fundConfig.m_retraceStopLoss
        elseif XT_HISTORY_MAX_RETRACE_STOPLOSS == stopLossType then
            stopLossConfig = fundConfig.m_historyRetraceStopLoss
        end

        local forbidenOpenPosition = false
        if nil ~= stopLossConfig.m_forbidenOpenPosition then
            forbidenOpenPosition = stopLossConfig.m_forbidenOpenPosition
        end

        if forbidenOpenPosition and not isOrderInfo then
            local stopLossCmdIdVec = rcGetProductTypedStopLossCmd(m_nProductId, stopLossType)   -- 获取产品该类型止损指令
            local stocks = param
            if stocks and stopLossCmdIdVec:size() > 0 then
                for i = 0, stocks:size() - 1, 1 do
                    local stock = stocks:at(i)
                    local m_stock = stock.m_stock
                    if m_stock then
                        local market = m_stock.m_strMarket
                        local code = m_stock.m_strCode
                        local name = m_stock.m_strName
                        if not rcIsCommandInOpenPositionWhiteList(m_nProductId, stopLossType, market, code, name) then
                            local msg = string.format("触发止损%s, 禁止开仓!", getCmdIdString(stopLossCmdIdVec))
                            rcprintLog(m_strLogTag .. msg)
                            if nil ~= testInfo and type(msgHeader) == 'string' then
                                -- 风控试算
                                -- 虽然说未来这个东西考虑扩展成按分类来允许开仓的，那样的话按对应到某支是合理的
                                -- 不过暂时是简单粗暴的禁止开仓的，从这个角度上来说还是当成全局的错误显示比较合理
                                appendTTError(testInfo, -1, msgHeader .. msg)
                                cont = false
                                break
                            else
                                -- 下单检查
                                return true, msg
                            end
                        end
                    end
                end
            else
                rcprintLog(m_strLogTag .. string.format("product %d %d stopLoss cmd not found", m_nProductId, stopLossType))
            end
        end

        if not cont then
            break
        end
    end

    return false, ''
end

function setTTError(testInfo, i, errorId, errorMsg)
    local e = testInfo.m_testResults:at(i)
    if e:isSuccess() then
        e:setErrorId(errorId)
        e:setErrorMsg(errorMsg)
    end
end

function batchSetTTError(accountInfo, testInfo, errorId, errorMsg)
    local size = testInfo.m_cmd.m_stockParams:size()
    if size > testInfo.m_testResults:size() then size = testInfo.m_testResults:size() end

    for i = 0, size - 1, 1 do
        if isMyAccount(accountInfo, testInfo.m_cmd.m_stockParams:at(i)) then
            setTTError(testInfo, i, -1, errorMsg)
        end
    end
end

function batchSetSingleStockTTError(accountInfo, stockCode, testInfo, errorId, errorMsg)
    local size = testInfo.m_cmd.m_stockParams:size()
    if size > testInfo.m_testResults:size() then size = testInfo.m_testResults:size() end

    for i = 0, size - 1, 1 do
        if isMyAccount(accountInfo, testInfo.m_cmd.m_stockParams:at(i)) and testInfo.m_cmd.m_stockParams:at(i).m_stock.m_strCode == stockCode then
            setTTError(testInfo, i, -1, errorMsg)
        end
    end
end

function batchSetSingleProductTTError(accountInfo, productCode, testInfo, errorId, errorMsg)
    local size = testInfo.m_cmd.m_stockParams:size()
    if size > testInfo.m_testResults:size() then size = testInfo.m_testResults:size() end

    for i = 0, size - 1, 1 do
        if isMyAccount(accountInfo, testInfo.m_cmd.m_stockParams:at(i)) and testInfo.m_cmd.m_stockParams:at(i).m_stock.m_strProduct == productCode then
            setTTError(testInfo, i, -1, errorMsg)
        end
    end
end

function batchSetSingleFactoryTTError(accountInfo, issuerId, testInfo, errorId, errorMsg)
    local size = testInfo.m_cmd.m_stockParams:size()
    if size > testInfo.m_testResults:size() then size = testInfo.m_testResults:size() end

    for i = 0, size - 1, 1 do
        if isMyAccount(accountInfo, testInfo.m_cmd.m_stockParams:at(i)) and rcGetIssuerId(testInfo.m_cmd.m_stockParams:at(i).m_stock.m_strMarket, testInfo.m_cmd.m_stockParams:at(i).m_stock.m_strCode) == issuerId then
            setTTError(testInfo, i, -1, errorMsg)
        end
    end
end

function appendTTError(testInfo, errorId, errorMsg)
    local e = TTError()
    e:setErrorId(errorId)
    e:setErrorMsg(errorMsg)
    testInfo.m_overallResults:push_back(e)
end

function checkStkAccountCompliance(accountInfo, accountConfig, strExchangeId, eOperationType)
    local accountRCConfig = accountConfig.m_riskControl
    local strmsg = ""

    --rcprintLog(m_strLogTag .. "checkStkAccountCompliance: " .. tostring(accountConfig) .. strExchangeId .. tostring(eOperationType))
    if not accountRCConfig then
        rcprintLog(m_strLogTag .. "accountRCConfig is nil, return true, 合规检查通过")
        return true, strmsg
    end

    if not accountRCConfig.m_stkCompliances then
        rcprintLog(m_strLogTag .. "account compliance config is empty, return true, 合规检查通过")
        return true, strmsg
    end
    
    local config = accountRCConfig.m_stkCompliances
    if not config then
        rcprintLog(m_strLogTag .. "account compliance config is nil, return true, 合规检查通过")
        return true, strmsg
    end
    
    -- RuleID SH置为0， SZ置为1
    local ruleID = 0
    if strExchangeId == "SH" then
        ruleID = 0
    elseif strExchangeId == "SZ" then
        ruleID = 1
    end

    local cancelRatioRCData = {}
    cancelRatioRCData.m_nTotalOrder         = -1
    cancelRatioRCData.m_nJunkOrder          = -1
    cancelRatioRCData.m_nCancelOrder        = -1
    cancelRatioRCData.m_nOrderedVolume      = -1
    cancelRatioRCData.m_nTradedVolume       = -1
    cancelRatioRCData.m_dCancelRatio        = -1
    cancelRatioRCData.m_dJunkRatio          = -1
    cancelRatioRCData.m_dVolumeRatio        = -1
    cancelRatioRCData.m_bCancelRatioBreak   = false
    cancelRatioRCData.m_bJunkRatioBreak     = false
    cancelRatioRCData.m_bVolumeRatioBreak   = false

    local bForbidCancelRatioBreak = false
    local bWarnCancelRatioBreak = false

    local nTotalOrder = rcGetAccountOrderStatIndex(accountInfo, strExchangeId, XT_RCF_ACCOUNT_STOCKS_TOTAL_ORDER_NUM)
    cancelRatioRCData.m_nTotalOrder = nTotalOrder

    if ( (nil ~= config.m_dWarnCancelRatio and isGreaterTick(config.m_dWarnCancelRatio, 0, POSITIVE_DEAL_ERROR)) or
        (nil ~= config.m_dForbidCancelRatio and isGreaterTick(config.m_dForbidCancelRatio, 0, POSITIVE_DEAL_ERROR)) ) then

        if config.m_nOrderFloor == nil or config.m_nOrderFloor < 0 or (config.m_nOrderFloor >= 0 and nTotalOrder >= config.m_nOrderFloor) then
            local nJunkOrder = rcGetAccountOrderStatIndex(accountInfo, strExchangeId, XT_RCF_ACCOUNT_STOCKS_JUNK_ORDER_NUM)
            if (nTotalOrder > nJunkOrder) then

                local nCancelOrder = rcGetAccountOrderStatIndex(accountInfo, strExchangeId, XT_RCF_ACCOUNT_STOCKS_CANCEL_ORDER_NUM)
                local dCancelRatio = nCancelOrder / (nTotalOrder - nJunkOrder)
                cancelRatioRCData.m_nJunkOrder = nJunkOrder
                cancelRatioRCData.m_nCancelOrder = nCancelOrder
                cancelRatioRCData.m_dCancelRatio = dCancelRatio
                
                if (nil ~= config.m_dForbidCancelRatio and isGreaterTick(config.m_dForbidCancelRatio, 0, POSITIVE_DEAL_ERROR)) and
                    isGreaterEqualTick(dCancelRatio, config.m_dForbidCancelRatio, POSITIVE_DEAL_ERROR) then
                    bForbidCancelRatioBreak = true
                elseif (nil ~= config.m_dWarnCancelRatio and isGreaterTick(config.m_dWarnCancelRatio, 0, POSITIVE_DEAL_ERROR)) and
                    isGreaterEqualTick(dCancelRatio, config.m_dWarnCancelRatio, POSITIVE_DEAL_ERROR) then
                    bWarnCancelRatioBreak = true
                end
                cancelRatioRCData.m_bCancelRatioBreak = bForbidCancelRatioBreak or bWarnCancelRatioBreak
            end
        end
    end

    local bForbidJunkRatioBreak = false
    local bWarnJunkRatioBreak = false
    
    if ( (nil ~= config.m_dWarnJunkRatio and isGreaterTick(config.m_dWarnJunkRatio, 0, POSITIVE_DEAL_ERROR)) or
        (nil ~= config.m_dForbidJunkRatio and isGreaterTick(config.m_dForbidJunkRatio, 0, POSITIVE_DEAL_ERROR)) ) then

        if config.m_nOrderFloor == nil or config.m_nOrderFloor < 0 or (config.m_nOrderFloor >= 0 and nTotalOrder >= config.m_nOrderFloor) then
            local nJunkOrder = rcGetAccountOrderStatIndex(accountInfo, strExchangeId, XT_RCF_ACCOUNT_STOCKS_JUNK_ORDER_NUM)
            if (nTotalOrder > 0) then
                local dJunkRatio = nJunkOrder / nTotalOrder
                cancelRatioRCData.m_nJunkOrder = nJunkOrder
                cancelRatioRCData.m_dJunkRatio = dJunkRatio
                
                if (nil ~= config.m_dForbidJunkRatio and isGreaterTick(config.m_dForbidJunkRatio, 0, POSITIVE_DEAL_ERROR)) and
                    isGreaterEqualTick(dJunkRatio, config.m_dForbidJunkRatio, POSITIVE_DEAL_ERROR) then
                    bForbidJunkRatioBreak = true
                elseif (nil ~= config.m_dWarnJunkRatio and isGreaterTick(config.m_dWarnJunkRatio, 0, POSITIVE_DEAL_ERROR)) and
                    isGreaterEqualTick(dJunkRatio, config.m_dWarnJunkRatio, POSITIVE_DEAL_ERROR) then
                    bWarnJunkRatioBreak = true
                end
                cancelRatioRCData.m_bJunkRatioBreak = bForbidJunkRatioBreak or bWarnJunkRatioBreak
            end
        end
    end

    if (nil ~= config.m_dWarnVolumeRatio and isGreaterTick(config.m_dWarnVolumeRatio, 0, POSITIVE_DEAL_ERROR)) then

        if config.m_nOrderFloor == nil or config.m_nOrderFloor < 0 or (config.m_nOrderFloor >= 0 and nTotalOrder >= config.m_nOrderFloor) then

            local nOrderedVolume = rcGetAccountOrderStatIndex(accountInfo, strExchangeId, XT_RCF_ACCOUNT_STOCKS_ORDERED_VOLUME_NUM)

            if nOrderedVolume > 0 then

                local nTradedVolume = rcGetAccountOrderStatIndex(accountInfo, strExchangeId, XT_RCF_ACCOUNT_STOCKS_TRADED_VOLUME_NUM)
                local dVolumeRatio = nTradedVolume / nOrderedVolume
                cancelRatioRCData.m_nOrderedVolume = nOrderedVolume
                cancelRatioRCData.m_nTradedVolume = nTradedVolume
                cancelRatioRCData.m_dVolumeRatio = dVolumeRatio

                if isLessEqualTick(dVolumeRatio, config.m_dWarnVolumeRatio, POSITIVE_DEAL_ERROR) then
                    cancelRatioRCData.m_bVolumeRatioBreak = true
                end
            end
        end
    end

    rcUpdateCancelRatioRCData(m_nProductId, XT_RC_SCOPE_TYPE_ACCOUNT, m_accountInfo:getKey(), ruleID, cancelRatioRCData)

    if bForbidCancelRatioBreak then
        strmsg = string.format("在%s委托%d次, 撤单%d次, 撤单率%.4f%%超过最大允许撤单率%.4f%%, 禁止操作! ", getMarketName(strExchangeId), cancelRatioRCData.m_nTotalOrder, cancelRatioRCData.m_nCancelOrder, cancelRatioRCData.m_dCancelRatio * 100, config.m_dForbidCancelRatio * 100)
        rcReport(m_nProductId, m_accountInfo, genAccountMsgTag(XT_COrderInfo) .. strmsg)
        rcprintLog(m_strLogTag .. "checkStkAccountCompliance, error:"..strmsg)
        return false, strmsg
    elseif bWarnCancelRatioBreak then
        strmsg = string.format("在%s委托%d次, 撤单%d次, 撤单率%.4f%%超过撤单率报警阈值%.4f%%! ", getMarketName(strExchangeId), cancelRatioRCData.m_nTotalOrder, cancelRatioRCData.m_nCancelOrder, cancelRatioRCData.m_dCancelRatio * 100, config.m_dWarnCancelRatio * 100)
        rcReport(m_nProductId, m_accountInfo, genAccountMsgTag(XT_COrderInfo) .. strmsg)
        rcStopTask(m_accountInfo) -- 违规则暂停所有相关任务
        rcprintLog(m_strLogTag .. "checkStkAccountCompliance, warning:"..strmsg)
    end
    if bForbidJunkRatioBreak then
        strmsg = string.format("在%s委托%d次, 废单%d次，废单率%f%%超过最大允许废单率%f%%，禁止操作！", getMarketName(strExchangeId), cancelRatioRCData.m_nTotalOrder, cancelRatioRCData.m_nJunkOrder, cancelRatioRCData.m_dJunkRatio * 100, config.m_dForbidJunkRatio * 100)
        rcReport(m_nProductId, m_accountInfo, genAccountMsgTag(XT_COrderInfo) .. strmsg)
        rcprintLog(m_strLogTag .. "checkStkAccountCompliance, error:"..strmsg)
        return false, strmsg
    elseif bWarnJunkRatioBreak then
        strmsg = string.format("在%s委托%d次, 废单%d次，废单率%f%%超过废单率报警阈值%f%%！", getMarketName(strExchangeId), cancelRatioRCData.m_nTotalOrder, cancelRatioRCData.m_nJunkOrder, cancelRatioRCData.m_dJunkRatio * 100, config.m_dWarnJunkRatio * 100)
        rcReport(m_nProductId, m_accountInfo, genAccountMsgTag(XT_COrderInfo) .. strmsg)
        rcStopTask(m_accountInfo) -- 违规则暂停所有相关任务
        rcprintLog(m_strLogTag .. "checkStkAccountCompliance, warning:"..strmsg)
    end
    if cancelRatioRCData.m_bVolumeRatioBreak then
        strmsg = string.format("在%s委托%d, 成交%d，成交比%.4f%% 低于成交比报警阈值%.4f%%!", getMarketName(strExchangeId), cancelRatioRCData.m_nOrderedVolume, cancelRatioRCData.m_nTradedVolume, cancelRatioRCData.m_dVolumeRatio * 100, config.m_dWarnVolumeRatio * 100)
        rcReport(m_nProductId, m_accountInfo, genAccountMsgTag(XT_COrderInfo) .. strmsg)
        rcprintLog(m_strLogTag .. "checkStkAccountCompliance, warning:"..strmsg)
    end

    return true, strmsg
end

function checkAccountMaxOrderTimes(accountData, accountConfig, orderInfo)
    local strmsg = ""
    local accountRCConfig = accountConfig.m_riskControl

    if not accountData then
        rcprintLog(m_strLog .. "checkAccountMaxOrderTimes accountData is nil, return true, 数量合规检查通过")
        return true, strmsg
    end

    if not accountRCConfig then
        rcprintLog(m_strLogTag .. "checkAccountMaxOrderTimes accountRCConfig is nil, return true, 数量合规检查通过")
        return true, strmsg
    end

    if not orderInfo then
        rcprintLog(m_strLogTag .. "checkAccountMaxOrderTimes orderInfo is nil, return true, 数量合规检查通过")
        return true, strmsg
    end

    local config = accountRCConfig.m_stkNumericCompliance
    if not config then
        rcprintLog(m_strLogTag .. "checkAccountMaxOrderTimes account numeric compliance config is nil, return true, 数量合规检查通过")
        return true, strmsg
    end

    if config.m_bCheckAccountMaxOrderTimes then
        local nAccountMaxOrderTimes = config.m_nAccountMaxOrderTimes
        local nOrder = rcGetAccountMaxOrderTimes(accountData, orderInfo)
        rcprintDebugLog(m_strLogTag .. string.format("checkAccountMaxOrderTimes maxOrderTimes=%s, nOrder=%s", tostring(nAccountMaxOrderTimes), tostring(nOrder)))
        if (nil ~= nAccountMaxOrderTimes and not isInvalidInt(nAccountMaxOrderTimes) and nAccountMaxOrderTimes >= 0)
            and (nil ~= nOrder and not isInvalidInt(nOrder)) then
            if nOrder > nAccountMaxOrderTimes then
                strmsg = string.format("账号%s报委托%d次, 已超出了单日最大委托%d次, 禁止操作!", getAccountDisplayID(m_accountInfo), nOrder, nAccountMaxOrderTimes)
                return false, strmsg
            end
        end
    end
    return true, strmsg
end

local function checkProductTradeParamsImpl(value, limitValueRange, outputValueRange, categoryName, strParamName)
    if nil ~= limitValueRange and not isValueInRange(value, limitValueRange) then
        local strValue  = ""
        if 0 == limitValueRange.m_valueType then
            strValue = string.format("%.2f%%", value * 100)
        else
            strValue = tostring(value)
        end
        strmsg = string.format(' 在类别"%s"的参数: %s 不合规, 当前值为%s, 需要满足 %s', categoryName, strParamName, strValue, valueRangeToString(outputValueRange, strParamName))
        return false, strmsg
    end
    return true, ""
end

function checkProductTradeParams(fundConfig, codeOrderParam)
    local strmsg = ""
    local ret = true

    if not fundConfig or not codeOrderParam then
        rcprintLog(m_strLogTag .. "checkProductTradeParams fundConfig or codeOrderParams is nil, return true, 交易参数限制检查通过")
        return true, strmsg
    end

    local tradeParamsConfig = fundConfig.m_tradeParams
    if not tradeParamsConfig or table.getn(tradeParamsConfig) == 0 then
        rcprintLog(m_strLogTag .. "checkProductTradeParams product tradeParams config is empty, return true, 交易参数限制检查通过")
        return true, strmsg
    end
    
    if codeOrderParam.m_eOrderType ~= OTP_ALGORITHM and codeOrderParam.m_eOrderType ~= OTP_ALGORITHM2 and codeOrderParam.m_eOrderType ~= OTP_ALGORITHM3 then
        rcprintLog(m_strLogTag .. "checkProductTradeParams 交易类型不是算法交易, 交易参数限制检查通过")
        return true, strmsg
    end

    local market = codeOrderParam.m_stock.m_strMarket
    local code   = codeOrderParam.m_stock.m_strCode

    for i = 1, table.getn(tradeParamsConfig), 1 do
        local tradeParamsRC = tradeParamsConfig[i]

        if tradeParamsRC.m_nCategoryId and rcIsStockInCategoryWithoutName(market, code, tradeParamsRC.m_nCategoryId)
        and tradeParamsRC.m_singleParamLimit then
            for j = 1, table.getn(tradeParamsRC.m_singleParamLimit), 1 do
                local singleParamLimit = tradeParamsRC.m_singleParamLimit[j]

                if singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_dSuperPrice then
                    -- 因为CValueRange转化为字符串时会自动转换成百分数，因此这里计算小数，基准量比例与波动区间下同
                    local dSuperPriceRate = codeOrderParam.m_dSuperPrice / codeOrderParam.m_dFixPrice
                    -- 这里的m_dSuperPrice已经被priceTick四舍五入过了，不再是原来精确的值
                    -- 但是精确的m_dSuperPriceRate也是拿不到了，所以算出m_dSuperPriceRate可能的区间
                    -- priceTick / 2 是dSuperPrice四舍五入可能的最大偏离
                    local priceTick = 0
                    local instrument = rcGetInstrument(market, code)
                    if nil ~= instrument then
                        priceTick = instrument.PriceTick
                    end
                    local dSuperPriceRateDelta = priceTick / 2 / codeOrderParam.m_dFixPrice
                    local looseRange = {}
                    looseRange.m_valueType      = singleParamLimit.m_valueRange.m_valueType
                    looseRange.m_min            = singleParamLimit.m_valueRange.m_min
                    looseRange.m_compMinType    = singleParamLimit.m_valueRange.m_compMinType
                    looseRange.m_max            = singleParamLimit.m_valueRange.m_max
                    looseRange.m_compMaxType    = singleParamLimit.m_valueRange.m_compMaxType
                    if XT_RLT_EX_INVALID ~= looseRange.m_compMinType then
                        looseRange.m_min = looseRange.m_min - dSuperPriceRateDelta
                    end
                    if XT_RLT_EX_INVALID ~= looseRange.m_compMaxType then
                        looseRange.m_max = looseRange.m_max + dSuperPriceRateDelta
                    end
                    ret, strmsg = checkProductTradeParamsImpl(dSuperPriceRate, looseRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "单笔超价(百分比)")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_dSingleVolumeRate then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_dSingleVolumeRate, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "基准量比例")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_dPlaceOrderInterval then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_dPlaceOrderInterval, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "下单间隔")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_dWithdrawOrderInterval then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_dWithdrawOrderInterval, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "撤单间隔")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_nSuperPriceStart then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_nSuperPriceStart, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "超价启用笔数")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_nSingleNumMin then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_nSingleNumMin, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "单笔最小量")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_nSingleNumMax then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_nSingleNumMax, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "单笔最大量")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_dPriceRangeMax
                    or singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_dPriceRangeMin then
                    local dPriceRangeRate = (codeOrderParam.m_dPriceRangeMax - codeOrderParam.m_dPriceRangeMin) / (codeOrderParam.m_dPriceRangeMax + codeOrderParam.m_dPriceRangeMin)
                    -- priceTick是m_dPriceRangeMin和m_dPriceRangeMax分别四舍五入可能造成的最大偏离之和
                    local priceTick = 0
                    local instrument = rcGetInstrument(market, code)
                    if nil ~= instrument then
                        priceTick = instrument.PriceTick
                    end
                    local dPriceRangeRateDelta = priceTick / (codeOrderParam.m_dPriceRangeMax + codeOrderParam.m_dPriceRangeMin)
                    local looseRange = {}
                    looseRange.m_valueType      = singleParamLimit.m_valueRange.m_valueType
                    looseRange.m_min            = singleParamLimit.m_valueRange.m_min
                    looseRange.m_compMinType    = singleParamLimit.m_valueRange.m_compMinType
                    looseRange.m_max            = singleParamLimit.m_valueRange.m_max
                    looseRange.m_compMaxType    = singleParamLimit.m_valueRange.m_compMaxType
                    if XT_RLT_EX_INVALID ~= looseRange.m_compMinType then
                        looseRange.m_min = looseRange.m_min - dPriceRangeRateDelta
                    end
                    if XT_RLT_EX_INVALID ~= looseRange.m_compMaxType then
                        looseRange.m_max = looseRange.m_max + dPriceRangeRateDelta
                    end
                    ret, strmsg = checkProductTradeParamsImpl(dPriceRangeRate, looseRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "波动区间(百分比)")
                    if not ret then
                        return ret, strmsg
                    end
                elseif singleParamLimit.m_nTradeParamFieldId == CCodeOrderParam_m_nMaxOrderCount then
                    ret, strmsg = checkProductTradeParamsImpl(codeOrderParam.m_nMaxOrderCount, singleParamLimit.m_valueRange, singleParamLimit.m_valueRange, tradeParamsRC.m_strCategoryName, "最大委托次数")
                    if not ret then
                        return ret, strmsg
                    end
                end
            end -- for i = 0, tradeParamsRC.m_singleParamLimit:size() - 1, 1
        end -- if rcIsStockInCategoryWithoutName(market, code, tradeParamsRC.m_nCategoryId)
    end -- for i = 0, tradeParamsConfig:size() - 1, 1 do
    return true, strmsg
end

function pollingAccountMaxOrderTimes(accountData, accountConfig)
    if not accountData then
        return true, -1
    end
    
    local accountRCConfig = accountConfig.m_riskControl
    if not accountRCConfig then
        return true, -1
    end

    local config = accountRCConfig.m_stkNumericCompliance
    if not config then
        return true, -1
    end

    if config.m_bCheckAccountMaxOrderTimes then
        local nOrder= rcGetAccountMaxOrderTimes(accountData, COrderInfo())
        local nAccountMaxOrderTimes = config.m_nAccountMaxOrderTimes
        rcprintDebugLog(m_strLogTag .. string.format("checkAccountMaxOrderTimes maxOrderTimes=%s, nOrder=%s", tostring(nAccountMaxOrderTimes), tostring(nOrder)))
        if (nil ~= nAccountMaxOrderTimes and not isInvalidInt(nAccountMaxOrderTimes) and nAccountMaxOrderTimes >= 0)
            and (nil ~= nOrder and not isInvalidInt(nOrder)) then
            if nOrder > nAccountMaxOrderTimes then
                --strmsg = string.format("账号%s报委托%d次，已超出了单日最大委托%d次, 禁止操作！", getAccountDisplayID(m_accountInfo), nOrder, nAccountMaxOrderTimes)
                return false, nOrder
            end
        end
        
        return true, nOrder
    end
    
    return true, -1
end

-- @brief 生成产品单位净值、单位净值跌幅或回撤相关的警告或止损消息
-- @param[in] msgOption 消息生成选项table
-- @note msgOption.stopLossType 是否按照占比显示警告消息
-- @note msgOption.isExecuting 是否按照倍率显示警告消息
-- @note msgOption.nBrokerType 账号类型
-- @note msgOption.autoExe 是否在轮询中生成警告消息
-- @param[in] strProductTag 产品标识
-- @param[in] dNetValue 单位净值
-- @param[in] rcName 风控项名称
-- @param[in] dReference1 考察指标
-- @param[in] dReference2 参考指标
-- @param[in] valueRange 指标范围
-- @param[in] nTimeout 超时自动执行
-- @return 警告信息
function genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOther, valueRange, nTimeout)    
    local referenceMsg = ''
    local rangeTag = ''
    local conclusion = ''
    local autoStopLoss = ''
    --- local default_stoploss_interval = 10   --由于止损需要指令冻结，所以设置一个默认的止损间隔时间 10秒
    
    if XT_NETVALUE_STOPLOSS == msgOption.stopLossType then
        local netValue_min = ""
        local netValue_max = ""

        if "number" == type(valueRange.m_min) and valueRange.m_compMinType ~= XT_RLT_EX_INVALID then
            netValue_min = tostring(valueRange.m_min)
        end

        if "number" == type(valueRange.m_max) and valueRange.m_compMaxType ~= XT_RLT_EX_INVALID then
            netValue_max = tostring(valueRange.m_max)
        end

        rangeTag = string.format('产品单位净值分档[ %s, %s ]', netValue_min, netValue_max)
    elseif XT_NETVALUE_LOSS_STOPLOSS == msgOption.stopLossType then
        referenceMsg = string.format(', 相比前一日%.4f跌幅为%.4f%%', dOther, dReference * 100)
        local lossRate_min = ""
        local lossRate_max = ""
--
        if "number" == type(valueRange.m_min) and valueRange.m_compMinType ~= XT_RLT_EX_INVALID then
            lossRate_min = tostring(valueRange.m_min * 100) .. "%"
        end

        if "number" == type(valueRange.m_max) and valueRange.m_compMaxType ~= XT_RLT_EX_INVALID then
            lossRate_max = tostring(valueRange.m_max * 100) .. "%"
        end
       
        rangeTag = string.format('产品单位净值跌幅分档[ %s , %s ]', lossRate_min, lossRate_max)
        
    elseif XT_MAX_RETRACE_STOPLOSS == msgOption.stopLossType then
        referenceMsg = string.format(', 当日最大回撤为%.4f%%', dReference * 100)
        local retrace_min = ""
        local retrace_max = ""
        
        if "number" == type(valueRange.m_min) and valueRange.m_compMinType ~= XT_RLT_EX_INVALID then
            retrace_min = tostring(valueRange.m_min * 100) .. "%"
        end

        if "number" == type(valueRange.m_max) and valueRange.m_compMaxType ~= XT_RLT_EX_INVALID then
            retrace_max = tostring(valueRange.m_max * 100) .. "%"
        end
        
        rangeTag = string.format('当日最大回撤分档[ %s , %s ]', retrace_min, retrace_max)
    elseif XT_HISTORY_MAX_RETRACE_STOPLOSS == msgOption.stopLossType then
        referenceMsg = string.format(', 历史最大回撤为%.8f%%', dReference * 100)
        local retrace_min = ""
        local retrace_max = ""

        if "number" == type(valueRange.m_min) and valueRange.m_compMinType ~= XT_RLT_EX_INVALID then
            retrace_min = tostring(valueRange.m_min * 100) .. "%"
        end

        if "number" == type(valueRange.m_max) and valueRange.m_compMaxType ~= XT_RLT_EX_INVALID then
            retrace_max = tostring(valueRange.m_max * 100) .. "%"
        end
        
        rangeTag = string.format('历史最大回撤分档[ %s , %s ]', retrace_min, retrace_max)
    else
        return ''
    end
    
    if not msgOption.isExecuting then
        conclusion = '触发报警!'
    end
    
    if msgOption.isExecuting then
        conclusion = '平仓止损!'
    end

    
    if msgOption.isExecuting and msgOption.autoExe and 'number' == type(nTimeout) then
        autoStopLoss = string.format(' %s秒后如未执行则自动执行.', tostring(nTimeout))
    end
    
    local strmsg = string.format('%s当前单位净值为%.4f%s, 处于%s中, %s %s', strProductTag, dNetValue, referenceMsg, rangeTag, conclusion, autoStopLoss)
    return strmsg
end 

-- 检查产品止损配置项
function checkProductStopLossRule(strProductTag, nType, strTypeTag, stopLossConfig, dNetValue, dReference, dOtherRef)
    if nil == stopLossConfig or nil == m_pollingCnt or nil == m_lastPollingCnt then
        return
    end
    
    -- 检查止损条件
    local conditionPassed = passCondition(stopLossConfig.m_condition, '')   

    -- 检查止损有效时间
    local isInTimeRange = true 
    if stopLossConfig.m_validTimeRange ~= nil then
        isInTimeRange = isSubFundRuleInTimeRange(stopLossConfig)
    end
    
    -- 获取止损指标所在的止损区间
    local successRef, refRate = getLimitRateByNetValueStopLoss(stopLossConfig, dReference)  -- 函数名有点不太合适

    local hasRange = true
    if not stopLossConfig.m_rates then
        hasRange = false
    elseif 0 == table.getn(stopLossConfig.m_rates) then
        hasRange = false
    end

    local nScope = 0;
    local strObjID = ""
    if m_nProductId == PRODUCT_ID_PRODUCT_GROUP then
        nScope = XT_RC_SCOPE_TYPE_PRODUCTGROUP
        strObjID = tostring(m_nGroupId)
    else
        nScope = XT_RC_SCOPE_TYPE_PRODUCT
        strObjID = tostring(m_nProductId)
    end
    
    local nDelaySecLeft = getInvalidInt()
    if conditionPassed and isInTimeRange and successRef and refRate and (not m_stoplossing) then
        if isDelayStopLossRateConfig(refRate) then
            nDelaySecLeft = rcJudgeStopLossTimeout(strProductTag .. tostring(m_nProductId) .. strTypeTag, table2json(refRate))
        else
            nDelaySecLeft = 0
        end
    elseif conditionPassed and isInTimeRange and not (successRef and refRate) then
        rcUpdateStopLossRCData(m_nProductId, nScope, strObjID, nType, "", hasRange, dReference, true, false)
        return  -- 不再向下检查了
    elseif not (conditionPassed and isInTimeRange) and successRef and refRate then
        if isDelayStopLossRateConfig(refRate) and m_stoplossing == false then
            rcDelStopLossDelayConfig(strProductTag .. tostring(m_nProductId) .. strTypeTag)
        end
        rcUpdateStopLossRCData(m_nProductId, nScope, strObjID, nType, table2json(refRate.m_valueRange), hasRange, dReference, false, false)
        return  -- 不再向下检查了
    elseif not (conditionPassed and isInTimeRange) and not (successRef and refRate) then
        rcUpdateStopLossRCData(m_nProductId, nScope, strObjID, nType, "", hasRange, dReference, false, false)
        return  -- 不再向下检查了
    end
    
    rcUpdateStopLossRCData(m_nProductId, nScope, strObjID, nType, table2json(refRate.m_valueRange), hasRange, dReference, true, true)
    
    --rcprintLog(m_strLogTag .. " checkProductStopLossRule 3 : " .. tostring(dNetValue) .. " " .. tostring(dReference))
    -- 止损标志m_stoplossing是一个全局变量，定义在RCProductPolling.lua文件中，每次polling开始会置为false，止损后置为true
    if m_stoplossing == false then    
        local msgOption = {}
        local strmsg = ''
        local interval = refRate.m_nWarnInterval
        if type(interval) == 'string' then
            interval = tonumber(interval)
        end

        if interval and interval > 0 then
            rcprintDebugLog(m_strLogTag .. string.format("interval = %s, m_pollingCnt = %s", tostring(interval), tostring(m_pollingCnt)))
            msgOption.stopLossType = nType
            msgOption.isExecuting = false
            msgOption.nBrokerType = nil
            msgOption.autoExe = false
            if isDelayStopLossRateConfig(refRate) then
                if isInvalidInt(nDelaySecLeft) then
                    local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                    if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                        local strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, -1)
                        rcprintLog(m_strLogTag .. strmsg)
                        rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
                    end
                elseif nDelaySecLeft >= 3600 then
                    local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                    if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                        local strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, -1)
                        rcMsg = string.format("%s %s秒后将发出止损指令", strmsg, tostring(nDelaySecLeft))
                        rcprintLog(m_strLogTag .. rcMsg)
                        rcReport(m_nProductId, CAccountInfo(), rcMsg, m_nGroupId)
                    end
                elseif nDelaySecLeft >= 600 then
                    local thisPolling = getIntFromDouble(m_pollingCnt/60)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/60)
                    if (0 == m_pollingCnt%(60)) or (thisPolling - lastPolling >= 1) then
                        local strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, -1)
                        rcMsg = string.format("%s %s秒后将发出止损指令", strmsg, tostring(nDelaySecLeft))
                        rcprintLog(m_strLogTag .. rcMsg)
                        rcReport(m_nProductId, CAccountInfo(), rcMsg, m_nGroupId)
                    end
                elseif nDelaySecLeft > 300 then
                    local thisPolling = getIntFromDouble(m_pollingCnt/30)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/30)
                    if (0 == m_pollingCnt%(30)) or (thisPolling - lastPolling >= 1) then
                        local strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, -1)
                        rcMsg = string.format("%s %s秒后将发出止损指令", strmsg, tostring(nDelaySecLeft))
                        rcprintLog(m_strLogTag .. rcMsg)
                        rcReport(m_nProductId, CAccountInfo(), rcMsg, m_nGroupId)
                    end
                elseif nDelaySecLeft > 0 then
                    local thisPolling = getIntFromDouble(m_pollingCnt/10)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/10)
                    if (0 == m_pollingCnt%(10)) or (thisPolling - lastPolling >= 1) then
                        local strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, -1)
                        rcMsg = string.format("%s %s秒后将发出止损指令", strmsg, tostring(nDelaySecLeft))
                        rcprintLog(m_strLogTag .. rcMsg)
                        rcReport(m_nProductId, CAccountInfo(), rcMsg, m_nGroupId)
                    end
                end
            else
                local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                --rcprintLog(m_strLogTag .. string.format("thisPolling : %d, lastPolling: %d, m_pollingCnt: %d", thisPolling, lastPolling, m_pollingCnt))
                if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                    local strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, -1)
                    rcprintLog(m_strLogTag .. strmsg)
                    rcReport(m_nProductId, CAccountInfo(), strmsg, m_nGroupId)
                end
            end
        else
            rcprintDebugLog(m_strLogTag .. string.format("interval type: %s, num: %s", type(interval), tostring(interval)))
        end

        local isStopLossByCategory = false
        if nil ~= refRate.m_bStopLossByCategory then
            isStopLossByCategory = refRate.m_bStopLossByCategory
        end
        
        local isForbidenOpenPosition = false
        if nil ~= stopLossConfig.m_forbidenOpenPosition then
            isForbidenOpenPosition = stopLossConfig.m_forbidenOpenPosition
        end
        
        rcAddStopLoss(m_nProductId, nType)
        if refRate.m_enableOpenPosition then
            rcSetOpenPositionWhiteList(m_nProductId, nType, refRate.m_enableOpenPosition)
        end
        
        if nDelaySecLeft <= 0 then

            if isStopLossByCategory then
                if isDelayStopLossRateConfig(refRate) then
                    rcSetStopLossDelayConfig(strProductTag .. tostring(m_nProductId) .. strTypeTag, table2json(refRate))
                end
                
                for i = 0, m_accountInfos:size() - 1, 1 do
                    local v = m_accountInfos:at(i)
                    if refRate.m_nClosePositions and v.m_nBrokerType and refRate.m_nTimeout then
                        rcprintDebugLog(m_strLogTag .. string.format("v.m_nBrokerType = %s, refRate.m_nTimeout = %s", tostring(v.m_nBrokerType), tostring(refRate.m_nTimeout)))
                    end
                end
                
                if refRate.m_nTimeout == nil or refRate.m_nTimeout == "" then
                    timeout = -1   -- -1表示一直等待执行
                else
                    if type(refRate.m_nTimout) == 'string' then
                        timeout = tonumber(refRate.m_nTimeout)
                    else
                        timeout = refRate.m_nTimeout
                    end                
                end
                                
                msgOption.stopLossType = nType
                msgOption.isExecuting = true
                if timeout and timeout > 0 then
                    msgOption.autoExe = true
                else
                    msgOption.autoExe = false
                end 
                strmsg = genProductStopLossMsg(msgOption, strProductTag, dNetValue, dReference, dOtherRef, refRate.m_valueRange, timeout)

                local isNeedWarning = false
                if interval and interval > 0 then
                    local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                    if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                        isNeedWarning = true
                    end
                end
                
                local hasStopLossCmd = nil
                if nil ~= refRate.m_categoryInfo then
                    hasStopLossCmd = rcStoplossAll(m_accountInfos, strmsg, timeout, refRate.m_categoryInfo, g_lastStopLossTime, isNeedWarning, m_productInfo.m_nId, nType)
                end
                
                if hasStopLossCmd then
                    g_lastStopLossTime = os.time()
                else
                    local curTime = os.time()
                    local c_stoplossMinInterval = 30
                    rcprintDebugLog(m_strLogTag .. string.format("try stoploss product %d, curtime %s - last_stoploss_time %s less than %d seconds, wait.", m_nProductId, os.date('%H:%M:%S', curTime), os.date('%H:%M:%S', g_lastStopLossTime), c_stoplossMinInterval))                   
                end
                --m_stoplossing = true  -- 有指令冻结了，这东西没什么用了，一直叫他false就行了
            else
                --m_stoplossing = true
                if interval and interval > 0 and not m_bProductGroupRC then
                    local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                    local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                    if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                        local rcMsg = string.format('%s没有配置止损分类，将不会产生止损指令',strProductTag)
                        rcReport(m_nProductId, CAccountInfo(), rcMsg, m_nGroupId)
                        rcUpdateStopLossRCData(m_nProductId, nScope, strObjID, nType, table2json(refRate.m_valueRange), hasRange, getInvalidDouble(), true, false)
                    end
                end
            end
        end
    end
end

function checkAccountMoney(accountConfig, accountData, params, cmdID)
    local strmsg = ""
    if (not accountConfig) or (not accountConfig.m_riskControl) or (not accountConfig.m_riskControl.m_moneyLimit) then
        return true, strmsg
    end

    -- 检查日内最大净买入
    if accountConfig.m_riskControl.m_moneyLimit.m_bCheckMaxBuyMoney then
        local maxLimitMoney = accountConfig.m_riskControl.m_moneyLimit.m_maxBuyMoney
        local curLimitMoney = rcGetAccountMoney(accountData, params, cmdID, false)
        if (nil ~= maxLimitMoney) and isGreaterTick(maxLimitMoney, 0, POSITIVE_DEAL_ERROR) and isGreaterEqualTick(curLimitMoney, maxLimitMoney, POSITIVE_DEAL_ERROR) then
            strmsg = string.format("当前净买入资金%.4f达到当日最大净买入阈值%.4f, 禁止开仓!", curLimitMoney, maxLimitMoney)
            return false, strmsg
        else
            return true, strmsg
        end
    end

    return true, strmsg
end


function pollingAccountMoney(accountConfig, accountData)
    if (not accountConfig) or (not accountConfig.m_riskControl) or (not accountConfig.m_riskControl.m_moneyLimit) then
        return true, getInvalidDouble()
    end

    if accountConfig.m_riskControl.m_moneyLimit.m_bCheckMaxBuyMoney then
        local curLimitMoney = rcGetAccountMoney(accountData, CCodeOrderParamList().m_params, -1, true)
        local maxLimitMoney = accountConfig.m_riskControl.m_moneyLimit.m_maxBuyMoney
        if (nil ~= maxLimitMoney) and isGreaterTick(maxLimitMoney, 0, POSITIVE_DEAL_ERROR) and isGreaterEqualTick(curLimitMoney, maxLimitMoney, POSITIVE_DEAL_ERROR) then
            --strmsg = string.format("当前净买入资金%.4f达到当日最大净买入阈值%.4f，禁止开仓！", curLimitMoney, maxLimitMoney)
            return false, curLimitMoney
        else
            return true, curLimitMoney
        end
    end

    return true, getInvalidDouble()
end


function mergeAutoBlackToGlobalBlackList(nBrokerType, globalConfig)
    local ret = {}
    local typeIndex = nil
    if m_accountInfo == nil then
        return ret, nil
    end
    
    if nBrokerType == AT_STOCK or nBrokerType == AT_CREDIT then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_STOCK
    elseif nBrokerType == AT_NEW3BOARD then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_NEW3BOARD
    elseif nBrokerType == AT_HUGANGTONG then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_HGT
    elseif nBrokerType == AT_STOCK_OPTION then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_STOCKOPTION
    elseif nBrokerType == AT_FUTURE then
        typeIndex = XT_BROKER_TYPE_GLOBALRISK_FUTURE
    else 
        return ret, nil
    end
    
    local codeBW = globalConfig[typeIndex].stocks
    local totalBlack = {}
    if nil ~= codeBW then
        if nil ~= codeBW["black"] then
            for i = 1, #(codeBW["black"]), 1 do
                totalBlack[#totalBlack + 1] = codeBW["black"][i]
            end 
        end
        
        if nil ~= codeBW["auto_black"] then
            for i = 1, #(codeBW["auto_black"]), 1 do
                totalBlack[#totalBlack + 1] = codeBW["auto_black"][i]
            end 
        end
        ret = totalBlack
    end
    return ret, typeIndex
end
