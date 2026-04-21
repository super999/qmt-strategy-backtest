--RCGlobalTester.lua

-- 针对全局的指令、任务与委托风控测试

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")


g_config        = nil   -- 暂不用
future_config   = nil   -- 传入的期货风控， bson
stock_config    = nil   -- 传入的股票风控， bson
assets_config   = nil   -- 传入的资产组合风控， bson

m_globalConfig  = nil   -- 暂不用
m_futureConfig  = nil   -- 期货风控， table
m_stockConfig   = nil   -- 股票风控， table
m_assetsConfig  = nil   -- 资产组合风控， table

m_nProductId    = nil   -- 伪造的产品ID， -1
m_productInfo   = nil   -- 伪造的产品信息
m_accountInfos  = nil   -- 传入的账号组
m_strLogTag     = ''
m_strLogTagOriginal = ''

m_nAssetsId         = nil   -- 传入的资产比例风控ID
m_bTester           = true  -- 判断是否为风控试算
function init()
    m_strLogTagOriginal = "[ global_test ] "
    rcprintLog(m_strLogTagOriginal .. 'init')
    if future_config then
        m_futureConfig = bson.toLua(future_config)
    end
    if stock_config then
        m_futureConfig = bson.toLua(stock_config)
    end
    if assets_config then
        m_assetsConfig = bson.toLua(assets_config)
    end
end

-- 销毁
function destroy()
    rcprintLog(m_strLogTag .. "destroy")
    m_futureConfig  = nil
    m_stockConfig   = nil 
    m_assetsConfig  = nil
    m_strLogTag     = ''
end

-- 检查全局资产组合
local function testGlobalAsset(param, isHedge)
    local msgHeader = '[全局资产组合风控]'
    if not m_assetsConfig or not m_assetsConfig.m_assetsRCs then
        return TTError()
    end
    
    local resMsg = ''
    
    local assetsRCs = reorderAssetsRCs(m_assetsConfig.m_assetsRCs)
    local size = table.getn(assetsRCs)
    for iRule = 1, size, 1 do
        if shouldCheckAssets(assetsRCs[iRule].m_nID) then
            local res, msg = checkSubFundRule(param.m_cmd.m_stockParams, isOrderInfo, assetsRCs[iRule], msgHeader, isHedge, param)
        end
    end
    
    return TTError()
end

function globalTestPriceTypeLimit(param)
    local msgHeader = '[全局交易价格风控]'
    if not m_assetsConfig or not m_assetsConfig.m_orderLimit then
        return TTError()
    end

    return checkPriceTypeLimit(param, false, m_assetsConfig.m_orderLimit, msgHeader)
end

-- 合规检查:
function check(param)
    collectgarbage("collect")
    m_strLogTag = "[test_params|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    rcprintLog(m_strLogTag .. ' check start.')

    if shouldCheckGlobal() then
        local vecRes = rcGlobalTest(param.m_cmd.m_stockParams)
        for i = 0, vecRes:size() - 1, 1 do
            local e = vecRes:at(i)
            if not e:isSuccess() then
                setTTError(param, i, e:errorID(), e:errorMsg())
            end
        end
    
        for i = 0, param.m_cmd.m_stockParams:size() - 1, 1 do
            local stockparam  = param.m_cmd.m_stockParams:at(i)
            local res = globalTestPriceTypeLimit(stockparam)
            if not res:isSuccess() then
                setTTError(param, i, res:errorID(), res:errorMsg())
            end
        end
    end

    if not m_assetsConfig then
        rcprintLog(m_strLogTag .. " return success : 资产比例风控配置为空")
        return TTError()
    end

    local isHedge = false
    local hedgeParam = bson.toLua(param.m_cmd.m_hedgeParam)
    if hedgeParam and hedgeParam.m_bAutoHedge then
        isHedge = true
    end

    local res = testGlobalAsset(param, isHedge)

    return TTError()
end
