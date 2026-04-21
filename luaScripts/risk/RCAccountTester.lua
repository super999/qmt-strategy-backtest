--RCAccountTester.lua

-- 针对账号的测试，包括指令、任务、委托

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")
m_accountInfo       = nil   -- 传入的账号信息
m_accountInfos      = nil   -- 传入的账号组，用于计算持仓组合
g_config            = nil   -- 传入的账号风控配置，bson格式
m_nProductId        = nil   -- 产品ID，方便查看日志，例如243
m_bIsStandalone     = nil

m_accountConfig     = nil   --账号风控配置，由g_config转换过来的
m_strLogTag         = ''    --lua日志前缀，例如"Lua script message : strProductKey:243 strAccountID:00000266, account check: "
m_strLogTagOriginal = ''
m_globalConfig      = nil   -- 传入的全局风控配置，bson格式
s_globalConfig      = nil   -- 全局风控配置，luaTable格式

m_riskControl       = nil  -- 账号风控配置，从账号配置获取
m_bAccountRC        = true

m_nAssetsId         = nil   -- 传入的资产比例风控ID
m_bTester           = true  -- 判断是否为风控试算

m_bCheckFutureProduct  = true  -- 判断是否做期货交易限制, 当配置黑白名单缺失时而且有检查交易限制应该放行

m_institutionConfig = nil
m_institutionConfigTable = nil

-- 初始化, 注册信息
function init()
    m_strLogTagOriginal = "[ account_test : product=" .. tostring(m_nProductId) .. ", account=" .. getAccountDisplayID(m_accountInfo) .. " ] "
    rcprintLog(m_strLogTagOriginal .. "init")
    if g_config then
        m_accountConfig = bson.toLua(g_config)
        if m_accountConfig then
            m_riskControl = m_accountConfig.m_riskControl
        end
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
    rcprintLog(m_strLogTag .. "destroy")
    m_accountConfig = nil
    m_strLogTag = ''
    s_globalConfig = nil
end

local function testAccountAssets(param, isHedge)
    if not m_riskControl then 
        return TTError() 
    end
    
    -- rcprintDebugLog(m_strLogTag .. string.format('m_riskControl = %s', table2json(m_riskControl)))
    local msgHeader = string.format("[账号资产组合风控]: %s ", getAccountDisplayID(m_accountInfo))   --   账号风控报警消息要带有账号信息
    local resMsg = ''

    if nil ~= m_riskControl.m_assetsRCs then
        -- 资产风控项排序    
        local assetsRCs = reorderAssetsRCs(m_riskControl.m_assetsRCs)

        -- 检查资产风控项
        local size = table.getn(assetsRCs)
        for iRule = 1, size, 1 do
            if shouldCheckAssets(assetsRCs[iRule].m_nID) then
                local res, msg = checkSubFundRule(param.m_cmd.m_stockParams, false, assetsRCs[iRule], msgHeader, isHedge, param)
            end
        end
    end
    return TTError()
end

