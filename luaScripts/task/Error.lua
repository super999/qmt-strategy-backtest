-- 通用错误定义
TRADE_COMMON_ERROR = 10004

-- CTP错误定义
CTP_NONE                                       = 0 -- 综合交易平台：正确
CTP_INVALID_DATA_SYNC_STATUS                   = 1 -- 综合交易平台：不在已同步状态
CTP_INCONSISTENT_INFORMATION                   = 2 -- 综合交易平台：会话信息不一致
CTP_INVALID_LOGIN                              = 3 -- 综合交易平台：不合法的登录
CTP_USER_NOT_ACTIVE                            = 4 -- 综合交易平台：用户不活跃
CTP_DUPLICATE_LOGIN                            = 5 -- 综合交易平台：重复的登录
CTP_NOT_LOGIN_YET                              = 6 -- 综合交易平台：还没有登录
CTP_NOT_INITED                                 = 7 -- 综合交易平台：还没有初始化
CTP_FRONT_NOT_ACTIVE                           = 8 -- 综合交易平台：前置不活跃
CTP_NO_PRIVILEGE                               = 9 -- 综合交易平台：无此权限
CTP_CHANGE_OTHER_PASSWORD                      = 10 -- 综合交易平台：修改别人的口令
CTP_USER_NOT_FOUND                             = 11 -- 综合交易平台：找不到该用户
CTP_BROKER_NOT_FOUND                           = 12 -- 综合交易平台：找不到该经纪公司
CTP_INVESTOR_NOT_FOUND                         = 13 -- 综合交易平台：找不到投资者
CTP_OLD_PASSWORD_MISMATCH                      = 14 -- 综合交易平台：原口令不匹配
CTP_BAD_FIELD                                  = 15 -- 综合交易平台：报单字段有误
CTP_INSTRUMENT_NOT_FOUND                       = 16 -- 综合交易平台：找不到合约
CTP_INSTRUMENT_NOT_TRADING                     = 17 -- 综合交易平台：合约不能交易
CTP_NOT_EXCHANGE_PARTICIPANT                   = 18 -- 综合交易平台：经纪公司不是交易所的会员
CTP_INVESTOR_NOT_ACTIVE                        = 19 -- 综合交易平台：投资者不活跃
CTP_NOT_EXCHANGE_CLIENT                        = 20 -- 综合交易平台：投资者未在交易所开户
CTP_NO_VALID_TRADER_AVAILABLE                  = 21 -- 综合交易平台：该交易席位未连接到交易所
CTP_DUPLICATE_ORDER_REF                        = 22 -- 综合交易平台：报单错误：不允许重复报单
CTP_BAD_ORDER_ACTION_FIELD                     = 23 -- 综合交易平台：错误的报单操作字段
CTP_DUPLICATE_ORDER_ACTION_REF                 = 24 -- 综合交易平台：撤单已报送，不允许重复撤单
CTP_ORDER_NOT_FOUND                            = 25 -- 综合交易平台：撤单找不到相应报单
CTP_INSUITABLE_ORDER_STATUS                    = 26 -- 综合交易平台：报单已全成交或已撤销，不能再撤
CTP_UNSUPPORTED_FUNCTION                       = 27 -- 综合交易平台：不支持的功能
CTP_NO_TRADING_RIGHT                           = 28 -- 综合交易平台：没有报单交易权限
CTP_CLOSE_ONLY                                 = 29 -- 综合交易平台：只能平仓
CTP_OVER_CLOSE_POSITION                        = 30 -- 综合交易平台：平仓量超过持仓量
CTP_INSUFFICIENT_MONEY                         = 31 -- 综合交易平台：资金不足
CTP_DUPLICATE_PK                               = 32 -- 综合交易平台：主键重复
CTP_CANNOT_FIND_PK                             = 33 -- 综合交易平台：找不到主键
CTP_CAN_NOT_INACTIVE_BROKER                    = 34 -- 综合交易平台：设置经纪公司不活跃状态失败
CTP_BROKER_SYNCHRONIZING                       = 35 -- 综合交易平台：经纪公司正在同步
CTP_BROKER_SYNCHRONIZED                        = 36 -- 综合交易平台：经纪公司已同步
CTP_SHORT_SELL                                 = 37 -- 综合交易平台：现货交易不能卖空
CTP_INVALID_SETTLEMENT_REF                     = 38 -- 综合交易平台：不合法的结算引用
CTP_CFFEX_NETWORK_ERROR                        = 39 -- 综合交易平台：中金所网络连接失败
CTP_CFFEX_OVER_REQUEST                         = 40 -- 综合交易平台：中金所未处理请求超过许可数
CTP_CFFEX_OVER_REQUEST_PER_SECOND              = 41 -- 综合交易平台：中金所每秒发送请求数超过许可数
CTP_SETTLEMENT_INFO_NOT_CONFIRMED              = 42 -- 综合交易平台：结算结果未确认
CTP_DEPOSIT_NOT_FOUND                          = 43 -- 综合交易平台：没有对应的入金记录
CTP_EXCHANG_TRADING                            = 44 -- 综合交易平台：交易所已经进入连续交易状态
CTP_PARKEDORDER_NOT_FOUND                      = 45 -- 综合交易平台：找不到预埋（撤单）单
CTP_PARKEDORDER_HASSENDED                      = 46 -- 综合交易平台：预埋（撤单）单已经发送
CTP_PARKEDORDER_HASDELETE                      = 47 -- 综合交易平台：预埋（撤单）单已经删除
CTP_INVALID_INVESTORIDORPASSWORD               = 48 -- 综合交易平台：无效的投资者或者密码
CTP_INVALID_LOGIN_IPADDRESS                    = 49 -- 综合交易平台：不合法的登录IP地址
CTP_OVER_CLOSETODAY_POSITION                   = 50 -- 综合交易平台：平今仓位不足
CTP_OVER_CLOSEYESTERDAY_POSITION               = 51 -- 综合交易平台：平昨仓位不足
CTP_BROKER_NOT_ENOUGH_CONDORDER                = 52 -- 综合交易平台：经纪公司没有足够可用的条件单数量
CTP_INVESTOR_NOT_ENOUGH_CONDORDER              = 53 -- 综合交易平台：投资者没有足够可用的条件单数量
CTP_BROKER_NOT_SUPPORT_CONDORDER               = 54 -- 综合交易平台：经纪公司不支持条件单
CTP_RESEND_ORDER_BROKERINVESTOR_NOTMATCH       = 55 -- 综合交易平台：重发未知单经济公司/投资者不匹配
CTP_MARKET_CLOSED                              = 100 -- 交易市场状态停止
CTP_TIME_NO_ENTRUSTING                         = 101 -- 当前时间不允许委托
CTP_SEND_INSTITUTION_CODE_ERROR                = 1000 -- 银期转账：发送机构代码错误
CTP_NO_GET_PLATFORM_SN                         = 1001 -- 银期转账：取平台流水号错误
CTP_ILLEGAL_TRANSFER_BANK                      = 1002 -- 银期转账：不合法的转账银行
CTP_ALREADY_OPEN_ACCOUNT                       = 1003 -- 银期转账：已经开户
CTP_NOT_OPEN_ACCOUNT                           = 1004 -- 银期转账：未开户
CTP_PROCESSING                                 = 1005 -- 银期转账：处理中
CTP_OVERTIME                                   = 1006 -- 银期转账：交易超时
CTP_RECORD_NOT_FOUND                           = 1007 -- 银期转账：找不到记录
CTP_NO_FOUND_REVERSAL_ORIGINAL_TRANSACTION     = 1008 -- 银期转账：找不到被冲正的原始交易
CTP_CONNECT_HOST_FAILED                        = 1009 -- 银期转账：连接主机失败
CTP_SEND_FAILED                                = 1010 -- 银期转账：发送失败
CTP_LATE_RESPONSE                              = 1011 -- 银期转账：迟到应答
CTP_REVERSAL_BANKID_NOT_MATCH                  = 1012 -- 银期转账：冲正交易银行代码错误
CTP_REVERSAL_BANKACCOUNT_NOT_MATCH             = 1013 -- 银期转账：冲正交易银行账户错误
CTP_REVERSAL_BROKERID_NOT_MATCH                = 1014 -- 银期转账：冲正交易经纪公司代码错误
CTP_REVERSAL_ACCOUNTID_NOT_MATCH               = 1015 -- 银期转账：冲正交易资金账户错误
CTP_REVERSAL_AMOUNT_NOT_MATCH                  = 1016 -- 银期转账：冲正交易交易金额错误
CTP_DB_OPERATION_FAILED                        = 1017 -- 银期转账：数据库操作错误
CTP_SEND_ASP_FAILURE                           = 1018 -- 银期转账：发送到交易系统失败
CTP_NOT_SIGNIN                                 = 1019 -- 银期转账：没有签到
CTP_ALREADY_SIGNIN                             = 1020 -- 银期转账：已经签到
CTP_AMOUNT_OR_TIMES_OVER                       = 1021 -- 银期转账：金额或次数超限
CTP_NOT_IN_TRANSFER_TIME                       = 1022 -- 银期转账：这一时间段不能转账
CTP_BANK_SERVER_ERROR                          = 1023 -- 银行主机错
CTP_BANK_SERIAL_IS_REPEALED                    = 1024 -- 银期转账：银行已经冲正
CTP_BANK_SERIAL_NOT_EXIST                      = 1025 -- 银期转账：银行流水不存在
CTP_NOT_ORGAN_MAP                              = 1026 -- 银期转账：机构没有签约
CTP_EXIST_TRANSFER                             = 1027 -- 银期转账：存在转账，不能销户
CTP_BANK_FORBID_REVERSAL                       = 1028 -- 银期转账：银行不支持冲正
CTP_DUP_BANK_SERIAL                            = 1029 -- 银期转账：重复的银行流水
CTP_FBT_SYSTEM_BUSY                            = 1030 -- 银期转账：转账系统忙，稍后再试
CTP_MACKEY_SYNCING                             = 1031 -- 银期转账：MAC密钥正在同步
CTP_ACCOUNTID_ALREADY_REGISTER                 = 1032 -- 银期转账：资金账户已经登记
CTP_BANKACCOUNT_ALREADY_REGISTER               = 1033 -- 银期转账：银行账户已经登记
CTP_DUP_BANK_SERIAL_REDO_OK                    = 1034 -- 银期转账：重复的银行流水,重发成功
CTP_NO_VALID_BANKOFFER_AVAILABLE               = 2000 -- 综合交易平台：该报盘未连接到银行
CTP_PASSWORD_MISMATCH                          = 2001 -- 综合交易平台：资金密码错误
CTP_DUPLATION_BANK_SERIAL                      = 2004 -- 综合交易平台：银行流水号重复
CTP_DUPLATION_OFFER_SERIAL                     = 2005 -- 综合交易平台：报盘流水号重复
CTP_SERIAL_NOT_EXSIT                           = 2006 -- 综合交易平台：被冲正流水不存在(冲正交易)
CTP_SERIAL_IS_REPEALED                         = 2007 -- 综合交易平台：原流水已冲正(冲正交易)
CTP_SERIAL_MISMATCH                            = 2008 -- 综合交易平台：与原流水信息不符(冲正交易)
CTP_IdentifiedCardNo_MISMATCH                  = 2009 -- 综合交易平台：证件号码或类型错误
CTP_ACCOUNT_NOT_FUND                           = 2011 -- 综合交易平台：资金账户不存在
CTP_ACCOUNT_NOT_ACTIVE                         = 2012 -- 综合交易平台：资金账户已经销户
CTP_NOT_ALLOW_REPEAL_BYMANUAL                  = 2013 -- 综合交易平台：该交易不能执行手工冲正
CTP_AMOUNT_OUTOFTHEWAY                         = 2014 -- 综合交易平台：转帐金额错误
CTP_WAITING_OFFER_RSP                          = 999999 -- 综合交易平台：等待银期报盘处理结果

