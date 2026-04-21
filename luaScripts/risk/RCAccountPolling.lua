--RCAccountPolling.lua

-- 针对账号的轮询处理

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")

m_accountInfo       = nil   -- 传入的账号
m_accountInfos      = nil
g_config            = nil   -- 传入的配置
m_productInfo       = nil   -- 传入的产品信息, 把账号所属产品信息传入，统计时计算产品中指定账号的部分
m_nProductId        = nil   -- 产品ID，方便查看日志
m_bIsStandalone     = nil
m_riskControl       = nil
m_accountConfig     = nil   --账号配置信息，由json转换成lua table
m_strLogTag         = ''
m_stoplossing       = false
m_bAccountRC        = true
m_bPollingRC        = true
m_bEntrustable      = true

m_globalConfig      = nil   -- 传入的全局风控配置，bson格式
s_globalConfig      = nil   -- 全局风控配置，luaTable格式

m_lastPollingTime = 0           --上次轮询的时间
m_lastPollingCnt = 0            --上次轮询的前，轮询总秒数

m_pollingTime = 0               --本次轮询的时间
m_pollingCnt = 0                --本次轮询前，轮询总秒数

m_institutionConfig = nil
m_institutionConfigTable = nil
m_bCheckFutureProduct = true   -- 判断是否做期货交易限制, 当配置黑白名单缺失时而且有检查交易限制应该放行



-- 初始化, 注册信息
function init()
    m_strLogTag = "[ account_polling : account=" .. getAccountDisplayID(m_accountInfo) .. ", product=" .. tostring(m_nProductId) .. " ] "
    rcprintDebugLog(m_strLogTag .. "init")
    if g_config then
        m_accountConfig = bson.toLua(g_config)
        if m_accountConfig then
            m_riskControl = m_accountConfig.m_riskControl   -- 从账号配置中获取账号风控配置
        else
            rcprintLog(m_strLogTag .. "m_accountConfig is nil")
        end
    else
        rcprintLog(m_strLogTag .. "g_config is nil")
    end
    
    if m_globalConfig then
        s_globalConfig = bson.toLua(m_globalConfig)
                
        local nBrokerType = m_accountInfo.m_nBrokerType
        local mergedBlack, typeIndex = mergeAutoBlackToGlobalBlackList(nBrokerType, s_globalConfig)
        
        --rcprintLog("init merged Black" .. string.format('mergedBlack = %s', table2jsonOld(mergedBlack)))
        
        if nil ~= typeIndex and nil ~= s_globalConfig[typeIndex] and nil ~= s_globalConfig[typeIndex]["stocks"] then
            s_globalConfig[typeIndex]["stocks"]["black"] = mergedBlack
        end
    end
    
    if m_institutionConfig then
        local configTable = bson.toLua(m_institutionConfig)
        m_institutionConfigTable = configTable["content"]
    end
end

-- 销毁
function destroy()
    m_accountConfig = nil
    m_strLogTag = ''
    m_stoplossing = nil
    m_riskControl = nil
    s_globalConfig = nil
end

local function genMsgTag()
    local strAcc = getAccountDisplayID(m_accountInfo)
    local strMsgTag = string.format("账号 %s : ", strAcc)
    return strMsgTag
end 

