# v5: Full Single-Cycle RV32I Mainline

## Overview

`v5` 是单周期阶段的收束版本。该版本补齐常规 RV32I 单周期主线，使后续流水线阶段可以在统一的功能基线之上展开。

## Scope

本版本支持以下内容：

- `add/sub/slt/sltu/xor/or/and/sll/srl/sra`
- `addi/slti/sltiu/xori/ori/andi/slli/srli/srai`
- `lui/auipc`
- `beq/bne/blt/bge/bltu/bgeu`
- `jal/jalr`
- `lb/lh/lw/lbu/lhu`
- `sb/sh/sw`
- `ecall`

## Design Focus

该版本的重点不在于性能，而在于功能完整性与结构清晰性：

- 单周期条件下的统一控制路径
- 访存与控制流在同一周期内的协同关系
- 调试写回口与架构状态更新的同步方式

## Files

- [myCPU.sv](./myCPU.sv)：顶层单周期 CPU
- [RegisterFile.sv](./RegisterFile.sv)：通用寄存器堆
- [ALU.sv](./ALU.sv)：整数运算单元
- [add.sv](./add.sv)：加减法子模块
- [sext.sv](./sext.sv)：加载数据扩展模块
- [para.sv](./para.sv)：操作码与 ALU 编码定义

## Verification

建议执行以下用例：

```bash
cd ../cdp-tests
make clean
make run TEST=add  CPU_DIR=../v5
make run TEST=beq  CPU_DIR=../v5
make run TEST=lw   CPU_DIR=../v5
make run TEST=sw   CPU_DIR=../v5
make run TEST=jalr CPU_DIR=../v5
```

## Relation To Later Versions

`v6-v8` 不会改变本版本定义的 ISA 行为，而是将本版本的单周期组合通路逐步拆解为多级流水线，并进一步加入冒险处理与 CSR 控制。
