# v8: Final Teaching Version

## Overview

`v8` 是 `BigBird` 的最终教学收束版本。该版本对齐当前验证平台中的成熟实现，并在此基础上承载整套教程的最终回归验证。

## Scope

本版本具备以下特征：

- 完整流水线主链路
- 更成熟的冒险处理逻辑
- CSR 与异常返回相关通路
- 与当前仿真平台高度一致的实现细节

这里需要强调：`v8` 并不是“第一次出现 CSR”的版本。系统指令与 CSR 主路径在 `v6`、`v7` 中已经存在；`v8` 的意义在于把这些路径与访存、前递、回写等细节进一步收束为一套更成熟、更适合完整回归验证的实现。

## Design Focus

`v8` 的主要用途包括：

- 作为 `v1-v7` 各阶段知识点的统一收束点
- 作为完整回归测试的目标版本
- 作为后续继续扩展 CPU 功能的起点

## Verification

单条测试：

```bash
cd ../cdp-tests
make clean
make run TEST=addi CPU_DIR=../v8
make run TEST=lw   CPU_DIR=../v8
make run TEST=jalr CPU_DIR=../v8
```

全量回归：

```bash
cd ../cdp-tests
make clean
CPU_DIR=../v8 python3 run_all_tests.py
```

## Suggested Review Order

建议在阅读完全部版本后，按以下顺序进行复盘：

1. `v1`：接口与最小闭环
2. `v2-v5`：单周期主线逐步补齐
3. `v6`：流水线结构引入
4. `v7`：冒险处理机制
5. `v8`：工程化收束与完整验证
