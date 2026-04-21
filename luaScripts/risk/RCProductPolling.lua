--RCProductPolling.lua

-- 针对产品的轮询处理

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")

require('bit')

--外部变量，一般由C++传入
m_accountInfos      = nil   -- 传入的账号组
g_config            = nil   -- 传入的产品配置(bson格式) 
m_productInfo       = nil   -- 传入的产品信息
m_nProductId        = nil   -- 传入的产品ID，方便查看日志

--以下变量为LUA虚拟机内部使用变量
m_productConfig     = nil   -- 产品配置，由g_config转为lua的table格式
m_strLogTag         = ''
m_stoplossing       = false
m_lastNetValueWarn  = nil
m_bPollingRC        = true
m_bEntrustable      = true

m_lastPollingTime = 0           --上次轮询的时间
m_lastPollingCnt = 0            --上次轮询的前，轮询总秒数

m_pollingTime = 0               --本次轮询的时间
m_pollingCnt = 0                --本次轮询前，轮询总秒数

g_lastStopLossTime = 0

-- 初始化, 注册信息
function init()
    m_strLogTag = "[ product_polling : product=" .. tostring(m_nProductId) .. " ] "
    rcprintLog(m_strLogTag .. "init")
    if g_config then
        m_productConfig = bson.toLua(g_config)
    end
end

-- 销毁
function destroy()
    m_productConfig = nil
    m_strLogTag = ''
    m_lastNetValueWarn = nil
    m_stoplossing      = nil
end

--按单位净值、单位净值跌幅、日最大回撤检查止损
--目前只支持止损时平全部期货仓位和全部权益类证券仓位
--todo支持夜中夜末
local function checkProductStopLoss(fundConfig)
    assert(fundConfig)
    
    -- 检查产品的账号是否已经全部初始化完成。如果有账号没有初始化，则可能净值的计算也是有问题的。
    -- 直接返回  不进行止损
    -- 需要打印一条日志
    local uninitedAccounts = rcGetProductUnInitedAccounts(m_nProductId)
    if 0 < uninitedAccounts:size() then
        local strProductTag = genProductTag(m_productInfo)
        local unInitedAccountIds = ''
        local hasOmission = false
        local size = uninitedAccounts:size()
        
        if size > 3 then
            size = 3
            hasOmission = true
        end
        
        for i = 0 ,size - 1, 1 do
            local accountId = uninitedAccounts:at(i)
            unInitedAccountIds = unInitedAccountIds .. accountId
            if i ~= size - 1 then
                unInitedAccountIds = unInitedAccountIds .. ', '
            end
        end
        
        if hasOmission then
            unInitedAccountIds = unInitedAccountIds .. '...'
        end
        
        rcprintDebugLog(m_strLogTag .. strProductTag .. ' has uninitialized account ' .. unInitedAccountIds .. ', it will not stop loss!')
        return
    end
        
    local dNetValue, dBNetValue, dTotalNetValue = getProductNetValue(m_productInfo)

    --rcprintLog(m_strLogTag .. 'dNetValue : ' .. dNetValue .. ' dBNetValue : ' .. dBNetValue .. ' dTotalNetValue : ' .. dTotalNetValue)
    if isZero(dTotalNetValue) or (isInvalidDouble(dTotalNetValue)) then
        return
    end
    
    -- 1. 净值检查
    local strProductTag = genProductTag(m_productInfo)
    checkProductStopLossRule(strProductTag, XT_NETVALUE_STOPLOSS, "NetValueStopLoss", fundConfig.m_netValueStoploss, dNetValue, dNetValue, 0)
    
    -- 2. 净值跌幅检查
    local preNetValue
    preNetValue = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_PRE_NAV)

    if isInvalidDouble(preNetValue) then
        preNetValue = 1
        rcprintDebugLog(m_strLogTag .. 'preNetValue为无效值,double的最大值,可能产品是今天成立的,没有昨净值,调整为1.0000')
    elseif preNetValue == 0 then
        preNetValue = 1
        rcprintDebugLog(m_strLogTag .. 'preNetValue为0,容错处理,调整为1.0000')
    else
        --do nothing
    end
    
    local lossRate = ((preNetValue - dNetValue) / preNetValue)
        
    checkProductStopLossRule(strProductTag, XT_NETVALUE_LOSS_STOPLOSS, "NetValueLossStopLoss", fundConfig.m_netValueLossStopLoss, dNetValue, lossRate, preNetValue)
    
    -- 3. 当日最大回撤检查
    local dMaxRetrace = 0
    dMaxRetrace = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_MAX_RETRACE)
    
    checkProductStopLossRule(strProductTag, XT_MAX_RETRACE_STOPLOSS, "RetracementStopLoss", fundConfig.m_retraceStopLoss, dNetValue, dMaxRetrace, 0)
    
    -- 4. 历史最大回撤检查
    local dHistoryMaxRetrace = 0
    dHistoryMaxRetrace = rcGetProductBasicIndex(m_nProductId, XT_RCF_PRODUCT_HISTORY_MAX_RETRACE)

    rcprintDebugLog(m_strLogTag .. string.format("dHistoryMaxRetrace = %s, fundConfig.m_historyRetraceStopLoss = %s", tostring(dHistoryMaxRetrace), table2json(fundConfig.m_historyRetraceStopLoss)))
    checkProductStopLossRule(strProductTag, XT_HISTORY_MAX_RETRACE_STOPLOSS, "HistoryRetracementStopLoss", fundConfig.m_historyRetraceStopLoss, dNetValue, dHistoryMaxRetrace, 0)
