dofile('../luaScripts/risk/RCUtils.lua')
dofile('../luaScripts/risk/luaCategoryForCaihui.lua')
dofile('../luaScripts/risk/luaCategoryForJuyuan.lua')
dofile('../luaScripts/risk/luaCategoryForWind.lua')
dofile('../luaScripts/risk/luaCategoryForCustom.lua')
JSON = (loadfile("../config/JSON.lua"))()

customStockList = nil
caihuiStockList = nil   --存储了财汇categoryID->stockList的全局表
juyuanStockList = nil   --存储了聚源categoryID->stockList的全局表
windStockList = nil     --存储了万得categoryID->stockList的全局表
windCodeData = nil      --存储了万得stockCode-> remainYear modifiedduration的对应关系
windIssueData = nil     --存储了万得stockCode-> issueId issueName的对应关系
windPurchaseStartDate = nil --存储了万得stockCode stocaMarket ->purchaseStartDate的对应关系
juyuanIssueData = nil   --存储了聚源stockCode-> issueId issueName的对应关系
juyuanIssuerId2Name = nil --存储了聚源issueId-> issueName的对应关系
result = {}
g_mysql_conf = nil


local function printCategoryTable(categoryTable)
    for k1, v1 in pairs(categoryTable) do
        print("categoryID: "..k1)
        for k2, v2 in pairs(v1) do
            print("stockCode: " .. k2)
        end
    end
end

local function getCon(mysql_conf)
    local res = string.gmatch(mysql_conf, "([^,]+),")
    local ip = res()
    local port = tonumber(res())
    local db = res()
    local user = res()
    local passwd = res()
    local driver = require "luasql.mysql"
    local env = driver.mysql()
    local con = env:connect(db, user, passwd, ip, port)
    return con
end

local function queryCategoryTable(mysql_conf, isSys)
    local categoryTable = {}
    local codeTable = {}
    local stockCode
    local stockMarket
    local stockCategory_id
    local con = getCon(mysql_conf)
    if nil == con then
        return categoryTable
    end

    local strQuery = string.format("select stockMarket, stockCode, stockCategory_id from account_stockcategoryitem where is_sys = %s;", tostring(isSys))
    con:execute[[set names utf8]]
    local cur = con:execute(strQuery)
    local rowNum = cur:numrows()
    if rowNum <= 0 then
        con:close()
        return categoryTable
    end
    for i = 1, rowNum, 1 do
        local row = cur:fetch({}, "n")
        stockMarket = row[1]
        stockCode = row[2]
        stockCategory_id = tonumber(row[3])
        if stockCategory_id and not categoryTable[stockCategory_id] then
            categoryTable[stockCategory_id] = {}
        end
        categoryTable[stockCategory_id][stockMarket .. stockCode] = 1
    end
    con:close()
    return categoryTable
end

function initCategoryTable(mysql_conf, isSys)
    if 0 == isSys then
        customStockList = queryCategoryTable(mysql_conf, 0)
    elseif 2 == isSys then
        caihuiStockList = queryCategoryTable(mysql_conf, 2) --isSys=2-->财汇stocklist
    elseif 3 == isSys then
        juyuanStockList = queryCategoryTable(mysql_conf, 3) --isSys=3-->聚源stocklist
    elseif 12 == isSys then
        windStockList = queryCategoryTable(mysql_conf, 12) --isSys=12-->万得stocklist
    end
end

function initLuaCategory(mysql_conf)
    g_mysql_conf = mysql_conf
    local t1 = getLuaCategoryForCaihui()   --获取为财会数据定义的Category ID列表
    local t2 = getLuaCategoryForJuyuan()   --获取为聚源数据定义的category ID列表
    local t3 = getLuaCategoryForCustom()   --获取用户在lua中自定义的category ID列表
    local t4 = getLuaCategoryForWind()   --获取用户在lua中自定义的category ID列表
    for i, v in ipairs(t1) do
        table.insert(result, v)
    end
    for i, v in ipairs(t2) do
        table.insert(result, v)
    end
    for i, v in ipairs(t3) do
        table.insert(result, v)
    end
    for i, v in ipairs(t4) do
        table.insert(result, v)
    end

    initCategoryTable(mysql_conf, 0)
    initCategoryTable(mysql_conf, 2)  --isSys=2-->财汇stocklist
    initCategoryTable(mysql_conf, 3)  --isSys=3-->聚源stocklist
    initCategoryTable(mysql_conf, 12)  --isSys=12-->万得stocklist
    --rcprintLog(string.format("initLuaCategory:windCodeData1"))
    windCodeData = initCodeData(mysql_conf, 12)
    windIssueData = initIssueData_wind(mysql_conf, 12)
    windPurchaseStartDate = initPurchaseStartDate(mysql_conf, 12)
    juyuanIssueData = initIssueDataJuyuan(mysql_conf, 3)   --isSys=3-->聚源
    juyuanIssuerId2Name = juyuanIssueData["juyuan_issueId2Name"]
    --rcprintLog(string.format("initLuaCategory:windCodeData2"))
    --rcprintLog(string.format("initLuaCategory:windCodeData=%s",table2jsonOld(windCodeData)))
    --printCategoryTable(caihuiStockList)
