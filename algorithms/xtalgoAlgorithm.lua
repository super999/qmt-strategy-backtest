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

function getAlgorithmsXtAlgoParams()
	return table2json({content = g_algorithms})
end

function getAlgoName()
    return "getAlgorithmsXtAlgoParams";
end


g_algorithms = {
    m_strAlgName="智能算法",
    m_params={
        {m_nId=40,m_strName="订单类型",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="市价",m_strEnumName="市价,限价",m_strEnumValue="1,2",m_strNameKey="OrdType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=6061,m_strName="算法名称",m_strType=1,m_strRange="",m_nFlag=1,m_strDefault="VWAP",m_strEnumName="VWAP,TWAP,跟量,跟价,快捷,盘口,直接下单,换仓,冰山,尾盘,网格,VWAP+,开盘,IS,短时VWAP,融券卖出,快速交易,跟量+,ALGOINTERFACE,FTAIWAP,融券对冲,主动VWAP,混合VWAP,主动VWAPPLUS,KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,KF_VWAP_CORE,KF_POV_CORE,KF_T0,KF_PASSTHRU,CGS_TWAP,CGS_VWAP,CGS_POV,FT_AI_WAP,QND_T0,T0_QINENGDA,T0_FEITU,T0_TAOJIN,T0_YUSHU",m_strEnumValue="VWAP,TWAP,VP,PINLINE,DMA,FLOAT,MSO,SWITCH,ICEBERG,MOC,GRID,VWAPPLUS,MOO,IS,STWAP,SLOS,XTFAST,VPPLUS,ALGOINTERFACE,FTAIWAP,SLOH,VWAPA1,VWAPM1,VWAPAPLUS,KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,KF_VWAP_CORE,KF_POV_CORE,KF_T0,KF_PASSTHRU,CGS_TWAP,CGS_VWAP,CGS_POV,FT_AI_WAP,QND_T0,T0_QINENGDA,T0_FEITU,T0_TAOJIN,T0_YUSHU",m_strNameKey="strategyType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="" },
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
    },
    m_customParams={
        {m_nId=6002,m_strName="开始时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="9:30:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeStart",m_strParamsVisible="TWAP,VWAP,跟量,跟价,快捷,盘口,直接下单,换仓,冰山,尾盘,网格,VWAP+,开盘,IS,短时VWAP,融券卖出,快速交易,跟量+,ALGOINTERFACE,FTAIWAP,融券对冲,主动VWAP,混合VWAP,主动VWAPPLUS,KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,KF_VWAP_CORE,KF_POV_CORE,KF_T0,KF_PASSTHRU,CGS_TWAP,CGS_VWAP,CGS_POV,FT_AI_WAP,QND_T0",m_strParamsUnit="",m_strParamsHidden="0",m_strDefaultByAlgName="T0_TAOJIN=9:31:00,T0_YUSHU=9:32:00",m_strRangeByAlgName="" },
        {m_nId=6003,m_strName="结束时间",m_strType=2,m_strRange="",m_nFlag=0,m_strDefault="15:00:00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nValidTimeEnd",m_strParamsVisible="TWAP,VWAP,跟量,跟价,快捷,盘口,直接下单,换仓,冰山,尾盘,网格,VWAP+,开盘,IS,短时VWAP,融券卖出,快速交易,跟量+,ALGOINTERFACE,FTAIWAP,融券对冲,主动VWAP,混合VWAP,主动VWAPPLUS,KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,KF_VWAP_CORE,KF_POV_CORE,KF_T0,KF_PASSTHRU,CGS_TWAP,CGS_VWAP,CGS_POV,FT_AI_WAP,QND_T0",m_strParamsUnit="",m_strParamsHidden="0",m_strDefaultByAlgName="T0_TAOJIN=18:10:00,T0_YUSHU=15:30:00",m_strRangeByAlgName="" },
        {m_nId=6004,m_strName="量比比例",m_strType=4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="20.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dLimitOverRate",m_strParamsVisible="VWAP,TWAP,跟量,跟价,快捷,盘口,换仓,冰山,尾盘,VWAP+,开盘,IS,短时VWAP,融券卖出,跟量+,ALGOINTERFACE,FTAIWAP,融券对冲",m_strParamsUnit="%",m_strParamsHidden="0" },
        {m_nId=6005,m_strName="委托最小金额",m_strType=4,m_strRange="0-100000",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dMinAmountPerOrder",m_strParamsVisible="VWAP,TWAP,跟量,跟价,快捷,盘口,换仓,冰山,尾盘,VWAP+,开盘,IS,短时VWAP,融券卖出,跟量+,ALGOINTERFACE,FTAIWAP,T0_QINENGDA,T0_FEITU,T0_TAOJIN,T0_YUSHU",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6006,m_strName="仅用卖出金额",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="0,1",m_strNameKey="m_bOnlySellAmountUsed",m_strParamsVisible="换仓",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6007,m_strName="目标价格",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="己方盘口1",m_strEnumName="己方盘口1,己方盘口2,己方盘口3,己方盘口4,己方盘口5,最新价,对方盘口",m_strEnumValue="1,2,3,4,5,6,7",m_strNameKey="m_nTargetPriceLevel",m_strParamsVisible="冰山",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6008,m_strName="价格间距类型",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="价格最小变动单位",m_strEnumName="价格最小变动单位,百分比",m_strEnumValue="1,2",m_strNameKey="m_nPriceDiffType",m_strParamsVisible="网格",m_strParamsUnit="",m_strParamsHidden="0" },		
        {m_nId=6009,m_strName="价格间距大小",m_strType= 4,m_strRange="0-100.00",m_nFlag=0,m_strDefault="1",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dPriceDiffVal",m_strParamsVisible="网格",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6010,m_strName="首笔金额类型",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="固定金额(元)",m_strEnumName="固定金额(元),母单金额百分比",m_strEnumValue="1,2",m_strNameKey="m_nFirstOrderAmtType",m_strParamsVisible="网格",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6011,m_strName="首笔金额大小",m_strType= 4,m_strRange="0.00-90000000.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dFirstOrderAmount",m_strParamsVisible="网格",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6012,m_strName="金额递增比例",m_strType= 4,m_strRange="-99~1000.00",m_nFlag=0,m_strDefault="0",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dOrderAmountDelta",m_strParamsVisible="网格",m_strParamsUnit="%",m_strParamsHidden="0" },
        {m_nId=6013,m_strName="买卖偏差上限",m_strType= 4,m_strRange="3-100.00",m_nFlag=0,m_strDefault="10",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dBuySellAmountDeltaPct",m_strParamsVisible="换仓",m_strParamsUnit="%",m_strParamsHidden="0" },
        {m_nId=6014,m_strName="涨跌停控制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="涨停不卖跌停不买",m_strEnumName="无,涨停不卖跌停不买",m_strEnumValue="0,1",m_strNameKey="m_nStopTradeForOwnHiLow",m_strParamsVisible="TWAP,VWAP,跟量,跟价,快捷,盘口,换仓,冰山,尾盘,VWAP+,短时VWAP,融券卖出,跟量+",m_strParamsUnit="",m_strParamsHidden="0"},
        {m_nId=6015,m_strName="超价起始笔数",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nSuperPriceStart",m_strParamsVisible="快速交易,融券对冲",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6016,m_strName="打单价格档位",m_strType=1,m_strRange="",m_nFlag=0,m_strDefault="对方3档",m_strEnumName="对方1档,对方2档,对方3档,对方4档,对方5档",m_strEnumValue="1,2,3,4,5",m_strNameKey="m_nPriceOffsetForAggrOrder",m_strParamsVisible="跟量+",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6018,m_strName="单笔下单比率",m_strType= 4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dSingleVolumeRate",m_strParamsVisible="融券对冲",m_strParamsUnit="%",m_strParamsHidden="0" },
        {m_nId=6019,m_strName="最大轧差数量",m_strType=4,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_nMaxNettingVol",m_strParamsVisible="融券对冲",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6020,m_strName="最大亏损金额",m_strType=4,m_strRange="1-99999999",m_nFlag=0,m_strDefault="99999999",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dMaxDeficitAmount",m_strParamsVisible="融券对冲",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6023,m_strName="涨停不卖",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="否",m_strEnumName="否,是",m_strEnumValue="0,1",m_strNameKey="stopSellingWhenBuyOverFlow",m_strParamsVisible="混合VWAP",m_strParamsUnit="",m_strParamsHidden="0"},
        {m_nId=6024,m_strName="算法类型",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="算法",m_strEnumName="算法",m_strEnumValue="0",m_strNameKey="algo_type",m_strParamsVisible="混合VWAP",m_strParamsUnit="",m_strParamsHidden="0"},
        {m_nId=6027,m_strName="触价设置",m_strType=8,m_strRange="0.00-10000.00",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dTriggerPrice",m_strParamsVisible="TWAP,VWAP,跟量,跟价,快捷,盘口,冰山,尾盘,网格,VWAP+,开盘,IS,短时VWAP,极速融券,快速交易,跟量+,IVWAP",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6030,m_strName="参与市场成交最大百分比",m_strType= 4,m_strRange="0.00-100.00",m_nFlag=0,m_strDefault="0.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_dMaxPercentage",m_strParamsVisible="KF_POV_CORE,CGS_POV",m_strParamsUnit="%",m_strParamsHidden="0" },
        {m_nId=6031,m_strName="T0买入方向",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="普通买入",m_strEnumName="普通买入,买券还券,融资买入",m_strEnumValue="1,3,5",m_strNameKey="m_nBuySide",m_strParamsVisible="KF_T0,QND_T0",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6032,m_strName="T0卖出方向",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="普通卖出",m_strEnumName="普通卖出,融资卖出,卖券还款",m_strEnumValue="2,4,6",m_strNameKey="m_dSellSide",m_strParamsVisible="KF_T0,QND_T0",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6064,m_strName="涨跌停是否继续执行",m_strType=1,m_strRange="0,1",m_nFlag=0,m_strDefault="0",m_strEnumName="0,1",m_strEnumValue="0,1",m_strNameKey="limit_action",m_strParamsVisible="KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,KF_T0,FT_AI_WAP,QND_T0",m_strParamsUnit="" },
        {m_nId=6065,m_strName="过期后是否继续执行",m_strType=1,m_strRange="0,1",m_nFlag=0,m_strDefault="0",m_strEnumName="0,1",m_strEnumValue="0,1",m_strNameKey="after_action",m_strParamsVisible="KF_TWAP_PLUS,KF_TWAP_CORE,KF_VWAP_PLUS,FT_AI_WAP,KF_VWAP_CORE,KF_POV_CORE,KF_T0,FT_AI_WAP,QND_T0",m_strParamsUnit="" },
        {m_nId=6162,m_strName="最小金额限制",m_strType=7,m_strRange="10000.00-99999999",m_nFlag=0,m_strDefault="10000.00",m_strEnumName="",m_strEnumValue="",m_strNameKey="limitAmt",m_strParamsVisible="QND_T0",m_strParamsUnit="" },
        {m_nId=9999,m_strName="投资备注",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_strCmdRemark",m_strParamsVisible="TWAP,VWAP,跟量,跟价,快捷,盘口,换仓,冰山,尾盘,网格,VWAP+,开盘,IS,短时VWAP,融券卖出,快速交易,跟量+,融券对冲,主动VWAP,混合VWAP,主动VWAPPLUS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=9998,m_strName="投资备注1",m_strType=6,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="m_strCmdRemark1",m_strParamsVisible="TWAP,VWAP,跟量,跟价,快捷,盘口,换仓,冰山,尾盘,网格,VWAP+,开盘,IS,短时VWAP,融券卖出,快速交易,跟量+,融券对冲,主动VWAP,混合VWAP,主动VWAPPLUS",m_strParamsUnit="",m_strParamsHidden="0" },
        {m_nId=6037,m_strName="T0信用买入类型",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="担保品买入",m_strEnumName="担保品买入,融资买入,买券还券",m_strEnumValue="1,2,3",m_strNameKey="m_nBuyType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="0",m_strDefaultByAlgName="",m_strRangeByAlgName="T0_TAOJIN:担保品买入|融资买入|买券还券,T0_FEITU:担保品买入|融资买入|买券还券,T0_QINENGDA:担保品买入|融资买入|买券还券,T0_YUSHU:担保品买入|买券还券" },
        {m_nId=6038,m_strName="T0信用卖出类型",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="担保品卖出",m_strEnumName="担保品卖出,融券卖出,卖券还款",m_strEnumValue="1,2,3",m_strNameKey="m_dSellType",m_strParamsVisible="",m_strParamsUnit="",m_strParamsHidden="0",m_strDefaultByAlgName="",m_strRangeByAlgName="T0_TAOJIN:担保品卖出|融券卖出|卖券还款,T0_FEITU:担保品卖出|融券卖出|卖券还款,T0_QINENGDA:担保品卖出|融券卖出|卖券还款,T0_YUSHU:担保品卖出|卖券还款" },
    },
    m_strategyBrokerLimit={
        {m_nId=1,m_strName="期货账号策略限制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="brokertype",m_strParamsVisible="TWAP,VWAP,VP,MOO,IS",m_strParamsUnit="",m_strParamsHidden="" },
        {m_nId=6,m_strName="股票期权账号策略限制",m_strType= 1,m_strRange="",m_nFlag=0,m_strDefault="",m_strEnumName="",m_strEnumValue="",m_strNameKey="brokertype",m_strParamsVisible="TWAP,VWAP,VP,MOO,IS",m_strParamsUnit="",m_strParamsHidden="" },
    },
    m_strAuthority="mdl_alg_xtalg1",
}