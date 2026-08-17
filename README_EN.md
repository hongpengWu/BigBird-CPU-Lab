[**English**](./README_EN.md) | [**简体中文**](./README.md)

# BigBird CPU Lab

**BigBird** is a beginner-oriented RV32I processor design course implemented in SystemVerilog. It develops a CPU through eight runnable versions, progressing from a minimal single-cycle core to a pipelined implementation with hazard handling, CSRs, and exception return.

The project is organized around one principle: introduce one meaningful layer of complexity at a time while keeping the top-level interface and verification workflow stable. Readers can run every stage, observe what changed, and connect each new mechanism to a concrete test result.

## Why BigBird?

Many processor tutorials present a complete pipeline too early, forcing beginners to learn the datapath, control logic, forwarding, stalls, flushes, and exceptions simultaneously. BigBird instead uses small, verifiable steps:

- Start with a minimal executable path before introducing the full ISA.
- Build intuition with a single-cycle implementation before pipeline partitioning.
- Keep the `myCPU` interface stable across versions.
- Reuse one regression environment so progress remains measurable.
- Delay hazards and system control until the main datapath is understood.

The long-term goal is a SystemVerilog teaching project with the same emphasis on progressive learning that projects such as Berkeley Sodor bring to Chisel-based processor education.

## Learning Path

| Version | Main topic | Learning objective |
| --- | --- | --- |
| `v1` | Minimal single-cycle skeleton | Connect the PC, fetch path, and debug write-back interface; run `jal`, `addi`, and `ecall`. |
| `v2` | Basic integer and branch path | Add the register file, `lui`, `auipc`, `add`, and basic branches. |
| `v3` | Integer ALU | Complete the common arithmetic, logical, comparison, and shift operations. |
| `v4` | Loads and stores | Introduce the `perip_*` memory interface, load extension, and store masks. |
| `v5` | Complete single-cycle RV32I path | Add `jalr` and complete the single-cycle control-flow baseline. |
| `v6` | Pipeline structure | Split the datapath into IF/ID/EX/MEM/WB stages while preserving the verification interface. |
| `v7` | Hazard handling | Add forwarding, stalls, and flushes for data and control hazards. |
| `v8` | Integrated teaching baseline | Consolidate memory, forwarding, write-back, CSR, and system-control behavior for full regression. |

## Quick Start

The verification environment is based on the [HITSZ-CDP trace-testing framework](https://github.com/HITSZ-CDP/cdp-tests) and is intended for Linux.

### Dependencies

```bash
sudo apt-get update
sudo apt-get install -y verilator make g++ python3
```

### Run the Minimal Version

From the repository root:

```bash
cd cdp-tests
make clean
make run TEST=simple CPU_DIR=../v1
```

If the environment and `v1` implementation are working, the output should contain:

```text
Test Point Pass!
```

### Run the Final Regression

```bash
cd cdp-tests
make clean
CPU_DIR=../v8 python3 run_all_tests.py
```

## Repository Structure

```text
.
|-- v1/                 # Minimal single-cycle processor
|-- v2/                 # Register-file and basic control-flow path
|-- v3/                 # Integer ALU path
|-- v4/                 # Load/store path
|-- v5/                 # Complete single-cycle baseline
|-- v6/                 # Five-stage pipeline structure
|-- v7/                 # Forwarding, stalls, and flushes
|-- v8/                 # Final integrated teaching version
`-- cdp-tests/          # Shared Verilator and trace-testing environment
```

Each version normally contains:

- `myCPU.sv`: the stable CPU top-level module.
- Supporting datapath and control modules appropriate to that stage.
- A version-specific README describing the design step.

## Verification Strategy

All versions use the same test entry point. `CPU_DIR` selects the processor source directory without changing the SoC wrapper or testbench:

```bash
make run TEST=simple CPU_DIR=../v1
make run TEST=addi   CPU_DIR=../v3
make run TEST=lw     CPU_DIR=../v5
```

This arrangement serves two purposes:

- A failure is easier to attribute to the design change introduced in the current version.
- The same instruction tests can be revisited as the processor evolves from single-cycle to pipelined execution.

The early use of `ecall` is intentional: before the full exception model is introduced, it provides a stable end-of-test signal for automated verification.

## Recommended Study Order

1. Run `v1` and identify the minimum fetch-to-write-back loop.
2. Compare `v1` through `v2` to understand basic data movement and control selection.
3. Study `v3` through `v5` to complete the single-cycle datapath.
4. Compare `v5` and `v6` to see how a single-cycle design is partitioned into pipeline stages.
5. Use `v7` to study forwarding, stalls, and flushes with failing and passing traces.
6. Run the full regression on `v8`, then use it as a baseline for further extensions.

## Design Scope

BigBird prioritizes readability, continuity, and repeatable verification over aggressive microarchitectural optimization. It is intended for:

- Undergraduate students building their first processor.
- Readers familiar with digital logic but new to CPU organization.
- Instructors looking for staged laboratory material.
- Developers interested in comparing single-cycle and pipelined RTL under one test framework.

## Roadmap

- Add annotated waveforms and timing diagrams.
- Expand the laboratory instructions for each version.
- Add exercises and checkpoints suitable for coursework.
- Improve documentation of exception and system-control paths.

## License

This project is released under the [MIT License](./LICENSE).
