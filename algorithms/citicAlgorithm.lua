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

function getAlgorithmsCiticParams()
    return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsCiticParams";
end

g_algorithms = {
    m_strAlgName="中信证券",
    m_params={
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="" },
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="TWAP",m_strEnumName="TWAP,VWAP,VolumeInline,TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,VolumeInline3,Scaling3,CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP,SmartVolumeInline3,Dynamic3,Iceberg3,Sniper3,QMOO3,QMOC3,CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSMOO6,CITICSMOC6,CITICSAITWAP,CITICSIceberg,CITICSRTWAP,CITICSRVWAP",m_strEnumValue="TWAP,VWAP,VolumeInline,TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,VolumeInline3,Scaling3,ZJTWAP,ZJVWAP,VOL,AlphaTWAP,AlphaVWAP,SmartVolumeInline3,Dynamic3,Iceberg3,Sniper3,QMOO3,QMOC3,ZJTWAP6,ZJVWAP6,ZJVOL6,ZJDynamic6,ZJScaling6,ZJEscalator6,ZJStop6,ZJFloat6,ZJSniper6,ZJFloatSniper6,ZJIceberg6,ZJMOO6,ZJMOC6,AITWAP,ZJIceberg,RTWAP,RVWAP",m_strEnumRemark="时间加权均价算法,成交量加权均价算法,跟量算法,时间加权均价算法,成交量加权均价算法,动态分布时间加权均价算法,动态分布成交量加权均价算法,主动时间加权均价算法,主动成交量加权均价算法,跟量算法,分层跟量算法,证金时间加权均价算法,证金成交量加权均价算法,证金跟量算法,证金AlphaTWAP,证金AlphaVWAP,主动跟量算法,主动跟量算法,冰山算法,狙击手算法,量化开盘算法,量化收盘算法,证金TWAP6,证金VWAP6,证金VOL6,证金Dynamic6,证金Scaling6,证金Escalator6,证金Stop6,证金Float6,证金Sniper6,证金FloatSniper6,证金Iceberg6,证金MOO6,证金MOC6,证金AITWAP,证金冰山算法,证金RTWAP,证金RVWAP", m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="" },
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
        {m_nId=6062,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="beginTime",m_strParamsVisible="TWAP,VWAP,VolumeInline,TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,VolumeInline3,Scaling3,SmartVolumeInline3,Dynamic3,Iceberg3,Sniper3,QMOC3",m_strParamsUnit="" },
        {m_nId=6063,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="endTime",m_strParamsVisible="TWAP,VWAP,VolumeInline,TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,VolumeInline3,Scaling3,SmartVolumeInline3,Dynamic3,Iceberg3,Sniper3,QMOO3",m_strParamsUnit="" },
        {m_nId=6064,m_strName="最大量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="participateRate",m_strParamsVisible="TWAP,VWAP,TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,Scaling3,Iceberg3,Sniper3",m_strParamsUnit="" },
        {m_nId=6065,m_strName="交易风格",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="正常",m_strEnumName="紧,正常,宽",m_strEnumValue="0,1,2",m_strNameKey="tradingStyle",m_strParamsVisible="TWAP,VWAP,VolumeInline3,SmartVolumeInline3,Dynamic3,QMOO3",m_strParamsUnit="" },
        {m_nId=6066,m_strName="跟量比例",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.33",m_strEnumName="",m_strEnumValue="",m_strNameKey="participateRate",m_strParamsVisible="VolumeInline,VolumeInline3,SmartVolumeInline3,Dynamic3",m_strParamsUnit="" },
        {m_nId=6162,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="startTime",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSIceberg,CITICSRTWAP,CITICSRVWAP",m_strParamsUnit="" },
        {m_nId=6163,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="endTime",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSIceberg,CITICSRTWAP,CITICSRVWAP",m_strParamsUnit="" },
        {m_nId=6164,m_strName="侵略级别",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="Neutral",m_strEnumName="Passive,Neutral,Aggressive",m_strEnumValue="1,2,3",m_strNameKey="aggressiveLevel",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSRTWAP,CITICSRVWAP,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSAITWAP",m_strParamsUnit="" },
        {m_nId=6165,m_strName="是否尽量成交",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="true",m_strEnumName="true,false",m_strEnumValue="true,false",m_strNameKey="forceToTradeAll",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSRTWAP,CITICSRVWAP",m_strParamsUnit="" },
        {m_nId=6166,m_strName="运行时长",m_strType=4,m_strRange="0-1000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="totalDuration",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSRTWAP,CITICSRVWAP,CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
        {m_nId=6167,m_strName="价格类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="对方盘口",m_strEnumName="己方盘口,对方盘口",m_strEnumValue="0,1",m_strNameKey="priceType",m_strParamsVisible="CITICSIceberg",m_strParamsUnit="" },
        {m_nId=6168,m_strName="切片大小",m_strType=4,m_strRange="1-10000",m_nFlag=0,m_strDefault="500",m_strEnumName="",m_strEnumValue="",m_strNameKey="clipSize",m_strParamsVisible="CITICSIceberg",m_strParamsUnit="" },
        {m_nId=6169,m_strName="时间间隔",m_strType=4,m_strRange="1-7200",m_nFlag=0,m_strDefault="30",m_strEnumName="",m_strEnumValue="",m_strNameKey="timeDelay",m_strParamsVisible="CITICSIceberg",m_strParamsUnit="" },
        {m_nId=6170,m_strName="计划参与比例",m_strType=4,m_strRange="0-100",m_nFlag=0,m_strDefault="5",m_strEnumName="",m_strEnumValue="",m_strNameKey="targetRate",m_strParamsVisible="CITICSVOL",m_strParamsUnit="%" },
        {m_nId=6262,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="09:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="beginTime",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSAITWAP",m_strParamsUnit="" },
        {m_nId=6263,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="16:35:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="endTime",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSAITWAP",m_strParamsUnit="" },
        {m_nId=6264,m_strName="侵略级别",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="Neutral",m_strEnumName="Passive,Neutral,Aggressive,Crossnow",m_strEnumValue="1,2,3,4",m_strNameKey="aggressiveLevel",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6",m_strParamsUnit="" },
        {m_nId=6265,m_strName="止损价",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="triggerPrice",m_strParamsVisible="CITICSStop6",m_strParamsUnit="" },
        {m_nId=22201,m_strName="限价阈值",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="priceThresholds",m_strParamsVisible="Scaling3",m_strParamsUnit="" },
        {m_nId=22202,m_strName="跟量比例阈值",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="participateRateThresholds",m_strParamsVisible="Scaling3",m_strParamsUnit="" },
        {m_nId=22203,m_strName="阈值个数",m_strType=4,m_strRange="0-100",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="numberOfThresholds",m_strParamsVisible="Scaling3",m_strParamsUnit="" },
        {m_nId=22204,m_strName="允许超量",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="不能超量",m_strEnumName="不能超量,可以超量",m_strEnumValue="0,1",m_strNameKey="allowExceedTargetQty",m_strParamsVisible="CITICSRTWAP,CITICSRVWAP",m_strParamsUnit="" },
        {m_nId=9999,m_strName="投资备注",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_strCmdRemark",m_strParamsVisible="TWAP,VWAP,VolumeInline,TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,VolumeInline3,SmartVolumeInline3,Dynamic3,Scaling3,CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=22205,m_strName="开盘集合竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="false",m_strEnumName="true,false",m_strEnumValue="true,false",m_strNameKey="openCall",m_strParamsVisible="VolumeInline3,Scaling3,SmartVolumeInline3,Dynamic3",m_strParamsUnit="" },
        {m_nId=22206,m_strName="收盘集合竞价",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="false",m_strEnumName="true,false",m_strEnumValue="true,false",m_strNameKey="closeCall",m_strParamsVisible="VolumeInline3,Scaling3,SmartVolumeInline3,Dynamic3",m_strParamsUnit="" },
        {m_nId=22207,m_strName="IWould价格",m_strType=4,m_strRange="1-10000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldPrice",m_strParamsVisible="TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,VolumeInline3,Scaling3,SmartTWAP3,SmartVWAP3,SmartVolumeInline3,Dynamic3",m_strParamsUnit="" },
        {m_nId=22208,m_strName="IWould最大量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldMax",m_strParamsVisible="TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,VolumeInline3,Scaling3,SmartTWAP3,SmartVWAP3,SmartVolumeInline3,Dynamic3",m_strParamsUnit="" },
        {m_nId=22209,m_strName="基准价格",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="算法均价",m_strEnumName="算法均价,市场均价,到达价,全天市场均价,开盘价,昨收价",m_strEnumValue="1,2,3,4,5,6",m_strNameKey="benchmark",m_strParamsVisible="Dynamic3",m_strParamsUnit="" },
        {m_nId=22210,m_strName="最大量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.20",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxPartRate",m_strParamsVisible="Dynamic3",m_strParamsUnit="" },
        {m_nId=22211,m_strName="最小量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.10",m_strEnumName="",m_strEnumValue="",m_strNameKey="minPartRate",m_strParamsVisible="Dynamic3",m_strParamsUnit="" },
	    {m_nId=22212,m_strName="暴露数量",m_strType=4,m_strRange="1-1000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="qtyExposed",m_strParamsVisible="Iceberg3",m_strParamsUnit="" },
	    {m_nId=22213,m_strName="下单间隔",m_strType=4,m_strRange="1-7200",m_nFlag=0,m_strDefault="8",m_strEnumName="",m_strEnumValue="",m_strNameKey="intervalLength",m_strParamsVisible="Iceberg3",m_strParamsUnit="" },
	    {m_nId=22214,m_strName="交易风格",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="宽",m_strEnumName="紧,正常,宽,更宽,无限制",m_strEnumValue="0,1,2,3,4",m_strNameKey="tradingStyle",m_strParamsVisible="TWAP3,VWAP3,SmartTWAP3,SmartVWAP3,QMOC3",m_strParamsUnit="" },
	    {m_nId=22215,m_strName="开盘量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.20",m_strEnumName="",m_strEnumValue="",m_strNameKey="mooPartRate",m_strParamsVisible="QMOO3",m_strParamsUnit="" },
        {m_nId=22216,m_strName="开盘后量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.30",m_strEnumName="",m_strEnumValue="",m_strNameKey="postPartRate",m_strParamsVisible="QMOO3",m_strParamsUnit="" },
	    {m_nId=22217,m_strName="收盘量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.20",m_strEnumName="",m_strEnumValue="",m_strNameKey="mocPartRate",m_strParamsVisible="QMOC3",m_strParamsUnit="" },
	    {m_nId=22218,m_strName="收盘前量比",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.30",m_strEnumName="",m_strEnumValue="",m_strNameKey="prePartRate",m_strParamsVisible="QMOC3",m_strParamsUnit="" },
	    {m_nId=22219,m_strName="最小下单量",m_strType=4,m_strRange="0-1000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="minSize",m_strParamsVisible="Sniper3",m_strParamsUnit="" },
	    {m_nId=22220,m_strName="扫描盘口档数",m_strType=4,m_strRange="1-10",m_nFlag=0,m_strDefault="5",m_strEnumName="",m_strEnumValue="",m_strNameKey="depthLevel",m_strParamsVisible="Sniper3",m_strParamsUnit="" },
	    {m_nId=22221,m_strName="置信度",m_strType=4,m_strRange="0-1.0",m_nFlag=0,m_strDefault="0.50",m_strEnumName="",m_strEnumValue="",m_strNameKey="confidence",m_strParamsVisible="Sniper3",m_strParamsUnit="" },
	    {m_nId=22222,m_strName="子单撤单时间",m_strType=4,m_strRange="1-7200",m_nFlag=0,m_strDefault="3",m_strEnumName="",m_strEnumValue="",m_strNameKey="autoCancelSec",m_strParamsVisible="Sniper3",m_strParamsUnit="" },
	    {m_nId=22223,m_strName="每分钟最大委托笔数",m_strType=4,m_strRange="0-1000000",m_nFlag=0,m_strDefault="8",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxOrderCntIn1Minute",m_strParamsVisible="Sniper3",m_strParamsUnit="" },
	    {m_nId=22224,m_strName="最小下单金额",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="minAmount",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSIceberg,CITICSRTWAP,CITICSRVWAP,CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSMOO6,CITICSMOC6",m_strParamsUnit="" },
	    {m_nId=22225,m_strName="目标金额",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="targetAmt",m_strParamsVisible="CITICSTWAP,CITICSVWAP,CITICSVOL,CITICSAlphaTWAP,CITICSAlphaVWAP,CITICSIceberg,CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSMOO6,CITICSMOC6",m_strParamsUnit="" },
	   -- {m_nId=22226,m_strName="hedge标识",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="专项头寸,非专项头寸,空",m_strEnumValue="4,5,0",m_strNameKey="hedgeFlag",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSMOO6,CITICSMOC6",m_strParamsUnit="" },
	    {m_nId=22227,m_strName="开盘价目标量",m_strType=4,m_strRange="0-10000000000.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxOpenOrderQty",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22228,m_strName="收盘价目标量",m_strType=4,m_strRange="0-10000000000.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="minCloseOrderQty",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22229,m_strName="参与度",m_strType=4,m_strRange="0-0.4",m_nFlag=0,m_strDefault="0.2",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxRate",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSMOO6,CITICSMOC6",m_strParamsUnit="" },
        {m_nId=22230,m_strName="是否设置涨停不卖跌停不买",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="不控制",m_strEnumName="涨停不卖跌停不卖,不控制",m_strEnumValue="true,false",m_strNameKey="isDownOrUpStopStockNotTrade",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6,CITICSMOO6,CITICSMOC6",m_strParamsUnit="" },
        {m_nId=22231,m_strName="iWould触发价格类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="TargetPrice",m_strEnumName="ArrivalPrice,TargetPrice,VWAP,VSOT,Open,PreviousClose",m_strEnumValue="1,2,3,4,5,6",m_strNameKey="iWouldTriggerBenchmark",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22232,m_strName="iWould触发价格",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldTriggerPrice",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22233,m_strName="iWould触发价偏差",m_strType=4,m_strRange="0.00-0.30",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldTriggerOffSetPct",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22234,m_strName="iWould执行比例(剩余量)",m_strType=4,m_strRange="0.00-1.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldPctOfRemain",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22235,m_strName="iWould执行比例(目标量)",m_strType=4,m_strRange="0.00-1.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldPctOfTarget",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
	    {m_nId=22236,m_strName="iWould参与度",m_strType=4,m_strRange="0.00-1.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="iWouldMaxRate",m_strParamsVisible="CITICSTWAP6,CITICSVWAP6,CITICSVOL6,CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSStop6,CITICSFloat6,CITICSSniper6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
        {m_nId=22237,m_strName="动态范围限制",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxRestriction",m_strParamsVisible="CITICSDynamic6",m_strParamsUnit="" },
        {m_nId=22238,m_strName="跟踪目标价格类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="ArrivalPrice",m_strEnumName="ArrivalPrice,TargetPrice,VWAP,VSOT,Open,PreviousClose",m_strEnumValue="1,2,3,4,5,6",m_strNameKey="targetBenchmark",m_strParamsVisible="CITICSDynamic6",m_strParamsUnit="" },
        {m_nId=22239,m_strName="跟踪目标价格",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="targetPrice",m_strParamsVisible="CITICSDynamic6",m_strParamsUnit="" },
        {m_nId=22240,m_strName="最小参与度",m_strType=4,m_strRange="0.00-0.40",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="minRate",m_strParamsVisible="CITICSDynamic6,CITICSScaling6,CITICSEscalator6",m_strParamsUnit="" },
        {m_nId=22241,m_strName="中间参与度",m_strType=4,m_strRange="0.00-0.40",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="midRate",m_strParamsVisible="CITICSScaling6",m_strParamsUnit="" },
        {m_nId=22242,m_strName="最大参与度",m_strType=4,m_strRange="0.00-0.40",m_nFlag=0,m_strDefault="0.20",m_strEnumName="",m_strEnumValue="",m_strNameKey="maxRate",m_strParamsVisible="CITICSDynamic6,CITICSScaling6,CITICSEscalator6,CITICSAITWAP",m_strParamsUnit="" },
        {m_nId=22243,m_strName="下边界价",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="lowerTargetPrice",m_strParamsVisible="CITICSScaling6",m_strParamsUnit="" },
        {m_nId=22244,m_strName="上边界价",m_strType=4,m_strRange="0.00-10000000000.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="upperTargetPrice",m_strParamsVisible="CITICSScaling6",m_strParamsUnit="" },
        {m_nId=22245,m_strName="电梯落差序列",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="varianceSeq",m_strParamsVisible="CITICSEscalator6",m_strParamsUnit="" },
        {m_nId=22246,m_strName="参与度序列",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="participationRateSeq",m_strParamsVisible="CITICSEscalator6",m_strParamsUnit="" },
        {m_nId=22247,m_strName="单笔委托量",m_strType=4,m_strRange="0-100000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="showQty",m_strParamsVisible="CITICSFloat6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
        {m_nId=22248,m_strName="委托价位个数",m_strType=4,m_strRange="1-100000000",m_nFlag=0,m_strDefault="1",m_strEnumName="",m_strEnumValue="",m_strNameKey="priceLevels",m_strParamsVisible="CITICSFloat6,CITICSFloatSniper6,CITICSIceberg6",m_strParamsUnit="" },
        {m_nId=22249,m_strName="最小触发数量",m_strType=4,m_strRange="0-100000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="minAvailableQty",m_strParamsVisible="CITICSSniper6,CITICSFloatSniper6",m_strParamsUnit="" },
        {m_nId=22250,m_strName="狙击保留数量",m_strType=4,m_strRange="0-100000000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="leaveQty",m_strParamsVisible="CITICSSniper6,CITICSFloatSniper6",m_strParamsUnit="" },
        {m_nId=22251,m_strName="开盘订单比例",m_strType=4,m_strRange="0-1.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="openCallPct",m_strParamsVisible="TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,Dynamic3",m_strParamsUnit="" },
        {m_nId=22252,m_strName="收盘订单比例",m_strType=4,m_strRange="0-1.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="closeCallPct",m_strParamsVisible="TWAP3,VWAP3,TWAPPlus3,VWAPPlus3,SmartTWAP3,SmartVWAP3,Dynamic3",m_strParamsUnit="" },
    },
    m_strAuthority="mdl_alg_zxzq1",
}
