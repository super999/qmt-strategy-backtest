--RCProductChecker.lua

-- 针对产品的检查，包括指令、任务、委托

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")

require('bit')

m_accountInfos      = nil   -- 传入的账号组
g_config            = nil   -- 传入的产品配置
m_nProductId        = nil   -- 传入的产品ID，方便查看日志，todo可删除
m_nAssetsId         = nil   -- 传入的资产比例风控ID
m_productInfo       = nil   -- 传入的产品信息，其中已经包含m_nProductId

m_productConfig = nil
m_strLogTagOriginal = ''
m_strLogTag     = ''
m_accountInfo   = nil

local function perfLog(log)
    printLogLevel(LLV_DEBUG, m_strLogTag .. log)
end

-- 初始化, 注册信息
function init()
    if g_config then m_productConfig = bson.toLua(g_config) end
    m_strLogTagOriginal = "[ product_check : product=" .. tostring(m_nProductId) .. " ] "
    rcprintLog(m_strLogTagOriginal .. "init")
end

-- 销毁
function destroy()
    m_productConfig = nil
    m_strLogTag     = ''
    m_accountInfo   = nil
end

local function checkProductFund(m_nId, param, isOrderInfo, hedgeType, isHedge)
    perfLog(string.format("checkProductFund begin : "))
    local fundConfig = getProductRCConfig(m_productConfig)
    if not fundConfig then return TTError() end
    
    local des = string.format('( config = %s)', table2jsonOld(fundConfig))
    local msgHeader = genProductMsgTag(m_nId)
    local resMsg = ''

    -- 产品交易参数合法性检查
    if not isOrderInfo then
        for i = 0, param:size() - 1, 1 do
            local ret, strmsg = checkProductTradeParams(fundConfig, param:at(i))
            if not ret then
                strmsg = msgHeader..strmsg
                rcprintLog(m_strLogTag .. "checkProductTradeParams, error" .. strmsg)
                return TTError(-1, strmsg)
            end
        end
    end

    --判断当日是否触发了止损，如果触发止损，则只允许开仓分类集合中的证券或期货,只判断指令
    if shouldCheckGlobal() and (not isOrderInfo) then
        local res, msg = isStopLossForbidenOpenPosition(fundConfig, param, isOrderInfo)
        if res then
            local e = TTError()
            e:setErrorId(-1)
            e:setErrorMsg(msgHeader .. msg)
            rcprintLog(m_strLogTag .. msg)
            perfLog(string.format("checkSubFund end 0 fail : disableTrade fail."))
            return e
        end
    end
    
    -- 检查可交易类型
    if shouldCheckGlobal() and (not isOrderInfo) then
        -- rcprintLog(m_strLogTag .. " my assets_id = " .. tostring(m_nAssetsId) .. ", check global.")
        local res, msg = checkSubFundTradeType(param, fundConfig, isOrderInfo)
        if not res then
            local e = TTError()
            e:setErrorId(-1)
            e:setErrorMsg(msgHeader..msg)
            rcprintLog(m_strLogTag .. string.format('%s%s return fail, msg = %s', m_strLogTag, des, msg))
            perfLog(string.format("checkSubFund end 1 fail : checkFundTradeType fail."))
            return e
        end
    end

    -- 交易价格限制检查
    if shouldCheckGlobal() and nil ~= fundConfig.m_orderLimit then
        if isOrderInfo then
            res = checkPriceTypeLimit(param, isOrderInfo, fundConfig.m_orderLimit, msgHeader)
            if not res:isSuccess() then
                return res
            end
        else
            for i = 0, param:size() - 1, 1 do
                local stockparam = param:at(i)
                res = checkPriceTypeLimit(stockparam, isOrderInfo, fundConfig.m_orderLimit, msgHeader)
                if not res:isSuccess() then
                    return res
                end
            end
        end
    end

    local bCheckAssets = (not isOrderInfo and (hedgeType ~= BHT_MANNUAL))

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
                res, msg = checkSubFundRule(param, isOrderInfo, assetsRCs[iRule], msgHeader, isHedge)
            end
            if not res then
                local e = TTError()
                e:setErrorId(-1)
                e:setErrorMsg(msg)
                perfLog(string.format("checkSubFund end 2 fail : checkSubFundRule fail, iRule = %d", iRule - 1))
                return e
            end
            if string.len(msg) > 0 then
                if string.len(resMsg) > 0 then
                    resMsg = resMsg .. '\n'
                end
                resMsg = resMsg .. msg
            end
        end
    end

    local finalRes = TTError()
    finalRes:setErrorMsg(resMsg)
    rcprintDebugLog(m_strLogTag .. string.format('%s%s return success, msg = %s', m_strLogTag, des, resMsg))
    perfLog(string.format("checkSubFund end 3 success : checkSubFundRule succeed."))
    return finalRes
end

-- 合规检查:
function check(param)
    --perfLog("*** check begin.")
    collectgarbage("collect")
    --perfLog("after collect.")
    local m_nId = param:getStructDes().m_nId
    if XT_COrderCommand == m_nId then
        m_strLogTag = "[check_cmd|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    elseif XT_COrderInfo == m_nId then
        m_strLogTag = "[check_order|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    else
        m_strLogTag = m_strLogTagOriginal
    end

    rcprintLog(m_strLogTag .. '开始产品风控检查')
    local isProductInDateRange = rcIsProductInDateRange(m_productInfo)
    if not isProductInDateRange then
        rcprintLog(m_strLogTag .. " return success : 产品不在起止时间范围内")
        local e = TTError()
        e:setErrorId(-1)
        e:setErrorMsg("产品不在起止时间范围内,禁止下单!")
        return e
    end  
    if not m_productConfig then
        rcprintLog(m_strLogTag .. " return success : 产品配置为空")
        return TTError()
    end
        
    --检查是否为全仓止损指令，是则直接返回，不进行风控检查
    if m_nId == XT_COrderCommand and param.m_eStopLossType == SLT_ALL_LOSS then
        return TTError()
    end

    if m_nId == XT_COrderCommand or m_nId == XT_CCreateTaskReq then
        m_accountInfo = getOneAccountInfo(param.m_stockParams)
    elseif m_nId == XT_COrderInfo then
        m_accountInfo = param.m_accountInfo
    end

    if m_nId == XT_COrderCommand or m_nId == XT_CCreateTaskReq or m_nId == XT_COrderInfo then

        local params = nil
        local isOrderInfo = false
        local hedgeType = 0
        local isHedge = false
        if XT_COrderInfo == m_nId then
            params = param  -- COrderInfoPtr
            isOrderInfo = true
        else
            params = param.m_stockParams    -- CCodeOrderParam
            local hedgeParam = bson.toLua(param.m_hedgeParam)
            if hedgeParam and hedgeParam.m_bAutoHedge then
                isHedge = true
                hedgeType = hedgeParam.m_nHedgeType
            end
        end

        -----------母基金 日中--------------
        local res = TTError()
        res = checkProductFund(m_nId, params, isOrderInfo, hedgeType, isHedge)
        if not res:isSuccess() then
            perfLog(string.format("--- check end fail."))
            return res
        end
    end

    perfLog(string.format("--- check end succeed."))
    return TTError()
end