-- 检查合约止损
local function checkInstrumentStopLoss(accountData, accountConfig)
    local datas = accountData:getVector(XT_CPositionStatics)
    local dataCenter  = g_traderCenter:getDataCenter()
    local strMsgHeader = string.format("[账号合约止损] %s", genMsgTag())
    for i = 0, datas:size()-1, 1 do
        local v = datas:at(i)
        local m_strInstrumentID = v:getString(CPositionStatics_m_strInstrumentID)
        local m_strProductID = v:getString(CPositionStatics_m_strProductID)
        local m_strExchangeID = v:getString(CPositionStatics_m_strExchangeID)
        local m_nDirection =  v:getInt(CPositionStatics_m_nDirection)
        local m_nPosition =  v:getInt(CPositionStatics_m_nPosition)
        local m_dOpenPrice = v:getDouble(CPositionStatics_m_dOpenPrice)
        local m_bIsToday = v:getBool(CPositionStatics_m_bIsToday)
        local m_nHedgeFlag = v:getInt(CPositionStatics_m_nHedgeFlag)
        if m_nPosition > 0 then
            -- 如果仓位很多，这个日志量太大，后续有必要再加上
            -- rcprintDebugLog(m_strLogTag .. "check instrumentStoploss m_strInstrumentID:"..m_strInstrumentID.." m_nPosition:".. m_nPosition)
            local stopLoss = getAccountStopLoss(accountConfig, m_strInstrumentID)
            if stopLoss and stopLoss.m_dMaxLoss > 0 and stopLoss.m_bEnabled then
                if m_bIsToday == true or ( m_bIsToday == false and stopLoss.m_bStopYesterday == true) then
                    local priceData = dataCenter:getPrice(m_accountInfo.m_nPlatformID, m_strExchangeID, m_strInstrumentID)
                    if priceData then
                        local m_dLastPrice = priceData.m_dLastPrice
                        local loss = m_dLastPrice - m_dOpenPrice
                        -- 如果仓位很多，这个日志量太大，后续有必要再加上
                        -- rcprintDebugLog(m_strLogTag .. "check instrumentStoploss m_nDirection:"..m_nDirection.." loss:".. loss.." m_dMaxLoss:"..stopLoss.m_dMaxLoss)
                        if m_nDirection == ENTRUST_BUY then
                            if m_dOpenPrice > m_dLastPrice and abs(loss) >= stopLoss.m_dMaxLoss and m_nPosition > 0 then
                                local nOperation = OPT_CLOSE_LONG_TODAY
                                if m_bIsToday == false then
                                    nOperation = OPT_CLOSE_LONG_HISTORY
                                end
                                local volCanClose = rcGetVolumeRcCanClose(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nHedgeFlag)
                                if volCanClose > 0 then
                                    local strmsg = string.format("%s合约%s亏损已超过止损阈值%.2f, 平仓止损!", strMsgHeader, m_strInstrumentID, stopLoss.m_dMaxLoss)
                                    rcprintLog(m_strLogTag .. strmsg)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nPosition, getInvalidInt(), strmsg, SLT_ALL_LOSS, m_nHedgeFlag)
                                else
                                    -- rcprintDebugLog(m_strLogTag .. strmsg .. " volCanClose <= 0")
                                end
                            end
                        else
                            if m_dOpenPrice < m_dLastPrice and abs(loss) >= stopLoss.m_dMaxLoss and m_nPosition > 0 then
                                local nOperation = OPT_CLOSE_SHORT_TODAY
                                if m_bIsToday == false then
                                    nOperation = OPT_CLOSE_SHORT_HISTORY
                                end
                                local volCanClose = rcGetVolumeRcCanClose(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nHedgeFlag)
                                if volCanClose > 0 then
                                    local strmsg = string.format("%s合约%s亏损已超过止损阈值%.2f, 平仓止损!", strMsgHeader, m_strInstrumentID, stopLoss.m_dMaxLoss)
                                    rcprintLog(m_strLogTag .. strmsg)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nPosition, getInvalidInt(), strmsg, SLT_ALL_LOSS, m_nHedgeFlag)
                                else
                                    -- rcprintDebugLog(m_strLogTag .. strmsg .. " volCanClose <= 0")
                                end
                            end
                        end
                    end -- priceData
                end --isToday
            end -- config
        end -- m_nPosition > 0            
    end -- end for
end