end

--用于沪新股额和深新股额
local function isSkipTradeLimitPolling(market, code, name)
    if rcIsStockInCategory(market, code, name, XT_RCC_SYSTEM_CODE_SECURITIES_XGED_SHSZ) then
       return true
    end
    return false
end

-- 产品交易限制
-- @param[in] param       下单信息，格式为COrderInfoPtr 或者 std::vector<ttservice::CCodeOrderParam>
-- @param[in] fundConfig  基金配置信息，格式为CSubFundRCConfig
-- @param[in] isOrderInfo 确定param的格式
-- @return v1, v2
-- @retval v1=true  通过
-- @retval v1=false 拒绝，v2为string，拒绝的原因
-- @note 检查基本原则，只要显性的说明允许交易，则交易之，否则拒单 
local function pollingSubFundTradeType(operationRCs, m_accountInfos)
    -- 未设置产品交易限制,默认允许交易
    if not operationRCs               or
        0 == table.getn(operationRCs)  then
        return true, ''
    end
    
    -- 执行到此, table.getn(fundConfig.operationRCs)一定大于0
    assert(table.getn(operationRCs) > 0)    
    -- 筛选出需要check的COperationRC
    local validOperationRCs = {}
    local iOper = 1
    local indexToRuleIDMap = {}
    for iOper = 1, table.getn(operationRCs), 1 do
        local operationRC = operationRCs[iOper]
        if  operationRC.m_operations                        and
            table.getn(operationRC.m_operations) > 0        and
            nowInTimeRange(operationRC.m_validTimeRange)    and
            passCondition(operationRC.m_condition, operationRC.m_description)    then
            operations = operationRC.m_operations
            table.insert(validOperationRCs, operationRC)
            local k = table.getn(validOperationRCs)
            indexToRuleIDMap[k] = iOper - 1
        else
            rcUpdateOrderLimitRCData(m_nProductId, XT_RC_SCOPE_TYPE_PRODUCT, XT_RC_ST_TRADELIMIT, tostring(m_productInfo.m_nId), iOper - 1, {}, false)
        end
    end
    
        
    if 0 == table.getn(validOperationRCs) then
        rcprintDebugLog(m_strLogTag .. string.format("当前没有有效的交易限制, 不需要轮询检查持仓."))
        return true, ''    --全部为平仓操作的单,放行
    end
    
    --扫描持仓，检查是否存在ST变化或者持仓不符合现在交易限制约束的证券或期货
    --rcprintDebugLog(m_strLogTag .. string.format("The size of m_accountInfos is %s", tostring(m_accountInfos:size())))
    local iAccount = 1
    local strProductTag = genProductTag(m_productInfo)
    local strMsgHeader = string.format("[产品交易限制] %s", tostring(strProductTag))
    local timeout = -1   --初始化为-1，表示指令无限等待执行
    local ruleToStockMap = {}   --规则id对应的不合规的代码vector
    
    for iAccount = 0, m_accountInfos:size() - 1, 1 do
        local accountInfo = m_accountInfos:at(iAccount)
        -- rcprintLog(m_strLogTag .. string.format("Begin to check the positions of account %s", tostring(accountInfo:getKey())))
        local accountData = getAccountData(accountInfo)
        if accountData ~= CAccountData_NULL then
            --统计持仓大于0的信息,若发现不符合交易限制的持仓种类，则报警或平仓
            local positions = accountData:getVector(XT_CPositionStatics)
            -- rcprintLog(m_strLogTag .. string.format("The size of positions is %s", tostring(positions:size())))
            local brokerType = accountInfo.m_nBrokerType

            for j = 0, positions:size()-1, 1 do
                local position = positions:at(j)
                local market = position:getString(CPositionStatics_m_strExchangeID)
                local stock  = position:getString(CPositionStatics_m_strInstrumentID)
                local name   = position:getString(CPositionStatics_m_strInstrumentName)
                if not isSkipTradeLimitPolling(market, stock, name) then
                    local m_strProductID = position:getString(CPositionStatics_m_strProductID)
                    -- for循环里不要轻易加日志，尤其还是两重for循环，账号+持仓多的话这个量太可怕了
                    --rcprintLog(m_strLogTag .. string.format("market = %s, stock = %s, name = %s, m_strProductID = %s", tostring(market), tostring(stock), tostring(name), tostring(m_strProductID)))

                    -- 这儿统一用m_nPosition判断是没问题的
                    -- 因为客户端会用m_nPosition去过滤显示，应保持统一
                    local canClose = position:getInt(CPositionStatics_m_nPosition)

                    if canClose > 0 then
                        local accountType = accountInfo.m_nBrokerType
                        local valid = false
                                            
                        local pollingOpFlag = 0
                        if rcIsStockInCategory(market, stock, name, XT_RCC_SYSTEM_CODE_SECURITIES_ZHG) 
                            or rcIsStockInCategory(market, stock, name, XT_RCC_SYSTEM_CODE_SECURITIES_STD_BOND) then

                            pollingOpFlag = bit.bor(bit.bor(bit.bor(XT_TRADE_LIMIT_BUY, XT_TRADE_LIMIT_FIN_BUY), XT_TRADE_LIMIT_SLO_SELL), XT_TRADE_LIMIT_SELL)
                        else
                            pollingOpFlag = bit.bor(bit.bor(XT_TRADE_LIMIT_BUY, XT_TRADE_LIMIT_FIN_BUY), XT_TRADE_LIMIT_SLO_SELL)
                        end
                        
                        for k = 1, table.getn(validOperationRCs), 1 do
                            local operationRC = validOperationRCs[k]
                            if checkTradeLimit(operationRC.m_operations, accountType, market, stock, pollingOpFlag) then
                                valid = true
                            else
                                local positionKey = position:getKey()
                                local iOper = indexToRuleIDMap[k]
                                if nil == ruleToStockMap[iOper] then
                                    ruleToStockMap[iOper] = {}
                                end
                                ruleToStockMap[iOper][positionKey] = positionKey
                            end
                        end
                    
                        --对不符合目前交易限制的持仓进行平仓止损
                        if not valid then
                            local strStockShow = stock
                            if isStockMarket(market) or isNew3BoardMarket(market) or isStockOptionMarket(market) or isHGTMarket(market) then
                                strStockShow = market .. stock
                            end
                            local strmsg = string.format("%s 账号 %s 持仓 %s (%s) 不符合当前设置的产品交易限制, 触发报警!", strMsgHeader, getAccountDisplayID(accountInfo), strStockShow, name)
                            rcprintLog(m_strLogTag .. strmsg)
                            rcReport(m_nProductId, accountInfo, strmsg)

                            --对于违反目前交易限制的持仓进行平仓止损
                            --if accountType == AT_FUTURE then
                                --stopLossAccountFutures(accountInfo, strmsg, timeout)
                            --else
                                --stopLossAccountStock(accountInfo, strmsg, timeout)
                            --end
                        end
                    end
                end
            end
        end
    end
    
    -- 静态风控更新
    for ruleID, posDatas in pairs(ruleToStockMap) do
        rcUpdateOrderLimitRCData(m_nProductId, XT_RC_SCOPE_TYPE_PRODUCT, XT_RC_ST_TRADELIMIT, tostring(m_productInfo.m_nId), ruleID, posDatas, true)
    end
    
    return true, ''   --全部为平仓操作或者交易限制允许其操作,放行            
