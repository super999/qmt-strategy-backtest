-- RCProductGroupChecker.lua

-- 针对产品组的指令、任务与委托风控检查

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")


g_config        = nil   

m_accountInfos  = nil   -- 传入的账号组
m_strLogTagOriginal = ''
m_strLogTag     = ''

m_groupConfig = nil
m_nGroupId = nil
m_bProductGroupRC = true
m_productGroupTag = ''

function init()
    if g_config then m_groupConfig = bson.toLua(g_config) end
    m_strLogTagOriginal = "[ productgroup_check : group=" .. tostring(m_nGroupId) ..  " ] "
    rcprintLog(m_strLogTagOriginal .. "init")
end

-- 销毁
function destroy()
    rcprintLog(m_strLogTag .. "destroy")
    g_config        = nil   
    m_accountInfos  = nil
    m_strLogTag     = ''
    m_groupConfig = nil
    m_nGroupId = nil
    m_productGroupTag = ''
end

local function checkGroupAsset(param, isOrderInfo, isHedge)
    local msgHeader = '[产品组风控] ' .. m_productGroupTag
    if not m_groupConfig or not m_groupConfig.m_Rule or not m_groupConfig.m_Rule.m_assetsRCs then
        return TTError()
    end
    --rcprintLog(m_strLogTag .. " config: " .. table2jsonOld(m_groupConfig))
    local resMsg = ''
    
    local assetsRCs = reorderAssetsRCs(m_groupConfig.m_Rule.m_assetsRCs)
    local size = table.getn(assetsRCs)
    for iRule = 1, size, 1 do
        local res, msg = checkSubFundRule(param, isOrderInfo, assetsRCs[iRule], msgHeader, isHedge)
        --rcprintLog(m_strLogTag .. string.format("%d. res: %s, msg:%s ", iRule, tostring(res), msg ))
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

    rcprintLog(m_strLogTag .. '开始账号组风控检查')

    local m_nId = param:getStructDes().m_nId
    
    local res = TTError()
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
                hedgeType = hedgeParam.m_nHedgeType
                isHedge = true
            end
        end
    
        res = checkGroupAsset(params, isOrderInfo, isHedge)
        if not res:isSuccess() then
            return res
        end
    end
    return TTError()
end
