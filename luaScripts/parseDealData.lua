local TYPE_INT = 1
local TYPE_STRING = 2
local TYPE_BOOL = 3
local TYPE_DOUBLE = 4
local TYPE_DATE = 5
local ISINVALIDDOUBLE = 1.7976931348623157e+308
local ISINVALIINT = 2147483647
local KEY_SPLITTER = "____"

local XT_CDealDetail = "544"
local XT_CPositionDetail = "545"
local XT_CPositionStatics = "547"
local XT_CFlowFund = "499"

local tableDeal = {"m_strInstrumentID", "m_nOffsetFlag", "m_dPrice", "m_nVolume", "m_dTradeAmount","m_strTradeDate", "m_strTradeTime", "m_strAccountID", "m_strExchangeName"}
local tablePost = {"m_strInstrumentID", "m_strInstrumentName", "m_nYesterdayVolume", "m_nCanUseVolume", "m_dOpenPrice", "m_dSettlementPrice", "m_dOpenCost", "m_dInstrumentValue", "m_nPosition", "m_strAccountID", "m_strExchangeName"}
local tableFlow = {"m_strDate", "m_nDirection", "m_dMoney",}

local dealDetailNameAndType = {
         m_accountInfo = {
                {"m_nBrokerType", TYPE_INT}, {"m_strAccountID", TYPE_STRING}
             },
         ownField = {
				{"m_strExchangeID", TYPE_STRING}, {"m_strExchangeName", TYPE_STRING}, {"m_strProductID", TYPE_STRING},
                {"m_strProductName", TYPE_STRING}, {"m_strInstrumentID", TYPE_STRING}, {"m_strInstrumentName", TYPE_STRING}, {"m_strTradeID", TYPE_STRING},
                {"m_strOrderRef", TYPE_STRING}, {"m_strOrderSysID", TYPE_STRING}, {"m_nDirection", TYPE_INT}, {"m_nOffsetFlag", TYPE_INT},
                {"m_nHedgeFlag", TYPE_INT}, {"m_dPrice", TYPE_DOUBLE}, {"m_nVolume", TYPE_INT}, {"m_strTradeDate", TYPE_STRING},
                {"m_strTradeTime", TYPE_STRING}, {"m_dComssion", TYPE_DOUBLE}, {"m_dTradeAmount", TYPE_DOUBLE}, {"m_nTaskId", TYPE_INT},
				{"m_nOrderPriceType", TYPE_INT}, {"m_strOptName", TYPE_STRING},
			},
         m_xtTag = {
                {"m_strUser", TYPE_STRING},
              },
}

local positionStaticsNameAndType = {
        m_accountInfo = {
            {"m_nBrokerType", TYPE_INT}, {"m_nPlatformID", TYPE_INT}, {"m_strApiType", TYPE_STRING}, {"m_strBrokerID", TYPE_STRING},
            {"m_strBrokerName", TYPE_STRING}, {"m_nAccountType", TYPE_INT}, {"m_strAccountID", TYPE_STRING}, {"m_strPassword", TYPE_STRING},
            {"m_strAccountName", TYPE_STRING}, {"m_strSubAccount", TYPE_STRING}, {"m_strBankNo", TYPE_STRING}, {"m_strSHAccount", TYPE_STRING},
            {"m_strSZAccount", TYPE_STRING}, {"m_iStatus", TYPE_INT},
        },
        ownField = {
            {"m_strExchangeID", TYPE_STRING}, {"m_strExchangeName", TYPE_STRING}, {"m_nYesterdayVolume", TYPE_INT}, {"m_dProfitRate", TYPE_DOUBLE},
            {"m_strProductID", TYPE_STRING}, {"m_strInstrumentID", TYPE_STRING}, {"m_strInstrumentName", TYPE_STRING},
            {"m_nHedgeFlag", TYPE_INT}, {"m_nDirection", TYPE_INT}, {"m_nPosition", TYPE_INT}, {"m_dOpenPrice", TYPE_DOUBLE},
            {"m_dOpenCost", TYPE_DOUBLE}, {"m_dSettlementPrice", TYPE_DOUBLE}, {"m_dFloatProfit", TYPE_DOUBLE}, {"m_dPositionCost", TYPE_DOUBLE},
            {"m_dPositionProfit", TYPE_DOUBLE}, {"m_dInstrumentValue", TYPE_DOUBLE}, {"m_bIsToday", TYPE_BOOL},
            {"m_strStockHolder", TYPE_STRING}, {"m_nFrozenVolume", TYPE_INT}, {"m_nCanUseVolume", TYPE_INT}, {"m_nOnRoadVolume", TYPE_INT},
        },
        m_xtTag = {
            {"m_strUser", TYPE_STRING}, {"m_eXtHedgeType", TYPE_INT}, {"m_nFundProductID", TYPE_INT}, {"m_strFundProductName", TYPE_STRING},
            {"m_nCommandID", TYPE_INT}, {"m_nGroupID", TYPE_INT}, {"m_eTraderType", TYPE_INT}, {"m_strDate", TYPE_STRING},
            {"m_strInterfaceId", TYPE_STRING}, {"m_strSource", TYPE_STRING}, {"m_strSessionTag", TYPE_STRING}, {"m_nRequestId", TYPE_INT},
            {"m_nProperty", TYPE_INT}, {"m_eOrderType", TYPE_INT},
        },
}

