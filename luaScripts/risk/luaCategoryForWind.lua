dofile('../luaScripts/risk/RCUtils.lua')

local function getCon(mysql_conf)
    local res = string.gmatch(mysql_conf, "([^,]+),")
    local ip = res()
    local port = tonumber(res())
    local db = res()
    local user = res()
    local passwd = res()
    local driver = require "luasql.mysql"
    local env = driver.mysql()
    local con = env:connect(db, user, passwd, ip, port)
    return con
end

wind_lua_categories = {
    [35001] = {
        key = "万得-债券评级",
        field = "bondRating",
        types = {
            [35001] = { "AAA", "AAA" },
            [35002] = { "AAA-", "AAA-" },
            [35003] = { "AA+", "AA+" },
            [35004] = { "AA", "AA" },
            [35005] = { "AA-", "AA-" },
            [35006] = { "A+", "A+" },
            [35007] = { "A", "A" },
            [35008] = { "A-", "A-" },
            [35009] = { "BBB+", "BBB+" },
            [35010] = { "BBB", "BBB" },
            [35011] = { "BBB-", "BBB-" },
            [35012] = { "BB+", "BB+" },
            [35013] = { "BB", "BB" },
            [35014] = { "BB-", "BB-" },
            [35015] = { "B+", "B+" },
            [35016] = { "B", "B" },
            [35017] = { "B-", "B-" },
            [35018] = { "CCC", "CCC" },
            [35019] = { "CC", "CC" },
            [35020] = { "D", "D" },
            [35021] = { "A-1+", "A-1+" },
            [35022] = { "A-1", "A-1" },
            [35023] = { "A-1-", "A-1-" },
            [35024] = { "A-2", "A-2" },
            [35025] = { "A-3", "A-3" },
            [35026] = { "C", "C" },
        },
    },

    [35101] = {
        key = "万得-债券分类",
        field = "bondFirstClassification",
        types = {
            [35101] = { "国债", "国债" },
            [35102] = { "金融债", "金融债" },
            [35103] = { "短期融资券", "短期融资券" },
            [35104] = { "央行票据", "央行票据" },
            [35105] = { "定向工具", "定向工具" },
            [35106] = { "企业债", "企业债" },
            [35107] = { "政府支持机构债", "政府支持机构债" },
            [35108] = { "中期票据", "中期票据" },
            [35109] = { "国际机构债", "国际机构债" },
            [35110] = { "资产支持证券", "资产支持证券" },
            [35111] = { "地方政府债", "地方政府债" },
            [35112] = { "可转债", "可转债" },
            [35113] = { "同业存单", "同业存单" },
            [35114] = { "公司债", "公司债" },
            [35115] = { "可分离转债存债", "可分离转债存债" },
            [35121] = { "政策银行债", "政策银行债" },
            [35122] = { "超短期融资债券", "超短期融资债券" },
            [35123] = { "其它金融机构债", "其它金融机构债" },
            [35124] = { "一般企业债", "一般企业债" },
            [35125] = { "集合企业债", "集合企业债" },
            [35126] = { "商业银行次级债券", "商业银行次级债券" },
            [35127] = { "一般短期融资券", "一般短期融资券" },
            [35128] = { "证券公司债", "证券公司债" },
            [35129] = { "商业银行债", "商业银行债" },
            [35130] = { "集合票据", "集合票据" },
            [35131] = { "银监会主管ABS", "银监会主管ABS" },
            [35132] = { "RMBS", "RMBS" },
            [35133] = { "证券公司短期融资券", "证券公司短期融资券" },
            [35134] = { "交易商协会ABN", "交易商协会ABN" },
            [35135] = { "一般中期票据", "一般中期票据" },
            [35136] = { "私募债", "私募债" },
            [35137] = { "一般公司债", "一般公司债" },
            [35138] = { "证监会主管ABS", "证监会主管ABS" },
            [35139] = { "保险公司债", "保险公司债" },
        },
    },

    [35201] = {
        key = "万得-利率类型",
        field = "interestRateType",
        types = {
            [35201] = { "固定利率", "固定利率" },
            [35202] = { "浮动利率", "浮动利率" },
            [35203] = { "累进利率", "累进利率" },
        },
    },

    [35301] = {
        key = "万得-是否城投债",
        field = "isCityDebt",
        types = {
            [35301] = { "是", "是" },
            [35302] = { "否", "否" },
        },
    },

    [35401] = {
        key = "万得-是否次级债",
        field = "isSubordinatedDebt",
        types = {
            [35401] = { "是", "是" },
            [35402] = { "否", "否" },
        },
    },

    [35501] = {
        key = "万得-是否混合资本",
        field = "isHybridCapitalBond",
        types = {
            [35501] = { "是", "是" },
            [35502] = { "否", "否" },
        },
    },

    [35601] = {
        key = "万得-债券上市地点",
        field = "listingLocation",
        types = {
            [35601] = { "银行间", "银行间" },
            [35602] = { "上海", "上海" },
            [35603] = { "银行柜台债券", "银行柜台债券" },
            [35604] = { "其他", "其他" },
            [35605] = { "深圳", "深圳" },
            [35606] = { "浙江股权交易中心", "浙江股权交易中心" },
            [35607] = { "天津股权交易所", "天津股权交易所" },
            [35608] = { "海峡股权交易中心", "海峡股权交易中心" },
            [35609] = { "甘肃股权交易中心", "甘肃股权交易中心" },
            [35610] = { "江苏股权交易中心", "江苏股权交易中心" },
            [35611] = { "新疆股权交易中心", "新疆股权交易中心" },
            [35612] = { "北京股权交易中心", "北京股权交易中心" },
            [35613] = { "齐鲁股权交易中心", "齐鲁股权交易中心" },
            [35614] = { "辽宁股权交易中心", "辽宁股权交易中心" },
            [35615] = { "重庆股份转让中心", "重庆股份转让中心" },
            [35616] = { "前海股权交易中心", "前海股权交易中心" },
            [35617] = { "武汉金融资产交易所", "武汉金融资产交易所" },
            [35618] = { "上海股权托管交易中心", "上海股权托管交易中心" },
        },
    },

    [35701] = {
        key = "万得-是否增发",
        field = "isAdditionDebt",
        types = {
            [35701] = { "是", "是"},
            [35702] = { "否", "否" },
        },
    },

    [35801] = {
        key = "万得-债券发行方式",
        field = "issuingMode",
        types = {
            [35801] = { "公募", "公募" },
            [35802] = { "采用价格招投标方式发行", "采用价格招投标方式发行"},
            [35803] = { "采用基本利差招投标方式发行", "采用基本利差招投标方式发行" },
            [35804] = { "采用利率招投标方式发行", "采用利率招投标方式发行" },
            [35805] = { "通过承销团竞价投标，定向发行", "通过承销团竞价投标，定向发行" },
            [35806] = { "以招标方式发行", "以招标方式发行" },
            [35807] = { "以招标发行", "以招标发行" },
            [35808] = { "以价格招标贴现发行", "以价格招标贴现发行" },
            [35809] = { "以竞争性价格招标方式发行", "以竞争性价格招标方式发行" },
            [35810] = { "平价发行", "平价发行" },
            [35811] = { "贴现价格招标", "贴现价格招标" },
            [35812] = { "票面利率招标", "票面利率招标" },
            [35813] = { "价格招标", "价格招标" },
            [35814] = { "采用单一基本利差招标方式", "采用单一基本利差招标方式" },
            [35815] = { "采用贴现、多重价格中标（美国式）的招标方式", "采用贴现、多重价格中标（美国式）的招标方式" },
            [35816] = { "采用价格(折价)招投标方式发行", "采用价格(折价)招投标方式发行" },
            [35817] = { "采用价格（贴现）招投标方式发行", "采用价格（贴现）招投标方式发行" },
            [35818] = { "单一利率招标", "单一利率招标" },
            [35819] = { "以价格招标方式贴现发行", "以价格招标方式贴现发行"},
            [35820] = { "通过承销团竞价投标,定向发行", "通过承销团竞价投标,定向发行" },
            [35821] = { "簿记建档", "簿记建档" },
            [35822] = { "贴现发行", "贴现发行" },
            [35823] = { "价格（贴现）招投标方式", "价格（贴现）招投标方式" },
            [35824] = { "利率招投标方式发行", "利率招投标方式发行" },
            [35825] = { "私募", "私募" },
            [35826] = { "公开发行", "公开发行" },
            [35827] = { "网下发行", "网下发行" },
            [35828] = { "定向", "定向" },
            [35829] = { "上网定价", "上网定价" },
            [35830] = { "定向配售，网上定价", "定向配售，网上定价" },
            [35831] = { "上网定价和网下配售", "上网定价和网下配售" },
            [35832] = { "优先配售，网上定价和网下配售", "优先配售，网上定价和网下配售" },
            [35833] = { "优先配售和上网定价", "优先配售和上网定价" },
            [35834] = { "优先配售，网下配售", "优先配售，网下配售" },
            [35835] = { "网上发行", "网上发行" },
            [35836] = { "包销团包销", "包销团包销" },
            [35837] = { "优先配售，定向配售和网上定价", "优先配售，定向配售和网上定价" },
            [35838] = { "采取利率招标的方式发行", "采取利率招标的方式发行" },
        },
    },

    [35901] = {
        key = "万得-基金类型",
        field = "fundType",
        types = {
            [35901] = { "契约型开放式", "契约型开放式" },
            [35902] = { "契约型封闭式", "契约型封闭式" },
        },
    },

    [36001] = {
        key = "万得-投资类型(一级分类)",
        field = "investTypeFirstClass",
        types = {
            [36001] = { "混合型基金", "混合型基金" },
            [36002] = { "债券型基金", "债券型基金" },
            [36003] = { "股票型基金", "股票型基金" },
            [36004] = { "货币市场型基金", "货币市场型基金" },
            [36005] = { "国际(QDII)基金", "国际(QDII)基金" },
            [36006] = { "另类投资基金", "另类投资基金" },
            [36007] = { "其它类基金", "其它类基金" },
        },
    },

    [36101] = {
        key = "万得-投资类型(二级分类)",
        field = "investTypeSecondClass",
        types = {
            [36101] = { "偏股混合型基金", "偏股混合型基金" },
            [36102] = { "混合债券型二级基金", "混合债券型二级基金" },
            [36103] = { "中长期纯债型基金", "中长期纯债型基金" },
            [36104] = { "被动指数型基金", "被动指数型基金" },
            [36105] = { "货币市场型基金", "货币市场型基金" },
            [36106] = { "混合债券型一级基金", "混合债券型一级基金" },
            [36107] = { "普通股票型基金", "普通股票型基金" },
            [36108] = { "混合型被动指数型债券基金基金", "混合型被动指数型债券基金基金" },
            [36109] = { "偏债混合型基金", "偏债混合型基金" },
            [36110] = { "灵活配置型基金", "灵活配置型基金" },
            [36111] = { "国际(QDII)股票型基金", "国际(QDII)股票型基金" },
            [36112] = { "增强指数型基金", "增强指数型基金" },
            [36113] = { "短期纯债型基金", "短期纯债型基金" },
            [36114] = { "国际(QDII)债券型基金", "国际(QDII)债券型基金" },
            [36115] = { "国际(QDII)另类投资基金", "国际(QDII)另类投资基金" },
            [36116] = { "宏观策略", "宏观策略" },
            [36117] = { "股票多空", "股票多空" },
            [36118] = { "平衡混合型基金", "平衡混合型基金" },
            [36119] = { "国际(QDII)混合型基金", "国际(QDII)混合型基金" },
            [36120] = { "REITs", "REITs" },
            [36121] = { "增强指数型债券基金", "增强指数型债券基金" },
            [36122] = { "封闭式基金", "封闭式基金" },
            [36123] = { "其他另类投资基金", "其他另类投资基金" },
            [36124] = { "事件驱动", "事件驱动" },
            [36125] = { "另类投资基金", "另类投资基金" },
            [36126] = { "相对价值", "相对价值" },
        },
    },
    [36201] = {
        key = "万得-基金投资风格",
        field = "investStyle",
        types = {
            [36201] = { "成长型", "成长型" },
            [36202] = { "债券型", "债券型" },
            [36203] = { "被动指数型", "被动指数型" },
            [36204] = { "货币型", "货币型" },
            [36205] = { "增值型", "增值型" },
            [36206] = { "股票型", "股票型" },
            [36207] = { "保本混合型", "保本混合型" },
            [36208] = { "灵活配置型", "灵活配置型" },
            [36209] = { "增长型", "增长型" },
            [36210] = { "增强指数型", "增强指数型" },
            [36211] = { "混合型", "混合型" },
            [36212] = { "黄金现货合约", "黄金现货合约" },
            [36213] = { "增强型", "增强型" },
            [36214] = { "稳健增长型", "稳健增长型" },
            [36215] = { "平衡型", "平衡型" },
            [36216] = { "保本增值型", "保本增值型" },
            [36217] = { "创新型", "创新型" },
            [36218] = { "优选增长型", "优选增长型" },
            [36219] = { "强化收益型", "强化收益型" },
            [36220] = { "价值型", "价值型" },
            [36221] = { "稳定增值型", "稳定增值型" },
            [36222] = { "增强回报型", "增强回报型" },
            [36223] = { "成长收益复合型", "成长收益复合型" },
            [36224] = { "稳健型", "稳健型" },
            [36225] = { "收益型", "收益型" },
            [36226] = { "积极配置型", "积极配置型" },
            [36227] = { "积极成长型", "积极成长型" },
            [36228] = { "增强债券型", "增强债券型" },
            [36229] = { "优化增强型", "优化增强型" },
            [36230] = { "稳定型", "稳定型" },
            [36231] = { "主题型", "主题型" },
            [36232] = { "周期型", "周期型" },
            [36233] = { "行业型", "行业型" },
            [36234] = { "科技型", "科技型" },
            [36235] = { "增利型", "增利型" },
            [36236] = { "积极型", "积极型" },
            [36237] = { "增强收益型", "增强收益型" },
            [36238] = { "价值成长型", "价值成长型" },
            [36239] = { "价值增长型", "价值增长型" },
            [36240] = { "灵活配置", "灵活配置" },
            [36241] = { "平稳型", "平稳型" },
            [36242] = { "优选稳健型", "优选稳健型" },
        },
    },

    [36301] = {
        key = "万得-股票种类",
        field = "stockClasses",
        types = {
            [36301] = { "A股", "A股" },
            [36302] = { "B股", "B股" },
            [36303] = { "三板股", "三板股" },
        },
    },

    [36401] = {
        key = "万得-股票上市版",
        field = "listedSection",
        types = {
            [36401] = { "主板", "主板" },
            [36402] = { "中小企业板", "中小企业板" },
            [36403] = { "创业板", "创业板" },
            [36404] = { "三板", "三板" },
        },
    },

    [36501] = {
        key = "万得-股票上市地点",
        field = "listedLocation",
        types = {
            [36501] = { "齐鲁股权交易中心", "齐鲁股权交易中心" },
            [36502] = { "山西股权交易中心", "山西股权交易中心" },
            [36503] = { "深圳", "深圳" },
            [36504] = { "天津股权交易所", "天津股权交易所" },
            [36505] = { "吉林股权交易所", "吉林股权交易所" },
            [36506] = { "湖南股权交易所", "湖南股权交易所" },
            [36507] = { "成都股权托管中心", "成都股权托管中心" },
            [36508] = { "甘肃股权交易中心", "甘肃股权交易中心" },
            [36509] = { "武汉股权托管交易中心", "武汉股权托管交易中心" },
            [36510] = { "上海股权托管交易中心", "上海股权托管交易中心" },
            [36511] = { "海峡股权交易中心", "海峡股权交易中心" },
            [36512] = { "三板", "三板" },
            [36513] = { "上海", "上海" },
            [36514] = { "石家庄股权交易中心", "石家庄股权交易中心" },
            [36515] = { "青海股权交易中心", "青海股权交易中心" },
            [36516] = { "新疆股权交易中心", "新疆股权交易中心" },
            [36517] = { "前海股权交易中心", "前海股权交易中心" },
            [36518] = { "江苏股权交易中心", "江苏股权交易中心" },
            [36519] = { "重庆股份转让中心", "重庆股份转让中心" },
            [36520] = { "青岛蓝海股权交易中心", "青岛蓝海股权交易中心" },
            [36521] = { "安徽省股权托管交易中心", "安徽省股权托管交易中心" },
            [36522] = { "浙江股权交易中心", "浙江股权交易中心" },
            [36523] = { "广州股权交易中心", "广州股权交易中心" },
            [36524] = { "辽宁股权交易中心", "辽宁股权交易中心" },
        },
    },

    [36601] = {
        key = "万得-证券评估机构",
        field = "listedLocation",
        types = {
            [36601] = { "大公国际资信评估有限公司", "大公国际资信评估有限公司" },
            [36602] = { "中诚信国际信用评级有限责任公司", "中诚信国际信用评级有限责任公司" },
            [36603] = { "联合资信评估有限公司", "联合资信评估有限公司" },
            [36604] = { "上海新世纪资信评估投资服务有限公司", "上海新世纪资信评估投资服务有限公司" },
            [36605] = { "鹏元资信评估有限公司", "鹏元资信评估有限公司" },
        },
    },
    
    [36701] = {
        key = "万得-是否含权债",
        field = "isBondOpt",
        types = {
            [36701] = {"是", "是"},
            [36702] = {"否", "否"},
        },
    },
}