end

-- 轮询风控
-- 定时轮询
local function pollingFundCheck(nId)
    local fundConfig = getProductRCConfig(m_productConfig)
    if not fundConfig then
        rcprintDebugLog(m_strLogTag .. 'pollingFundCheck : nil fundConfig, return.')
        return
    end

    local des = string.format('(config = %s)', table2jsonOld(fundConfig))
    local productTag = genProductMsgTag(XT_RegularCheck)
    
    -- 检查止损
    checkProductStopLoss(fundConfig)

    -- 检查账号是否资产处于可信状态
    if not rcIsAccountsEntrustable(m_accountInfos) then
        if m_bEntrustable then
            rcprintLog(m_strLogTag .. ' not all accounts entrustable, pass')
        end
        m_bEntrustable = false
        return
    else
        if not m_bEntrustable then
            rcprintLog(m_strLogTag .. ' all accounts entrustable, go on')
        end
        m_bEntrustable = true
    end

    if nil ~= fundConfig.m_operationRCs then
        -- 检查持仓中是否存在ST股变化或者不符合现在交易限制的情况
        local operationRCs = fundConfig.m_operationRCs
        if operationRCs then
            rcprintDebugLog(m_strLogTag .. string.format("operationRCs = %s", table2json(operationRCs)))
        end

        if operationRCs and nil ~= fundConfig.m_operationPollingInterval then
            local interval = fundConfig.m_operationPollingInterval
            if interval > 0 then
                local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                    local ret, strmsg = pollingSubFundTradeType(operationRCs, m_accountInfos)
                    if ret == false then
                        rcprintLog(m_strLogTag .. "pollingSubFund: pollingSubFundTradeType return false. " .. strmsg)
                    end
                end
            end
        end
    else
        rcprintDebugLog(m_strLogTag .. "fundConfig.m_operations is nil.")
    end

    if nil ~= fundConfig.m_assetsRCs then
        local msgHeader = string.format("[产品资产组合风控] %s", productTag)
        -- 资产风控项排序
        local assetsRCs = reorderAssetsRCs(fundConfig.m_assetsRCs)

        -- 检查资产风控项
        local size = table.getn(assetsRCs)
        for iRule = 1, size, 1 do
            local rc = assetsRCs[iRule]
            local interval = rc.m_pollingInterval
            if type(interval) == 'string' then
                interval = tonumber(interval)
            end
            if interval > 0 then
                local thisPolling = getIntFromDouble(m_pollingCnt/interval)
                local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
                if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then
                    rcprintIdLog(122, m_strLogTag .. string.format("pollingFundCheck assetId: %d, m_pollingCnt:%d, interval:%d, thisPolling:%d, lastPolling:%d", rc.m_nID, m_pollingCnt, interval, thisPolling, lastPolling))
                    local res, msg = pollingSubFundRule(nId, CCodeOrderParamList().m_params, false, rc, msgHeader, tostring(m_nProductId))
                    if nil == m_strLogTag then
                        m_strLogTag = ''
                    end
                    if res then
                        -- rcprintDebugLog(m_strLogTag .. string.format('%s%s rule %s return success, msg = %s', m_strLogTag, des, rc.m_description, msg))
                    else
                        -- rcprintDebugLog(m_strLogTag .. string.format('%s%s rule %s return fail, msg = %s', m_strLogTag, des, rc.m_description, msg))
                    end
                else
                    if rc and rc.m_nID and m_productInfo and m_productInfo.m_nId then
                        rcUseOldProductAssetsData(m_productInfo.m_nId, rc.m_nID ,CAccountInfo())
                    end
                end
            end
        end
    end
