-- 分单脚本

package.path = package.path .. ";./../luaScripts/task/?.lua"
dofile("../luaScripts/task/Common.lua")

local function setError(err, msg)
    if err ~= TTError_NULL then
        err:setErrorId(TT_ERROR_DEFAULT)
        err:setErrorMsg(msg)
    end
end

local function weightSplit(totalVolume, price, accounts, weights, market, stock, operationType, hedgeFlag, err, positionType, availableByTsAccounts, availableVolumes, bAvailable, vSecuAccount)

    -- printLogLevel(2, string.format('[Splitter] xxx'))
    -- printLogLevel(2, string.format('[Splitter] weightSplit begin : account_num = %d, stock = %s, opt = %d, hedgeFlag = %d, price = %f, totalVolume = %f', accounts:size(), stock, operationType, hedgeFlag, price, totalVolume))
    -- 是否是直接还款（price为非法值，totalVolume其实是金额，market, stock应该忽略）
    local isDirectCashRepay = (OPT_DIRECT_CASH_REPAY == operationType) or (OPT_DIRECT_CASH_REPAY_SPECIAL == operationType) or (OPT_INTEREST_FEE == operationType)
    local isDirectSecuRepay = (OPT_DIRECT_SECU_REPAY == operationType) or (OPT_DIRECT_SECU_REPAY_SPECIAL == operationType)
    local isSellCashRepay = (OPT_SELL_CASH_REPAY == operationType) or (OPT_SELL_CASH_REPAY_SPECIAL == operationType)
    local isMoneyFund = (OPT_FUND_PRICE_BUY == operationType) or (OPT_FUND_PRICE_SELL == operationType)
    local isETFMoneyFund = (OPT_ETF_PURCHASE == operationType) or (OPT_ETF_REDEMPTION == operationType)
    local isMoneyFundBuy = (OPT_FUND_PRICE_BUY == operationType)
    local isMoneyFundSell = (OPT_FUND_PRICE_SELL == operationType)
    local isKCB = isKCBCode(market, stock) 

    local totalWeight = 0
    for i = 0, weights:size() - 1, 1 do
        local weight = weights:at(i)
        if weight < 0 then
            setError(err, "权重值" .. weight .. "非法!")
            return isDirectCashRepay and DoubleVec() or Int64Vec()
        end
        totalWeight = totalWeight + weight
    end

    if totalWeight == 0 then
        setError(err, "总权重为0!")
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end

    local dataCenter = g_traderCenter:getDataCenter()
    local availables = {}
    local availablesOdd = {}
    local stringErr = ""
    for i = 0, accounts:size() - 1, 1 do
        local account = accounts:at(i)    
        if account == CAccountInfo_NULL then
            availables[i] = 0
            availablesOdd[i] = 0
            printLogLevel(2, string.format('[Splitter] weightSplit 0 : account = NULL, available = 0'))
        else
            local key = account:getKey()
            local accountData = dataCenter:getAccount(key)
            if accountData ~= CAccountData_NULL then
                if isInvalidDouble(price) and getDirectionByOperation(operationType) and (not isDirectCashRepay) then
                    printLogLevel(2, string.format('[Splitter] weightSplit 1 : account = %s, available = 1e8', accountDisplayId(account)))
                    availables[i] = 1e8
                    availablesOdd[i] = 1e8
                else
                   -- 此处判断可用量使用服务器的还是客户端的
                    local bVolumeUseTs = false
                    local index = -1
                    
                    for i = 0, availableByTsAccounts:size() - 1, 1 do
                        local strKey = availableByTsAccounts:at(i)
                        if key == strKey then 
                           bVolumeUseTs = true
                           index = i
                           break
                        end
                    end

                    local volume = accountData:getCanOrderVolumeWithReason(market, stock, operationType, hedgeFlag, price, vSecuAccount:at(i))
                    if bVolumeUseTs and index ~= -1 then
                        volume.m_dVolume = availableVolumes:at(index)
                    end
                    if isDirectCashRepay then
                        -- 计算的地方说"钱使用者要负责/100，目的是不额外做一个double的接口"，这里做下这个处理
                        volume.m_dVolume = volume.m_dVolume / 100
                    end

                    local length = string.len(volume.m_strError)
                    if length ~= 0 and volume.m_dVolume == 0 then
                        stringErr = stringErr .. " 账号 [" .. accountDisplayId(account) .. "] " .. volume.m_strError .. "!"
                    end
                    
                    printLogLevel(2, string.format('[Splitter] weightSplit 2 : account = %s, weight = %f, stock = %s, opt = %d, hedgeFlag = %d, price = %f, availables = %f', accountDisplayId(account), weights:at(i), stock, operationType, hedgeFlag, price, volume.m_dVolume))
                    if isInvalidDouble(volume.m_dVolume) or volume.m_dVolume <= 0 then
                        availables[i] = 0
                        availablesOdd[i] = 0
                    else
                        availables[i] = volume.m_dVolume
                        availablesOdd[i] = volume.m_dVolume
                    end
                end
            else
                printLogLevel(2, string.format('[Splitter] weightSplit 3 : account = %s, available = 0', accountDisplayId(account)))
                availables[i] = 0
                availablesOdd[i] = 0
            end
        end
    end

    local totalAvailable = 0
    for i = 0, accounts:size() - 1, 1 do
        totalAvailable = totalAvailable + availables[i]
    end

    if totalAvailable == 0 then
        setError(err, "总可下单量为0!" .. stringErr)
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end

    local splits = {}
    for i = 0, accounts:size() - 1, 1 do splits[i] = 0 end
    
    local id2Values = {}
    for i = 0, accounts:size() - 1, 1 do
        if PTP_WEIGHT == positionType then
            table.insert(id2Values, {id = i, value = weights:at(i)})
        else
            table.insert(id2Values, {id = i, value = availables[i]})
        end
    end
    table.sort(id2Values, function(a, b) return a.value > b.value end)
    local ids = Int64Vec()
    for k, v in ipairs(id2Values) do
        ids:push_back(v.id)
    end

    local roundVolume = totalVolume
    while roundVolume > 0 do
        local leftVolume = roundVolume

        local totalWeight = 0
        for i = 0, accounts:size() - 1, 1 do
            if (availables[i] > 0 or not bAvailable) then totalWeight = totalWeight + weights:at(i) end
        end
        if totalWeight == 0 then break end

        local total = 0
        for i = 0, accounts:size() - 1, 1 do
            --accounts是按插入顺序，而不是权重顺序，所以用排序后的分配
            local id = ids:at(i)
            local num = 0
            if isDirectCashRepay then
                num = weights:at(id) * roundVolume / totalWeight
            elseif isMoneyFundBuy then
                num = max(math.floor(weights:at(id) * roundVolume / totalWeight), 100000)
            else
                num = max(math.floor(weights:at(id) * roundVolume / totalWeight), 1)
            end

            if bAvailable then
                num = min(availables[id], min(num, leftVolume))
            else
                num = min(num, leftVolume)
            end

            total = total + num

            splits[id] = splits[id] + num
            availables[id] = availables[id] - num
            leftVolume = leftVolume - num
        
            if leftVolume == 0 then break end
        end
        
        if leftVolume == roundVolume then break end
            
        roundVolume = leftVolume
    end

    local strLog = '[Splitter] raw result : [total = ' .. tostring(totalVolume) .. '] ['
    for i = 0, accounts:size() - 1, 1 do
        local account = accounts:at(i)
        local ret = splits[i]
        strLog = strLog .. accountDisplayId(account) .. " = " .. tostring(ret) .. ", "
    end
    strLog = strLog .. ']'
    printLogLevel(2, strLog)
    
    if (isStock(market) or isHGTMarket(market) or isSGTMarket(market) or isHKMarket(market)) and (not isDirectCashRepay) then
        local interval
        if isDirectSecuRepay or isSellCashRepay or OPT_OPTION_SECU_LOCK == operationType or OPT_OPTION_SECU_UNLOCK == operationType then
            interval = 1
        elseif isMoneyFund then
            interval = 1
        elseif isETFMoneyFund then
            interval = dataCenter:getETFReportUnit(market, stock)
        else
            interval = getTradeMinUnit(market, stock, operationType)
        end

        local leftVolume = 0
        for i = 0, accounts:size() - 1, 1 do
            if operationType == OPT_BUY or availables[i] > 0 or not bAvailable then
                if isMoneyFundBuy and 100000 > splits[i] then
                    local volume = splits[i]
                    splits[i] = splits[i] - volume
                    availables[i] = availables[i] + volume
                    leftVolume = leftVolume + volume
                elseif isKCB then
                     if splits[i] < interval and (operationType == OPT_BUY or availables[i] ~= 0) then
                       volume = splits[i]
                       splits[i] = splits[i] - volume
                       availables[i] = availables[i] + volume
                       leftVolume = leftVolume + volume
                     end
                else
                    local volume = splits[i] % interval
                    splits[i] = splits[i] - volume
                    availables[i] = availables[i] + volume
                    leftVolume = leftVolume + volume
                end
            end
        end

        if leftVolume > 0 then
            for i = 0, accounts:size() - 1, 1 do

                if leftVolume == 0 then break end

                local id = ids:at(i)
                if availables[id] > 0 or not bAvailable then
                    local volume
                    if bAvailable then
                        volume = min(availables[id], leftVolume)
                    else
                        volume = leftVolume
                    end
                    if operationType == OPT_BUY then
                        if not isKCB then
                            volume = math.floor(volume / interval) * interval
                        end
                        if isMoneyFundBuy then
                            if volume > 100000 or splits[id] > 100000 then
                                splits[id] = splits[id] + volume
                                availables[id] = availables[id] - volume
                                leftVolume = leftVolume - volume
                            end
                        else
                            if volume > 0 then
                                splits[id] = splits[id] + volume
                                availables[id] = availables[id] - volume
                                leftVolume = leftVolume - volume
                            else
                                break
                            end
                        end
                    else
                        if not isHGTMarket(market) and not isSGTMarket(market) and not isHKMarket(market) and volume < availables[id] or not bAvailable then
                            if not isKCB then
                                volume = math.floor(volume / interval) * interval
                                if volume > 0 then
                                    splits[id] = splits[id] + volume
                                    availables[id] = availables[id] - volume
                                    leftVolume = leftVolume - volume
                                end
                            end
                        else
                            splits[id] = splits[id] + volume
                            availables[id] = availables[id] - volume
                            leftVolume = leftVolume - volume
                        end
                    end
                end
            end
        end
        
        local oddVolume = totalVolume % interval
        if(isStock(market)) and not isKCB and (operationType == OPT_SELL or operationType == OPT_AFTER_FIX_SELL) then
            local id2Values = {}
            for i = 0, accounts:size() - 1, 1 do
                local avavolume = availablesOdd[i] % interval
                local splvolume = splits[i] % interval
                oddVolume = oddVolume - splvolume
                id2Values[i] = avavolume - splvolume
            end

            table.sort(id2Values, function(a, b) return a > b end)
            for k, v in pairs(id2Values) do
                if  oddVolume < v then
                    id2Values[k] = 0
                else
                    oddVolume = oddVolume - v
                end
            end
            for i = 0, accounts:size() - 1, 1 do
                splits[i] = splits[i] + id2Values[i]
            end
        end  
    end

    strLog = '[Splitter] final result : [total = ' .. tostring(totalVolume) .. '] ['
    for i = 0, accounts:size() - 1, 1 do
        local account = accounts:at(i)
        local ret = splits[i]
        strLog = strLog .. accountDisplayId(account) .. " = " .. tostring(ret) .. ", "
    end
    strLog = strLog .. ']'
    printLogLevel(2, strLog)

    local ret = isDirectCashRepay and DoubleVec() or Int64Vec()
    for i = 0, accounts:size() - 1, 1 do
        ret:push_back(splits[i])
    end
    
    if ret:size() == 0 then
        setError(err, "所有账号分单结果均为0!" .. stringErr)
    end

    return ret