function getLuaCategoryForWind()
    local categories = {}
    for index, subTable in pairs(wind_lua_categories) do
        local typesTable = subTable["types"]
        for id, desc in pairs(typesTable) do
            table.insert(categories, id)
        end
    end
    return categories
end

function getLuaCategoryInfoForWind(category_id)
    local index = category_id - (category_id % 100) + 1
    local subTable = wind_lua_categories[index]
    if subTable then
        local key = subTable["key"]
        local typesTable = subTable["types"]
        if key and typesTable and typesTable[category_id] then
            key = key .. ":" .. typesTable[category_id][1]
            return { category_id, key, 0 }
        end
    end
    return { category_id, "", 0 }
end

function isStockInMetadataWindTable(metadataWind, market, code, category_id)
    local index = category_id - (category_id % 100) + 1
    local subTable = wind_lua_categories[index]
    -- rcprintDebugLog(string.format("isStockInMetadataCaihuiTable:  market=%s, code=%s, category_id=%s, index=%s", tostring(market), tostring(code), tostring(category_id), tostring(index)))
    if subTable then
        local fieldName = subTable["field"]
        local typesTable = subTable["types"]
        if fieldName and metadataWind and metadataWind[code] and metadataWind[code][fieldName] and typesTable and typesTable[category_id] then
            local v = metadataWind[code][fieldName]
            -- rcprintDebugLog(string.format("isStockInMetadataCaihuiTable: v = %s, typesTable[category_id][2] = %s", tostring(v), tostring(typesTable[category_id][2])))
            if filedName == "duration_mod" then   --债券久期范围需要特殊处理，不要直接相等
                -- rcprintDebugLog(string.format("isStockInMetadataCaihuiTable: duration_mod=%s", tostring(v)))
                return (tonumber(v) <= tonumber(typesTable[category_id][2]) and tonumber(v) >= 0)
            elseif tostring(v) == tostring(typesTable[category_id][2]) then
                -- rcprintDebugLog(string.format("isStockInMetadataCaihuiTable: %s belongs to %s", tostring(code), tostring(category_id)))
            end
            return tostring(v) == tostring(typesTable[category_id][2])
        end
    end
    return false