end

-- 合规检查
function check()
    -- 第一次polling时要检查
    if 0 ~= m_lastPollingTime then
        m_pollingTime = os.time()
        m_pollingCnt = m_lastPollingCnt + m_pollingTime - m_lastPollingTime
    end
    
    collectgarbage("collect")
    rcprintDebugLog(m_strLogTag .. "check start")

    m_stoplossing = false
    
    if not m_productConfig then
        rcprintDebugLog(m_strLogTag .. "nil m_productInfo, return")
        -- 未配置产品风控
        return TTError()
    end
    
    -----------A基金 日中--------------
    pollingFundCheck(XT_RC_SCOPE_TYPE_PRODUCT, TRADING_DAY_MID)
    
    m_lastPollingCnt = m_pollingCnt
    
    -- 第一次设置的时候设置当前的时间，后面设置轮询前的时间
    -- 如果都设置成当前时间，则可能轮询前时间没有达到轮询点，导致没有轮询，但是轮询后的时间达到了轮询点，
    -- 导致下一次轮询的时候误认为这次已经轮询，下面就不会在轮询。从而可能会漏掉某些轮询
    if 0 == m_lastPollingTime then
        m_lastPollingTime = os.time()
    else
        m_lastPollingTime = m_pollingTime
    end

    return TTError()
end