-- 金证股票错误定义
INVS_ERR_COMMUNICATION            = 101 -- 通讯错误
INVS_ERR_NOT_CHECK_IN           = 110 -- 尚未签入系统
INVS_ERR_NO_SUBSEQUENT_PACK     = 111 -- 无后续数据包
INVS_ERR_LOGIN_FAILED           = 301 -- 帐户登录失败
INVS_ERR_ACC_STATUS_INVALID     = 302 -- 您的帐户状态不正常
INVS_ERR_CARD_INEXIST           = 303 -- 磁卡号不存在
INVS_ERR_SECU_ACC_INEXIST       = 304 -- 股东代码不存在
INVS_ERR_FUND_ACC_INEXIST       = 305 -- 资产帐号不存在
INVS_ERR_USER_CODE_INEXIST      = 306 -- 用户代码不存在
INVS_ERR_MARKET_INEXIST         = 307 -- 交易市场不存在
INVS_ERR_MOD_PWD_FAILED         = 308 -- 修改密码失败
INVS_ERR_PASSWORD               = 309 -- 密码错误
INVS_ERR_OPER_FAILED            = 310 -- 操作失败
INVS_ERR_EXT_INST_INEXIST       = 311 -- 外部机构不存在
INVS_ERR_BANK_PWD               = 312 -- 银行密码错
INVS_ERR_WRONG_PASSWORD         = 313 -- 密码有误
INVS_ERR_SECU_INEXIST           = 401 -- 此股票不存在
INVS_ERR_TRADE_UNDO             = 402 -- 您未作指定交易
INVS_ERR_INVALID_ENTRUST_TYPE   = 403 -- 此股不能进行此类委托
INVS_ERR_ENTRUST_FAILED         = 404 -- 委托失败
INVS_ERR_INSUFF_ENBALE_FUND     = 405 -- 可用金额不足
INVS_ERR_INSUFF_SECU_AMT        = 406 -- 股票余额不足
INVS_ERR_ORDER_NOT_FOUND        = 420 -- 无此委托
INVS_ERR_CANT_NOT_CANCEL        = 421 -- 此委托不能撤单
INVS_ERR_ORDER_CANCELD          = 422 -- 此委托已撤单
INVS_ERR_NO_RECORDS             = 501 -- 无查询结果
INVS_ERR_QUERY_FAILED           = 502 -- 查询失败
INVS_ERR_TRSF_NOT_OPEN          = 601 -- 未开通银行转帐业务
INVS_ERR_BANK_TRST_NOT_OPEN     = 602 -- 未开通此银行转帐业务
INVS_ERR_BANK_WITHOUT_TRSF      = 603 -- 该银行尚未开通该项业务
INVS_ERR_BANK_INEXIST           = 605 -- 银行不存在
INVS_ERR_TRSF_FAILED            = 604 -- 转帐失败
INVS_ERR_INVEST_NOT_OPEN        = 701 -- 未开通存折炒股业务
INVS_ERR_RESET_COST_FAILED      = 801 -- 重置成本失败
INVS_ERR_OTHERS                 = 999 -- 其它错误