end

function initIssueData_wind(mysql_conf, isSys)
    local issueData = {}
    local secuCode
    local issueId
    local issueName
    local con = getCon(mysql_conf)
    if nil == con then
        return issueData
    end
    local strQuery = string.format("select stockMarket, secuCode, issueID, issueName from account_metadata_wind where isSys = %s;", tostring(isSys))
    con:execute[[set names utf8]]
    local cur = con:execute(strQuery)
    if cur ~= nil then
        local rowNum = cur:numrows()
        if rowNum <= 0 then
            con:close()
            return issueData
        end
        for i=1, rowNum, 1 do 
            local row = cur:fetch({}, "n")
            if row[1] ~= nil and row[2] ~= nil then
                secuCode = tostring(row[1]) .. tostring(row[2])   --market + code
                if row[3] ~= nil then
                    issueId = tostring(row[3])
                else
                    issueId = "null"
                end
                if row[4] ~= nil then
                    issueName = tostring(row[4])
                else
                    issueName = "null"
                end
                if secuCode and not issueData[secuCode] then
                    issueData[secuCode] = {}
                end
                issueData[secuCode]["issueID"] = issueId
                issueData[secuCode]["issueName"] = issueName
            end
        end
        cur:close()
    end
    con:close()
    return issueData
end

