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

function getAlgorithmsFzParams()
    return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsFzParams";
end

g_algorithms = {
    m_strAlgName="方正算法",
    m_params={
        {m_nId=23001,m_strName="算法参数",m_strType=5,m_strRange="",m_nFlag=2147483647,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=2147483647,m_strDefault="STRATEGY_ALGO_VWAP_PLUS",m_strEnumName="STRATEGY_ALGO_VWAP_PLUS,STRATEGY_COMB_T0",m_strEnumValue="STRATEGY_ALGO_VWAP_PLUS,STRATEGY_COMB_T0",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
    },
    m_fixedParams={},
    m_strAuthority="mdl_alg_fzzq1",
    m_customParams={
        {m_nId=6002,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=2147483647,m_strDefault="9:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="effectiveTime",m_strParamsVisible="STRATEGY_ALGO_VWAP_PLUS",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6065,m_strName="过期后是否继续执行",m_strType=1,m_strRange="",m_nFlag=2147483647,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="0,1",m_strNameKey="expireAction",m_strParamsVisible="STRATEGY_ALGO_VWAP_PLUS",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6003,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=2147483647,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="expireTime",m_strParamsVisible="STRATEGY_ALGO_VWAP_PLUS",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6064,m_strName="涨跌停是否继续执行",m_strType=1,m_strRange="",m_nFlag=2147483647,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="0,1",m_strNameKey="limitAction",m_strParamsVisible="STRATEGY_ALGO_VWAP_PLUS",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=2147483647,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="0,1",m_strNameKey="priceLimit",m_strParamsVisible="STRATEGY_ALGO_VWAP_PLUS",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6066,m_strName="使用资金量",m_strType=4,m_strRange="",m_nFlag=2147483647,m_strDefault="使用自有资金",m_strEnumName="使用自有资金,使用担保品资金",m_strEnumValue="0,1",m_strNameKey="cash",m_strParamsVisible="STRATEGY_COMB_T0",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6068,m_strName="资金使用模式",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=2147483647,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="fundUseMode",m_strParamsVisible="STRATEGY_COMB_T0",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
        {m_nId=6067,m_strName="最大风险敞口",m_strType=4,m_strRange="20-50",m_nFlag=2147483647,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxRiskExposure",m_strParamsVisible="STRATEGY_COMB_T0",m_strParamsUnit="",m_strParamsHidden="",m_strEnumRemark="",m_strDefaultByAlgName="",m_strRangeByAlgName=""},
    },
}