-- 股票通用错误号
ERR_CONNECTION             = 10 -- 连接错误
ERR_INVALID_DATA           = 11 -- 无效数据
ERR_FUNC_UNDEF             = 12 -- 未定义功能，尚不支持 
ERR_PROTOCOL_CONVERT       = 13 -- 协议转换错误
ERR_SESSION_INEXIST        = 14 -- 会话不存在
ERR_NOT_LOGIN              = 15 -- 账号未登录
ERR_DISCONNECTED_SECU      = 16 -- 至券商连接断开
ERR_INVALID_PARAM          = 17 -- 无效参数（解析有误）

ERR_COMMUNICATION          = 101 -- 通讯错误
ERR_NOT_CHECK_IN           = 110 -- 尚未签入系统
ERR_NO_SUBSEQUENT_PACK     = 111 -- 无后续数据包
ERR_LOGIN_FAILED           = 301 -- 帐户登录失败
ERR_ACC_STATUS_INVALID     = 302 -- 您的帐户状态不正常
ERR_CARD_INEXIST           = 303 -- 磁卡号不存在
ERR_SECU_ACC_INEXIST       = 304 -- 股东代码不存在
ERR_FUND_ACC_INEXIST       = 305 -- 资产帐号不存在
ERR_USER_CODE_INEXIST      = 306 -- 用户代码不存在
ERR_MARKET_INEXIST         = 307 -- 交易市场不存在
ERR_MOD_PWD_FAILED         = 308 -- 修改密码失败
ERR_PASSWORD               = 309 -- 密码错误
ERR_OPER_FAILED            = 310 -- 操作失败
ERR_EXT_INST_INEXIST       = 311 -- 外部机构不存在
ERR_BANK_PWD               = 312 -- 银行密码错
ERR_PWD_INVALID            = 313 -- 密码有误
ERR_NO_AUTHORITY           = 314 -- 无此权限
ERR_ACCT_INEXIST           = 315 -- 无此账号(通用账号)
ERR_SECU_INEXIST           = 401 -- 此股票不存在
ERR_TRADE_UNDO             = 402 -- 您未作指定交易
ERR_INVALID_ENTRUST_TYPE   = 403 -- 此股不能进行此类委托
ERR_ENTRUST_FAILED         = 404 -- 委托失败,特别的，恒生系的所有委托失败都会到这个错误，包括未做指定
ERR_INSUFF_ENBALE_FUND     = 405 -- 可用金额不足
ERR_INSUFF_SECU_VOL        = 406 -- 股票余量不足
ERR_STOCK_SUSPENDED        = 407 -- 股票停牌  // new
ERR_MARKET_CLOSED          = 408 -- 已闭市
ERR_INVALID_PRICE          = 409 -- 委托价格超过涨跌停范围
ERR_ORDER_NOT_FOUND        = 420 -- 无此委托
ERR_NO_CANCEL              = 421 -- 此委托不能撤单
ERR_ORDER_CANCELD          = 422 -- 此委托已撤单
ERR_NO_RECORDS             = 501 -- 无查询结果
ERR_QUERY_FAILED           = 502 -- 查询失败
ERR_TRSF_NOT_OPEN          = 601 -- 未开通银行转帐业务
ERR_BANK_TRST_NOT_OPEN     = 602 -- 未开通此银行转帐业务
ERR_BANK_WITHOUT_TRSF      = 603 -- 该银行尚未开通该项业务
ERR_BANK_INEXIST           = 605 -- 银行不存在
ERR_TRSF_FAILED            = 604 -- 转帐失败
ERR_INVEST_NOT_OPEN        = 701 -- 未开通存折炒股业务
ERR_RESET_COST_FAILED      = 801 -- 重置成本失败