local flowFundNameAndType = {
        ownField = {
            {"m_strDate", TYPE_STRING}, {"m_nDirection", TYPE_INT}, {"m_dMoney", TYPE_DOUBLE},
        },
}

local function sixIntTimeToSeconds(year, month, day, hour, minute, second)
    month = month - 2
    if 0 >= month then
        month = month + 12
        year = year - 1
    end

    local a = math.modf(year / 4)
    local b = math.modf(year / 100)
    local c = math.modf(year / 400)
    local d = math.modf(367 * month / 12)
    return ((((a - b + c + d + day) + year * 365 - 719499) * 24 + hour - 8) * 60 + minute) * 60 + second
end

local function intTimeToSeconds(datetime)
    local _date = math.modf(datetime / 1000000)
    local _time = datetime % 1000000
    local year =  math.modf(_date / 10000)
    local month = math.modf(_date % 10000 / 100)
    local day = math.modf(_date % 100)
    local hour = math.modf(_time / 10000)
    local minute = math.modf(_time % 10000 / 100)
    local second = math.modf(_time % 100)
    return sixIntTimeToSeconds(year, month, day, hour, minute, second)
end

local function strTimeToSeconds( timeStr )
    local datetime = 0
    timeStr = string.gsub(timeStr, "-", "")
    timeStr = string.gsub(timeStr, " ", "");
    timeStr = string.gsub(timeStr, ":", "");
    datetime = tonumber(timeStr)

    return intTimeToSeconds(datetime)
end

local function getValueByType(value, t)
    if t == TYPE_STRING then
		if type(value) == type("") then
			return value
		else
			return "" .. value
		end
    elseif t == TYPE_DATE then
		return value
    elseif t == TYPE_BOOL then
        if value == "0" then
            return false
        end
        return true
    end
    if t == TYPE_INT or t == TYPE_DOUBLE then
        return tonumber(value)
    end
end

local function getIsinvalValue(type)
    if type == TYPE_INT then
        return ISINVALIINT
    end
    if type == TYPE_STRING then
        return ""
    end
    if type == TYPE_BOOL then
        return 1
    end
    if type == TYPE_DOUBLE then
        return ISINVALIDDOUBLE
    end
    if type == TYPE_DATE then
        return "20500101"
    end
end

function trim(s)
    return s:gsub("%s+", "") .. ""
end