end

local function getMoneyWeights(accounts, market, stock, operationType, hedgeFlag)
    -- 买进按可用资金，卖出按可用余额
    local weights = Int64Vec()
    local dataCenter = g_traderCenter:getDataCenter()
    for i = 0, accounts:size() - 1, 1 do        
        local account = accounts:at(i)        
        local weight, isMoney = getMoneyOrPosition(account, market, stock, operationType, hedgeFlag)
        if isInvalidDouble(weight) then weight = 0 end
        if weight == nil then weight = 0 end        
        weights:push_back(weight)
    end
    return weights
end

-- 分单逻辑
-- [in]total: 总量
-- [in]price: 价格
-- [in]accounts: 账号组
-- [in]weights: 权重
-- [in]positionType: 分仓类型
-- [out]splitted 分单之后的量
-- [in]avaiableByTsAccounts: 可用量通过TS获取的帐号组
-- [in]avaiables: 上述账号组对应的可用量
-- [in]vSecuAccount: 上述账号组对应的股东号
function split(sTcLuaParameter)
    
    local total = sTcLuaParameter.m_nTotal
    local price = sTcLuaParameter.m_dPrice
    local accounts = sTcLuaParameter.m_vAccounts
    local weights = sTcLuaParameter.m_vWeights
    local positionType = sTcLuaParameter.m_ePositionType
    local market = sTcLuaParameter.m_strMarket
    local stock = sTcLuaParameter.m_strStock
    local operationType = sTcLuaParameter.m_eOperationType
    local hedgeFlag = sTcLuaParameter.m_eHedgeFlag
    local err = sTcLuaParameter.m_pError
    local bAvailable = sTcLuaParameter.m_bAvailable
    local availableByTsAccounts = sTcLuaParameter.m_availableByTsAccounts
    local availableVolumes = sTcLuaParameter.m_availables
    local vSecuAccount = sTcLuaParameter.m_vSecuAccount
    
    local isDirectCashRepay = (OPT_DIRECT_CASH_REPAY == operationType or OPT_DIRECT_CASH_REPAY_SPECIAL == operationType or OPT_INTEREST_FEE == operationType)
    local isDirectSecuRepay = (OPT_DIRECT_SECU_REPAY == operationType) or (OPT_DIRECT_SECU_REPAY_SPECIAL == operationType)
    local isSellCashRepay = (OPT_SELL_CASH_REPAY == operationType) or (OPT_SELL_CASH_REPAY_SPECIAL == operationType)
    local isMoneyFund = (OPT_FUND_PRICE_BUY == operationType) or (OPT_FUND_PRICE_SELL == operationType)
    local isETFMoneyFund = (OPT_ETF_PURCHASE == operationType) or (OPT_ETF_REDEMPTION == operationType)

    if isDirectCashRepay then
        total = sTcLuaParameter.m_nTotalMoney 
    end
    
    if (not isDirectCashRepay and isInvalidInt(total)) or total <= 0 then
        setError(err, "分单总量" .. total .. "非法!")
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end

    --if isInvalidDouble(price) or price < 0 then
    --    setError(err, "最新价格非法!")
    --    return Int64Vec()
    --end

    if accounts:size() == 0 then
        setError(err, "账号数目为0!")
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end

    if weights:size() == 0 then
        setError(err, "权重数目为0!")
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end

    if accounts:size() ~= weights:size() then
        setError(err, "账号数目" .. accounts:size() .. "和权重数目" .. weights:size() .. "不匹配!")
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end

    if accounts:size() == 1 then
        local isKCB = isKCBCode(market, stock) 
        local ret = isDirectCashRepay and DoubleVec() or Int64Vec()
        if (isStock(market) or isHGTMarket(market) or isSGTMarket(market) or isHKMarket(market)) and (not isDirectCashRepay) then
            local interval
            if isDirectSecuRepay or OPT_OPTION_SECU_LOCK == operationType or OPT_OPTION_SECU_UNLOCK == operationType then
                interval = 1
            elseif isMoneyFund then
                interval = 1
            elseif isETFMoneyFund then
                interval = dataCenter:getETFReportUnit(market, stock)
            else
                interval = getTradeMinUnit(market, stock, operationType)
            end

            if (operationType == OPT_SELL or operationType == OPT_AFTER_FIX_SELL or isSellCashRepay) then
                local dataCenter = g_traderCenter:getDataCenter()
                local account = accounts:at(0)
                if account == CAccountInfo_NULL then
                    total = 0
                    printLogLevel(2, string.format('[Splitter] : account = NULL, available = 0'))
                else
                    local key = account:getKey()
                    local accountData = dataCenter:getAccount(key)
                    if accountData == CAccountData_NULL then
                        total = 0
                        printLogLevel(2, string.format('[Splitter] : accountData = NULL, available = 0'))
                    else
                        local volume = accountData:getCanOrderVolumeWithReason(market, stock, operationType, hedgeFlag, price, vSecuAccount:at(0))
                        local accountinfo = accountData:getAccountInfo()
                        if volume.m_dVolume == total or accountinfo.m_nBrokerType == AT_CREDIT then
                            total = total
                        else
                            if( not isKCB) then
                                totalremainder = total % interval
                                if(totalremainder == 0) then --本次报单为最小下单量整数倍直接报
                                    total = total
                                else
                                    surplus = volume.m_dVolume - total
                                    remainder = surplus % interval
                                    if(remainder == 0) then--报单剩余量不会产生零股，可以直接卖出本次的量
                                        total = total
                                    else
                                        total = math.floor(total / interval) * interval
                                    end
                                end
                            else
                                if total < interval then
                                    total = 0
                                else
                                    total = total;
                                end
                            end
                        end
                    end
                end
            else
                if(not isKCB) then
                    total = math.floor(total / interval) * interval
                else
                    if(total < interval) then
                        total = 0
                    else
                        total = total;
                    end
                end
            end
        end
        ret:push_back(total)
        return ret
    end

    if PTP_AVERAGE == positionType then
        local newWeights = Int64Vec()
        for i = 0, accounts:size() - 1, 1 do newWeights:push_back(1) end
        return weightSplit(total, price, accounts, newWeights, market, stock, operationType, hedgeFlag, err, positionType, availableByTsAccounts, availableVolumes, bAvailable, vSecuAccount)
    elseif PTP_WEIGHT == positionType then
        return weightSplit(total, price, accounts, weights, market, stock, operationType, hedgeFlag, err, positionType, availableByTsAccounts, availableVolumes, bAvailable , vSecuAccount)
    elseif PTP_MONEY == positionType then
        if (operationType < OPT_OPTION_BUY_OPEN or OPT_N3B_LIMIT_PRICE_SELL < operationType) and 
        operationType ~= OPT_PLEDGE_IN and operationType ~= OPT_PLEDGE_OUT and
        OPT_NEEQ_O3B_LIMIT_PRICE_BUY ~= operationType and OPT_NEEQ_O3B_LIMIT_PRICE_SELL ~= operationType then
            weights = getMoneyWeights(accounts, market, stock, operationType, hedgeFlag)
        end
        local totalWeight = 0
        for i = 0, weights:size() - 1, 1 do
            local weight = weights:at(i)
            totalWeight = totalWeight + weight
        end
        if totalWeight <= 0.00 then
            setError(err, "总可用资金为0!")
            local isDirectCashRepay = (OPT_DIRECT_CASH_REPAY == operationType or OPT_DIRECT_CASH_REPAY_SPECIAL == operationType or OPT_INTEREST_FEE == operationType)
            return isDirectCashRepay and DoubleVec() or Int64Vec()
        else
            return weightSplit(total, price, accounts, weights, market, stock, operationType, hedgeFlag, err, positionType, availableByTsAccounts, availableVolumes, bAvailable, vSecuAccount)
        end
    else
        setError(err, "分单方式" .. positionType .. "非法!")
        return isDirectCashRepay and DoubleVec() or Int64Vec()
    end
end