ERR_OTHERS                 = 999 -- 其它错误    

ERR_AGENT_REQ_PARAM         = 10000 --agent错误
ERR_AGENT_SESSION_NOT_FOUND = 10001 --agent错误
ERR_AGENT_DISCONNECTED      = 10002 --agent错误
ERR_AGENT_REQUEST_FAILED    = 10003 --agent错误
ERR_AGENT_SEND_DATA         = 10004 --agent错误
ERR_AGENT_RECV_DATA         = 10005 --agent错误
ERR_CRC_CHECK               = 10006 --agent错误
ERR_AGENT_OTHERS            = 11000 --agent错误

ERR_CHINAGALAXY_NOT_ENOUGH_MONEY            = -150906130   -- 银河证券可用资金不足
ERR_CHINAGALAXY_NOT_ENOUGH_MONEY1           = -620001334
ERR_CHINAGALAXY_NOT_ENOUGH_MONEY2           = -9
ERR_CHINAGALAXY_NOT_ENOUGH_MONEY3           = 20016 --融券价格废单

XT_ERROR_TYPE_ORDER_TYPE                    = 100000       --错误的下单类型
XT_ERROR_TYPE_NOT_FIND_ACCOUNT              = 100001       --未找到账号有效数据
XT_ERROR_TYPE_ACCOUNT_NOT_INITED            = 100002       --账号尚未初始化
XT_ERROR_TYPE_ORDER_CHECK_ERROR             = 100009       --合规检测错误
XT_ERROR_TYPE_IS_NOT_RUNNING                = 100011       --任务非运行状态