--local function checkAccountStop(m_accountInfo, accountRCConfig, isSelf)
local function checkAccountStop(m_accountInfo, accountRCConfig)
    local accountData = getAccountData(m_accountInfo)
    local datas = accountData:getVector(XT_CPositionStatics)
    local config = nil
    local strMsgHeader = string.format("[合约止盈止损] %s", genMsgTag())
    for i = 0, datas:size() - 1, 1 do
        local v = datas:at(i)
        local m_strInstrumentID = v:getString(CPositionStatics_m_strInstrumentID)
        local m_strProductID = v:getString(CPositionStatics_m_strProductID)
        local m_strExchangeID = v:getString(CPositionStatics_m_strExchangeID)
        local m_nDirection =  v:getInt(CPositionStatics_m_nDirection)
        local m_nPosition =  v:getInt(CPositionStatics_m_nPosition)
        local m_bIsToday = v:getBool(CPositionStatics_m_bIsToday)
        local m_dOpenPrice = v:getDouble(CPositionStatics_m_dOpenPrice)
        local m_nHedgeFlag =  v:getInt(CPositionStatics_m_nHedgeFlag)
        local rcMsg = nil

        local m_dLastPrice = rcGetLastPrice(m_accountInfo.m_nPlatformID, m_strExchangeID, m_strInstrumentID)

        if m_strProductId and m_strInstrumentId and m_nPosition then
            -- 如果仓位很多，这个日志量太大，后续有必要再加上
            -- rcprintLog(m_strLogTag .. "checkAccountStop, m_strProductId:"..m_strProductId.." m_strInstrumentId:"..m_strInstrumentId.." m_nPosition:"..m_nPosition)
        end
       
        if m_nPosition > 0 then
            config = getAccountStop(accountRCConfig, m_strInstrumentID) --获取合约止盈止损配置
        
            if config then
                rcprintDebugLog(m_strLogTag .. string.format('getAccountStop: config=%s', table2json(config)))
                --config.m_bStopProfit
                --config.m_dStopProfitValue
                --config.m_settingStopProfit
                --config.m_bStopLoss
                --config.m_dStopLossValue
                --config.m_settingStopLoss
                if not config or accountData == CAccountData_NULL then 
                    --rcprintDebugLog(m_strLogTag .. string.format("与合约 %s 对应的配置为空", m_strInstrumentID)) 
                end

                local stopProfit = tostring(config.m_bStopProfit)
                local stopLoss   = tostring(config.m_bStopLoss)
                local stopProfitValue = config.m_settingStopProfit.m_dStopProfitValue
                local stopLossValue = config.m_settingStopLoss.m_dStopLossValue

                --检查合约止盈是否启用
                --if not isInvalidBool(config.m_bStopProfit) and config.m_bStopProfit == true then

                --检查合约止损是否启用
                --if not isInvalidBool(config.m_bStopLoss) and config.m_bStopLoss == true then

                --获取当前持仓的盈亏情况
                now = m_dLastPrice - m_dOpenPrice   --计算当前账号的持仓的赢亏状况 : 最新价 - 开仓价

                --判断操作类型
                if m_nPosition > 0 then
                    local nOperation = OPT_CLOSE_LONG_TODAY
                    if m_nDirection == ENTRUST_BUY then
                        if m_bIsToday == false then nOperation = OPT_CLOSE_LONG_HISTORY else nOperation = OPT_CLOSE_LONG_TODAY end
                    else
                        if m_bIsToday == false then nOperation = OPT_CLOSE_SHORT_HISTORY else nOperation = OPT_CLOSE_SHORT_TODAY end
                    end
                end

                -- rcprintLog(m_strLogTag .. "check accountStopProfit, "..m_strInstrumentID.." now:"..now..", m_dStopProfitValue:"..stopProfitValue)
                --采取止盈过阈值的动作
                --local orderSetting = config.m_settingStopProfit  如果后台能拿到该账号对应品种的止盈止损配置，则不需要把下单参数传给C++的止盈止损函数
                -- rcprintDebugLog(m_strLogTag .. "开始检查止盈阈值...")
                if stopProfit == "true" then
                    if m_nDirection == ENTRUST_BUY then
                        if m_dOpenPrice < m_dLastPrice and abs(now) >= stopProfitValue and m_nPosition > 0 then
                            local nOperation = OPT_CLOSE_LONG_TODAY
                            local strmsg = ""
                            if m_bIsToday == false then nOperation = OPT_CLOSE_LONG_HISTORY end
                            -- rcprintDebugLog(m_strLogTag .. " stopLossAccountFutures, stoploss m_strInstrumentID:"..m_strInstrumentID.." volume:"..m_nPosition)
                            strmsg = strmsg..string.format("%s合约%s赢利已超过止盈阈值%.4f, 平仓止盈!", strMsgHeader, m_strInstrumentID, stopProfitValue)
                            --rcReport(m_accountInfo, strmsg.." 合约"..m_strInstrumentID.."平仓"..m_nPosition.."手")
                            local timeout = -1   --设置一个timeout值
                            local volCanClose = rcGetVolumeRcCanClose(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nHedgeFlag)

                            if volCanClose > 0 then
                                if m_nPosition > volCanClose then
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, volCanClose)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, volCanClose, timeout, rcMsg, SLT_INSTRUMENT_PROFIT, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                else
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, m_nPosition)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nPosition, timeout, rcMsg, SLT_INSTRUMENT_PROFIT, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                end
                                rcprintLog(m_strLogTag .. "stopLossAccountFutures Closed" .. string.format("%s total position: %s, available position: %s", 
                                            tostring(m_strInstrumentID), tostring(m_nPosition), tostring(volCanClose)))
                            else
                                -- rcprintDebugLog(m_strLogTag .. "stopLossAccountFutures, m_strInstrumentID: " .. m_strInstrumentID .. " position frozen." .. tostring(m_nPosition))
                            end
                        end
                    else
                        if m_dOpenPrice > m_dLastPrice and abs(now) >= stopProfitValue and m_nPosition > 0 then
                            local nOperation = OPT_CLOSE_SHORT_TODAY
                            local strmsg = ""
                            if m_bIsToday == false then nOperation = OPT_CLOSE_SHORT_HISTORY end
                            -- rcprintDebugLog(m_strLogTag .. " stopLossAccountFutures, stoploss m_strInstrumentID:"..m_strInstrumentID.." volume:"..m_nPosition)
                            strmsg = strmsg..string.format("%s合约%s赢利已超过止盈阈值%.4f, 平仓止盈!", strMsgHeader, m_strInstrumentID, stopProfitValue)
                            --rcReport(m_accountInfo, strmsg.." 合约"..m_strInstrumentID.."平仓"..m_nPosition.."手")
                            local timeout = -1   --设置一个timeout值
                            local volCanClose = rcGetVolumeRcCanClose(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nHedgeFlag)

                            if volCanClose > 0 then
                                if m_nPosition > volCanClose then
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, volCanClose)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, volCanClose, timeout, rcMsg, SLT_INSTRUMENT_PROFIT, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                else
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, m_nPosition)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nPosition, timeout, rcMsg, SLT_INSTRUMENT_PROFIT, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                end
                                rcprintLog(m_strLogTag .. "stopLossAccountFutures Closed" .. string.format("%s total position: %s, available position: %s", 
                                            tostring(m_strInstrumentID), tostring(m_nPosition), tostring(volCanClose)))
                            else
                                -- rcprintDebugLog(m_strLogTag .. "stopLossAccountFutures, m_strInstrumentID: " .. m_strInstrumentID .. " position frozen." .. tostring(m_nPosition))
                            end
                        end
                    end
                end

                --检查止损阈值
                -- rcprintLog(m_strLogTag .. "check accountStopLoss, "..m_strInstrumentID.." now:"..now..", m_dStopLossValue:"..stopLossValue)
                --采取止损过阈值的动作
                --local orderSetting = config.m_settingStopLoss 后台能获取合约对应的下单参数，不需要传给C++
                -- rcprintDebugLog(m_strLogTag .. "开始检查止损阈值...")

                if stopLoss == "true" then
                    if m_nDirection == ENTRUST_BUY then
                        if m_dOpenPrice > m_dLastPrice and abs(now) >= stopLossValue and m_nPosition > 0 then
                            local nOperation = OPT_CLOSE_LONG_TODAY
                            local strmsg = ""
                            if m_bIsToday == false then nOperation = OPT_CLOSE_LONG_HISTORY end
                            -- rcprintDebugLog(m_strLogTag .. " stopLossAccountFutures, stoploss m_strInstrumentID:"..m_strInstrumentID.." volume:"..m_nPosition)
                            strmsg = strmsg..string.format("%s合约%s亏损已超过止损阈值%.4f, 平仓止损!", strMsgHeader, m_strInstrumentID, stopLossValue)
                            --rcReport(m_accountInfo, strmsg.." 合约"..m_strInstrumentID.."平仓"..m_nPosition.."手")
                            local timeout = -1   --设置一个timeout值
                            local volCanClose = rcGetVolumeRcCanClose(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nHedgeFlag)

                            if volCanClose > 0 then
                                if m_nPosition > volCanClose then
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, volCanClose)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, volCanClose, timeout, rcMsg, SLT_INSTRUMENT_LOSS, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                else
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, m_nPosition)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nPosition, timeout, rcMsg, SLT_INSTRUMENT_LOSS, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                end
                                rcprintLog(m_strLogTag .. "stopLossAccountFutures Closed" .. string.format("%s total position: %s, available position: %s", 
                                        tostring(m_strInstrumentID), tostring(m_nPosition), tostring(volCanClose)))
                            else
                                -- rcprintDebugLog(m_strLogTag .. "stopLossAccountFutures, m_strInstrumentID: " .. m_strInstrumentID .. " position frozen." .. tostring(m_nPosition))
                            end
                        end
                    else
                        if m_dOpenPrice < m_dLastPrice and abs(now) >= stopLossValue and m_nPosition > 0 then
                            local nOperation = OPT_CLOSE_SHORT_TODAY
                            local strmsg = ""
                            if m_bIsToday == false then nOperation = OPT_CLOSE_SHORT_HISTORY end
                            -- rcprintDebugLog(m_strLogTag .. " stopLossAccountFutures, stoploss m_strInstrumentID:"..m_strInstrumentID.." volume:"..m_nPosition)
                            strmsg = strmsg..string.format("%s合约%s亏损已超过止损阈值%.4f, 平仓止损!", strMsgHeader, m_strInstrumentID, stopLossValue)
                            --rcReport(m_accountInfo, strmsg.." 合约"..m_strInstrumentID.."平仓"..m_nPosition.."手")
                            local timeout = -1   --设置一个timeout值
                            local volCanClose = rcGetVolumeRcCanClose(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nHedgeFlag)

                            if volCanClose > 0 then
                                if m_nPosition > volCanClose then
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, volCanClose)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, volCanClose, timeout, rcMsg, SLT_INSTRUMENT_LOSS, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                else
                                    rcMsg = string.format("%s合约%s平仓%d手 ", strmsg, m_strInstrumentID, m_nPosition)
                                    rcStoplossFutures(m_accountInfo, nOperation, m_strExchangeID, m_strInstrumentID, m_strProductID, m_nPosition, timeout, rcMsg, SLT_INSTRUMENT_LOSS, m_nHedgeFlag)
                                    --     rcReport(m_nProductId, m_accountInfo, rcMsg)
                                end
                                rcprintLog(m_strLogTag .. "stopLossAccountFutures Closed" .. string.format("%s total position: %s, available position: %s", 
                                            tostring(m_strInstrumentID), tostring(m_nPosition), tostring(volCanClose)))
                            else
                                -- rcprintDebugLog(m_strLogTag .. "stopLossAccountFutures, m_strInstrumentID: " .. m_strInstrumentID .. " position frozen." .. tostring(m_nPosition))
                            end
                        end
                    end
                end
            end
        end
    end
    --轮询完所有持仓，如果发现没有找到与持仓对应的止盈止损配置，则直接返回
    if not config or accountData == CAccountData_NULL then
        rcprintDebugLog(m_strLogTag .. "没有找到与持仓对应的止盈止损配置.")
    end
