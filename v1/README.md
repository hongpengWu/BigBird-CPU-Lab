# v1: Minimal Single-Cycle Skeleton

## Overview

`v1` 是 `BigBird` 教学链路中的起始版本。该版本采用单文件、单周期实现，仅保留最小可运行的处理器骨架，用于说明顶层接口、程序计数器、基础译码与调试写回口之间的关系。

## Scope

本版本支持以下指令：

- `jal`
- `addi`
- `ecall`

本版本暂不包含：

- 独立寄存器堆模块
- 独立 ALU 模块
- 访存指令
- 条件分支
- `jalr`
- `lui/auipc`
- CSR 与异常返回
- 流水线相关控制

## Design Notes

- `myCPU` 顶层接口与后续版本保持一致。
- 为与现有仿真平台对齐，复位 PC 采用 `0x00000000`。
- 虽然内部实现经过极简化处理，但取指、译码、执行、写回四个基本步骤已经具备。

## Reading Guide

建议按如下顺序阅读 [myCPU.sv](./myCPU.sv)：

1. 端口定义与外部接口
2. `pc` 与寄存器数组
3. 指令字段与立即数生成
4. 指令识别与下一条 PC 选择
5. 调试写回与状态更新

## Verification

推荐首先执行最小样例：

```bash
cd ../cdp-tests
make clean
make run TEST=simple CPU_DIR=../v1
```

通过该测试后，可确认顶层接口、PC 推进逻辑与 `debug_wb_*` 调试信号已经与验证平台对齐。

## Next Step

`v2` 将在保留单周期结构的前提下，引入寄存器堆闭环、基础整数运算与条件分支，为后续完整单周期版本建立稳定基础。
