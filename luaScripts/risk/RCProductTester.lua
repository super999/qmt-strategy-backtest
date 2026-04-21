--RCProductTester.lua

-- 针对产品的测试，包括指令、任务、委托

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")

require('bit')

m_accountInfos      = nil   -- 传入的账号组
g_config            = nil   -- 传入的产品配置
m_nProductId        = nil   -- 传入的产品ID，方便查看日志，todo可删除
m_nAssetsId         = nil   -- 传入的资产比例风控ID
m_productInfo       = nil   -- 传入的产品信息，其中已经包含m_nProductId

m_productConfig = nil
m_strLogTag     = ''
m_strLogTagOriginal = ''
m_accountInfo   = nil
m_bTester       = true  -- 判断是否为风控试算
local function perfLog(log)
    printLogLevel(LLV_DEBUG, m_strLogTag .. log)
end

-- 初始化, 注册信息
function init()
    if g_config then m_productConfig = bson.toLua(g_config) end
    m_strLogTagOriginal = "[ product_test : product=" .. tostring(m_nProductId) .. " ] "
    rcprintLog(m_strLogTagOriginal .. "init")
end

-- 销毁
function destroy()
    m_productConfig = nil
    m_strLogTag     = ''
    m_accountInfo   = nil
end

local function testProductFund(param, hedgeType, isHedge)
    local fundConfig = getProductRCConfig(m_productConfig)
    if not fundConfig then return TTError() end
    
    local des = string.format('(config = %s)', table2jsonOld(fundConfig))    
    local msgHeader = genProductMsgTag(-1)

    -- 产品交易参数合法性检查
    if not isOrderInfo then
        for i = 0, param.m_cmd.m_stockParams:size() - 1, 1 do
            local ret, strmsg = checkProductTradeParams(fundConfig, param.m_cmd.m_stockParams:at(i))
            if not ret and param.m_testResults:at(i):isSuccess() then
                param.m_testResults:at(i):setErrorId(-1)
                param.m_testResults:at(i):setErrorMsg(msgHeader..strmsg)
            end
        end
    end

    --判断当日是否触发了止损，如果触发止损，则只允许开仓分类集合中的证券或期货,只判断指令
    if shouldCheckGlobal() then
        isStopLossForbidenOpenPosition(fundConfig, param.m_cmd.m_stockParams, isOrderInfo, param, msgHeader)
    end

    -- 检查可交易类型
    if shouldCheckGlobal() then
        -- 检查可交易类型
        -- rcprintDebugLog(m_strLogTag .. " my assets_id = " .. tostring(m_nAssetsId) .. ", check global.")
        checkSubFundTradeType(param.m_cmd.m_stockParams, fundConfig, false, param.m_testResults)
    end

    -- 交易价格限制检查
    if shouldCheckGlobal() and nil ~= fundConfig.m_orderLimit then
        for i = 0, param.m_cmd.m_stockParams:size() - 1, 1 do
            local stockparam = param.m_cmd.m_stockParams:at(i)
            if isMyProduct(m_accountInfos, stockparam) then
                res = checkPriceTypeLimit(stockparam, false, fundConfig.m_orderLimit, msgHeader)
                if not res:isSuccess() and param.m_testResults:at(i):isSuccess() then
                    param.m_testResults:at(i):setErrorId(-1)
                    param.m_testResults:at(i):setErrorMsg(res:errorMsg())
                end
            end
        end
    end

    local bCheckAssets = (hedgeType ~= BHT_MANNUAL)
    if nil ~= fundConfig.m_assetsRCs and bCheckAssets then
        -- 资产风控项排序    
        local assetsRCs = reorderAssetsRCs(fundConfig.m_assetsRCs)

        -- 检查资产风控项
        local size = table.getn(assetsRCs)
        for iRule = 1, size, 1 do
            res = true
            msg = ''
            if shouldCheckAssets(assetsRCs[iRule].m_nID) then
                -- rcprintLog(m_strLogTag .. " my assets_id = " .. tostring(m_nAssetsId) .. ", check assets " .. tostring(assetsRCs[iRule].m_nID) .. ".")
                local res, msg = checkSubFundRule(param.m_cmd.m_stockParams, false, assetsRCs[iRule], msgHeader, isHedge, param)
            end
        end
    end

    local finalRes = TTError()
    return finalRes
end

-- 合规检查:
function check(param)
    --perfLog("*** check begin.")
    collectgarbage("collect")
    --perfLog("after collect.")
    
    m_strLogTag = "[test_params|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    rcprintDebugLog(m_strLogTag .. ' check start.')

    if not m_productConfig then
        rcprintLog(m_strLogTag .. " return success : 产品配置为空")
        return TTError()
    end
    
    local hedgeType = 0
    local isHedge = false
    local hedgeParam = bson.toLua(param.m_cmd.m_hedgeParam)
    if hedgeParam and hedgeParam.m_bAutoHedge then
        hedgeType = hedgeParam.m_nHedgeType
        isHedge = true
    end

    -----------母基金 日中--------------
    local res = TTError()
    res = testProductFund(param, hedgeType, isHedge)
    if not res:isSuccess() then
        --perfLog(string.format("--- check end fail."))
        return res
    end
    
    --perfLog(string.format("--- check end succeed."))
    return TTError()
end

