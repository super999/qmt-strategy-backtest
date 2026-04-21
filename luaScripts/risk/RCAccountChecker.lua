--RCAccountChecker.lua

-- 针对账号的检查，包括指令、任务、委托

package.path = package.path .. ";./../luaScripts/risk/?.lua"
dofile("../luaScripts/risk/RCCommon.lua")
m_accountInfo       = nil   -- 传入的账号信息
m_accountInfos      = nil   -- 传入的账号组，用于计算持仓组合
g_config            = nil   -- 传入的账号风控配置，bson格式
m_nProductId        = nil   -- 产品ID，方便查看日志，例如243

m_accountConfig     = nil   --账号风控配置，由g_config转换过来的
m_strLogTagOriginal = ''
m_strLogTag         = ''    --lua日志前缀，例如"Lua script message : strProductKey:243 strAccountID:00000266, account check: "

m_globalConfig      = nil   -- 传入的全局风控配置，bson格式
s_globalConfig      = nil   -- 全局风控配置，luaTable格式

m_riskControl       = nil  -- 账号风控配置，从账号配置获取
m_bAccountRC        = true

m_nAssetsId         = nil   -- 传入的资产比例风控ID

m_bCheckFutureProduct  = true  -- 判断是否做期货交易限制, 当配置黑白名单缺失时而且有检查交易限制应该放行

m_institutionConfig = nil
m_institutionConfigTable = nil

-- 初始化, 注册信息
function init()
    m_strLogTagOriginal = "[ account_check : product=" .. tostring(m_nProductId) .. ", account=" .. getAccountDisplayID(m_accountInfo) .. " ] "
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


local function checkAccountAssets(m_nId, param, isOrderInfo, isHedge)
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
    end
    local finalRes = TTError()
    finalRes:setErrorMsg(resMsg)
    return finalRes
end