end

local function pollingAccountAssets(nId, m_riskControl, m_accountInfo, accountKey)
    rcprintDebugLog(m_strLogTag .. string.format('polling Account Assets : m_accountInfo:getKey() = %s', tostring(m_accountInfo:getKey())))
    local fundConfig = getProductRCConfig(m_productConfig)

    local des = string.format('(config = %s, m_accountInfo = %s)', table2jsonOld(fundConfig), table2jsonOld(m_accountInfo))
    
    if m_riskControl and nil ~= m_riskControl.m_assetsRCs then     --从账号风控配置读取账号的资产组合风控配置

        -- 资产风控项排序
        local assetsRCs = reorderAssetsRCs(m_riskControl.m_assetsRCs)
        local msgHeader = string.format("[账号资产组合风控]: %s ", getAccountDisplayID(m_accountInfo))

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
                    rcprintIdLog(122, m_strLogTag .. string.format("pollingAccountAssets assetId: %d, m_pollingCnt:%d, interval:%d, thisPolling:%d, lastPolling:%d", rc.m_nID, m_pollingCnt, interval, thisPolling, lastPolling))
                    local res, msg = pollingSubFundRule(XT_RC_SCOPE_TYPE_ACCOUNT, CCodeOrderParamList().m_params, false, rc, msgHeader, accountKey)
                    if nil == m_strLogTag then
                        m_strLogTag = ''
                    end
                    if res then
                        -- rcprintDebugLog(m_strLogTag .. string.format('accountRCConfig: %s%s rule %s return success, msg = %s', m_strLogTag, des, rc.m_description, msg))
                    else
                        -- rcprintDebugLog(m_strLogTag .. string.format('accountRCConfig: %s%s rule %s return fail, msg = %s', m_strLogTag, des, rc.m_description, msg))
                    end
                else
                    rcUseOldProductAssetsData(m_productInfo.m_nId, rc.m_nID, m_accountInfo)
                end
            end
        end
    end
