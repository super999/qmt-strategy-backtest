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

function getAlgorithmsCicc2Params()
	return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsCicc2Params";
end

--m_strType=1 下拉列表；4 数值；2 时间类型；
g_algorithms = {
    m_strAlgName="中金EQ",
    m_params={
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="VWAP_PLUS",m_strEnumName="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strEnumValue="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=23001,m_strName="算法参数",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="strategyParams",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
    }, 
    m_fixedParams={
        {m_nId=11,m_strName="申报号",m_strType=0,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CIOrdID",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=15,m_strName="币种",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="CNY",m_strEnumName="",m_strEnumValue="",m_strNameKey="Currency",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=38,m_strName="目标量",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OrderQty",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=44,m_strName="限价",m_strType=3,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Price",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=54,m_strName="买卖方向",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Side",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=55,m_strName="证券代码",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Symbol",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=60,m_strName="发送时间（UTC时间）",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="TransactTime",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=77,m_strName="开平标志",m_strType=7,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OpenClose",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=100,m_strName="交易所",m_strType=8,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="ExDestination",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=526,m_strName="信息标识",m_strType=9,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="SecondaryCIOrdID",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=7054,m_strName="两融标志",m_strType=10,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="MarginTradeType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=1,m_strName="资金帐号",m_strType=11,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Account",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=7055,m_strName="账号标识",m_strType=12,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="AccountKey",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=7056,m_strName="下单操作",m_strType=13,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OperationType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=7057,m_strName="还款合约编号",m_strType=14,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CompactID",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=152,m_strName="委托金额",m_strType=15,m_strRange="",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="CashOrderQty",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
    },
    m_customParams={
        {m_nId=9996,m_strName="时间类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="按区间",m_strEnumName="按区间,按执行时间",m_strEnumValue="0,1",m_strNameKey="m_nTimeType",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=9995,m_strName="执行时间",m_strType=4,m_strRange="0-1440",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nTimeValue",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="分",m_strParamsHidden="" },
        {m_nId=6002,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeStart",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6003,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeEnd",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6004,m_strName="量比比例",m_strType=4,m_strRange="0.01-50.00",m_nFlag=0,m_strDefault="30.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dLimitOverRate",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="%",m_strParamsHidden="0",m_strDefaultByAlgName="TWAP_PLUS:30.00,VWAP_PLUS:30.00,VOLINLINE_PLUS:30.00,MOO_PLUS:30.00,MOC_PLUS:30.00",m_strRangeByAlgName="TWAP_PLUS:0.00-50.00,VWAP_PLUS:0.00-50.00,VOLINLINE_PLUS:0.00-50.00,MOO_PLUS:0.00-50.00,MOC_PLUS:0.00-50.00" },
        {m_nId=6041,m_strName="开盘集合竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="不参与",m_strEnumName="不参与,参与",m_strEnumValue="0,1",m_strNameKey="m_bOpenTrade",m_strParamsVisible="VOLINLINE_PLUS",m_strParamsUnit="",m_strParamsHidden="0",m_strAuth="mdl_alg_active_open_trade"},
        {m_nId=6042,m_strName="尾盘集合竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="不参与",m_strEnumName="不参与,参与",m_strEnumValue="0,1",m_strNameKey="m_bCloseTrade",m_strParamsVisible="VOLINLINE_PLUS",m_strParamsUnit="",m_strParamsHidden="0",m_strAuth="mdl_alg_active_close_trade",m_strBrokerType="2,3" },
        {m_nId=6043,m_strName="尾盘集合竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="参与",m_strEnumName="参与",m_strEnumValue="1",m_strNameKey="m_bCloseTrade",m_strParamsVisible="MOC_PLUS",m_strParamsUnit="",m_strParamsHidden="0",m_strAuth="mdl_alg_active_close_trade",m_strBrokerType="2,3" },
        {m_nId=6044,m_strName="开盘集合竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="参与",m_strEnumName="参与",m_strEnumValue="1",m_strNameKey="m_bOpenTrade",m_strParamsVisible="MOO_PLUS",m_strParamsUnit="",m_strParamsHidden="0",m_strAuth="mdl_alg_active_open_trade"},
    },
    m_strategyBrokerLimit={
        {m_nId=1,m_strName="期货账号策略限制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="brokertype",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=6,m_strName="股票期权账号策略限制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="brokertype",m_strParamsVisible="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strParamsUnit="",m_strParamsHidden="" },
    },
    m_strategyAuthority={
        {m_nId=9997,m_strName="授权字段",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="TWAP_PLUS,VWAP_PLUS,VOLINLINE_PLUS,MOO_PLUS,MOC_PLUS",m_strEnumValue="mdl_alg_zjalgo",m_strNameKey="m_strStrategyAuthorityCode",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden=""},
    },
    m_strAuthority="mdl_alg_cicc2",
}
