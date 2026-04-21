--RCProductGroupTester.lua

-- 针对产品组的指令、任务与委托风控测试

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")


g_config        = nil   

m_accountInfos  = nil   -- 传入的账号组
m_strLogTag     = ''
m_strLogTagOriginal = ''

m_groupConfig = nil
m_nGroupId = nil

m_strLogTag     = ''
m_bProductGroupRC = true
m_productGroupTag = ''


function init()
    if g_config then m_groupConfig = bson.toLua(g_config) end
    m_strLogTagOriginal = "[ group_test : group=" .. tostring(m_nGroupId) ..  " ] "
    rcprintLog(m_strLogTagOriginal .. "init")
end

-- 销毁
function destroy()
rcprintLog(m_strLogTag .. "destroy")
    g_config        = nil   
    m_accountInfos  = nil
    m_strLogTag     = ''
    m_groupConfig   = nil
    m_nGroupId      = nil
    m_productGroupTag = ''
end

local function testGroupAsset(param, isHedge)
    local msgHeader = '[产品组风控] ' .. m_productGroupTag
    if not m_groupConfig or not m_groupConfig.m_Rule or not m_groupConfig.m_Rule.m_assetsRCs then
        return TTError()
    end

    --rcprintLog(m_strLogTag .. " config: " .. table2jsonOld(m_groupConfig))
    local resMsg = ''
    
    local assetsRCs = reorderAssetsRCs(m_groupConfig.m_Rule.m_assetsRCs)
    local size = table.getn(assetsRCs)
    for iRule = 1, size, 1 do
        local res, msg = checkSubFundRule(param.m_cmd.m_stockParams, false, assetsRCs[iRule], msgHeader, isHedge, param)
    end
    
    return TTError()
end

-- 合规检查:
function check(param)
    collectgarbage("collect")
    m_strLogTag = "[test_params|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    rcprintLog(m_strLogTag .. ' check start.')

    local isHedge = false
    local hedgeParam = bson.toLua(param.m_cmd.m_hedgeParam)
    if hedgeParam and hedgeParam.m_bAutoHedge then
        isHedge = true
    end

    testGroupAsset(param, isHedge)

    return TTError()
end

