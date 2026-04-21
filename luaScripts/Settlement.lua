dofile('../config/config.lua')

local function trim(s)
    return s:gsub("%s+", "") .. ""
end

local function getCon(mysql_conf)
    res = string.gmatch(mysql_conf, "([^,]+),")
    ip = res()
    port = tonumber(res())
    db = res()
    user = res()
    passwd = res()
    local driver = require "luasql.mysql"
    local env = driver.mysql()
    local con = env:connect(db, user, passwd, ip, port)
    return con
end

KEY_SPLITTER = "____"
local function genAccountKey(m_nPlatformID, m_strBrokerID, m_strSubAccount, m_nBrokerType, m_nAccountType, m_strAccountID)
    return m_nBrokerType .. KEY_SPLITTER ..
        m_nPlatformID .. KEY_SPLITTER ..
        m_strBrokerID .. KEY_SPLITTER ..
        m_nAccountType .. KEY_SPLITTER ..
        m_strAccountID .. KEY_SPLITTER ..
        m_strSubAccount
end

local function genQuerySettlementSql(m_nPlatformID, m_strBrokerID, m_strSubAccount, m_nBrokerType, m_nAccountType, m_strAccountID, m_startDate, m_endDate)    
    local sql = 'select m_dEBalance, m_dIOGold, m_strDate from idata_cstatement where '
        .. 'm_priKey_tag = "' .. genAccountKey(m_nPlatformID, m_strBrokerID, m_strSubAccount, m_nBrokerType, m_nAccountType, m_strAccountID) 
        .. '" and m_strDate >= "' .. m_startDate .. '" and m_strDate<= "' .. m_endDate .. '";'
    return sql
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
            if (v_type ~= "table") or (table.maxn(v) ~= 0) or (trim(value) ~= "{}") then
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

function querySettlement(m_nPlatformID, m_strBrokerID, m_strSubAccount, m_nBrokerType, m_nAccountType, m_strAccountID, m_startDate, m_endDate, mysql_conf)
    local strQuery = genQuerySettlementSql(m_nPlatformID, m_strBrokerID, m_strSubAccount, m_nBrokerType, m_nAccountType, m_strAccountID, m_startDate, m_endDate)
    print(strQuery)
    local con = getCon(mysql_conf)
    con:execute[[set names utf8]]
    local cur = con:execute(strQuery)
    if cur == nil then return "" end
    
    local rowNum = cur:numrows()

    if rowNum <= 0 then
        return ""
    end

    tblSettlement = {}
    for i = 1, rowNum, 1 do
        local row = cur:fetch({}, "a")
        tblSettlement[i] = {}
        tblSettlement[i]["m_tradingDate"] = row["m_strDate"]
        tblSettlement[i]["m_dBalance"] = tonumber(row["m_dEBalance"])
        tblSettlement[i]["m_dDeposit"] = tonumber(row["m_dIOGold"])
        tblSettlement[i]["m_dWithdraw"] = 0.0
    end

    return table2json({settlement = tblSettlement})
end

local function extract(settlement, tag)
    local reg = tag
    local i, j = string.find(settlement, reg)
    reg = "%s*([-]?%d*%.%d*)"
    str = string.sub(settlement,  string.find(settlement, reg, j))
    return "" .. tonumber(str)
end

function getClientBalance(settlement)
    local reg = "客户权益："
    return extract(settlement, reg)
end

function getDepositWithraw(settlement)
    local reg = "出 入 金："
    return extract(settlement, reg)
end

function test()
    r = querySettlement(21001, 1026, "00000005_01", 1, -1, "00000005", "20130826", "20130926", g_mysql_config)
    print("result" .. r)
end

function testExtract()
    local str = [[
----------------------------------------------------------------------------------------------------
期初结存：          10026109.33    交割手续费：               0.00    交割保证金：              0.00
出 入 金：         -10026109.33    期末结存：                 0.00    可用资金：                0.00
平仓盈亏：                 0.00    质 押 金：                 0.00    风 险 度：               0.00%
持仓盯市盈亏：             0.00    客户权益：                 0.00    应追加资金：              0.00
手 续 费：                 0.00    保证金占用：               0.00    基础保证金：              0.00
质押变化金额：             0.00

                                        出入金明细
--------------------------------------------------------------------
    ]]
    print(extract(str, "客户权益："))
    print(extract(str, "出 入 金："))
end

--testExtract()
--test()
