function table2json(t)
    local function serialize(tbl)
        local tmp = {}
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            local key = (k_type == "string" and "\"" .. k .. "\":")
                or (k_type == "number" and "")
            local value = (v_type == "table" and serialize(v))
                or (v_type == "boolean" and tostring(v))
                or (v_type == "string" and "\"" .. v .. "\"")
                or (v_type == "number" and v)
            tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
        end
        if table.maxn(tbl) == 0 then
            return "{" .. table.concat(tmp, ",") .. "}"
        else
            return "[" .. table.concat(tmp, ",") .. "]"
        end
    end
    assert(type(t) == "table")
    return serialize(t)
end

function getAlgorithmsJazzParams()
	return table2json({content = g_algorithms})
end

g_algorithms = {
	m_strAlgName="睿金算法",
	m_params={
		{m_nId=40,m_strName= "订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=5000,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="TWAP",m_strEnumName="TWAP,VWAP,VWAPPLUS",m_strEnumValue="TWAP,VWAP,VWAPPLUS",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=5001,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="9:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="StartTime",m_strParamsVisible="TWAP,VWAP,VWAPPLUS",m_strParamsUnit="" },
		{m_nId=5002,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="EndTime",m_strParamsVisible="TWAP,VWAP,VWAPPLUS",m_strParamsUnit="" },
		{m_nId=5003,m_strName="量比比例",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="30",m_strEnumName="",m_strEnumValue="",m_strNameKey="ParticipationRate",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=5004,m_strName="相对限价偏移基准",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="对方盘口,己方盘口,昨收价,最新价,到达价格",m_strEnumValue="0,1,2,3,4",m_strNameKey="RelativeLimitBase",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=5005,m_strName="相对限价偏移单位",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="最小买卖单位,基点",m_strEnumValue="0,1",m_strNameKey="RelativeLimitType",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=5006,m_strName="相对限价偏移值",m_strType=4,m_strRange="0-100",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="RelativeLimitOffset",m_strParamsVisible="",m_strParamsUnit="" },
	},
	
	m_fixedParams={
		{m_nId=11,m_strName="申报号",m_strType=0,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CIOrdID",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=15,m_strName="币种",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="CNY",m_strEnumName="",m_strEnumValue="",m_strNameKey="Currency",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=38,m_strName="目标量",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OrderQty",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=44,m_strName="限价",m_strType=3,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Price",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=54,m_strName="买卖方向",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Side",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=55,m_strName="证券代码",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Symbol",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=60,m_strName="发送时间（UTC时间）",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="TransactTime",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=77,m_strName="开平标志",m_strType=7,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OpenClose",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=100,m_strName="交易所",m_strType=8,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="ExDestination",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=526,m_strName="信息标识",m_strType=9,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="SecondaryCIOrdID",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=7054,m_strName="两融标志",m_strType=10,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="MarginTradeType",m_strParamsVisible="",m_strParamsUnit="" },
		{m_nId=1,m_strName="资金帐号",m_strType=11,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Account",m_strParamsVisible="",m_strParamsUnit="" },
	},
	m_strAuthority="mdl_alg_jazz1",
}