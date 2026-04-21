# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a quantitative trading strategy backtest repository for 光大证券QMT (Golden Sun Securities QMT). The repository contains trading strategies that run inside the QMT client application.

## Architecture

The project consists of several code directories:

- **python/** - Python strategy scripts (33 files). These are the main trading strategies that run within QMT's Python environment.
- **algorithms/** - Algorithm configurations (13 .lua files) for various broker algorithms
- **luaScripts/** - Lua scripts for monitoring, risk control, and task execution
- **mpython/** - Python utility modules
- **config_local/** - Local customer configurations

## Strategy Types

The repository contains five main categories of strategies:

1. **Grid Strategies** - Grid trading (网格策略.py, 增强网格策略V2.py, 期货网格.py, 期权网格.py)
2. **Stock Selection** - Multi-factor, sector rotation (多因子选股回测示例.py, 行业轮动回测示例.py)
3. **Intraday** - Day trading strategies (日内回转回测示例.py)
4. **Live Trading** - Real-time execution (双均线实盘示例PY.py, 交易实时主推示例.py)
5. **Auxiliary** - Cash management, IPO, data fetching

## QMT Strategy API

Strategies run inside QMT's Python environment with these entry points:

```python
def init(ContextInfo):
    # Called once at strategy initialization
    pass

def handlebar(ContextInfo):
    # Called on each K-line/bar
    # Main strategy logic goes here
    close = ContextInfo.get_market_data(['close'])
    ContextInfo.paint('close', close, -1, 0)
```

Key ContextInfo methods:
- `get_market_data(fields)` - Get market data (price, volume, etc.)
- `get_bar_timetag(index)` - Get timestamp of a specific bar
- `paint(name, value)` - Draw indicator curves
- `get_account()` - Get account information
- `order_stock()` - Place orders

## Important Notes

- All strategy files are encoded in GBK (Chinese)
- Strategies must be run inside the QMT client - they cannot be executed standalone
- Live trading requires appropriate QMT permissions
- Test thoroughly in backtest mode before running live

## Git Usage

This repo tracks only strategy code:
```
git add python/ algorithms/ luaScripts/ mpython/ config_local/
```

Ignored: system files (bin.x64/, data/, config/, userdata/, etc.)