# 多因子选股回测示例.py 策略分析报告

**文件**: `python/多因子选股回测示例.py`  
**分析日期**: 2026-04-21  
**状态**: ⚠️ 文件内容异常

---

## 一、文件状态

| 项目 | 状态 |
|------|------|
| 文件大小 | 5,426 bytes |
| 编码状态 | ⚠️ 内容为混淆/乱码，无法正常解析 |
| Git状态 | 已提交，但原始内容已损坏 |

**问题说明**:  
该文件在Git仓库中存储的内容为乱码（Base64编码或混淆数据），无法通过常规文本编辑器或Python解析。文件开头显示类似加密字符串：`MmJNMuofqSiOo1t_QO0x3t5H...`

---

## 二、同类文件对比

为提供有效参考，我分析了同一目录下的可读策略文件：

### 2.1 可正常读取的文件

| 文件名 | 状态 | 说明 |
|--------|------|------|
| `PY简单示例.py` | ✅ 可读 | 基础示例，含init/handlebar结构 |
| `PY模型回测示例.py` | ✅ 可读 | 包含均线策略逻辑 |
| `双均线实盘示例PY.py` | ✅ 可读 | 实盘策略示例 |
| `网格策略.py` | ⚠️ | 也是乱码 |
| `增强网格策略V2.py` | ⚠️ | 也是乱码 |

### 2.2 策略文件编码问题统计

| 类型 | 数量 | 占比 |
|------|------|------|
| 可正常读取 | ~10 | ~30% |
| 乱码/混淆 | ~23 | ~70% |

---

## 三、多因子选股策略通用框架

基于 `PY模型回测示例.py` 等可读文件，以下是多因子选股策略的标准结构：

### 3.1 策略入口函数

```python
#coding:gbk
#!/usr/bin/python
import numpy as np

def init(ContextInfo):
    """初始化函数，策略启动时执行一次"""
    # 获取选股池
    s = ContextInfo.get_stock_list_in_sector('成分股')
    
    # 设置股票池
    ContextInfo.set_universe(s)
    
    # 设置基准
    ContextInfo.benchmark = ContextInfo.stockcode + "." + ContextInfo.market

def handlebar(ContextInfo):
    """K线回调函数，每根K线执行一次"""
    d = ContextInfo.barpos
    realtime = ContextInfo.get_bar_timetag(d)
    
    # 获取持仓
    holdings = get_holdings('testS', 'STOCK')
    
    # 获取历史数据
    last20s = ContextInfo.get_history_data(21, '1d', 'close')
    
    # 因子计算逻辑
    for k, closes in list(last20s.items()):
        if len(closes) < 21:
            continue
        
        # 计算因子：20日均线 vs 5日均线
        m20 = np.mean(closes[:20])
        m5 = np.mean(closes[-6:-1])
        
        # 交易逻辑
        if m5 >= m20:
            # 买入信号
            pass
        else:
            # 卖出信号
            pass
```

### 3.2 核心API参考

| 函数/方法 | 说明 |
|-----------|------|
| `ContextInfo.get_stock_list_in_sector(sector_name)` | 获取板块成分股 |
| `ContextInfo.set_universe(stock_list)` | 设置股票池 |
| `ContextInfo.get_history_data(n, period, field)` | 获取历史数据 |
| `ContextInfo.get_market_data(fields)` | 获取行情数据 |
| `ContextInfo.paint(name, value)` | 绘制指标 |
| `order_shares(stock, shares, order_type, price, ctx, account)` | 下单 |

### 3.3 常见多因子

| 因子类型 | 因子名称 | 说明 |
|----------|----------|------|
| 估值因子 | PE (市盈率) | 市盈率越低越有价值 |
| 估值因子 | PB (市净率) | 市净率越低越好 |
| 盈利因子 | ROE (净资产收益率) | 越高盈利能力越强 |
| 成长因子 | 净利润增长率 | 越高成长性越好 |
| 规模因子 | 总市值 | 大盘/小盘选择 |
| 动量因子 | 20日涨幅 | 追涨杀跌 |

---

## 四、问题原因分析

### 可能原因

1. **文件导出时使用了混淆/加密** - QMT在某些情况下可能对策略进行编码保护
2. **Git编码问题** - 提交时编码转换出错
3. **文件损坏** - 存储介质问题导致数据损坏

### 建议解决方案

1. **重新获取原始文件**：从QMT客户端重新导出策略文件
2. **检查源文件编码**：使用 `file` 命令或编辑器检测编码
3. **手动重建策略**：基于策略思路重新编写

---

## 五、后续行动计划

1. [ ] 从QMT客户端重新导出 `多因子选股回测示例.py` 原始文件
2. [ ] 验证新文件可正常读取（无乱码）
3. [ ] 重新提交到Git仓库
4. [ ] 更新本分析报告

---

## 附录：相关文件

- `python/PY模型回测示例.py` - 可参考的选股策略示例
- `python/_PyContextInfo.py` - QMT Python API定义
- `README.md` - 项目总体说明
- `CLAUDE.md` - AI助手开发指南

---

**报告生成工具**: Claude Code  
**分析人员**: AI Assistant  
**版本**: v1.0