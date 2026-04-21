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

function getAlgorithmsCiccParams()
	return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsCiccParams";
end

--m_strType=1 下拉列表；4 数值；2 时间类型；
g_algorithms = {
    m_strAlgName="中金算法",
    m_params={
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="ZJVWAP",m_strEnumName="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strEnumValue="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
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
        {m_nId=6002,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeStart",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6003,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeEnd",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6004,m_strName="量比比例",m_strType=4,m_strRange="0.01-50.00",m_nFlag=0,m_strDefault="33.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dLimitOverRate",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="%",m_strParamsHidden="0",m_strDefaultByAlgName="ZJTWAP:30.00,ZJVWAP:30.00,ZJVOLINLINE:20.00,ZJIS:25.00,ZJMOO:15.00,ZJMOC:15.00,ZJPEG:33.00,ZJICEBERG:33.00,ZJFLOAT:33.00,ZJTWAPA:33.00,ZJSTOPLOSS:15.00",m_strRangeByAlgName="ZJTWAP:0.00-50.00,ZJVWAP:0.00-50.00,ZJVOLINLINE:0.00-40.00,ZJIS:15.00-60.00,ZJMOO:0.00-60.00,ZJMOC:0.00-30.00,ZJPEG:0.00-40.00,ZJICEBERG:0.00-40.00,ZJFLOAT:0.00-60.00,ZJTWAPA:0.00-50.00,ZJSTOPLOSS:15.00-60.00" },
        

		{m_nId=1000,m_strName="相对限价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="无",m_strEnumName="无,对方盘口,己方盘口,昨收盘,最新价,开盘价,最高价,最低价,到达价,均价",m_strEnumValue="0,1,2,3,4,5,6,7,8,9",m_strNameKey="relativePriceLimitBase",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1001,m_strName="相对限价单位",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="BPS基点",m_strEnumName="BPS基点,Tick档位,金额,BPS基点(基于买卖),Tick档位(基于买卖),CCY金额(基于买卖)",m_strEnumValue="1,2,3,4,5,6",m_strNameKey="relativePriceLimitType",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1002,m_strName="相对限价变化量",m_strType=4,m_strRange="-10000.0000~10000.0000",m_nFlag=0,m_strDefault="0.0000",m_strEnumName="",m_strEnumValue="",m_strNameKey="relativePriceLimitOffset",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1003,m_strName="最大挂单量",m_strType=4,m_strRange="0-1000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="displaySize",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="手",m_strParamsHidden="0" },
		{m_nId=1004,m_strName="最小挂单量",m_strType=4,m_strRange="0-1000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="minDisplaySize",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="手",m_strParamsHidden="0" },
		{m_nId=1005,m_strName="量比统计口径",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="价内量",m_strEnumName="价内量,全市场量",m_strEnumValue="0,1",m_strNameKey="volPctBase",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1006,m_strName="风格",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="中性",m_strEnumName="保守,中性,激进",m_strEnumValue="1,3,5",m_strNameKey="style",m_strParamsVisible="ZJVWAP,ZJTWAP,ZJPEG,ZJICEBERG,ZJFLOAT",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1007,m_strName="监控一段时间市场波动范围",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="monitorPeriodPct",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="%",m_strParamsHidden="0" },
		{m_nId=1008,m_strName="监控一段时间市场波动时间范围",m_strType=4,m_strRange="0-10000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="monitorPeriodTime",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="min",m_strParamsHidden="0" },
		{m_nId=1009,m_strName="监控执行期内市场波动阈值",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="pauseThreshold",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="%",m_strParamsHidden="0" },
		{m_nId=1010,m_strName="市场CoolDown后是否自动恢复",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="0,1",m_strNameKey="autoResume",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1011,m_strName="重启时重置量比统计",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="是",m_strEnumName="否,是",m_strEnumValue="0,1",m_strNameKey="resetVolOnAmend",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1012,m_strName="策略时长",m_strType=4,m_strRange="0-10000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="strategyDuration",m_strParamsVisible="",m_strParamsUnit="min",m_strParamsHidden="0" },
		{m_nId=1013,m_strName="ZJTWAPA预留时间占比",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="reservedClearSecondsPercent",m_strParamsVisible="ZJTWAPA",m_strParamsUnit="%",m_strParamsHidden="0" },
		{m_nId=1014,m_strName="ZJTWAPA时间间隔",m_strType=4,m_strRange="0-10000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="timeInterval",m_strParamsVisible="ZJTWAPA",m_strParamsUnit="秒",m_strParamsHidden="0" },
		{m_nId=1015,m_strName="ZJSTOPLOSS触发类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="最新价",m_strEnumName="最新价,挂单金额",m_strEnumValue="0,1",m_strNameKey="TriggerType",m_strParamsVisible="ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1016,m_strName="ZJSTOPLOSS触发方向",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="大于",m_strEnumName="大于,小于",m_strEnumValue="1,2",m_strNameKey="triggerDirection",m_strParamsVisible="ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1017,m_strName="ZJSTOPLOSS触发价格",m_strType=4,m_strRange="0.0000-10000.0000",m_nFlag=0,m_strDefault="0.0000",m_strEnumName="",m_strEnumValue="",m_strNameKey="triggerPrice",m_strParamsVisible="ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1018,m_strName="ZJSTOPLOSS触发金额",m_strType=4,m_strRange="0.00-100000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="triggerAmt",m_strParamsVisible="ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=1024,m_strName="ZJMOCAuto集合竞价发单价类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="固定价",m_strEnumName="固定价,浮动价",m_strEnumValue="0,1",m_strNameKey="auctionPriceType",m_strParamsVisible="ZJMOC",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1019,m_strName="ZJMOCAuto集合竞价发单价",m_strType=4,m_strRange="0.0000-10000.0000",m_nFlag=0,m_strDefault="0.0000",m_strEnumName="",m_strEnumValue="",m_strNameKey="auctionPrice",m_strParamsVisible="ZJMOC",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1020,m_strName="ZJMOCAuto集合竞价相对发单价计算基准",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="没有相对限价",m_strEnumName="没有相对限价,集合竞价第一笔行情,实时行情价",m_strEnumValue="0,1,2",m_strNameKey="auctionRelativeBase",m_strParamsVisible="ZJMOC",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1021,m_strName="ZJMOCAuto集合竞价相对发单价偏移量单位",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="Tick档位",m_strEnumName="BPS基点,Tick档位,金额,BPS基点(基于买卖),Tick档位(基于买卖),CCY金额(基于买卖)",m_strEnumValue="1,2,3,4,5,6",m_strNameKey="auctionRelativeType",m_strParamsVisible="ZJMOC",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1022,m_strName="ZJMOCAuto集合竞价相对发单价偏移量",m_strType=4,m_strRange="-10000.0000~10000.0000",m_nFlag=0,m_strDefault="0.0000",m_strEnumName="",m_strEnumValue="",m_strNameKey="auctionRelativeOffset",m_strParamsVisible="ZJMOC",m_strParamsUnit="",m_strParamsHidden="0" },
		{m_nId=1023,m_strName="ZJPEG盘口统计方式",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="盘口到相对限价",m_strEnumName="盘口,盘口到限价,盘口到相对限价",m_strEnumValue="1,2,3",m_strNameKey="displaySizeType",m_strParamsVisible="ZJPEG",m_strParamsUnit="",m_strParamsHidden="0" },
    },
    m_strategyBrokerLimit={
        {m_nId=1,m_strName="期货账号策略限制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="brokertype",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=6,m_strName="股票期权账号策略限制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="brokertype",m_strParamsVisible="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strParamsUnit="",m_strParamsHidden="" },
    },
    m_strategyAuthority={
        {m_nId=9997,m_strName="授权字段",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="ZJTWAP,ZJVWAP,ZJVOLINLINE,ZJIS,ZJMOO,ZJMOC,ZJPEG,ZJICEBERG,ZJFLOAT,ZJTWAPA,ZJSTOPLOSS",m_strEnumValue="mdl_alg_zjalgo",m_strNameKey="m_strStrategyAuthorityCode",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden=""},
    },
    m_strAuthority="mdl_alg_cicc",
}
