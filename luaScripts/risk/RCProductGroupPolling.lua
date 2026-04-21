--RCProductGroupPolling.lua

-- 产品组风控的轮询处理

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")

g_config        = nil   

m_nProductId    = nil   -- 伪造的产品ID， -4
m_productInfo   = nil   -- 伪造的产品信息
m_accountInfos  = nil   -- 传入的账号组
m_strLogTag     = ''

m_groupConfig = nil
m_nGroupId = nil

m_strLogTag     = ''
m_bPollingRC    = true
m_bProductGroupRC = true
m_productGroupTag = ''
m_bEntrustable  = true

m_lastPollingTime = 0           --上次轮询的时间
m_lastPollingCnt = 0            --上次轮询的前，轮询总秒数

m_pollingTime = 0               --本次轮询的时间
m_pollingCnt = 0                --本次轮询前，轮询总秒数

function init()
    if g_config then m_groupConfig = bson.toLua(g_config) end
    m_strLogTag = "[ productgroup_polling : group=" .. tostring(m_nGroupId) ..  " ] "
    rcprintLog(m_strLogTag .. "init")
end

-- 销毁
function destroy()
    rcprintLog(m_strLogTag .. "destroy")
    g_config        = nil   
    m_nProductId    = nil
    m_productInfo   = nil
    m_accountInfos  = nil
    m_strLogTag     = ''
    m_groupConfig = nil
    m_nGroupId = nil
    m_productGroupTag = ''
end

local function checkProductGroupStopLoss(fundConfig)
    
    local dNetValue = rcGetProductGroupBasicIndex(m_nGroupId, XT_RCF_PRODUCTGROUP_NAV)
    
    -- 1. 净值检查
    checkProductStopLossRule("产品组" .. m_productGroupTag, XT_NETVALUE_STOPLOSS, "NetValueStopLoss", fundConfig.m_netValueStoploss, dNetValue, dNetValue, 0)
 
    -- 2. 净值跌幅检查
    local preNetValue
    preNetValue = rcGetProductGroupBasicIndex(m_nGroupId, XT_RCF_PRODUCTGROUP_PRE_NAV)

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
        
    checkProductStopLossRule("产品组" .. m_productGroupTag, XT_NETVALUE_LOSS_STOPLOSS, "NetValueLossStopLoss", fundConfig.m_netValueLossStopLoss, dNetValue, lossRate, preNetValue)
end

local function pollingGroupAssets()
    local msgHeader = '[产品组风控] ' .. m_productGroupTag
    if not m_groupConfig or not m_groupConfig.m_Rule or not m_groupConfig.m_Rule.m_assetsRCs then
        return TTError()
    end
    --rcprintLog(m_strLogTag .. " config: " .. table2jsonOld(m_groupConfig))
    
    local assetsRCs = reorderAssetsRCs(m_groupConfig.m_Rule.m_assetsRCs)
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
                rcprintIdLog(122, m_strLogTag .. string.format("pollingGroupAssets assetId: %d, m_pollingCnt:%d, interval:%d, thisPolling:%d, lastPolling:%d", rc.m_nID, m_pollingCnt, interval, thisPolling, lastPolling))
                local res, msg = pollingSubFundRule(XT_RC_SCOPE_TYPE_PRODUCTGROUP, CCodeOrderParamList().m_params, false, assetsRCs[iRule], msgHeader, tostring(m_nGroupId))
            else
                rcUseOldProductAssetsData(-3, rc.m_nID, CAccountInfo())
            end
        end
    end
end

local function pollingProductGroupRule(rule)
    if nil ~= rule then
        checkProductGroupStopLoss(rule)
    end
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

    pollingGroupAssets()
end

function check()
    if 0 ~= m_lastPollingTime then
        m_pollingTime = os.time()
        m_pollingCnt = m_lastPollingCnt + m_pollingTime - m_lastPollingTime
    end
    
    collectgarbage("collect")
    rcprintDebugLog(m_strLogTag .. " start")
    
    if nil == m_groupConfig or nil == m_groupConfig.m_Rule then
        rcprintDebugLog(m_strLogTag .. 'check : nil fundConfig, return.')
        return TTError()
    end
    
    m_stoplossing = false
    pollingProductGroupRule(m_groupConfig.m_Rule)
    
    m_lastPollingCnt = m_pollingCnt

    -- 第一次设置的时候设置当前的时间，后面设置轮询前的时间
    -- 如果都设置成当前时间，则可能轮询前时间没有达到轮询点，导致没有轮询，但是轮询后的时间达到了轮询点，
    -- 导致下一次轮询的时候误认为这次已经轮询，下面就不会在轮询。从而可能会漏掉某些轮询
    if 0 == m_lastPollingTime then
        m_lastPollingTime = os.time()
    else
        m_lastPollingTime = m_pollingTime
    end
    
    rcprintDebugLog(m_strLogTag .. " end")
    return TTError()
end
