
local function trim(s)
    return s:gsub("%s+", "") .. ""
end

function table2jsonOld(t)
    local function serialize(tbl)
        local tmp = {}
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            local key = (k_type == "string" and "\"" .. k .. "\":")
                or (k_type == "number" and "")
            local value = (v_type == "table" and serialize(v))
                or (v_type == "boolean" and tostring(v))
                or (v_type == "string" and "\"" .. v .. "\"")
                or (v_type == "number" and v)
            if ((v_type ~= "table") or (table.maxn(v) ~= 0) or (value ~= "{}"))
                and ((v_type ~= "number") or ((not isInvalidDouble(v)) and (not isInvalidInt(v)))) then
                tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
            end
        end
        if table.maxn(tbl) == 0 then
            return "{" .. table.concat(tmp, ",") .. "}"
        else
            return "[" .. table.concat(tmp, ",") .. "]"
        end
    end
    if nil == t or type(t) ~= "table" then
        return ""
    end
    return serialize(t)
end

function table2json(t)
    local tab = "    "
    local function serialize(indent, tbl)
        local tmp = {}
        local tempIndent = indent .. tab
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            local key = (k_type == "string" and "\"" .. k .. "\" : ")
                or (k_type == "number" and "")
            local value = (v_type == "table" and serialize(indent .. tab, v))
                or (v_type == "boolean" and tostring(v))
                or (v_type == "string" and "\"" .. v .. "\"")
                or (v_type == "number" and v)
            if (v_type ~= "table") or (table.maxn(v) ~= 0) or (trim(value) ~= "{}") then
                tmp[#tmp + 1] = key and value and (tempIndent .. tostring(key) .. tostring(value) or nil)
            end
        end
        if table.maxn(tbl) == 0 then
            return "{\n" .. table.concat(tmp, ",\n") .. "\n" .. indent .. "}"
        else
            return "[\n" .. table.concat(tmp, ",\n") .. "\n" .. indent .. "]"
        end
    end
    if nil == t or type(t) ~= "table" then
        return ""
    end
    return serialize("", t)
end

function getTableFromMap(maptable, key)
    for i=1, table.getn(maptable), 2 do
        if maptable[i] == key then return maptable[i+1] end
    end
    return nil
end

function getOppositeDirection(nDirection)
    if nDirection == ENTRUST_BUY then
        return ENTRUST_SELL
    else
        return ENTRUST_BUY
    end
end

function getDirectionByOperation(nOperation)
    local isBuy = false;
    if nOperation == OPT_OPEN_LONG then isBuy = true
    elseif nOperation == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG then isBuy = true
    elseif nOperation == OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG then isBuy = true
    elseif nOperation == OPT_CLOSE_SHORT_TODAY then isBuy = true
    elseif nOperation == OPT_CLOSE_SHORT_HISTORY then isBuy = true
    elseif nOperation == OPT_CLOSE_SHORT_TODAY_FIRST then isBuy = true
    elseif nOperation == OPT_CLOSE_SHORT_HISTORY_FIRST then isBuy = true
    elseif nOperation == OPT_BUY then isBuy = true
    elseif nOperation == OPT_FIN_BUY then isBuy = true
    elseif nOperation == OPT_BUY_SECU_REPAY then isBuy = true
    elseif nOperation == OPT_OPTION_BUY_CLOSE then isBuy = true
    elseif nOperation == OPT_OPTION_BUY_OPEN then isBuy = true
    elseif nOperation == OPT_OPTION_COVERED_CLOSE then isBuy = true
    elseif nOperation == OPT_OPTION_CALL_EXERCISE then isBuy = true
    elseif nOperation == OPT_N3B_PRICE_BUY then isBuy = true
    elseif nOperation == OPT_N3B_CONFIRM_BUY then isBuy = true
    elseif nOperation == OPT_N3B_REPORT_CONFIRM_BUY then isBuy = true
    elseif nOperation == OPT_N3B_LIMIT_PRICE_BUY then isBuy = true
    elseif nOperation == OPT_FUND_SUBSCRIBE then isBuy = true
    elseif nOperation == OPT_FUND_MERGE then isBuy = true
    end
    return isBuy;
end

function isLong(nOperation)
    local isLong = false;
    if nOperation == OPT_OPEN_LONG then isLong = true
    elseif nOperation == OPT_CLOSE_LONG then isLong = true
    elseif nOperation == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG then isLong = true
    elseif nOperation == OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG then isLong = true
    elseif nOperation == OPT_CLOSE_LONG_TODAY then isLong = true
    elseif nOperation == OPT_CLOSE_LONG_HISTORY then isLong = true
    elseif nOperation == OPT_CLOSE_LONG_TODAY_FIRST then isLong = true
    elseif nOperation == OPT_CLOSE_LONG_HISTORY_FIRST then isLong = true
    end
    return isLong;
end

--判断期货交易的开仓方向
function isFtOpen(nOperation)
    return nOperation == OPT_OPEN_LONG
        or nOperation == OPT_OPEN_SHORT
        or nOperation == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG
        or nOperation == OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG
        or nOperation == OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT
        or nOperation == OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT
        or nOperation == OPT_OPEN
end

--判断证券交易的开仓方向
--融资融券的还不是很完善，待需求细化
function isStkOpen(nOperation)
    return nOperation == OPT_BUY
        or nOperation == OPT_FIN_BUY
        or nOperation == OPT_SLO_SELL
        or nOperation == OPT_BUY_SECU_REPAY
        or nOperation == OPT_OPTION_BUY_OPEN
        or nOperation == OPT_OPTION_SELL_OPEN
        or nOperation == OPT_OPTION_COVERED_OPEN
        or nOperation == OPT_OPTION_CALL_EXERCISE
        or nOperation == OPT_N3B_PRICE_BUY
        or nOperation == OPT_N3B_CONFIRM_BUY
        or nOperation == OPT_N3B_REPORT_CONFIRM_BUY
        or nOperation == OPT_N3B_LIMIT_PRICE_BUY
        or nOperation == OPT_COLLATERAL_TRANSFER_IN
        or nOperation == OPT_FUND_SUBSCRIBE
        or nOperation == OPT_FUND_MERGE
        or nOperation == OPT_ETF_PURCHASE
end

--判断一条指令或任务中的下单是否为开仓
--CCodeOrderParam.m_eOperationType
function getOperation(eOperationType, accountType)
    local ret = 0
    
    if accountType == AT_NEW3BOARD then -- 新三板类型
        if eOperationType == OPT_N3B_PRICE_BUY then -- 协议转让-定价买入
            ret = XT_TRADE_LIMIT_N3B_PRICE_BUY
        elseif eOperationType == OPT_N3B_PRICE_SELL then -- 协议转让-定价卖出
            ret = XT_TRADE_LIMIT_N3B_PRICE_SELL
        elseif eOperationType == OPT_N3B_LIMIT_PRICE_BUY then -- 做市转让-限价买入
            ret = XT_TRADE_LIMIT_N3B_LIMIT_PRICE_BUY
        elseif eOperationType == OPT_N3B_LIMIT_PRICE_SELL then -- 做市转让-限价卖出
            ret = XT_TRADE_LIMIT_N3B_LIMIT_PRICE_SELL
        end
    elseif AT_STOCK_OPTION == accountType then -- 期权类型
        if eOperationType == OPT_OPTION_BUY_OPEN then -- 买开
            ret = XT_TRADE_LIMIT_OPTION_BUY_OPEN
        elseif eOperationType == OPT_OPTION_SELL_OPEN then -- 卖开
            ret = XT_TRADE_LIMIT_OPTION_SELL_OPEN
        elseif eOperationType == OPT_OPTION_BUY_CLOSE then -- 买平
            ret = XT_TRADE_LIMIT_OPTION_BUY_CLOSE
        elseif eOperationType == OPT_OPTION_SELL_CLOSE then -- 卖平
            ret = XT_TRADE_LIMIT_OPTION_SELL_CLOSE
        elseif eOperationType == OPT_OPTION_COVERED_OPEN then -- 备兑开仓
            ret = XT_TRADE_LIMIT_OPTION_COVERED_OPEN
        elseif eOperationType == OPT_OPTION_COVERED_CLOSE then -- 备兑平仓
            ret = XT_TRADE_LIMIT_OPTION_COVERED_CLOSE
        elseif eOperationType == OPT_OPTION_CALL_EXERCISE
            or eOperationType == OPT_OPTION_PUT_EXERCISE then -- 行权
            ret = XT_TRADE_LIMIT_OPTION_EXERCISE
        elseif eOperationType == OPT_OPTION_SECU_LOCK then -- 锁定
            ret = XT_TRADE_LIMIT_OPTION_SECU_LOCK
        end
    else -- 股票期货类型
        if eOperationType == OPT_OPEN_LONG
            or eOperationType == OPT_OPEN_SHORT
            or eOperationType == OPT_CLOSE_SHORT_TODAY_HISTORY_THEN_OPEN_LONG
            or eOperationType == OPT_CLOSE_SHORT_HISTORY_TODAY_THEN_OPEN_LONG
            or eOperationType == OPT_CLOSE_LONG_TODAY_HISTORY_THEN_OPEN_SHORT
            or eOperationType == OPT_CLOSE_LONG_HISTORY_TODAY_THEN_OPEN_SHORT
            or eOperationType == OPT_OPEN
            or eOperationType == OPT_BUY then -- 买入
            ret = XT_TRADE_LIMIT_BUY
        elseif eOperationType == OPT_FIN_BUY then -- 融资买入
            ret = XT_TRADE_LIMIT_FIN_BUY
        elseif eOperationType == OPT_SLO_SELL then -- 融券卖出
            ret = XT_TRADE_LIMIT_SLO_SELL
        elseif eOperationType == OPT_CLOSE_LONG
            or eOperationType == OPT_CLOSE_SHORT
            or eOperationType == OPT_CLOSE_LONG_HISTORY
            or eOperationType == OPT_CLOSE_LONG_TODAY
            or eOperationType == OPT_CLOSE_SHORT_HISTORY
            or eOperationType == OPT_CLOSE_SHORT_TODAY
            or eOperationType == OPT_CLOSE_LONG_HISTORY_FIRST
            or eOperationType == OPT_CLOSE_LONG_TODAY_FIRST
            or eOperationType == OPT_CLOSE_SHORT_HISTORY_FIRST
            or eOperationType == OPT_CLOSE_SHORT_TODAY_FIRST
            or eOperationType == OPT_CLOSE
            or eOperationType == OPT_SELL then -- 卖出
            ret = XT_TRADE_LIMIT_SELL
        end
    end
    return ret
end

function minValue(i, j)
    if not i then i = 0 end
    if not j then j = 0 end
    if i < j then return i
    else return j
    end
end

function getAccountDisplayID(accountInfo)
    if (nil == accountInfo.m_strSubAccount) or accountInfo.m_strSubAccount == "" then
        if (nil == accountInfo.m_strAccountID) then
            return ''
        end
        return accountInfo.m_strAccountID
    else
        return accountInfo.m_strSubAccount
    end
end

function getAccountData(accountInfo)
    local dataCenter  = g_traderCenter:getDataCenter()
    local accountData = dataCenter:getAccount(accountInfo:getKey())
    if accountData == CAccountData_NULL then
        local msg = string.format("找不到账号%s的账号数据,可能g_traderCenter中的数据还未更新或有问题", accountInfo:getKey())
        rcprintDebugLog(msg)
    end
    return accountData
end

function isStockAccount(accountInfo)
    return (nil ~= accountInfo) and ((AT_STOCK == accountInfo.m_nBrokerType) or (AT_CREDIT == accountInfo.m_nBrokerType) or (AT_NEW3BOARD == accountInfo.m_nBrokerType))
end

function getProductNsData(nProductId)
    local dataCenter = g_traderCenter:getDataCenter()
    local proudctNsData = dataCenter:getProductNSData(nProductId)
    if CProductNSData_NULL == productNsData then
        local msg = string.format("找不到产品 = %s的非标数据，可能g_traderCenter中的数据还未更新或有问题", nProductId)
        rcprintDebugLog(msg)
    end
    return productNsData
end

function getAccountMoney(accountInfo, tag)
    local dValue = 0
    local accountData = getAccountData(accountInfo)
    if accountData == CAccountData_NULL then return dValue end
    local key = accountInfo:getKey()
    local accountDetail = accountData:getData(XT_CAccountDetail, key)
    if accountDetail == CAccountDetail_NULL then
        local msg = string.format("找不到账号%s的资金详细数据(XT_CAccountDetail),其值为NULL", key)
        rcprintDebugLog(msg)
        return dValue, false
    end
    dValue = accountDetail:getDouble(tag)
    if isInvalidDouble(dValue) then 
        local msg = string.format("账号%s的资金详细数据中字段%d值为无效值，即double的最大值, 重新赋值为0.0", key, tag)
        rcprintDebugLog(msg)
        dValue = 0.0, false
    end
    return dValue, true
end

--按一定精度四舍五入浮点数
--precision表示小数点后的位数
--例如 round(0.00289, 3) 等于0.003
function round(num, precision)
    return tonumber(string.format("%." .. (precision or 0) .. "f", num or 0))
end

function rcprintLog(strmsg)
    -- 如果打印lua文件名和行号影响性能，注释下面一句
    -- 倒不是因为性能，是觉得这样打出来的日志体积有点大了
    -- strmsg = debug.getinfo(2).short_src..":"..debug.getinfo(2).currentline.." "..strmsg
    printLogLevel(LLV_INFO, strmsg)
end

function rcprintDebugLog(strmsg)
    -- 如果打印lua文件名和行号影响性能，注释下面一句
    -- 倒不是因为性能，是觉得这样打出来的日志体积有点大了
    -- strmsg = debug.getinfo(2).short_src..":"..debug.getinfo(2).currentline.." "..strmsg
    printLogLevel(LLV_DEBUG, strmsg)
end

function isStockMarket(market)
    return (market == "SH" or market == "SZ")
end

function isNew3BoardMarket(market)
    return (market == "NEEQ")
end

function isHGTMarket(market)
    return (market == "HGT")
end

function isStockOptionMarket(market)
    return (market == "SHO")
end

function isGoldMarket(market)
    return (market == "SHGE")
end

function rcReport(nProductId, accountInfo, strmsg, nGroupId)
    if nil ~= nGroupId and "number" == type(nGroupId) then
        rcReportImpl(nProductId, nGroupId, accountInfo, strmsg)
    else
        rcReportImpl(nProductId, ACCOUNTGROUP_ID_SPECIAL_NONE, accountInfo, strmsg)
    end
end

-- 舍弃法根据double获取int值
function getIntFromDouble(db)
    local str = tostring(db)
    local pointPosition = string.find(str, '[%.]')
    if nil == pointPosition then
        return db
    end
    return tonumber(string.sub(str, 1, pointPosition - 1))
end

function rcprintIdLog(nDebugId, strmsg)
    strmsg = debug.getinfo(2).short_src..":"..debug.getinfo(2).currentline.." "..strmsg
    printLogId(nDebugId, strmsg)
end

function position2FakeParam(accounts, factors, param, isOrderInfo)
    local stockMap = {}    --
    local keyToAccount = {}
    local paramMap = {}
    
    if param ~= nil then
        if isOrderInfo then
            if param.m_accountInfo ~= nil then 
                local paramAccKey = param.m_accountInfo:getKey()  
                local market = param.m_strExchangeId
                local strProduct = param.m_strProductId
                local stock  = param.m_strInstrumentId
                local name   = param.m_strInstrumentName 
                
                if not paramMap[paramAccKey] then
                    paramMap[paramAccKey] = {}
                end
                if not paramMap[paramAccKey][market] then
                    paramMap[paramAccKey][market] = {}
                end
                paramMap[paramAccKey][market][stock] = name            
            end
        else
            for iParam = 0, param:size() - 1, 1 do
                if param:at(iParam).m_account ~= nil then
                    local paramAccKey = param:at(iParam).m_account:getKey()

                    local market = param:at(iParam).m_stock.m_strMarket
                    local strProduct = param:at(iParam).m_stock.m_strProduct
                    local stock  = param:at(iParam).m_stock.m_strCode
                    local name   = param:at(iParam).m_stock.m_strName

                    if not paramMap[paramAccKey] then
                        paramMap[paramAccKey] = {}
                    end
                    if not paramMap[paramAccKey][market] then
                        paramMap[paramAccKey][market] = {}
                    end
                    paramMap[paramAccKey][market][stock] = name
                end
            end
        end
    end
    
    for i = 0, accounts:size()-1, 1 do
        local accountInfo = m_accountInfos:at(i)
        local accountData = getAccountData(accountInfo)
        if accountData ~= CAccountData_NULL then
            local positions = accountData:getVector(XT_CPositionStatics)
            for j = 0, positions:size()-1, 1 do
                local position = positions:at(j)
                local market = position:getString(CPositionStatics_m_strExchangeID)
                local stock  = position:getString(CPositionStatics_m_strInstrumentID)
                local name   = position:getString(CPositionStatics_m_strInstrumentName)
                if position:getInt(CPositionStatics_m_nPosition) > 0 then
                    local acKey = accountInfo:getKey()
                    if not keyToAccount[acKey] then
                        keyToAccount[acKey] = accountInfo
                    end
                    
                    if not paramMap[paramAccKey] or not paramMap[paramAccKey][market] or not paramMap[paramAccKey][market][stock] then
                        if not stockMap[acKey] then
                            stockMap[acKey] = {}
                        end
                        if not stockMap[acKey][market] then
                            stockMap[acKey][market] = {}
                        end
                        stockMap[acKey][market][stock] = name
                    end
                end
            end
        end
    end
    
    if next(stockMap) ~= nil then
        local totalNum = 0
        for acKey, m in pairs(stockMap) do
            for k, v in pairs(m) do
                for k1, v1 in pairs(v) do
                    totalNum = totalNum + 1
                end
            end
        end
        
        local fakeParams = createParamList(totalNum)
        local i = 0
        for acKey, m in pairs(stockMap) do
            local account = keyToAccount[acKey]
            for k, v in pairs(m) do
                for k1, v1 in pairs(v) do
                    fakeParams:at(i).m_nNum = 0
                    fakeParams:at(i).m_account = account
                    fakeParams:at(i).m_stock.m_strMarket = k
                    fakeParams:at(i).m_stock.m_strCode = k1
                    fakeParams:at(i).m_stock.m_strName = v1
                    if isStockMarket(k) or isHGTMarket(k) then
                        fakeParams:at(i).m_eOperationType = OPT_BUY
                    elseif isNew3BoardMarket(k) then
                        local accountData = getAccountData(account)
                        if rcIsNew3BoardLimitPriceType(accountData, k, k1) then
                            fakeParams:at(i).m_eOperationType = OPT_N3B_LIMIT_PRICE_BUY
                        else
                            fakeParams:at(i).m_eOperationType = OPT_BUY
                        end
                    elseif isStockOptionMarket(k) then
                        fakeParams:at(i).m_eOperationType = OPT_OPTION_BUY_OPEN
                    else
                        fakeParams:at(i).m_eOperationType = OPT_OPEN_LONG
                    end
                    i = i + 1
                end
            end
        end
        return fakeParams
    end
    return nil
end

function shouldCheckGlobal()
    return PRODUCT_ASSETS_ID_ALL == m_nAssetsId or PRODUCT_ASSETS_ID_NOT_ASSETS == m_nAssetsId
end

function shouldCheckAssets(assetsId)
    return PRODUCT_ASSETS_ID_ALL == m_nAssetsId or assetsId == m_nAssetsId
end

function getMarketName(strMarket)
    if strMarket == "SH" then
        return "上海证券交易所"
    elseif strMarket == "SZ" then
        return "深圳证券交易所"
    elseif strMarket == "SHFE" then
        return "上海期货交易所"
    elseif strMarket == "CZCE" then
        return "郑州商品交易所"
    elseif strMarket == "DCE" then
        return "大连商品交易所"
    elseif strMarket == "CFFEX" then
        return "中国金融期货交易所"
    else    
        return strMarket
    end
end

function compTypeToString(operatorType)
    if operatorType == XT_RLT_EX_BIGGER_THAN then
        return '>'
    elseif operatorType == XT_RLT_EX_BIGGER_EQUAL then
        return '>='
    elseif operatorType == XT_RLT_EX_SMALLER_THAN then
        return '<'
    elseif operatorType == XT_RLT_EX_SMALLER_EQUAL then
        return '<='
    elseif operatorType == XT_RLT_EX_NOT_EQUAL then
        return '!='
    end
    return ''
end

function valueRangeToString(range, text)
    local ss = ''
    if XT_RLT_EX_INVALID ~= range.m_compMinType then
        if range.m_valueType ~= nil and range.m_valueType == 0 then
            ss = string.format("%s%.4f%%", ss, range.m_min * 100)
        else
            ss = string.format("%s%f", ss, range.m_min)
        end
        ss = string.format("%s %s ", ss, compTypeToString(range.m_compMinType))
    end
    ss = string.format("%s%s", ss, text)
    if XT_RLT_EX_INVALID ~= range.m_compMaxType then
        ss = string.format("%s %s ", ss, compTypeToString(range.m_compMaxType))
        if range.m_valueType ~= nil and range.m_valueType == 0 then
            ss = string.format("%s%.4f%%", ss, range.m_max * 100)
        else
            ss = string.format("%s%f", ss, range.m_max)
        end
    end
    return ss
end

function getCmdIdString(cmdIdVec)
    if nil ~= cmdIdVec and cmdIdVec:size() > 0 then
        local cmdIdMsg = "指令["
        for i = 0, cmdIdVec:size() - 1, 1 do
            if i >= 5 then
                break
            end
            if i == 0 then
                cmdIdMsg = cmdIdMsg .. tostring(cmdIdVec:at(i))
            else
                cmdIdMsg = cmdIdMsg .. ", " .. tostring(cmdIdVec:at(i))
            end
        end
        
        cmdIdMsg = cmdIdMsg .. "]"
        return cmdIdMsg
    end
    return ""
end
