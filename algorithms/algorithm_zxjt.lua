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

function getAlgorithmsParams2()
	return table2json({content = g_algorithms})
end

g_algorithms = {
	m_strAlgName="中信建投",
	m_params={
		{m_nId=40,m_strName="价格类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="市价,限价",m_strEnumValue="1,2" },
		{m_nId=126,m_strName="过期时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:30",m_strEnumName="",m_strEnumValue="" },
		{m_nId=6061,m_strName="策略名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="TWAP",m_strEnumName="TWAP,VWAP,VWAPPLUS",m_strEnumValue="TWAP,VWAP,VWAPPLUS" },
		{m_nId=6062,m_strName="有效时间",m_strType=3,m_strRange="",m_nFlag=0,m_strDefault="09:30:00-15:00:00",m_strEnumName="",m_strEnumValue="" },
		--{m_nId=6063,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="" },
		{m_nId=6075,m_strName="参与开盘竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="是,否",m_strEnumValue="Y,N" },
		{m_nId=6076,m_strName="参与收盘竟价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="是,否",m_strEnumValue="Y,N" },
	},
	m_fixedParams={
		{m_nId=11,m_strName="申报号",m_strType=0,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=15,m_strName="币种",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="CNY",m_strEnumName="",m_strEnumValue="" },
		{m_nId=38,m_strName="数量",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=44,m_strName="价格",m_strType=3,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=54,m_strName="委托方向",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=55,m_strName="股票代码",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=60,m_strName="发送时间（UTC时间）",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=77,m_strName="开平方向",m_strType=7,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=100,m_strName="市场类型",m_strType=8,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=526,m_strName="信息标识",m_strType=9,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
		{m_nId=7054,m_strName="信用委托方向",m_strType=10,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="" },
	},
	m_strAuthority="mdl_alg_zxjt1",
}