ERR_GUOTAIJUNAN_NOT_ENOUGH_MONEY            = -9           --国泰君安可用资金不足
ERR_GUOTAIJUNAN_LOWDELAY_NOT_ENOUGH_MONEY   = -410411020   --国泰君安低延迟股票可用资金不足
ERR_GUOTAIJUNAN_LOWDELAY_NOT_COLLATERAL     = 10014        --国泰君安低延迟两融证券不属于担保证券


-- CTP期货交易致命错误
g_ctp_trade_fatal_errors = {
    [CTP_INVALID_DATA_SYNC_STATUS] = "不在已同步状态",
    [CTP_INCONSISTENT_INFORMATION] = "会话信息不一致",
    [CTP_INVALID_LOGIN] = "不合法的登录",
    [CTP_USER_NOT_ACTIVE] = "用户不活跃",
    [CTP_DUPLICATE_LOGIN] = "重复的登录",
    [CTP_NOT_LOGIN_YET] = "还没有登录",
    [CTP_NOT_INITED] = "还没有初始化",
    [CTP_FRONT_NOT_ACTIVE] = "前置不活跃",
    [CTP_NO_PRIVILEGE] = "无此权限",
    [CTP_USER_NOT_FOUND] = "找不到该用户",
    [CTP_BROKER_NOT_FOUND] = "找不到该经纪公司",
    [CTP_INVESTOR_NOT_FOUND] = "找不到投资者",
    [CTP_OLD_PASSWORD_MISMATCH] = "原口令不匹配",
    [CTP_BAD_FIELD] = "报单字段有误",
    [CTP_INSTRUMENT_NOT_FOUND] = "找不到合约",
    [CTP_INSTRUMENT_NOT_TRADING] = "合约不能交易",
    [CTP_NOT_EXCHANGE_PARTICIPANT] = "经纪公司不是交易所的会员",
    [CTP_INVESTOR_NOT_ACTIVE] = "投资者不活跃",
    [CTP_NOT_EXCHANGE_CLIENT] = "投资者未在交易所开户",
    [CTP_NO_VALID_TRADER_AVAILABLE] = "该交易席位未连接到交易所",
    [CTP_DUPLICATE_ORDER_REF] = "不允许重复报单",
    [CTP_BAD_ORDER_ACTION_FIELD] = "错误的报单操作字段",
    --[CTP_DUPLICATE_ORDER_ACTION_REF] = "撤单已报送，不允许重复撤单",
    --[CTP_ORDER_NOT_FOUND] = "撤单找不到相应报单",
    --[CTP_INSUITABLE_ORDER_STATUS] = "报单已全成交或已撤销，不能再撤",
    [CTP_UNSUPPORTED_FUNCTION] = "不支持的功能",
    [CTP_NO_TRADING_RIGHT] = "没有报单交易权限",
    [CTP_CLOSE_ONLY] = "只能平仓",
    [CTP_OVER_CLOSE_POSITION] = "平仓量超过持仓量",
    [CTP_INSUFFICIENT_MONEY] = "资金不足",
    [CTP_DUPLICATE_PK] = "主键重复",
    [CTP_CANNOT_FIND_PK] = "找不到主键",
    [CTP_CAN_NOT_INACTIVE_BROKER] = "设置经纪公司不活跃状态失败",
    [CTP_BROKER_SYNCHRONIZING] = "经纪公司正在同步",
    [CTP_BROKER_SYNCHRONIZED] = "经纪公司已同步",
    [CTP_SHORT_SELL] = "现货交易不能卖空",
    [CTP_CFFEX_NETWORK_ERROR] = "中金所网络连接失败",
    [CTP_CFFEX_OVER_REQUEST] = "中金所未处理请求超过许可数",
    [CTP_CFFEX_OVER_REQUEST_PER_SECOND] = "中金所每秒发送请求数超过许可数",
    [CTP_OVER_CLOSETODAY_POSITION] = "平今仓位不足",
    [CTP_OVER_CLOSEYESTERDAY_POSITION] = "平昨仓位不足",
    [CTP_BROKER_NOT_ENOUGH_CONDORDER] = "经纪公司没有足够可用的条件单数量",
    [CTP_INVESTOR_NOT_ENOUGH_CONDORDER] = "投资者没有足够可用的条件单数量",
    [CTP_BROKER_NOT_SUPPORT_CONDORDER] = "经纪公司不支持条件单",
    [CTP_RESEND_ORDER_BROKERINVESTOR_NOTMATCH] = "重发未知单经济公司/投资者不匹配",
    [CTP_MARKET_CLOSED] = "交易市场状态停止",
    [CTP_TIME_NO_ENTRUSTING] = "当前时间不允许委托",
    [TRADE_COMMON_ERROR] = ""
}

