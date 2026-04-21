# QMT 量化交易策略回测仓库

本仓库包含在光大证券QMT量化交易平台上运行的策略代码。

## 目录结构

```
.
├── python/                 # Python策略脚本
│   ├── _PyContextInfo.py   # QMT Python上下文
│   ├── PY简单示例.py        # 入门示例
│   ├── 双均线实盘示例PY.py  # 双均线策略
│   ├── 网格策略.py          # 网格交易策略
│   ├── 增强网格策略V2.py    # 增强版网格
│   ├── 期货网格.py          # 期货网格
│   ├── 期权网格.py          # 期权网格
│   ├── 多因子选股回测示例.py # 多因子选股
│   ├── 机器学习回测示例.py  # ML策略
│   ├── 行业轮动回测示例.py  # 行业轮动
│   ├── 日内回转回测示例.py  # 日内回转
│   └── ...                 # 更多策略
│
├── algorithms/             # 算法委托配置
│   ├── ciccAlgorithm.lua   # 中金算法
│   ├── citicAlgorithm.lua  # 中信算法
│   └── ...
│
├── luaScripts/             # Lua脚本
│   ├── monitor/            # 监控脚本
│   ├── risk/               # 风控脚本
│   ├── task/               # 任务脚本
│   └── ...
│
├── mpython/                # Python模块
│   └── pythonbalance.py    # 余额管理
│
└── config_local/           # 本地配置
    └── customer.lua        # 客户化配置
```

## 策略分类

### 网格策略类
- `网格策略.py` - 基础网格交易
- `增强网格策略V2.py` - 增强版网格
- `期货网格.py` - 期货专用网格
- `期权网格.py` - 期权网格
- `比例网格.py` - 比例网格

### 选股策略类
- `多因子选股回测示例.py` - 多因子模型
- `行业轮动回测示例.py` - 行业轮动
- `集合竞价选股回测示例.py` - 集合竞价
- `ARIMA预测.py` - ARIMA预测

### 日内策略类
- `日内回转回测示例.py` - 日内回转
- `股票网格日内策略监控.py` - 日内监控

### 实盘策略类
- `双均线实盘示例PY.py` - 双均线实盘
- `交易实时主推示例.py` - 实时主推

### 辅助策略类
- `尾盘闲置资金自动逆回购.py` - 闲置资金理财
- `新股申购.py` - 新股申购
- `股本营收资产.py` - 数据获取

## 快速开始

### 1. 环境要求
- Python 3.6+
- QMT 客户端（光大证券金阳光）

### 2. 运行策略

在QMT客户端中打开 Python策略 编辑器，加载对应的 `.py` 文件。

示例 - 运行简单策略：
```python
# 在QMT Python编辑器中打开 PY简单示例.py
# 点击运行即可回测
```

### 3. 修改策略

打开对应的策略文件，修改参数：

```python
def init(ContextInfo):
    # 初始化设置
    pass

def handlebar(ContextInfo):
    # 策略逻辑
    # 获取行情数据
    close = ContextInfo.get_market_data(['close'])
    # 交易逻辑
    ContextInfo.paint('close', close, -1, 0)
```

## 核心API

### ContextInfo 对象

| 方法 | 说明 |
|------|------|
| `get_market_data(fields)` | 获取行情数据 |
| `get_bar_timetag(index)` | 获取K线时间戳 |
| `paint(name, value)` | 绘制指标曲线 |
| `log_info(message)` | 输出日志 |
| `get_account() `| 获取账户信息 |
| `order_stock()` | 股票下单 |

### 策略函数

| 函数 | 说明 |
|------|------|
| `init(ContextInfo)` | 初始化，每个策略只调用一次 |
| `handlebar(ContextInfo)` | 根K线调用策略逻辑 |
| `handle_trade(ContextInfo)` | 成交回报 |
| `handle_order(ContextInfo)` | 委托回报 |

## 策略参数说明

### 网格策略参数
```python
# 网格策略.py 中可调整的参数
grid_count = 10      # 网格数量
grid_ratio = 0.02    # 网格间距比例
```

### 多因子参数
```python
# 多因子选股回测示例.py
factors = ['PE', 'PB', 'ROE']  # 选股因子
stock_count = 50               # 持仓数量
```

## 注意事项

1. **实盘风险**：实盘前请先在回测中充分验证
2. **API限制**：部分API需要实盘权限
3. **数据完整性**：确保行情数据完整
4. **资金管理**：设置合理的止损止盈

## 更新日志

- 2024-02-27: 初始版本，包含网格、期权、期货等策略

## 许可证

MIT License