function initCodeData(mysql_conf, isSys) 
    local codeData = {}
    local secuCode
    local remainYear
    local modifiedduration
    local con = getCon(mysql_conf)
    if nil == con then
        return codeData
    end
    local strQuery = string.format("select stockMarket, secuCode, remainYear, modifiedduration, isBondOpt, exerciseDuration from account_metadata_wind where isSys = %s;", tostring(isSys))
    con:execute[[set names utf8]]
    local cur = con:execute(strQuery)
    if cur ~= nil then
        local rowNum = cur:numrows()
        if rowNum <= 0 then
            con:close()
            return codeData
        end
        for i=1, rowNum, 1 do
            local row = cur:fetch({}, "n")
            if row[1] ~= nil and row[2] ~= nil then
                secuCode = tostring(row[1]) .. tostring(row[2])  -- market + code
                
                if row[3] ~= nil then
                    remainYear = tostring(row[3])
                else 
                    remainYear = "null"
                end
                if row[4] ~= nil then 
                    modifiedduration = tostring(row[4])
                else
                    modifiedduration = "null"
                end
                if secuCode and not codeData[secuCode] then
                    codeData[secuCode] = {}
                end
                
                if row[5] == 'true' then
                    if row[6] ~= nil then
                        local exerciseDuration = tostring(row[6])
                        codeData[secuCode]["modifiedduration"] = exerciseDuration
                    else
                        codeData[secuCode]["modifiedduration"] = "null"
                    end
                else
                    codeData[secuCode]["modifiedduration"] = modifiedduration
                end
                codeData[secuCode]["remainYear"] = remainYear
                
            end
        end
        cur:close()
    end
    con:close()
    return codeData
