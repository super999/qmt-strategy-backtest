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

function getAlgorithmsShenwanParams()
    return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsShenwanParams";
end

g_algorithms = {
    m_strAlgName="申万算法",
    m_params={
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="皓兴TWAP",m_strEnumName="皓兴TWAP,皓兴VWAP,皓兴T0,非凸TWAPPLUS,非凸VWAPPLUS,非凸TWAP,非凸VWAP,迅投TWAP,迅投VWAP,迅投VP,迅投主动VWAP", m_strEnumValue="HX_SMART_TWAP,HX_SMART_VWAP,HX_SMART_T0,FT_AI_TWAP_PLUS,FT_AI_VWAP_PLUS,FT_AI_TWAP,FT_AI_VWAP,XT_TWAP,XT_VWAP,XT_VP,XT_VWAPA1", m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=23001,m_strName="算法参数",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="strategyParams",m_strParamsVisible="",m_strParamsUnit="" },
    },
    m_fixedParams={
        {m_nId=11,m_strName="申报号",m_strType=0,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CIOrdID",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=15,m_strName="币种",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="CNY",m_strEnumName="",m_strEnumValue="",m_strNameKey="Currency",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=38,m_strName="目标量",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OrderQty",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=44,m_strName="限价",m_strType=3,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Price",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=54,m_strName="买卖方向",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="1",m_strEnumName="",m_strEnumValue="",m_strNameKey="Side",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=55,m_strName="证券代码",m_strType=5,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Symbol",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=60,m_strName="发送时间（UTC时间）",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="TransactTime",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=77,m_strName="开平标志",m_strType=7,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OpenClose",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=100,m_strName="交易所",m_strType=8,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="ExDestination",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=526,m_strName="信息标识",m_strType=9,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="SecondaryCIOrdID",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=7054,m_strName="两融标志",m_strType=10,m_strRange="",m_nFlag=0,m_strDefault="1",m_strEnumName="",m_strEnumValue="",m_strNameKey="MarginTradeType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=1,m_strName="资金帐号",m_strType=11,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="Account",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=7055,m_strName="账号标识",m_strType=12,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="AccountKey",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=7056,m_strName="下单操作",m_strType=13,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="OperationType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=152,m_strName="目标金额",m_strType=14,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CashOrderQty",m_strParamsVisible="",m_strParamsUnit="" },
    },
    m_customParams={
        {m_nId=6002,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="start_time",m_strParamsVisible="皓兴TWAP,皓兴VWAP,皓兴T0,非凸TWAPPLUS,非凸VWAPPLUS,非凸TWAP,非凸VWAP,迅投TWAP,迅投VWAP,迅投VP,迅投主动VWAP",m_strParamsUnit="" },
        {m_nId=6003,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="end_time",m_strParamsVisible="皓兴TWAP,皓兴VWAP,皓兴T0,非凸TWAPPLUS,非凸VWAPPLUS,非凸TWAP,非凸VWAP,迅投TWAP,迅投VWAP,迅投VP,迅投主动VWAP",m_strParamsUnit="" },
        {m_nId=6004,m_strName="市场参与率",m_strType=4,m_strRange="0,100",m_nFlag=0,m_strDefault="20",m_strEnumName="",m_strEnumValue="",m_strNameKey="participation_rate",m_strParamsVisible="皓兴TWAP,皓兴VWAP",m_strParamsUnit="" },
        {m_nId=6014,m_strName="涨跌停动作",m_strType=1,m_strRange="false,true",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="false,true",m_strNameKey="limit_action",m_strParamsVisible="皓兴TWAP,皓兴VWAP",m_strParamsUnit="" },
        {m_nId=6016,m_strName="买方向动作",m_strType=1,m_strRange="BUY,MARGIN_TRADE,REPAY_STOCK",m_nFlag=0,m_strDefault="买",m_strEnumName="买,融资买入,买券还券",m_strEnumValue="BUY,MARGIN_TRADE,REPAY_STOCK",m_strNameKey="buy_side",m_strParamsVisible="皓兴T0",m_strParamsUnit="" },
        {m_nId=6017,m_strName="卖方向动作",m_strType=1,m_strRange="SELL,REPAY_MARGIN,SHORT_SELL",m_nFlag=0,m_strDefault="卖",m_strEnumName="卖,卖券还款,融券卖出",m_strEnumValue="SELL,REPAY_MARGIN,SHORT_SELL",m_strNameKey="sell_side",m_strParamsVisible="皓兴T0",m_strParamsUnit="" },
        {m_nId=6024,m_strName="算法增强调参",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="remark",m_strParamsVisible="皓兴TWAP,皓兴VWAP,皓兴T0",m_strParamsUnit="" },
        {m_nId=6022,m_strName="涨停挂买",m_strType=1,m_strRange="false,true",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="false,true",m_strNameKey="ReachHighLimitHang",m_strParamsVisible="非凸TWAPPLUS,非凸VWAPPLUS,非凸TWAP,非凸VWAP",m_strParamsUnit="" },
        {m_nId=6023,m_strName="跌停挂卖",m_strType=1,m_strRange="false,true",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="false,true",m_strNameKey="ReachLowLimitHang",m_strParamsVisible="非凸TWAPPLUS,非凸VWAPPLUS,非凸TWAP,非凸VWAP",m_strParamsUnit="" },
        {m_nId=6065,m_strName="过期继续执行",m_strType=1,m_strRange="false,true",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="false,true",m_strNameKey="OvertimeContinue",m_strParamsVisible="非凸TWAPPLUS,非凸VWAPPLUS,非凸TWAP,非凸VWAP",m_strParamsUnit="" },
        {m_nId=6066,m_strName="量比比例",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="20.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dLimitOverRate",m_strParamsVisible="迅投VWAP,迅投TWAP,迅投VP,迅投主动VWAP",m_strParamsUnit="%",m_strParamsHidden="0" },
        {m_nId=6067,m_strName="委托最小金额",m_strType=4,m_strRange="0-100000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dMinAmountPerOrder",m_strParamsVisible="迅投VWAP,迅投TWAP,迅投VP,迅投主动VWAP",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6068,m_strName="涨跌停控制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="涨停不卖跌停不买",m_strEnumName="无,涨停不卖跌停不买",m_strEnumValue="0,1",m_strNameKey="m_nStopTradeForOwnHiLow",m_strParamsVisible="迅投TWAP,迅投VWAP,迅投VP,迅投主动VWAP",m_strParamsUnit="",m_strParamsHidden="0"},
        {m_nId=6069,m_strName="过期是否继续交易",m_strType=1,m_strRange="false,true",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="false,true",m_strNameKey="after_action",m_strParamsVisible="皓兴TWAP,皓兴VWAP",m_strParamsUnit="" },
        {m_nId=6070,m_strName="过期继续交易时间",m_strType=4,m_strRange="60-14400",m_nFlag=0,m_strDefault="14400",m_strEnumName="",m_strEnumValue="",m_strNameKey="extendTimeAfterExpire",m_strParamsVisible="皓兴TWAP,皓兴VWAP",m_strParamsUnit="" },
        {m_nId=9999,m_strName="投资备注",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_strCmdRemark",m_strParamsVisible="迅投TWAP,迅投VWAP,迅投VP,迅投主动VWAP",m_strParamsUnit="",m_strParamsHidden="0" },

    },
    m_strAuthority="mdl_alg_shenwan",
}
