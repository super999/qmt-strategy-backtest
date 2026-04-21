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


function getAlgorithmsGuosenParams()
    return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsGuosenParams";
end

g_algorithms = {
    m_strAlgName="条件单",
    m_params={
        {m_nId=40,m_strName="报价方式",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="即时卖五",m_strEnumName="市价,即时卖五,即时卖四,即时卖三,即时卖二,即时卖一,即时最新,即时买一,即时买二,即时买三,即时买四,即时买五,指定价,市价即成剩撤,市价即全成否则撤,市价剩转限价",m_strEnumValue="12,0,1,2,3,4,5,6,7,8,9,10,11,27,28,29",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=6061,m_strName="条件单类型",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="VWAP",m_strEnumName="反弹买入,回落卖出,止盈止损,多条件监控",m_strEnumValue="RALLY,FALLBACK,STOP,MULTI",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="" },
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
        {m_nId=7057,m_strName="还款合约编号",m_strType=14,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CompactID",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
    },
    m_customParams={
        {m_nId=6062,m_strName="激活价格",m_strType=4,m_strRange="0.0001-100000000.00",m_nFlag=0,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="ATP",m_strParamsVisible="反弹买入,回落卖出",m_strParamsUnit="" },
        {m_nId=6063,m_strName="反弹价差",m_strType=1001,m_strRange="0.0001~100000000",m_nFlag=0,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="RallySpread",m_strParamsVisible="反弹买入",m_strParamsUnit="元,%" },
        {m_nId=6064,m_strName="回落价差",m_strType=1001,m_strRange="0.0001~100000000",m_nFlag=0,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="FallbackSpread",m_strParamsVisible="回落卖出",m_strParamsUnit="元,%" },
        {m_nId=6065,m_strName="止盈价格",m_strType=4,m_strRange="0.0001-100000000.00",m_nFlag=0,m_strDefault="100000000.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="StopProfitPrice",m_strParamsVisible="止盈止损",m_strParamsUnit="" },
        {m_nId=6066,m_strName="止损价格",m_strType=4,m_strRange="0.0001-100000000.00",m_nFlag=0,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="StopLossPrice",m_strParamsVisible="止盈止损",m_strParamsUnit="" },
        {m_nId=6067,m_strName="监控代码1",m_strType=1003,m_strRange="",m_nFlag=1,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="TriggerCode1",m_strParamsVisible="多条件监控",m_strParamsUnit="" },
        {m_nId=6068,m_strName="最新价1",m_strType=1002,m_strRange="0.00-100000000.00",m_nFlag=1,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="TriggerPrice1",m_strParamsVisible="多条件监控",m_strParamsUnit="" },
        {m_nId=6069,m_strName="日涨幅1",m_strType=1002,m_strRange="-100000000.00~100000000.00",m_nFlag=1,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="TriggerIncrease1",m_strParamsVisible="多条件监控",m_strParamsUnit="%" },
        {m_nId=6070,m_strName="监控代码2",m_strType=1003,m_strRange="",m_nFlag=1,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="TriggerCode2",m_strParamsVisible="多条件监控",m_strParamsUnit="" },
        {m_nId=6071,m_strName="最新价2",m_strType=1002,m_strRange="0.00-100000000.00",m_nFlag=1,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="TriggerPrice2",m_strParamsVisible="多条件监控",m_strParamsUnit="" },
        {m_nId=6072,m_strName="日涨幅2",m_strType=1002,m_strRange="-100000000.00~100000000.00",m_nFlag=1,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="TriggerIncrease2",m_strParamsVisible="多条件监控",m_strParamsUnit="%" },
        {m_nId=6073,m_strName="监控截至",m_strType=1000,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="TimeEnd",m_strParamsVisible="反弹买入,回落卖出,止盈止损,多条件监控",m_strParamsUnit="" },
        {m_nId=6074,m_strName="保护限价",m_strType=1001,m_strRange="0.00-100000000.00",m_nFlag=0,m_strDefault="0.01",m_strEnumName="",m_strEnumValue="",m_strNameKey="PriceLimit",m_strParamsVisible="反弹买入,回落卖出,止盈止损,多条件监控",m_strParamsUnit="元" },
    },
    m_strAuthority="mdl_alg_guosen1",
}