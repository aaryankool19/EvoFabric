# Recruiter Summary

## 3-Sentence Explanation

EvoFabric is a simulation-first SystemVerilog project that models a safe self-adaptive FPGA-style compute fabric with a RISC-V-style control path and memory-mapped accelerator interface. It dynamically selects between Popcount, CRC32, FIR filter, and 2x2 matrix-multiply accelerators through a mux-based virtual reconfiguration slot. The design includes an adaptive controller FSM, performance counters, safety-checking reference logic, fallback behavior, and directed testbenches that generate GTKWave-compatible VCD waveforms.

## Resume Bullets

- Designed a simulation-first adaptive FPGA SoC with a RISC-V-style control path, MMIO accelerator interface, performance counters, and runtime selection logic.
- Implemented a mux-based virtual partial-reconfiguration slot selecting Popcount, CRC32, FIR, and 2x2 matrix-multiply accelerators.
- Built an adaptive controller FSM using opcode, availability, latency, correctness status, and error feedback to choose accelerators.
- Developed safety-checking and trusted fallback logic comparing outputs against reference results to detect and recover from incorrect hardware behavior.
- Verified handshakes, runtime switching, failure detection, fallback activation, and performance-counter updates with SystemVerilog testbenches and GTKWave.

## Interview Talking Points

- **Architecture:** The project models a small SoC-style fabric instead of only a standalone accelerator. It includes control/status registers, a bus decoder, accelerator modules, a controller FSM, safety logic, and counters.
- **Runtime adaptation:** Accelerator choice is controlled by opcode, availability, and error history. If a selected accelerator fails, the controller can disable it and use fallback.
- **Virtual partial reconfiguration:** The slot is mux-based for simulation. This keeps the project portable while still showing the boundary and interface discipline that real FPGA partial reconfiguration would require.
- **Safety strategy:** Outputs are checked against trusted reference logic before being committed to visible result registers. The bad-result test intentionally injects an incorrect output to prove fallback behavior.
- **Verification:** The test suite covers each accelerator, the common interface, controller behavior, safety checking, workload switching, and injected-fault recovery.

## What Makes The Project Impressive

- It connects multiple computer architecture concepts into one coherent RTL project: MMIO, accelerators, controller FSMs, monitoring, and correctness checking.
- It is simulation-first and inspectable. The design produces VCD files that can be opened in GTKWave to validate behavior.
- It is honest about scope: the CPU is a placeholder, partial reconfiguration is virtual, and the current verification is directed simulation.
- It demonstrates safety-aware design thinking by checking accelerator outputs before trusting them.
- It is organized like an engineering project, with RTL, testbenches, documentation, and repeatable Makefile commands.

## What Was Verified

The current testbenches verify:

- individual accelerator correctness for Popcount, CRC32, FIR, and 2x2 matrix multiply,
- common start/busy/done/valid accelerator handshake behavior,
- adaptive controller accelerator selection,
- accelerator disable behavior after a mismatch,
- safety checker mismatch detection,
- fallback output correction after injected fault,
- top-level MMIO-style workload switching,
- performance counter updates,
- VCD generation for waveform inspection.

## Current Scope

EvoFabric is not a synthesized FPGA deployment and does not implement real vendor partial reconfiguration. It is a simulation-first architecture and verification project intended to demonstrate RTL design skills, system integration, and safe adaptive hardware concepts.
