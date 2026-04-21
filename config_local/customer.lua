{
    g_company = "光大证券QMT实盘",
    g_xtservice_address = "223.166.178.85:56000",
    g_update_url = "http://114.141.191.85:65000/download/update.cfg;http://[2400:8200:8002:1::43]:65000/download/update.cfg",
    g_bControlLoginTime = false,
    --g_updateTagName = "tradeclient",
    --g_bIncrementUpdater = 1,
    g_update_interval = 60,
    g_bswitchXtservice = true,
    g_pythonlib_url = "http://download.thinktrader.net:8800/download/update36.cfg",
    g_researchLib_url = "http://download.thinktrader.net:8800/download/updateitclient.cfg",
    g_cloudResearch_url = "http://download.thinktrader.net:8800/download/updatecloudresearch.cfg",
    g_traderclient_url = "http://download.thinktrader.net:8800/download/updatetraderclient.cfg",
    g_pbLib_url = "http://download.thinktrader.net:8800/download/updateamptraderclient.cfg",
    g_defaultPorts = {
        proxy = "109.244.69.47:59000",
        proxy_backup = "109.244.69.47:59000",
        xtquoter = "109.244.69.47:59000",
    },
    xtclient = {
        app = {
            debugId = "",
            logPath = "../config/xtclient.log4cxx",
            logWatch = 0,
            appendDate = 1,
            xtquoter_address = "222.66.65.67:59000",
        },
        xtaddress = {
            server = "光大证券QMT资管电信线路:114.141.191.85:56000,光大证券QMT资管电信ipv6线路:[2400:8200:8002:1::43]:56000,光大证券QMT资管联通ipv6线路1:[2408:870C:2060:2:1::43]:56000,光大证券QMT资管联通线路1:223.166.178.85:56000,光大证券QMT华南ipv6线路:[2402:4E00:4050:2:2::111]:56000,光大证券QMT华南线路:109.244.69.47:56000,光大证券QMT华北互联网线路:123.59.230.194:56000,光大证券QMT华北IPV6线路:[2406:CF00:0:501:1::111]:56000",
            gmserver = "",
            proxy = "光大证券QMT资管电信线路:114.141.191.85:59000,光大证券QMT资管联通ipv6线路1:[2408:870C:2060:2:1::43]:59000,光大证券QMT华南ipv6线路:[2402:4E00:4050:2:2::111]:59000,光大证券QMT华南线路:109.244.69.47:59000,光大证券QMT资管联通线路1:223.166.178.85:59000,光大证券QMT资管电信ipv6线路:[2400:8200:8002:1::43]:59000,光大证券QMT华北互联网线路:123.59.230.194:59000,光大证券QMT华北线路:[2406:CF00:0:501:1::111]:59000",
        },
        client_xtservice = {
            isUseSSL = "0",
            sslCaPath = "../data/server.crt",
        },
    },
    xtminiqmt = {
        client_xtservice = {
            isUseSSL = "0",
            sslCaPath = "../data/server.crt",
        },
    },
    xtquoter = {
        ["client_proxy"] = {
            isGetdAddressFromNameServer=0,
        },
        app = {
            logPath = "../config/xtquoter.log4cxx",
            logWatch = 0,
            appendDate = 1,
        },
    },
}