--金证股票交易致命错误
g_invs_trade_fatal_errors = {
    [INVS_ERR_COMMUNICATION] = "通讯错误",
    [INVS_ERR_NOT_CHECK_IN] = "尚未签入系统",
    [INVS_ERR_NO_SUBSEQUENT_PACK] = "无后续数据包",
    [INVS_ERR_LOGIN_FAILED] = "帐户登录失败",
    [INVS_ERR_ACC_STATUS_INVALID] = "您的帐户状态不正常",
    [INVS_ERR_CARD_INEXIST] = "磁卡号不存在",
    [INVS_ERR_SECU_ACC_INEXIST] = "股东代码不存在",
    [INVS_ERR_FUND_ACC_INEXIST] = "资产帐号不存在",
    [INVS_ERR_USER_CODE_INEXIST] = "用户代码不存在",
    [INVS_ERR_MARKET_INEXIST] = "交易市场不存在",
    [INVS_ERR_PASSWORD] = "密码错误",
    [INVS_ERR_OPER_FAILED] = "操作失败",
    [INVS_ERR_EXT_INST_INEXIST] = "外部机构不存在",
    [INVS_ERR_BANK_PWD] = "银行密码错",
    [INVS_ERR_WRONG_PASSWORD] = "密码有误",
    [INVS_ERR_SECU_INEXIST] = "此股票不存在",
    [INVS_ERR_TRADE_UNDO] = "您未作指定交易",
    [INVS_ERR_INVALID_ENTRUST_TYPE] = "此股不能进行此类委托",
    [INVS_ERR_ENTRUST_FAILED] = "委托失败",
    [INVS_ERR_INSUFF_ENBALE_FUND] = "可用金额不足",
    [INVS_ERR_INSUFF_SECU_AMT] = "股票余额不足",
    [INVS_ERR_ORDER_NOT_FOUND] = "无此委托",
    [INVS_ERR_OTHERS] = "其它错误",
    [TRADE_COMMON_ERROR] = ""
}

