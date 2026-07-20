# v6: First Pipelined Skeleton

## Overview

`v6` 是从单周期版本进入流水线版本的第一步。该版本的主要任务是引入 IF、ID、EX、MEM、WB 五级结构，并使读者首先建立阶段边界与数据流动的整体认识。

## Scope

本版本具备以下特征：

- 引入级间阶段划分
- 保持 `myCPU` 顶层接口稳定
- 控制逻辑经过刻意简化
- 不以完整前递与停顿机制为目标
- 为保持后续验证连续性，保留了系统指令与 CSR 主路径

## Design Focus

`v6` 关注的是结构迁移，而非把所有问题一次讲完：

- 单周期大组合逻辑如何拆分为多个阶段
- 不同阶段之间需要传递哪些关键信号
- 流水线结构为何天然会引入新的控制问题

需要特别说明的是：`v6` 虽然被称为“骨架版”，但这主要是指**教学重点**而非**功能删减程度**。为了保持后续版本与统一验证平台的连续性，本版本已经保留了 `ecall`、`mret`、CSR 读写等系统路径；这些内容会在后续版本中继续沿用，但本阶段不把讲解重点放在这里。

## Verification

建议优先执行最小样例：

```bash
cd ../cdp-tests
make clean
make run TEST=simple CPU_DIR=../v6
```

## Reading Guide

建议依次阅读以下文件：

- [myCPU.sv](./myCPU.sv)
- [IFU.sv](./IFU.sv)
- [IDU.sv](./IDU.sv)
- [EXU.sv](./EXU.sv)
- [LSU.sv](./LSU.sv)
- [WBU.sv](./WBU.sv)

## Next Step

`v7` 将在当前流水线骨架之上加入更完整的冒险处理逻辑，并把前递、暂停、冲刷这些真正决定“流水线能不能稳定工作”的机制补齐。