end

function initPurchaseStartDate(mysql_conf, is_sys)
    local codeData = {}
    local secuCode
    local purchaseStartDate
    local con = getCon(mysql_conf)
    if nil == con then
        return codeData
    end
    local strQuery = string.format("select stockMarket, secuCode, purchaseStartDate from account_metadata_wind;")
    con:execute[[set names utf8]]
    local cur = con:execute(strQuery)
    if cur ~= nil then
        local rowNum = cur:numrows()
        if rowNum <= 0 then
            con:close()
            return codeData
        end
        for i=1, rowNum, 1 do
            local row = cur:fetch({}, "n")
            if row[1] ~= nil and row[2] ~= nil then
                secuCode = tostring(row[1]) .. tostring(row[2])  -- market + code
                if row[3] ~= nil then
                    purchaseStartDate = tostring(row[3])
                else 
                    purchaseStartDate = "null"
                end
                if secuCode and not codeData[secuCode] then
                    codeData[secuCode] = {}
                end
                codeData[secuCode]["purchaseStartDate"] = purchaseStartDate
            end
        end
        cur:close()
    end
    con:close()
    return codeData
end
    
function queryHGTVersusStock_wind(mysql_conf)
    local con = getCon(mysql_conf)
    local strQuery = "select A.stockMarket, A.secuCode, B.stockMarket, B.secuCode from account_metadata_wind A, account_metadata_wind B where A.secuType = 3 and B.secuType = 5 and (A.stockMarket = 'SH' or A.stockMarket = 'SZ') and B.stockMarket = 'HK' and A.issueName = B.issueName;"
    con:execute[[set names utf8]]
    local cur, errDBMsg = con:execute(strQuery)
    if errDBMsg ~= nil then
        con:close()
        error(errDBMsg)
    end
    AtoHStock = {}
    HtoAStock = {}
    local rowNum = cur:numrows()
    for i = 1, rowNum, 1 do
        local row = cur:fetch({}, "n")
        if row[1] ~= nil and row[2] ~= nil and row[3] ~= nil and row[4] ~= nil then
            AMarket = row[1]
            if "HK" == AMarket then
                AMarket = "HGT"
            end
            AStockKey = AMarket .. row[2]
            HMarket = row[3]
            if "HK" == HMarket then
                HMarket = "HGT"
            end
            HStockKey = HMarket .. row[4]
            table.insert(AtoHStock, AStockKey)
            table.insert(AtoHStock, HStockKey)
            table.insert(HtoAStock, HStockKey)
            table.insert(HtoAStock, AStockKey)
        end
    end
    con:close()
    return table2json({AtoH = AtoHStock, HtoA = HtoAStock})
end