end

local function checkAccountOpenOpenPositionWithdraw(accountData, accountConfig)

    if not accountConfig then return nil end

    accountRCConfig = accountConfig.m_riskControl;
    local compliances = accountRCConfig.m_compliances
    local productId2ruleId = {}
    if compliances then
        -- 遍历所有合规配置
        local size = table.getn(compliances)
        for iCompliance = 1, size, 1 do
            productId2ruleId[compliances[iCompliance].m_strProductID] = iCompliance - 1
        end
    end

    local datas = accountData:getVector(XT_CPositionStatics)
    local ruleId2Datas = {}
    local mapDatas = {}

    for i = 0, datas:size()-1, 1 do
        local v = datas:at(i)

        local strInstrumentID = v:getString(CPositionStatics_m_strInstrumentID)
        local strProductID = v:getString(CPositionStatics_m_strProductID)
        local strExchangeID = v:getString(CPositionStatics_m_strExchangeID)
        local nPosition =  v:getInt(CPositionStatics_m_nPosition)
        local nHedgeFlag = v:getInt(CPositionStatics_m_nHedgeFlag)

        if nil == mapDatas[strProductID] then
            mapDatas[strProductID] = {}
        end
        if nil == mapDatas[strProductID][strInstrumentID] then
            mapDatas[strProductID][strInstrumentID] = {}
        end
        if nil == mapDatas[strProductID][strInstrumentID][nHedgeFlag] then
            mapDatas[strProductID][strInstrumentID][nHedgeFlag] = false
        end
        
        local compliance = getAccountCompliance(accountRCConfig, strProductID)

        if mapDatas[strProductID][strInstrumentID][nHedgeFlag] == false and compliance then

            mapDatas[strProductID][strInstrumentID][nHedgeFlag] = true

            local eHedgeFlags = compliance.m_nHedgeFlags
            if eHedgeFlags == nil then
                eHedgeFlags = XT_RC_CHECK_HEDGE_FLAG_ALL
            end
    
            local nOpen = rcGetAccountOpen(accountData, strProductID, eHedgeFlags, nHedgeFlag, strExchangeID, COrderInfo(), -1)    --对每个合约都要遍历一次计算开仓，是否有更好的办法？
            local nPosition = rcGetAccountPosition(accountData, strInstrumentID, eHedgeFlags, nHedgeFlag, strProductID, strExchangeID, COrderInfo(), -1)
            local nWithdraw = rcGetAccountWithDraw(accountData, strInstrumentID, eHedgeFlags, nHedgeFlag, strProductID, strExchangeID, COrderInfo(), -1)

            local bIsOpenPosBreak = false
            local bIsPositionBreak = false
            local bIsCancelBreak = false
            
            rcprintLog(m_strLogTag .. "checkAccountOpenOpenPositionWithdraw"..string.format("strProductID: %s, strInstrumentID: %s, nOpen: %s, nPosition: %s, nWithdraw: %s", tostring(strProductID), tostring(strInstrumentID), tostring(nOpen), tostring(nPosition), tostring(nWithdraw)))
            
            --检查开仓手数报警阈值
            if not isInvalidInt(compliance.m_nWarnOpen) and compliance.m_nWarnOpen > 0  and nOpen >= compliance.m_nWarnOpen then
                --strmsg = string.format("品种%s当前开仓量为%d手, 大于等于开仓量报警阈值%d!", m_strProductId, nOpen, compliance.m_nWarnOpen)
                bIsOpenPosBreak = true
            end

            --检查持仓量报警阈值
            if not isInvalidInt(compliance.m_nWarnPosition) and compliance.m_nWarnPosition > 0  and nPosition >= compliance.m_nWarnPosition then
                --strmsg = string.format("合约%s当前持仓为%d手, 大于等于持仓量报警阈值%d!", strInstrumentID, nPosition, compliance.m_nWarnPosition)
                bIsPositionBreak = true
            end

            --检查撤单次数报警阈值
            if not isInvalidInt(compliance.m_nWarnWithdraw) and compliance.m_nWarnWithdraw > 0  and nWithdraw >= compliance.m_nWarnWithdraw then
                bIsCancelBreak = true
            end

            local rcData = {}
            --让CPP去生成strKey
            rcData.m_strInstrumentId = strInstrumentID
            rcData.m_nPositionNum = nPosition
            rcData.m_nCancelNum = nWithdraw
            rcData.m_nOpenPositionNum = nOpen
            rcData.m_bOpenPosBreak = bIsOpenPosBreak
            rcData.m_bPositionBreak = bIsPositionBreak
            rcData.m_bCancelBreak = bIsCancelBreak
            rcData.m_nHedgeFlag = nHedgeFlag

            if not ruleId2Datas[productId2ruleId[strProductID]] then
                local rcDatas = {}
                table.insert(rcDatas, rcData)
                ruleId2Datas[productId2ruleId[strProductID]] = rcDatas
            else
                table.insert(ruleId2Datas[productId2ruleId[strProductID]], rcData)
            end
        end
    end

    for k, v in pairs(ruleId2Datas) do
        rcUpdateOpenPositionWithdrawRCData(m_nProductId, XT_RC_SCOPE_TYPE_ACCOUNT, m_accountInfo:getKey(), k, v)
    end
