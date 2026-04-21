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

function getAlgorithmsHuachuangParams()
    return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsHuachuangParams";
end

g_algorithms = {
    m_strAlgName="华创算法",
    m_params={
        {m_nId=40,m_strName="价格类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=126,m_strName="过期时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="" ,m_strNameKey="endTime",m_strParamsVisible="",m_strParamsUnit=""},  
        {m_nId=6061,m_strName="策略名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="TWAP",m_strEnumName="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strEnumValue="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=23001,m_strName="算法参数",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="strategyParams",m_strParamsVisible="",m_strParamsUnit="" },
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
        {m_nId=7055,m_strName="账号标识",m_strType=12,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="AccountKey",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=7056,m_strName="下单操作",m_strType=13,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OperationType",m_strParamsVisible="",m_strParamsUnit="" },
    },
    m_customParams={
        {m_nId=6062,m_strName="有效时间",m_strType=3,m_strRange="",m_nFlag=0,m_strDefault="09:30:00-15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="6062",m_strParamsVisible="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strParamsUnit="" },
        {m_nId=6064,m_strName="最大市场占比",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="6064",m_strParamsVisible="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strParamsUnit="" },
        {m_nId=6298,m_strName="限价内占比",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="是",m_strEnumName="是,否",m_strEnumValue="Y,N",m_strNameKey="6298",m_strParamsVisible="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strParamsUnit="" },
        {m_nId=6065,m_strName="执行偏移量",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="中",m_strEnumName="低,中,高",m_strEnumValue="1,2,3",m_strNameKey="6065",m_strParamsVisible="POV",m_strParamsUnit="" },
        {m_nId=6067,m_strName="最小跟量比例",m_strType=4,m_strRange="0.00-0.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="6067",m_strParamsVisible="PriceInLine",m_strParamsUnit="" },
        {m_nId=6087,m_strName="参考价格",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="日内均价",m_strEnumName="日内均价,交易时段均价,最新价,开盘价,昨日收盘价",m_strEnumValue="1,2,3,4,5",m_strNameKey="6087",m_strParamsVisible="PriceInLine",m_strParamsUnit="" },
        {m_nId=6075,m_strName="参与开盘竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="是",m_strEnumName="是,否",m_strEnumValue="Y,N",m_strNameKey="6075",m_strParamsVisible="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strParamsUnit="" },
        {m_nId=6076,m_strName="参与收盘竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="是",m_strEnumName="是,否",m_strEnumValue="Y,N",m_strNameKey="6076",m_strParamsVisible="TWAP,VWAP,VWAPPLUS,STRICTTWAP,PriceInLine,POV",m_strParamsUnit="" },
    },
    m_strAuthority="mdl_alg_huachuang1",
}