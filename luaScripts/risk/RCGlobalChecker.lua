--RCGlobalChecker.lua

-- 针对全局的指令、任务与委托风控检查

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")


g_config        = nil   -- 暂不用
future_config   = nil   -- 传入的期货风控， bson
stock_config    = nil   -- 传入的股票风控， bson
HGT_config      = nil   -- 传入的沪港通风控，bson
assets_config   = nil   -- 传入的资产组合风控， bson

m_globalConfig  = nil   -- 暂不用
m_futureConfig  = nil   -- 期货风控， table
m_stockConfig   = nil   -- 股票风控， table
m_HGTConfig     = nil   -- 沪港通风控，table
m_assetsConfig  = nil   -- 资产组合风控， table

m_nProductId    = nil   -- 伪造的产品ID， -1
m_productInfo   = nil   -- 伪造的产品信息
m_accountInfos  = nil   -- 传入的账号组
m_strLogTagOriginal = ''
m_strLogTag     = ''

m_nAssetsId         = nil   -- 传入的资产比例风控ID

function init()
    m_strLogTagOriginal = "[ global_check ] "
    rcprintLog(m_strLogTagOriginal .. "init")
    if future_config then
        m_futureConfig = bson.toLua(future_config)
    end
    if stock_config then
        m_stockConfig = bson.toLua(stock_config)
    end
    if HGT_config then
        m_HGTConfig = bson.toLua(HGT_config)
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
local function checkGlobalAsset(param, isOrderInfo, isHedge)
    local msgHeader = '[全局资产组合风控]'
    if not m_assetsConfig or not m_assetsConfig.m_assetsRCs then
        return TTError()
    end
    
    local resMsg = ''
    
    local assetsRCs = reorderAssetsRCs(m_assetsConfig.m_assetsRCs)
    local size = table.getn(assetsRCs)
    for iRule = 1, size, 1 do
        res = true
        msg = ''
        if shouldCheckAssets(assetsRCs[iRule].m_nID) then
            res, msg = checkSubFundRule(param, isOrderInfo, assetsRCs[iRule], msgHeader, isHedge)
        end
        if not res then
            local e = TTError()
            e:setErrorId(-1)
            e:setErrorMsg(msg)        
            return e
        end
        if string.len(msg) > 0 then
            if string.len(resMsg) > 0 then
                resMsg = resMsg .. '\n'
            end
            resMsg = resMsg .. msg
        end
    end
    
    local finalRes = TTError()
    finalRes:setErrorMsg(resMsg)
    return finalRes
end

--检查报单价格
function globalCheckPriceTypeLimit(param, isOrderInfo)
    local msgHeader = '[全局交易价格风控]'
    if not m_assetsConfig or not m_assetsConfig.m_orderLimit then
        return TTError()
    end

    return checkPriceTypeLimit(param, isOrderInfo, m_assetsConfig.m_orderLimit, msgHeader)
end

-- 合规检查:
function check(param)
    collectgarbage("collect")
    
    local m_nId = param:getStructDes().m_nId
    if XT_COrderCommand == m_nId then
        m_strLogTag = "[check_cmd|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    elseif XT_COrderInfo == m_nId then
        m_strLogTag = "[check_order|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    else
        m_strLogTag = m_strLogTagOriginal
    end

    rcprintLog(m_strLogTag .. '开始全局风控检查')

    local res = TTError()
    local params = nil
    local isOrderInfo = false
    local d1 = clockMSec()
    local d2 = clockMSec()
    local isHedge = false

    --检查是否为全仓止损指令，是则直接返回，不进行风控检查
    if m_nId == XT_COrderCommand and param.m_eStopLossType == SLT_ALL_LOSS then
        return TTError()
    end
    if m_nId == XT_COrderInfo and param.m_xtTag and param.m_xtTag.m_eStopLossType == SLT_ALL_LOSS then
        return TTError()
    end

    if shouldCheckGlobal() then
        if m_nId == XT_COrderCommand  or m_nId == XT_CCreateTaskReq then
            params = param.m_stockParams

            local hedgeParam = bson.toLua(param.m_hedgeParam)
            if hedgeParam and hedgeParam.m_bAutoHedge then
                isHedge = true
            end
            
            res = rcGlobalCheck(params)
            if not res:isSuccess() then
                rcprintLog(m_strLogTag .. string.format("end fail: rcGlobalCheck=%.2f msec.", clockMSec() - d1))
                return res
            end
            
            d2 = clockMSec()
            for i = 0, params:size() - 1, 1 do
                local stockparam  = params:at(i)
                res = globalCheckPriceTypeLimit(stockparam, false)
                if not res:isSuccess() then
                    return res
                end
            end
        elseif m_nId == XT_COrderInfo then
            isOrderInfo = true
            
            -- 先注释掉，委托不检查反向
            -- res = rcGlobalCheckOrder(param)
            -- if not res:isSuccess() then
                -- rcprintLog(m_strLogTag .. string.format("end fail: rcGlobalCheckOrder=%.2f msec.", clockMSec() - d1))
                -- return res
            -- end

            d2 = clockMSec()
            res = rcCheckOrderBucket(param)
            if not res:isSuccess() then
                rcprintLog(m_strLogTag .. string.format("end fail: rcGlobalCheckOrder=%.2f msec, rcCheckOrderBucket=%.2f msec.", d2 - d1, clockMSec() - d2))
                return res
            end
            
            res = globalCheckPriceTypeLimit(param, true)
            if not res:isSuccess() then
                return res
            end

            params = param
        end
    end

    local d3 = clockMSec()
    if not m_assetsConfig then
        rcprintLog(m_strLogTag .. string.format("end success (empty assets config): d12=%.2f msec, d23=%.2f msec.", d2 - d1, d3 - d2))
        return TTError()
    end
    
    if not isOrderInfo then
        params = param.m_stockParams
        if nil ~= params then
            res = checkGlobalAsset(params, isOrderInfo, isHedge)
            if not res:isSuccess() then
                rcprintLog(m_strLogTag .. string.format("end fail: d12=%.2f msec, d23=%.2f msec, checkGlobalAsset=%.2f msec.", d2 - d1, d3 - d2, clockMSec() - d3))
                return res
            end            
        end
        rcprintLog(m_strLogTag .. string.format("end success: d12=%.2f msec, d23=%.2f msec, checkGlobalAsset=%.2f msec.", d2 - d1, d3 - d2, clockMSec() - d3))
    end
    
    return TTError()
end
