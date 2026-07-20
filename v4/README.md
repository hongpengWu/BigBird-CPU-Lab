# v4: Single-Cycle Memory Access

## Overview

`v4` 在 `v3` 的整数执行通路之上补入数据访存能力。该版本首次完整使用 `perip_*` 接口，使处理器不仅能够执行整数计算，还能够访问数据存储。

## Scope

本版本支持以下内容：

- `v3` 中全部整数计算指令
- `lb/lh/lw/lbu/lhu`
- `sb/sh/sw`
- `jal`
- 全部基础分支指令
- `ecall`

本版本暂不包含：

- `jalr`
- CSR 与异常返回

## Design Focus

该版本主要说明以下问题：

- 访存地址如何由执行通路生成
- `perip_addr/perip_mask/perip_wdata/perip_rdata` 的语义划分
- 符号扩展与零扩展在加载指令中的差异
- 字节、半字、整字写入为何需要不同掩码

## Reading Guide

建议优先阅读以下文件：

- [myCPU.sv](./myCPU.sv)
- [sext.sv](./sext.sv)

## Verification

建议执行以下用例：

```bash
cd ../cdp-tests
make clean
make run TEST=lw CPU_DIR=../v4
make run TEST=lb CPU_DIR=../v4
make run TEST=sw CPU_DIR=../v4
make run TEST=sh CPU_DIR=../v4
```

## Next Step

`v5` 将补齐 `jalr` 与剩余控制流部分，使单周期阶段形成完整的 RV32I 主线版本。