end

function check()
    if 0 ~= m_lastPollingTime then
        m_pollingTime = os.time()
        m_pollingCnt = m_lastPollingCnt + m_pollingTime - m_lastPollingTime
    end

    collectgarbage("collect")
    local accountKey = ''
    if m_accountInfo and CAccountInfo_NULL ~= m_accountInfo then
        accountKey = m_accountInfo:getKey()
    end
    local accountData = getAccountData(m_accountInfo)
    if accountData == CAccountData_NULL then
        rcprintLog(m_strLogTag .. "accountData is NULL")
        return TTError()
    end

    -- 检查账号是否资产处于可信状态
    if not rcIsAccountsEntrustable(m_accountInfos) then
        if m_bEntrustable then
            rcprintLog(m_strLogTag .. ' not all accounts entrustable, pass')
        end
        m_bEntrustable = false
        return TTError()
    else
        if not m_bEntrustable then
            rcprintLog(m_strLogTag .. ' all accounts entrustable, go on')
        end
        m_bEntrustable = true
    end
    
    -----------指定账号的资产比例风控--------------
    pollingAccountAssets(XT_RegularCheck, m_riskControl, m_accountInfo, accountKey)

    local stkComplianceInterval = 30   -- 暂定30秒一轮询
    if nil ~= m_riskControl and nil ~= m_riskControl.m_pollingComplianceInterval then
        stkComplianceInterval = m_riskControl.m_pollingComplianceInterval
    end
    if stkComplianceInterval > 0 then
        local thisPolling = getIntFromDouble(m_pollingCnt/stkComplianceInterval)
        local lastPolling = getIntFromDouble(m_lastPollingCnt/stkComplianceInterval)
        if 0 == m_pollingCnt % stkComplianceInterval or (thisPolling - lastPolling >= 1) then
            if m_accountInfo.m_nBrokerType == AT_STOCK or m_accountInfo.m_nBrokerType == AT_CREDIT then
            
                -- 比例合规检查
                checkStkAccountCompliance(m_accountInfo, m_accountConfig, "SH", OPT_BUY)
                
                checkStkAccountCompliance(m_accountInfo, m_accountConfig, "SZ", OPT_BUY)
                
                local accountStocks = {}
                local accountData = getAccountData(m_accountInfo)

                -- 静态风控黑白名单轮询
                if accountData ~= CAccountData_NULL then
                    local positions = accountData:getVector(XT_CPositionStatics)
                    
                    if positions then
                        local size = positions:size()
                        for i = 0, positions:size() - 1, 1 do
                            local isInGlobal = false
                            local isInInstitution = false
                            local position = positions:at(i)
                            local market = position:getString(CPositionStatics_m_strExchangeID)
                            local stock  = position:getString(CPositionStatics_m_strInstrumentID)

                            -- 全局
                            if s_globalConfig then
                                local checkBWresult, errorMsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, market, stock, true, OPT_INVALID)
                                if not checkBWresult then
                                    table.insert(accountStocks, position:getKey())
                                    isInGlobal = true
                                end
                            end
                            
                            if m_institutionConfigTable and not isInGlobal then
                                local ins_checkBWresult, strmsg = checkInstitutionBlackWhite(m_accountInfo.m_nBrokerType, m_institutionConfigTable, market, stock, true)
                                if not ins_checkBWresult then
                                    isInInstitution = true
                                    table.insert(accountStocks, position:getKey())
                                end
                            end
                            
                            -- 帐号
                            if m_accountConfig and not isInGlobal and not isInInstitution then
                                checkBWresult, errorMsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, market, stock, true, OPT_INVALID)
                                if not checkBWresult then
                                    table.insert(accountStocks, position:getKey())
                                end
                            end
                        end
                    end
                end
                
                rcUpdateBlackWhiteRCData(m_nProductId, XT_RC_SCOPE_TYPE_ACCOUNT, XT_RC_ST_BLACKWHITE, accountKey, -1, accountStocks, accountKey)

                -- 检查证券账号数量合规
                local ret, nCurrentOrderNum = pollingAccountMaxOrderTimes(accountData, m_accountConfig)
                rcUpdateOrderNumLimitRCData(m_nProductId, XT_RC_SCOPE_TYPE_ACCOUNT, XT_RC_ST_ORDER_NUM, accountKey, -1, nCurrentOrderNum, not ret)
                
                -- 检查证券账号金额合规
                local ret, dCurrentLmitMoney = pollingAccountMoney(m_accountConfig, accountData)
                rcUpdateMoneyLimitRCData(m_nProductId, XT_RC_SCOPE_TYPE_ACCOUNT, XT_RC_ST_MONEY, accountKey, -1, dCurrentLmitMoney, not ret)
                
            elseif m_accountInfo.m_nBrokerType == AT_FUTURE then
                checkAccountOpenOpenPositionWithdraw(accountData, m_accountConfig)
                
                -- 静态风控黑白名单轮询
                local accountStocks = {}
                if accountData ~= CAccountData_NULL then
                    local positions = accountData:getVector(XT_CPositionStatics)
                    
                    if positions then
                        local size = positions:size()
                        for i = 0, positions:size() - 1, 1 do
                            local isInGlobal = false
                            local position = positions:at(i)
                            local market = position:getString(CPositionStatics_m_strExchangeID)
                            local stock  = position:getString(CPositionStatics_m_strInstrumentID)

                            -- 全局
                            if s_globalConfig then
                                local checkBWresult = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, market, stock, true, OPT_INVALID)
                                if not checkBWresult then
                                    table.insert(accountStocks, position:getKey())
                                    isInGlobal = true
                                end
                            end
                            
                            -- 帐号
                            if m_riskControl and not isInGlobal then
                                checkBWresult = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, market, stock, true, OPT_INVALID)
                                if not checkBWresult then
                                    table.insert(accountStocks, position:getKey())
                                end
                            end
                        end
                    end
                end
                
                rcUpdateBlackWhiteRCData(m_nProductId, XT_RC_SCOPE_TYPE_ACCOUNT, XT_RC_ST_FTBLACKWHITE, accountKey, -1, accountStocks, accountKey)
            end
        end
    end

    --检查账号止损                                                  
    m_stoplossing = false
    local accountKey = m_accountInfo:getKey()
    local interval = 5   --默认5秒检查一遍账号止盈止损

    if interval > 0 then
        local thisPolling = getIntFromDouble(m_pollingCnt/interval)
        local lastPolling = getIntFromDouble(m_lastPollingCnt/interval)
        if 0 == m_pollingCnt % interval or (thisPolling - lastPolling >= 1) then 
            if m_accountInfo.m_nBrokerType == AT_FUTURE then
                --检查账号止盈止损
                isSelf = true
                m_stoplossing = true
                checkAccountStop(m_accountInfo, m_riskControl, isSelf)           --新增了m_riskControl新账号风控
            end

            --检查合约止损
            if m_stoplossing == false and m_accountConfig ~= nil and m_accountInfo.m_nBrokerType == AT_FUTURE then --如果已经触发了账号的止损，就不再进行合约的止损了
                checkInstrumentStopLoss(accountData, m_accountConfig)
            end
        end
    end

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
