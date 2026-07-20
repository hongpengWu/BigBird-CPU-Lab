# v7: Hazard-Aware Pipeline

## Overview

`v7` 是流水线阶段的核心版本。该版本在 `v6` 的基础上引入前递、暂停与冲刷等关键控制机制，使流水线从“结构已经拆开”进一步走向“关键冲突能够被正确处理”。

## Scope

本版本具备以下特征：

- 引入数据冒险与控制冒险处理
- 为兼容当前验证平台，将复位 PC 调整为 `0x00000000`
- 延续 `v6` 中已有的系统指令与 CSR 主路径

## Design Focus

建议重点关注以下问题：

- `Control.sv` 如何统一管理下一条 PC、冲刷与暂停
- `Data_hazard.sv` 如何输出前递选择信息
- 为什么 load-use 冲突不能仅依靠前递解决
- 分支与跳转为何会影响流水线中多条指令的有效性

需要特别说明的是：`v7` 的主要增量是 hazard 处理，而不是首次引入 CSR 或异常返回。系统路径在 `v6` 中已经接入，本阶段重点是让流水线在这些既有功能存在的前提下，仍然保持行为稳定。

## Verification

建议执行以下用例：

```bash
cd ../cdp-tests
make clean
make run TEST=addi CPU_DIR=../v7
make run TEST=lw   CPU_DIR=../v7
make run TEST=jal  CPU_DIR=../v7
```

## Next Step

`v8` 将进一步收束为与当前验证平台高度一致的成熟实现，并作为整套教程的最终回归版本执行完整验证。
