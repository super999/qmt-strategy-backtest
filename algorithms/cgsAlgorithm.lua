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

function getAlgorithmsCgsParams()
    return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsCgsParams";
end

g_algorithms = {
    m_strAlgName="银河算法",
    m_params={
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="CGS_TWAP",m_strEnumName="KF_TWAP_PLUS,CGS_TWAP,KF_TWAP_CORE,KF_VWAP_PLUS,CGS_VWAP,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,CGS_POV,QND_T0,KF_T0,HX_SMART_TWAP,HX_SMART_VWAP,XIHE_WAP,FT_TWAP_AI,FT_VWAP_AI,FT_VWAP_AI_PLUS,FT_TWAP_AI_PLUS,XIHE_WAP_PLUS", m_strEnumValue="KF_TWAP_PLUS,CGS_TWAP,KF_TWAP_CORE,KF_VWAP_PLUS,CGS_VWAP,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,CGS_POV,QND_T0,KF_T0,HX_SMART_TWAP,HX_SMART_VWAP,XIHE_WAP,FT_TWAP_AI,FT_VWAP_AI,FT_VWAP_AI_PLUS,FT_TWAP_AI_PLUS,XIHE_WAP_PLUS", m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="" },
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
        {m_nId=152,m_strName="目标金额",m_strType=14,m_strRange="",m_nFlag=0,m_strDefault="123",m_strEnumName="",m_strEnumValue="",m_strNameKey="CashOrderQty",m_strParamsVisible="",m_strParamsUnit="" },
    },
    m_customParams={
        {m_nId=6062,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeStart",m_strParamsVisible="KF_TWAP_PLUS,CGS_TWAP,KF_TWAP_CORE,KF_VWAP_PLUS,CGS_VWAP,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,CGS_POV,QND_T0,KF_T0,HX_SMART_TWAP,HX_SMART_VWAP,XIHE_WAP,FT_TWAP_AI,FT_VWAP_AI,FT_VWAP_AI_PLUS,FT_TWAP_AI_PLUS,XIHE_WAP_PLUS",m_strParamsUnit="" },
        {m_nId=6063,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeEnd",m_strParamsVisible="KF_TWAP_PLUS,CGS_TWAP,KF_TWAP_CORE,KF_VWAP_PLUS,CGS_VWAP,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,CGS_POV,QND_T0,KF_T0,HX_SMART_TWAP,HX_SMART_VWAP,XIHE_WAP,FT_TWAP_AI,FT_VWAP_AI,FT_VWAP_AI_PLUS,FT_TWAP_AI_PLUS,XIHE_WAP_PLUS",m_strParamsUnit="" },
        {m_nId=6064,m_strName="涨跌停是否继续执行",m_strType=1,m_strRange="0,1",m_nFlag=0,m_strDefault="0",m_strEnumName="0,1",m_strEnumValue="0,1",m_strNameKey="limit_action",m_strParamsVisible="KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,QND_T0,KF_T0,HX_SMART_TWAP,HX_SMART_VWAP,XIHE_WAP,FT_TWAP_AI,FT_VWAP_AI,FT_VWAP_AI_PLUS,FT_TWAP_AI_PLUS,XIHE_WAP_PLUS",m_strParamsUnit="" },
        {m_nId=6065,m_strName="过期后是否继续执行",m_strType=1,m_strRange="0,1",m_nFlag=0,m_strDefault="0",m_strEnumName="0,1",m_strEnumValue="0,1",m_strNameKey="after_action",m_strParamsVisible="KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,QND_T0,KF_T0,HX_SMART_TWAP,HX_SMART_VWAP",m_strParamsUnit="" },
        {m_nId=6066,m_strName="最大市场参与比例%",m_strType=7,m_strRange="0.00-30.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="max_percentage",m_strParamsVisible="KF_POV_CORE,CGS_POV,HX_SMART_TWAP,HX_SMART_VWAP",m_strParamsUnit="" },
        {m_nId=6162,m_strName="最小金额限制",m_strType=7,m_strRange="10000.00-99999999",m_nFlag=0,m_strDefault="10000.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="limitAmt",m_strParamsVisible="QND_T0",m_strParamsUnit="" },
        {m_nId=6167,m_strName="买入方向",m_strType=1,m_strRange="1,3,5",m_nFlag=0,m_strDefault="普通买入",m_strEnumName="普通买入,买券还券,融资买入",m_strEnumValue="1,3,5",m_strNameKey="buyside",m_strParamsVisible="QND_T0,KF_T0",m_strParamsUnit="" },
        {m_nId=6168,m_strName="卖出方向",m_strType=1,m_strRange="2,4,6",m_nFlag=0,m_strDefault="普通卖出",m_strEnumName="普通卖出,融券卖出,卖券还款",m_strEnumValue="2,4,6",m_strNameKey="sellside",m_strParamsVisible="QND_T0,KF_T0",m_strParamsUnit="" },
    },
    m_strAuthority="mdl_alg_cgs1",
}
