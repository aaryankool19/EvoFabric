# EvoFabric

EvoFabric is a simulation-first SystemVerilog learning project for a safe self-adaptive FPGA-style SoC. It models a small RISC-V-style system shell, memory-mapped accelerator registers, runtime accelerator selection, correctness checking, performance counters, and a virtual reconfigurable accelerator slot.

The project does not use real vendor partial reconfiguration yet. Runtime reconfiguration is simulated by mux-selecting one of several already-instantiated safe accelerators.

## What Is Included

- RV32I-style CPU placeholder and instruction/data memory placeholders
- Memory-mapped bus for accelerator and performance counter registers
- Common accelerator port interface
- Virtual reconfiguration slot selected by the adaptive controller
- Safe accelerators:
  - `popcount_accel.sv`
  - `crc32_accel.sv`
  - `fir_filter_accel.sv`
  - `matmul2x2_accel.sv`
- Adaptive controller FSM
- Safety checker with reference logic and fallback outputs
- Performance counters for cycles, calls, failures, selected accelerator, and latency
- Testbenches with VCD output for GTKWave

## Safety Scope

EvoFabric is only for learning FPGA design, computer architecture, and safe adaptive hardware. It intentionally avoids malware, covert channels, RowHammer logic, destructive hardware behavior, voltage abuse, side-channel leakage, cryptographic evasion, and offensive security features.

## Quick Start

Install Icarus Verilog and GTKWave, then run:

```sh
make test
```

Generated waveforms are written to `build/*.vcd`.

```sh
make waves
gtkwave build/tb_top_workload_switching.vcd
```

## Register Map

The top-level memory-mapped interface uses word addresses:

| Address | Name | Description |
| --- | --- | --- |
| `0x00` | CONTROL | bit 0 starts a request, bits `[7:4]` hold opcode, bit 8 clears counters |
| `0x04` | INPUT_A | Operand A |
| `0x08` | INPUT_B | Operand B |
| `0x0C` | INPUT_C | Operand C |
| `0x10` | INPUT_D | Operand D |
| `0x14` | OUTPUT_0 | Result word 0 |
| `0x18` | OUTPUT_1 | Result word 1 |
| `0x1C` | OUTPUT_2 | Result word 2 |
| `0x20` | OUTPUT_3 | Result word 3 |
| `0x24` | STATUS | Busy, fallback, error, selected accelerator, disabled accelerators |
| `0x100` | TOTAL_CYCLES | Free-running cycle counter |
| `0x104` | CALLS | Number of requests |
| `0x108` | FAILURES | Safety or accelerator failures |
| `0x10C` | LAST_SELECTED | Last selected accelerator id |
| `0x110` | LAST_LATENCY | Last operation latency |
| `0x114` | BEST_LATENCY | Best observed latency |

## Opcodes

| Opcode | Operation |
| --- | --- |
| `1` | Popcount |
| `2` | CRC32 over one 32-bit word |
| `3` | Four-tap fixed-point FIR: `a + 2b + 3c + 4d` |
| `4` | 2x2 signed integer matrix multiply |

## Project Layout

```text
rtl/
  core/
  soc/
  accelerators/
  interconnect/
  monitors/
  control/
tb/
docs/
scripts/
README.md
Makefile
```

See [docs/architecture.md](docs/architecture.md) for a deeper design walkthrough.
