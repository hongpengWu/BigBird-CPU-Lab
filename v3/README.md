# v3: Single-Cycle Integer ALU

## Overview

`v3` 用于完成单周期整数执行通路。该版本补齐了常见的算术、逻辑、比较与移位指令，使处理器在不引入访存复杂度的前提下具备完整的整数 ALU 能力。

## Scope

本版本支持以下内容：

- `add/sub/slt/sltu/xor/or/and/sll/srl/sra`
- `addi/slti/sltiu/xori/ori/andi/slli/srli/srai`
- `lui/auipc`
- `beq/bne/blt/bge/bltu/bgeu`
- `jal`
- `ecall`

本版本暂不包含：

- 访存指令
- `jalr`
- CSR 与异常返回

## Design Focus

该版本的主要目标是说明以下问题：

- ALU 输入如何从寄存器值、立即数与 PC 中选择
- 操作码如何映射到算术、逻辑、比较与移位功能
- 比较类指令如何与统一 ALU 路径整合

## Reading Guide

建议优先阅读以下文件：

- [myCPU.sv](./myCPU.sv)
- [ALU.sv](./ALU.sv)
- [add.sv](./add.sv)

## Verification

建议执行以下用例：

```bash
cd ../cdp-tests
make clean
make run TEST=add  CPU_DIR=../v3
make run TEST=sub  CPU_DIR=../v3
make run TEST=andi CPU_DIR=../v3
make run TEST=slli CPU_DIR=../v3
```

## Next Step

`v4` 将在当前整数执行通路之上增加访存路径，第一次完整引入 `perip_*` 数据接口。