end

function getLuaCategory()
    return table2json({content = result})
end

local function isNewStockWithinTenDays(market, code, dayNum)
    local instrumentData --= rcGetInstrument(market, code)
    if instrumentData then
        local dayCountFromIPO = instrumentData.DayCountFromIPO
        --rcprintDebugLog(string.format("isNewStockWithinTendays: dayCountFromIPO = %s, dayNum = %s", tostring(dayCountFromIPO), tostring(dayNum)))
        if dayCountFromIPO <= dayNum then
            -- rcprintDebugLog(string.format("isNewStockWithTendays: maket = %s, code = %s is new stock within ten days. return true.", tostring(market), tostring(code)))
            return true
        else
            --rcprintDebugLog(string.format("isNewStockWithTendays: market = %s, code = %s is not new stock with ten days. return false.", tostring(market), tostring(code)))
            return false
        end
    else
        -- rcprintDebugLog("isNewStockWithTendays: Fail to get intrumentData!")
    end

    return false
end

function isInCategoryTable(market, code, categoryID, stockList)
    return (nil ~= categoryID)
        and (nil ~= stockList)
        and (nil ~= stockList[categoryID])
        and (1 == stockList[categoryID][market .. code])
end

--根据证券代码获得剩余期限
function getBondRemainYear(market, code)
    local ret = 'null'
    if market ~= nil and code ~= nil then
        local key = market .. code
        if windCodeData[key] ~= nil and windCodeData[key]["remainYear"] ~= nil then
            ret = windCodeData[key]["remainYear"]
        end
    end
    return ret
end

--根据证券代码获得收盘价修正久期
function getBondModifiedduration(market, code)
    local ret = 'null'
    if market ~= nil and code ~= nil then
        local key = market .. code
        if windCodeData[key] ~= nil and windCodeData[key]["modifiedduration"] ~= nil then
            ret = windCodeData[key]["modifiedduration"]
        end
    end
    return ret
end
    
--根据证券代码获取发行方Id
function getIssueId(market, code)
    local ret = 'null'
    if market ~= nil and code ~= nil then
        local key = market .. code
        if caihuiIssueData ~= nil and next(caihuiIssueData) ~= nil and caihuiIssueData[key] ~= nil and caihuiIssueData[key]["issueID"] ~= nil then
            ret = caihuiIssueData[key]["issueID"]
            return ret
        end
        if windIssueData ~= nil and next(windIssueData) ~= nil and windIssueData[key] ~= nil and windIssueData[key]["issueName"] ~= nil then
            ret = windIssueData[key]["issueID"] 
            return ret
        end
        if juyuanIssueData ~= nil and next(juyuanIssueData) ~= nil and juyuanIssueData[key] ~= nil and juyuanIssueData[key]["issueName"] ~= nil then
            ret = juyuanIssueData[key]["issueID"] 
            return ret
        end
    end
    return ret
end

--根据证券代码获取发行方名称
function getIssueName(market, code)
    local ret = 'null'
    if market ~= nil and code ~= nil then
        local key = market .. code
        if caihuiIssueData ~= nil and next(caihuiIssueData) ~= nil and caihuiIssueData[key] ~= nil and caihuiIssueData[key]["issueName"] ~= nil then
            ret = caihuiIssueData[key]["issueName"]
            return ret
        end
        if windIssueData ~= nil and next(windIssueData) ~= nil and windIssueData[key] ~= nil and windIssueData[key]["issueName"] ~= nil then
            ret = windIssueData[key]["issueName"]
            return ret
        end
        if juyuanIssueData ~= nil and next(juyuanIssueData) ~= nil and juyuanIssueData[key] ~= nil and juyuanIssueData[key]["issueName"] ~= nil then
            ret = juyuanIssueData[key]["issueName"]
            return ret
        end
    end
    return ret
end

--根据发行方ID获取发行方名称
function getIssueId2Name(Id)
    local ret = 'null'
    if Id ~= nil then
        if juyuanIssuerId2Name ~= nil and juyuanIssuerId2Name[Id] ~= nil then
            ret = juyuanIssuerId2Name[Id]
        elseif caihuiIssueData ~= nil and caihuiIssueName[Id] ~= nil then
            ret = caihuiIssueName[Id]
        end
    end
    return ret
end

