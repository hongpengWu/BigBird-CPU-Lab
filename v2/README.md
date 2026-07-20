# v2: Single-Cycle Core Subset

## Overview

`v2` 在 `v1` 的基础上补齐了寄存器堆闭环、上半立即数指令以及基础条件分支，形成一条可独立验证的单周期主干路径。

## Scope

本版本支持以下内容：

- `addi`
- `add`
- `lui`
- `auipc`
- `jal`
- `beq/bne/blt/bge/bltu/bgeu`
- `ecall`

本版本暂不包含：

- 完整整数 ALU 指令族
- 访存指令
- `jalr`
- CSR 与异常返回

## Design Focus

`v2` 的核心目标是建立以下概念：

- 寄存器堆的读写闭环
- `pc + imm` 与 `pc + 4` 两类写回来源
- 条件分支对 `next_pc` 的控制方式

该版本仍然保持单周期结构，从而避免在早期阶段引入流水线复杂度。

## Reading Guide

建议重点关注 [myCPU.sv](./myCPU.sv) 中以下部分：

- 指令字段与立即数生成
- `branch_taken` 的生成逻辑
- `rd_value_next` 与 `next_pc` 的选择逻辑
- `RegisterFile` 实例与调试写回口的配合关系

## Verification

建议执行以下用例：

```bash
cd ../cdp-tests
make clean
make run TEST=addi CPU_DIR=../v2
make run TEST=lui  CPU_DIR=../v2
make run TEST=beq  CPU_DIR=../v2
```

## Next Step

`v3` 将在保持单周期结构的前提下补齐常见整数运算指令，使执行通路具备完整的整数 ALU 能力。