--通用股票交易致命错误
g_stock_trade_fatal_errors = {
    [ERR_CONNECTION] = "连接错误",
    [ERR_INVALID_DATA] = "无效数据",
    [ERR_FUNC_UNDEF] = "未定义功能，尚不支持 ",
    [ERR_PROTOCOL_CONVERT] = "协议转换错误",
    [ERR_SESSION_INEXIST] = "会话不存在",
    [ERR_NOT_LOGIN] = "账号未登录",
    [ERR_DISCONNECTED_SECU] = "至券商连接断开",
    [ERR_INVALID_PARAM] = "无效参数",    
    [ERR_COMMUNICATION] = "通讯错误",
    [ERR_NOT_CHECK_IN] = "尚未签入系统",
    [ERR_NO_SUBSEQUENT_PACK] = "无后续数据包",
    [ERR_LOGIN_FAILED] = "帐户登录失败",
    [ERR_CARD_INEXIST] = "您的帐户状态不正常",
    [ERR_CARD_INEXIST] = "磁卡号不存在",
    [ERR_SECU_ACC_INEXIST] = "股东代码不存在",
    [ERR_FUND_ACC_INEXIST] = "资产帐号不存在",
    [ERR_USER_CODE_INEXIST] = "用户代码不存在",
    [ERR_MARKET_INEXIST] = "交易市场不存在",
    [ERR_MOD_PWD_FAILED] = "修改密码失败",
    [ERR_PASSWORD] = "密码错误",
    [ERR_OPER_FAILED] = "操作失败",
    [ERR_EXT_INST_INEXIST] = "外部机构不存在",
    [ERR_BANK_PWD] = "银行密码错",
    [ERR_PWD_INVALID] = "密码有误",
    [ERR_NO_AUTHORITY] = "无此权限",
    [ERR_SECU_INEXIST] = "此股票不存在",
    [ERR_ACCT_INEXIST] = "无此账号(通用账号)",
    [ERR_TRADE_UNDO] = "您未作指定交易",
    [ERR_INVALID_ENTRUST_TYPE] = "此股不能进行此类委托",
    [ERR_ENTRUST_FAILED] = "委托失败",
    [ERR_INSUFF_ENBALE_FUND] = "可用金额不足",
    [ERR_INSUFF_SECU_VOL] = "股票余额不足",
    [ERR_STOCK_SUSPENDED] = "股票停牌",
    [ERR_ORDER_NOT_FOUND] = "无此委托",
    [ERR_MARKET_CLOSED] = "已闭市",
    [ERR_INVALID_PRICE] = "委托价格超过涨跌停范围",
    
    --以下除了ERR_OTHERS我都不确定是否算入致命错误，请各位斧正
    [ERR_BANK_INEXIST] = "银行不存在",
    --[ERR_TRSF_FAILED] = "转帐失败",
    [ERR_INVEST_NOT_OPEN] = "未开通存折炒股业务",
    --[ERR_RESET_COST_FAILED] = "重置成本失败",
    --[ERR_QUERY_FAILED] = "查询失败",
    [ERR_TRSF_NOT_OPEN] = "未开通银行转帐业务",
    [ERR_BANK_TRST_NOT_OPEN] = "未开通此银行转帐业务",
    [ERR_BANK_WITHOUT_TRSF] = "该银行尚未开通该项业务",
    --[ERR_NO_CANCEL] = "此委托不能撤单",
    --[ERR_ORDER_CANCELD] = "此委托已撤单",
    [ERR_NO_RECORDS] = "无查询结果",
    
    [ERR_OTHERS] = "其它错误",

    [TRADE_COMMON_ERROR] = "",
}