-- 合规检查
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

    rcprintLog(m_strLogTag .. "开始账号风控检查")

    if not m_accountConfig and not s_globalConfig then
        rcprintLog(m_strLogTag .. "m_accountConfig and s_globalConfig is NULL")
        return TTError()
    end

    if not m_accountConfig then
        m_riskControl = m_accountConfig.m_riskControl
        -- rcprintDebugLog(string.format('m_riskControl = %s ', table2json(m_riskControl)))    --确认已成功取得账号风控设置
    end    
       
    --检查是否为全仓止损指令，是则直接返回，不进行风控检查
    if m_nId == XT_COrderCommand and param.m_eStopLossType == SLT_ALL_LOSS then
        return TTError()
    end
    if m_nId == XT_COrderInfo and param.m_xtTag and param.m_xtTag.m_eStopLossType == SLT_ALL_LOSS then
        return TTError()
    end
    
   
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
            return TTError(-1, strmsg)
        end

        local accountKey = m_accountInfo:getKey()

        if shouldCheckGlobal() then
            if m_nId == XT_COrderCommand  or m_nId == XT_CCreateTaskReq then
                local m_stockParams = param.m_stockParams

                local stockParams = getCodeOrderParms(m_stockParams, m_accountInfo)
                local Buy_money = 0
                for i = 0, stockParams:size() - 1, 1 do
                    local stockparam = stockParams:at(i)
                    if isMyAccount(m_accountInfo, stockparam) then
                        local m_strProductId = stockparam.m_stock.m_strProduct
                        local m_strInstrumentId = stockparam.m_stock.m_strCode
                        local m_strExchangeId = stockparam.m_stock.m_strMarket
                        local m_eOperationType = stockparam.m_eOperationType
                        local m_nNum = stockparam.m_nNum
                        
                        if OPT_DIRECT_CASH_REPAY ~= m_eOperationType 
                            and OPT_DIRECT_SECU_REPAY ~= m_eOperationType 
                            and OPT_OPTION_NS_DEPOSIT ~= m_eOperationType
                            and OPT_OPTION_NS_WITHDRAW ~= m_eOperationType then
                            --检查全局黑白名单风控
                            local s_checkBWresult, strmsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, m_strExchangeId, m_strInstrumentId, false, m_eOperationType)
                            if not s_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                return TTError(-1, strmsg)
                            end

                            --检查机构黑白名单风控
                            local ins_checkBWresult, strmsg = checkInstitutionBlackWhite(m_accountInfo.m_nBrokerType, m_institutionConfigTable, m_strExchangeId, m_strInstrumentId, false)
                            if not ins_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                return TTError(-1, strmsg)
                            end
                            
                            --检查帐号黑白名单风控
                            local m_checkBWresult, strmsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, m_strExchangeId, m_strInstrumentId, false)
                            if not m_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                return TTError(-1, strmsg)
                            end
                        end
                        --检查帐号的可买资金
                        if (OPT_BUY == m_eOperationType 
                            and (not rcIsStockInCategory(m_strExchangeId, m_strInstrumentId, stockparam.m_stock.m_strName, XT_RCC_SYSTEM_CODE_SECURITIES_SUBSCRIPTION)))
                            or OPT_BUY_SECU_REPAY == m_eOperationType then
                            --使用最新价计算 购买证券所需的资金
                            local LastPrice = rcGetLastPrice(m_accountInfo.m_nPlatformID, m_strExchangeId, m_strInstrumentId)
                            Buy_money = Buy_money + m_nNum * LastPrice
                            local Account_AvailableMoney, res = getAccountMoney(m_accountInfo, CAccountDetail_m_dAvailable)
                            local dExpiringMortgage = rcGetAccountExpiringMortgage(m_accountInfo)
                            if Buy_money > Account_AvailableMoney - dExpiringMortgage then
                                local strmsg = string.format("当前买入股票%s,累计资金已达到%.2f, 帐号的可用资金%.2f扣除结算后的回购额%.2f后，余额不足!", m_strInstrumentId, Buy_money, Account_AvailableMoney, dExpiringMortgage)
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcReport(m_nProductId, m_accountInfo, strmsg)
                                --暂时不禁止开仓
                                --return TTError(-1, strmsg)
                            end
                        end
                    end
                end 
            elseif m_nId == XT_COrderInfo then
                -- 检查证券账号数量合规
                local ret, strmsg = checkAccountMaxOrderTimes(accountData, m_accountConfig, param)
                if not ret then
                    strmsg = genAccountMsgTag(m_nId)..strmsg
                    rcprintLog(m_strLogTag .. "checkAccountOrderLimitTimes, error" .. strmsg)
                    return TTError(-1, strmsg)
                end
            end
        end
        
        if m_nId == XT_COrderCommand or m_nId == XT_CCreateTaskReq  then

            local isHedge = false
            local isOrderInfo = false
            local params = param.m_stockParams    -- CCodeOrderParam
            local hedgeParam = bson.toLua(param.m_hedgeParam)
            if hedgeParam and hedgeParam.m_bAutoHedge then
                isHedge = true
            end

            -- 检查证券账号金额合规
            local ret, strmsg = checkAccountMoney(m_accountConfig, accountData, params, param.m_nID)
            if not ret then
                strmsg = genAccountMsgTag(m_nId)..strmsg
                rcprintLog(m_strLogTag .. "checkAccountMoney, error:"..strmsg)
                return TTError(-1, strmsg)
            end
            
            -- 股票账号资产组合风控检查
            local res = TTError()
            res = checkAccountAssets(m_nId, params, isOrderInfo, isHedge)
            if not res:isSuccess() then
                return res
            end
        end 
        return TTError()
    elseif m_accountInfo.m_nBrokerType == AT_FUTURE then
        --期货账号
        if not m_accountConfig then
            rcprintLog(m_strLogTag .. "m_accountConfig is NULL")
            return TTError()
        end

        local accountData = getAccountData(m_accountInfo)
        if accountData == CAccountData_NULL then
            local strmsg = "账号数据为空!"
            rcprintLog(m_strLogTag .. "error:"..strmsg)
            return TTError(-1, strmsg)
        end
        local accountKey = m_accountInfo:getKey()
        
        --检查交易品种、开仓量、持仓量、撤单次数
        if shouldCheckGlobal() then
            if m_nId == XT_COrderCommand  or m_nId == XT_CCreateTaskReq then
                local m_stockParams = param.m_stockParams
                local stockParams = getCodeOrderParms(m_stockParams, m_accountInfo)
                local eTradeType = param.m_eTradeType
                --检查交易品种
                local hedgeType = param.m_eXtHedgeType
                if m_nId == XT_COrderCommand and eTradeType ~= TDT_NON_STANDARD then -- 场外业务不检查期货黑白名单与合规
                    if hedgeType == 0 or hedgeType == 1 or hedgeType == 2 or hedgeType == 3 or m_nId == XT_CCreateTaskReq then   --XT_HEDGE_TYPE_SPECULATION=0, XT_HEDGE_TYPE_GROUP=1, XT_HEDGE_TYPE_HEDGE=2, XT_HEDGE_TYPE_RENEW=3
                        local ret, strmsg = checkAccountOrderProduct(stockParams, m_accountConfig)
                        if not ret then
                            strmsg = genAccountMsgTag(m_nId)..strmsg
                            rcprintLog(m_strLogTag .. "checkAccountOrderProduct, error:"..strmsg)
                            return TTError(-1, strmsg)
                        end
                    end

                    for i = 0, stockParams:size() - 1, 1 do
                        local stockparam = stockParams:at(i)
                        if isMyAccount(m_accountInfo, stockparam) then
                            local strExchangeId = stockparam.m_stock.m_strMarket
                            local strInstrumentId = stockparam.m_stock.m_strCode
                            local m_eOperationType = stockparam.m_eOperationType

                            --检查全局黑白名单风控
                            local s_checkBWresult, strmsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, strExchangeId, strInstrumentId, false, m_eOperationType)
                            if not s_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                return TTError(-1, strmsg)
                            end

                            --检查机构黑白名单风控
                            local ins_checkBWresult, strmsg = checkInstitutionBlackWhite(m_accountInfo.m_nBrokerType, m_institutionConfigTable, strExchangeId, strInstrumentId, false)
                            if not ins_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                return TTError(-1, strmsg)
                            end

                            --检查帐号黑白名单风控
                            local m_checkBWresult, strmsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, strExchangeId, strInstrumentId, false)
                            if not m_checkBWresult then
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. strmsg)
                                return TTError(-1, strmsg)
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
                                strmsg = genAccountMsgTag(m_nId)..strmsg
                                rcprintLog(m_strLogTag .. "checkAccountOpenPositionWithDraw, error:"..strmsg)
                                return TTError(-1, strmsg)
                            end
                        end
                    end
                end
            elseif m_nId == XT_COrderInfo then
                --检查开仓量、持仓量、撤单次数
                local m_strProductId = param.m_strProductId
                local m_strExchangeId = param.m_strExchangeId
                local m_strInstrumentId = param.m_strInstrumentId
                local m_eOperationType = param.m_eOperationType
                local m_nOrderNum = param.m_nOrderNum
                local ret, strmsg = checkAccountOpenPositionWithDraw(accountData, m_accountConfig, m_strProductId, m_strExchangeId, m_strInstrumentId, m_nOrderNum, m_nId, m_eOperationType, param.m_nHedgeFlag, param)
                if not ret then
                    strmsg = genAccountMsgTag(m_nId)..strmsg
                    rcprintLog(m_strLogTag .. "checkAccountOpenPositionWithDraw, error:"..strmsg)
                    return TTError(-1, strmsg)
                end 
            end
        end
        
        if m_nId == XT_COrderCommand or m_nId == XT_CCreateTaskReq then
            local params = nil
            local isHedge = false
            local isOrderInfo = false
            if XT_COrderInfo == m_nId then
                params = param  -- COrderInfoPtr
                isOrderInfo = true
            else
                params = param.m_stockParams    -- CCodeOrderParam
                local hedgeParam = bson.toLua(param.m_hedgeParam)
                if hedgeParam and hedgeParam.m_bAutoHedge then
                    isHedge = true
                end
            end

            -----------期货账号的资产组合风控不需要区分母基金和B基金--------------
            local res = TTError()
            res = checkAccountAssets(m_nId, params, isOrderInfo, isHedge)
            if not res:isSuccess() then
                return res
            end
        end
    elseif m_accountInfo.m_nBrokerType == AT_STOCK_OPTION then
    
        if not m_accountConfig then
            rcprintLog(m_strLogTag .. "m_accountConfig is NULL")
            return TTError()
        end
        
        if m_nId == XT_COrderCommand then
            local m_stockParams = param.m_stockParams
            local stockParams = getCodeOrderParms(m_stockParams, m_accountInfo)
            
            for i = 0, stockParams:size() - 1, 1 do
                local stockparam = stockParams:at(i)
                if isMyAccount(m_accountInfo, stockparam) then
                    local m_strProductId = stockparam.m_stock.m_strProduct
                    local m_strInstrumentId = stockparam.m_stock.m_strCode
                    local m_strExchangeId = stockparam.m_stock.m_strMarket
                    local m_eOperationType = stockparam.m_eOperationType
                    local m_nNum = stockparam.m_nNum
                    -- 期权黑白名单风控， portal尚未做好 先不检查
                    if OPT_DIRECT_CASH_REPAY ~= m_eOperationType 
                        and OPT_DIRECT_SECU_REPAY ~= m_eOperationType 
                        and OPT_OPTION_NS_DEPOSIT ~= m_eOperationType
                        and OPT_OPTION_NS_WITHDRAW ~= m_eOperationType
                        and OPT_OPTION_SECU_LOCK ~= m_eOperationType
                        and OPT_OPTION_SECU_UNLOCK ~= m_eOperationType then
                        -- 检查全局黑白名单风控
                        -- 期权暂时没有全局黑白名单
                        local s_checkBWresult, strmsg = checkGlobalBlackWhite(m_accountInfo.m_nBrokerType, s_globalConfig, m_strExchangeId, m_strInstrumentId, false, m_eOperationType)
                        if not s_checkBWresult then
                            strmsg = genAccountMsgTag(m_nId)..strmsg
                            rcprintLog(m_strLogTag .. strmsg)
                            return TTError(-1, strmsg)
                        end

                        --检查帐号黑白名单风控
                        local m_checkBWresult, strmsg = checkAccountBlackWhite(m_accountInfo.m_nBrokerType, m_accountConfig, m_strExchangeId, m_strInstrumentId, false, m_eOperationType)
                        if not m_checkBWresult then
                            strmsg = genAccountMsgTag(m_nId)..strmsg
                            rcprintLog(m_strLogTag .. strmsg)
                            return TTError(-1, strmsg)
                        end
                    end
                end
            end
        end
    elseif m_accountInfo.m_nBrokerType == AT_GOLD then
        if m_nId == XT_COrderCommand  or m_nId == XT_CCreateTaskReq then        
            local isHedge = false
            local isOrderInfo = false
            local params = param.m_stockParams    -- CCodeOrderParam
            local hedgeParam = bson.toLua(param.m_hedgeParam)
            if hedgeParam and hedgeParam.m_bAutoHedge then
                isHedge = true
            end

            local res = TTError()
            res = checkAccountAssets(m_nId, params, isOrderInfo, isHedge)
            if not res:isSuccess() then
                return res
            end
        end
    end

    return TTError()
end

