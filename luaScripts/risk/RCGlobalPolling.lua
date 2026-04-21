-- RCGlobalPolling.lua
-- 全局风控的轮询处理

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")

-- 以下变量在本文件中调用
assets_config   = nil   -- C++传入的资产组合风控， bson
m_assetsConfig  = nil   -- 资产组合风控， table

m_strLogTag     = ''    -- 日志Tag

-- 以下变量在RCCommon.lua中调用
m_nProductId    = nil   -- 伪造的产品ID， -1
m_productInfo   = nil   -- 伪造的产品信息
m_accountInfos  = nil   -- 传入的账号组
m_bPollingRC    = true  -- Poll标示

m_lastPollingTime = 0           --上次轮询的时间
m_lastPollingCnt = 0            --上次轮询的前，轮询总秒数

m_pollingTime = 0               --本次轮询的时间
m_pollingCnt = 0                --本次轮询前，轮询总秒数


-- 初始化
function init()
    m_strLogTag = "[ global_polling ] "
    rcprintLog(m_strLogTag .. 'init')
    if assets_config then
        m_assetsConfig = bson.toLua(assets_config)
    end
end

-- 销毁
function destroy()
    rcprintLog(m_strLogTag .. "destroy")
    m_assetsConfig  = nil
    m_strLogTag     = ''
end

-- 轮询全局资产比例风控
local function pollingGlobalAssets()
    local msgHeader = '[全局资产组合风控]'

    if nil == m_assetsConfig or nil == m_assetsConfig.m_assetsRCs then
        return TTError()
    end

    -- local des = string.format('Config: %s', table2jsonOld(m_assetsConfig))
    -- rcprintLog(m_strLogTag .. 'pollingGlobalAssets' .. des)

    -- 根据资产类型重新排序资产项（法规、合同、操作）
    local assetsRCs = reorderAssetsRCs(m_assetsConfig.m_assetsRCs)

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
                rcprintIdLog(122, m_strLogTag .. string.format("pollingGlobalAssets assetId: %d, m_pollingCnt:%d, interval:%d, thisPolling:%d, lastPolling:%d", rc.m_nID, m_pollingCnt, interval, thisPolling, lastPolling))
                local res, msg = pollingSubFundRule(XT_RC_SCOPE_TYPE_GLOBAL, CCodeOrderParamList().m_params, false, rc, msgHeader, "-1")
                if res then
                    -- rcprintLog(m_strLogTag .. string.format('accountRCConfig: %s rule %s return success, msg = %s', des, rc.m_description, msg))
                else
                -- rcprintLog(m_strLogTag .. string.format('accountRCConfig: %s rule %s return fail, msg = %s', des, rc.m_description, msg))
                end
            else
                if rc and rc.m_nID then
                    rcUseOldProductAssetsData(-1, rc.m_nID, CAccountInfo())
                end
            end
        end
    end
end

-- 合规检查:
function check()
    if 0 ~= m_lastPollingTime then
        m_pollingTime = os.time()
        m_pollingCnt = m_lastPollingCnt + m_pollingTime - m_lastPollingTime
    end

    collectgarbage("collect")

    if nil == m_assetsConfig then
        rcprintDebugLog(m_strLogTag .. " return success : 资产比例风控配置为空")
        return TTError()
    end

    -- 全局就不检查可信状态了
    -- 要不然随便一个账号登不上就会影响后续的逻辑，轮询就完全没法用了
    -- if not rcIsAccountsEntrustable(m_accountInfos) then
        -- rcprintDebugLog(m_strLogTag .. ' not all accounts entrustable, pass')
        -- return TTError()
    -- end

    pollingGlobalAssets()

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