-- 合规检查
function check(param)
    m_strLogTag = "[test_params|" .. param:getKey() .. "] " .. m_strLogTagOriginal
    rcprintLog(m_strLogTag .. "开始账号风控检查")
    
    collectgarbage("collect")

    local m_nId = XT_COrderCommand
    
    if not m_accountConfig and not s_globalConfig then
        rcprintLog(m_strLogTag .. "m_accountConfig and s_globalConfig is NULL")
        batchSetTTError(m_accountInfo, param, -1, "账号" .. getAccountDisplayID(m_accountInfo) .. "账号配置不存在")
        return TTError()
    end

    if not m_accountConfig then
        m_riskControl = m_accountConfig.m_riskControl
        -- rcprintDebugLog(string.format('m_riskControl = %s ', table2json(m_riskControl)))    --确认已成功取得账号风控设置
    end

    if shouldCheckGlobal() then
        if m_accountInfo.m_nBrokerType == AT_STOCK or
            m_accountInfo.m_nBrokerType == AT_CREDIT or
            m_accountInfo.m_nBrokerType == AT_HUGANGTONG or
            m_accountInfo.m_nBrokerType == AT_NEW3BOARD then
            --rcprintLog(m_strLogTag .. "证券或信用账号")

            --股票账号的黑白名单风控
            local accountData = getAccountData(m_accountInfo)
            if accountData == CAccountData_NULL then
                local strmsg = "账号数据为空"
                rcprintLog(m_strLogTag .. ", error:"..strmsg)
                batchSetTTError(m_accountInfo, param, -1, "账号" .. getAccountDisplayID(m_accountInfo) .. "账号数据为空")
                return TTError()
            end

            local accountKey = m_accountInfo:getKey()

            local stockParams = param.m_cmd.m_stockParams
            local Buy_money = 0

            for i = 0, stockParams:size() - 1, 1 do

                local stockparam = stockParams:at(i)
                -- 打新中签放弃时，不进行风控检查
                if OPT_IPO_CANCEL ~= stockparam.m_eOperationType then
                    if isMyAccount(m_accountInfo, stockparam) then
                        local m_strInstrumentId = stockparam.m_stock.m_strCode
                        local m_strExchangeId = stockparam.m_stock.m_strMarket
                        local m_eOperationType = stockparam.m_eOperationType
                        
                        if OPT_DIRECT_CASH_REPAY ~= m_eOperationType and OPT_DIRECT_SECU_REPAY ~= m_eOperationType then
                            --检查全局黑白名单风控
                            local s_checkBWresult, strmsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, m_strExchangeId, m_strInstrumentId, false)
                            if not s_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                            end
                            
                            --检查机构黑白名单风控
                            local ins_checkBWresult, strmsg = checkInstitutionBlackWhite(m_accountInfo.m_nBrokerType, m_institutionConfigTable, m_strExchangeId, m_strInstrumentId, false)
                            if not ins_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                            end
                            
                            --检查帐号黑白名单风控
                            local m_checkBWresult, strmsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, m_strExchangeId, m_strInstrumentId, false)
                            if not m_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                            end
                        end
                    end
                end
            end
            
            -- 检查证券账号金额合规
            local ret, strmsg = checkAccountMoney(m_accountConfig, accountData, param.m_cmd.m_stockParams, param.m_cmd.m_nID)
            if not ret then
                strmsg = genAccountMsgTag(m_nId)..strmsg
                rcprintLog(m_strLogTag .. "checkAccountMoney, error:"..strmsg)
                batchSetTTError(m_accountInfo, param, -1, strmsg)
                return TTError()
            end
        elseif m_accountInfo.m_nBrokerType == AT_FUTURE then
            --期货账号
            if not m_accountConfig then
                rcprintLog(m_strLogTag .. "m_accountConfig is NULL")
                batchSetTTError(m_accountInfo, param, -1, "账号" .. getAccountDisplayID(m_accountInfo) .. "账号配置不存在")
                return TTError()
            end

            local accountData = getAccountData(m_accountInfo)
            if accountData == CAccountData_NULL then
                local strmsg = "账号数据为空!"
                rcprintLog(m_strLogTag .. "error:"..strmsg)
                batchSetTTError(m_accountInfo, param, -1, "账号" .. getAccountDisplayID(m_accountInfo) .. "账号数据为空")
                return TTError()
            end
            local accountKey = m_accountInfo:getKey()

            local stockParams = param.m_cmd.m_stockParams

            --检查交易品种
            for i = 0, stockParams:size() - 1, 1 do
                local stockparam = stockParams:at(i)
                if isMyAccount(m_accountInfo, stockparam) then
                    if not checkSingleProduct(m_accountConfig, stockparam.m_stock.m_strCode, stockparam.m_stock.m_strProduct) then
                        local strmsg =  string.format("投机交易品种受到限制! 合约:"..stockparam.m_stock.m_strCode.." 品种:"..stockparam.m_stock.m_strProduct)
                        rcprintLog(m_strLogTag .. strmsg)
                        rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                    end
                end
            end
            
            for i = 0, stockParams:size() - 1, 1 do
                local stockparam = stockParams:at(i)
                if isMyAccount(m_accountInfo, stockparam) then
                    local strExchangeId = stockparam.m_stock.m_strMarket
                    local strInstrumentId = stockparam.m_stock.m_strCode
                    local m_eOperationType = stockparam.m_eOperationType
                    
                    --检查期货全局黑白名单风控
                    local s_checkBWresult, strmsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, strExchangeId, strInstrumentId, false, m_eOperationType)
                    if not s_checkBWresult then
                        strmsg = genAccountMsgTag(m_nId)..strmsg
                        rcprintLog(m_strLogTag .. strmsg)
                        rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                    end

                    --检查期货机构黑白名单风控
                    local ins_checkBWresult, strmsg = checkInstitutionBlackWhite(m_accountInfo.m_nBrokerType, m_institutionConfigTable, strExchangeId, strInstrumentId, false)
                    if not ins_checkBWresult then
                        strmsg = genAccountMsgTag(m_nId)..strmsg
                        rcprintLog(m_strLogTag .. strmsg)
                        rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                    end

                    --检查期货帐号黑白名单风控期货
                    local m_checkBWresult, strmsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, strExchangeId, strInstrumentId, false)
                    if not m_checkBWresult then
                        strmsg = genAccountMsgTag(m_nId)..strmsg
                        rcprintLog(m_strLogTag .. strmsg)
                        rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                    end
                    
                end
            end

            --检查开仓量、持仓量、撤单次数
            for i = 0, stockParams:size() - 1, 1 do
                local stockparam = stockParams:at(i)
                if isMyAccount(m_accountInfo, stockparam) then
                    local m_strProductId = stockparam.m_stock.m_strProduct
                    local m_strExchangeId = stockparam.m_stock.m_strMarket
                    local m_strInstrumentId = stockparam.m_stock.m_strCode
                    local m_eOperationType = stockparam.m_eOperationType
                    local m_nNum = stockparam.m_nNum
                    local ret, strmsg = checkAccountOpenPositionWithDraw(accountData, m_accountConfig, m_strProductId, m_strExchangeId, m_strInstrumentId, m_nNum, m_nId, stockparam.m_eOperationType, stockparam.m_nHedgeFlag, COrderInfo())
                    if not ret then
                        rcprintLog(m_strLogTag .. strmsg)
                        rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                    end
                end
            end
        elseif m_accountInfo.m_nBrokerType == AT_STOCK_OPTION then
        
            if not m_accountConfig then
                rcprintLog(m_strLogTag .. "m_accountConfig is NULL")
                batchSetTTError(m_accountInfo, param, -1, "账号" .. getAccountDisplayID(m_accountInfo) .. "账号配置不存在")
                return TTError()
            end
            
            if m_nId == XT_COrderCommand then
                local stockParams = param.m_cmd.m_stockParams
                
                for i = 0, stockParams:size() - 1, 1 do
                    local stockparam = stockParams:at(i)
                    if isMyAccount(m_accountInfo, stockparam) then
                        local m_strProductId = stockparam.m_stock.m_strProduct
                        local m_strInstrumentId = stockparam.m_stock.m_strCode
                        local m_strExchangeId = stockparam.m_stock.m_strMarket
                        local m_eOperationType = stockparam.m_eOperationType
                        local m_nNum = stockparam.m_nNum
                        -- 期权黑白名单风控， portal尚未做好 先不检查
                        if OPT_DIRECT_CASH_REPAY ~= m_eOperationType and OPT_DIRECT_SECU_REPAY ~= m_eOperationType and OPT_OPTION_SECU_LOCK ~= m_eOperationType and OPT_OPTION_SECU_UNLOCK ~= m_eOperationType then
                            -- 检查全局黑白名单风控
                            -- 期权暂时没有全局黑白名单
                            local checkBWresult, strmsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, m_strExchangeId, m_strInstrumentId, false, m_eOperationType)
                            if not checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                            end

                            --检查帐号黑白名单风控
                            local checkBWresult, strmsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, m_strExchangeId, m_strInstrumentId, false, m_eOperationType)
                            if not checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                rcSetTTError(m_accountInfo, param.m_cmd.m_nID, i, -1, strmsg)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 资产比例风控项
    local isHedge = false
    local hedgeParam = bson.toLua(param.m_cmd.m_hedgeParam)
    if hedgeParam and hedgeParam.m_bAutoHedge then
        isHedge = true
    end
    testAccountAssets(param, isHedge)

    return TTError()
end

