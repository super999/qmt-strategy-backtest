package.path = package.path .. ";./../config/lua/task/?.lua"
dofile("../config/lua/task/Common.lua")

-- 参数解析
local function parseParam(obj)
    local param = CCodeOrderParam()
    local paramObj = obj:getObjectField("m_param")
    param:bsonValueFromObj(paramObj)
    return param
end

-- 函数执行
function run(obj)
    local param = parseParam(obj)    
    local ret = ""
    local lastOrderTime = 0

    -- 初始化历史委托状态，避免因未成委托处理造成超单
    local orders = task:getOrders()
    checkErrors(orders)

    while true do
        
        if task:isCompleteOrCancel() then
            --printLog("task canceled by user")
            break
        end
        sleep(1)
    end

    return ret
end