--根据证券代码获取开放式基金的开放日
function getPurchaseStartDate(market, code)
    local ret = 'null'
    if market ~= nil and code ~= nil then
        local key = market .. code
        if windPurchaseStartDate ~= nil and windPurchaseStartDate[key] ~= nil and windPurchaseStartDate[key]["purchaseStartDate"] ~= nil then
            ret = windPurchaseStartDate[key]["purchaseStartDate"]
            return ret
        end
    return ret
    end
end
        

-- 判断某个合约是否在num天之后过期, 正常的ExpireDate符合"YYYYMMDD"格式
function isExpired(ExpireDate, num)
    if( not type(ExpireDate) == "string" or ExpireDate == "99999999" or not string.len(ExpireDate) == 8) then
        return false                   -- 未设置合约过期日期或日期不符合格式要求, 在时间范围这一项检查放行
    else
        local today = os.date("*t")
        local secondOfToday = os.time({day=today.day, month=today.month, year=today.year, hour=0, minute=0, second=0})
        local expireYear = tonumber(string.sub(ExpireDate, 1, 4))
        local expireMonth = tonumber(string.sub(ExpireDate, 5, 6))
        local expireDay = tonumber(string.sub(ExpireDate, 7, 8))
        local secondOfExpireDate = os.time({day=expireDay, month=expireMonth, year=expireYear, hour=0, minute=0, second=0})
        distanceFromExpireDate = secondOfExpireDate - secondOfToday
        secondOfSetDaynum = num*24*60*60
        if distanceFromExpireDate > secondOfSetDaynum then
            return false             -- 未过期，返回flase
        else 
            return true              -- 已过期，返回true
        end
    end
end

function isStockInLuaCategory(market, code, name, categoryID)
    local ret = false
    -- Lua里对于基础类型的判断主要还是依赖C++提供的接口，再进行一些逻辑运算和时间范围推算
    if (categoryID >= 10001 and categoryID <= 20000) then
        ret = isInCategoryTable(market, code, categoryID, customStockList)
    elseif (categoryID >= 20001 and categoryID <= 21000) or (categoryID >= 30001 and categoryID <= 32000) then   --财汇分类判断
        ret = isInCategoryTable(market, code, categoryID, caihuiStockList)
    elseif categoryID >= 21001 and categoryID <= 30000 then   --聚源分类判断
        ret = isInCategoryTable(market, code, categoryID, juyuanStockList)
    elseif categoryID >= 35000 and categoryID <= 38000 then   --万得分类判断
        ret = isInCategoryTable(market, code, categoryID, windStockList)	
    end
    --以后增加扩展categoryID的判断
    return ret
end

function isStockInCategory(market, code, name, categoryID)
    if ( categoryID >= 10001 and categoryID <= 40000 ) then
        return isStockInLuaCategory(market, code, name, categoryID)
    else
        return rcIsStockInCppCategory(market, code, name, categoryID)
    end
end

function getLuaCategoryIdsForJuyuanDb()
    return getLuaCategoryForJuyuan()
end

function getLuaCategoryInfoForJuyuanDb(id)
    return getLuaCategoryInfoForJuyuan(id)
end

function getLuaCategoryIdsForCaihuiDb()
    return getLuaCategoryForCaihui()
end

function getLuaCategoryInfoForCaihuiDb(id)
    return getLuaCategoryInfoForCaihui(id)
end

--function getLuaCategoryIdsForWindDb()
--    return getLuaCategoryForWind()
--end

--function getLuaCategoryInfoForWindDb(id)
--    return getLuaCategoryInfoForWind(id)
--end

function getLuaSysGroupTable()
    local categoryIds = getLuaCategoryIdsForJuyuanDb()
    local sysGroupTable = {}
    for i = 0, #(categoryIds) - 1, 1 do
        local categoryId = categoryIds[i+1]
        local sysTable = getLuaCategoryInfoForJuyuanDb(categoryId)
        table.insert(sysGroupTable, sysTable)
    end

    local categoryIds2 = getLuaCategoryIdsForCaihuiDb()
    for i = 0, #(categoryIds2) -1, 1 do
        local categoryId = categoryIds2[i+1]
        local sysTable = getLuaCategoryInfoForCaihuiDb(categoryId)
        table.insert(sysGroupTable, sysTable)
    end

    --local categoryIds3 = getLuaCategoryIdsForWindDb()
    --for i = 0, #(categoryIds3) -1, 1 do
    --    local categoryId = categoryIds3[i+1]
    --    local sysTable = getLuaCategoryInfoForWindDb(categoryId)
    --    table.insert(sysGroupTable, sysTable)
    --end
    return sysGroupTable
end

function queryHGTVersusStock(mysql_conf)
    return queryHGTVersusStock_wind(mysql_conf)
end