--银河证券交易一般错误
g_chinagalaxy_trade_common_errors = {
    --[ERR_CHINAGALAXY_NOT_ENOUGH_MONEY] = "可用资金不足",
    --[ERR_CHINAGALAXY_NOT_ENOUGH_MONEY1] = "可用资金不足",
    --[ERR_CHINAGALAXY_NOT_ENOUGH_MONEY2] = "可用资金不足",
    [ERR_CHINAGALAXY_NOT_ENOUGH_MONEY3] = "融券价格废单",
}

g_guotaijunan_trade_fatal_errors={
    [ERR_GUOTAIJUNAN_LOWDELAY_NOT_COLLATERAL] = "证券不属于担保证券，不允许做信用普通买入",
}

--国泰君安交易一般错误
g_guotaijunan_trade_common_errors = {
    [ERR_GUOTAIJUNAN_NOT_ENOUGH_MONEY] = "可用资金不足",
    [ERR_GUOTAIJUNAN_LOWDELAY_NOT_ENOUGH_MONEY] = "可用资金不足",
}


g_trade_fatal_errors = {
    [20001] = g_ctp_trade_fatal_errors,            --CTP实盘
    [21001] = g_ctp_trade_fatal_errors,            --CTP模拟
    [10001] = g_invs_trade_fatal_errors,        --中投证券
    [11001] = g_invs_trade_fatal_errors,        --中投模拟
    [10002] = g_stock_trade_fatal_errors,        --中金证券
    [10004] = g_stock_trade_fatal_errors,        --长江证券
    [10003] = g_stock_trade_fatal_errors,        --东方证券
    [11003] = g_stock_trade_fatal_errors,        --东方模拟
    [10005] = g_stock_trade_fatal_errors,        --中信证券
    [10006] = g_stock_trade_fatal_errors,        --齐鲁证券
    [10018] = g_chinagalaxy_trade_common_errors,        --银河证券
    [10019] = g_chinagalaxy_trade_common_errors,
    [10290] = g_chinagalaxy_trade_common_errors,
    [10228] = g_guotaijunan_trade_fatal_errors,    --国泰君安低延迟两融
    [11262] = g_guotaijunan_trade_common_errors,        --国泰君安低延迟股票
}

-- 实际上未向柜台报送的委托错误号
g_xt_not_sent_order_errors = {
    [XT_ERROR_TYPE_ORDER_CHECK_ERROR] = "风控检查失败",
    [XT_ERROR_TYPE_ORDER_TYPE] = "委托类型错误",
    [XT_ERROR_TYPE_NOT_FIND_ACCOUNT] = "账号无有效数据",
    [XT_ERROR_TYPE_ACCOUNT_NOT_INITED] = "账号尚未初始化",
    [XT_ERROR_TYPE_IS_NOT_RUNNING] = "当前状态不能下单",
}