local function table2json(t)
    local tab = "    "
    local function serialize(indent, tbl)
        local tmp = {}
        local tempIndent = indent .. tab
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            local key = (k_type == "string" and "\"" .. k .. "\" : ")
                or (k_type == "number" and "")
            local value = (v_type == "table" and serialize(indent .. tab, v))
                or (v_type == "boolean" and tostring(v))
                or (v_type == "string" and "\"" .. v .. "\"")
                or (v_type == "number" and v)
            if ((v_type ~= "table") or (table.maxn(v) ~= 0) or (trim(value) ~= "{}"))
                and ((v_type ~= "number") or ((v ~= getIsinvalValue(TYPE_DOUBLE)) and (v ~= getIsinvalValue(TYPE_INT)))) then
                tmp[#tmp + 1] = key and value and (tempIndent .. tostring(key) .. tostring(value) or nil)
            end
        end
        if table.maxn(tbl) == 0 then
            return "{\n" .. table.concat(tmp, ",\n") .. "\n" .. indent .. "}"
        else
            return "[\n" .. table.concat(tmp, ",\n") .. "\n" .. indent .. "]"
        end
    end
    assert(type(t) == "table")
    return serialize("", t)
end

function genKey(m_accountInfo, m_strExchangeID, m_strInstrumentID, m_nOpenDate, m_strEntrustNo)
	local strKey =  m_accountInfo.m_nBrokerType .. KEY_SPLITTER .. m_accountInfo.m_nPlatformID ..
			KEY_SPLITTER .. m_accountInfo.m_strBrokerID .. KEY_SPLITTER .. m_accountInfo.m_nAccountType ..
			KEY_SPLITTER .. m_accountInfo.m_strAccountID .. KEY_SPLITTER .. m_accountInfo.m_strSubAccount ..
			KEY_SPLITTER .. m_strExchangeID .. KEY_SPLITTER .. m_strInstrumentID .. KEY_SPLITTER ..
			m_nOpenDate .. KEY_SPLITTER .. m_strEntrustNo
	return strKey
end

function genAccountKey(m_accountInfo)
	local  strKey =  m_accountInfo.m_nBrokerType .. KEY_SPLITTER .. m_accountInfo.m_nPlatformID ..
			KEY_SPLITTER .. m_accountInfo.m_strBrokerID .. KEY_SPLITTER .. m_accountInfo.m_nAccountType ..
			KEY_SPLITTER .. m_accountInfo.m_strAccountID .. KEY_SPLITTER .. m_accountInfo.m_strSubAccount
	return strKey
end

local function getTableJson(nameAndType, row)
    local tableJson = {}
    --rowNum = 2
	tableJson = {}
    for k, v in pairs(nameAndType) do
        local tmpTable = {}
        for kk, vv in pairs(v) do
            if row[vv[1]] == nil then
                row[vv[1]] = getIsinvalValue(vv[2])
            end
            if k == "ownField" then
                tableJson[vv[1]] = getValueByType(row[vv[1]], vv[2])
            else
                tmpTable[vv[1]] = getValueByType(row[vv[1]], vv[2])
            end
        end
        if k ~= "ownField" then
            tableJson[k] = tmpTable
        end
    end
    return tableJson
end

local function getNOffsetFlag(strName)
    if strName == "Âô³ö" then
        return 49
    elseif strName == "ÂòÈë" then
        return 48
    elseif strName == "ÈÚÈ¯" then
        return 49
    end
    return 48
end

local function getLit(strG, tableLit, nType)
	local res = string.gmatch(strG, "([^,]+),")
	local idx = 1
	local dit = {}
    for k, v in res do
		dit[tableLit[idx]] = k
		idx = idx + 1
	end
	if dit["m_strExchangeName"] ~= nil then
	    if string.find(dit["m_strExchangeName"], "ÉîÛÚ") ~= nil then
		    dit["m_strExchangeID"] = "SZ"
	    else
		    dit["m_strExchangeID"] = "SH"
	    end
    end
	if dit["m_nOffsetFlag"] ~= nil then
	    dit["m_nOffsetFlag"] = getNOffsetFlag(dit["m_nOffsetFlag"])
	end
	if dit["m_strTradeTime"] ~= nil then
	    dit["m_strTradeTime"] = strTimeToSeconds(dit["m_strTradeDate"] .. dit["m_strTradeTime"])
	end
	if dit["m_strTradeDate"] ~= nil then
	    dit["m_strTradeDate"] = string.gsub(dit["m_strTradeDate"], "-", "")
	end

	return dit
end

function getStrJson(fileDir, nType)
	local file = io.open(fileDir, "r")
	local flag = false
	local retJson = {}
	local index = 1
	for line in file:lines() do
		if flag then
		    local tableJson
			if nType == XT_CDealDetail then
			    local row = getLit(line, tableDeal, nType)
			    tableJson = getTableJson(dealDetailNameAndType, row)
			elseif nType == XT_CPositionStatics then
			    local row = getLit(line, tablePost, nType)
			    tableJson = getTableJson(positionStaticsNameAndType, row)
			elseif nType == XT_CFlowFund then
			    local row = getLit(line, tableFlow, nType)
			    tableJson = getTableJson(flowFundNameAndType, row)
			end
			tableJson["_typeId"] = tonumber(nType)
			retJson[index] = tableJson
			index = index + 1
		end
		flag = true
	end
	return table2json({content=retJson})
end

--[[
ret = getStrJson("D:\\LUA\\flowFund.in", "499")
print (ret)
n = io.read()
]]--