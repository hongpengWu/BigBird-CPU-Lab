# v7: Hazard-Aware Pipeline Close To `CPU/`

## Overview

`v7` 是流水线阶段的核心版本。该版本直接以原始 `CPU/` 工程为主要参考对象，引入前递、暂停与冲刷等关键控制机制，并保持与教学主线一致的接口形式。

## Scope

本版本具备以下特征：

- 贴近原始 `CPU/` 工程的模块划分
- 引入数据冒险与控制冒险处理
- 为兼容当前验证平台，将复位 PC 调整为 `0x00000000`

## Design Focus

建议重点关注以下问题：

- `Control.sv` 如何统一管理下一条 PC、冲刷与暂停
- `Data_hazard.sv` 如何输出前递选择信息
- 为什么 load-use 冲突不能仅依靠前递解决
- 分支与跳转为何会影响流水线中多条指令的有效性

## Verification

建议执行以下用例：

```bash
cd ../cdp-tests
make clean
make run TEST=addi CPU_DIR=../v7
make run TEST=lw   CPU_DIR=../v7
make run TEST=jal  CPU_DIR=../v7
```

## Relation To `CPU/`

`v7` 不是对原始工程的重新设计，而是其教学化投影版本。主要差异仅在于仿真平台适配，其中最关键的一项是复位 PC 与镜像布局的对齐。

## Next Step

`v8` 将进一步对齐当前验证平台中的成熟实现，并作为整套教程的最终收束版本执行完整回归。
