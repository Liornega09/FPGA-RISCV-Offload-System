# RTL (Hardware) Source

This directory contains the SystemVerilog/Verilog RTL for the FPGA design, including:
- A PicoRV32-based RISC-V sideband CPU subsystem
- Instruction / data memory blocks
- An Avalon-MM to AXI-MM bridge (and Avalon-MM muxing) used to connect the CPU to the system interconnect/fabric

## Contents

### Top-level
- `riscv_top.sv`  
  Top-level integration for the RISC-V subsystem and memory/peripherals.

### CPU
- `picorv32.v`  
  PicoRV32 core (upstream RTL).
- `riscv_cpu.sv`  
  Wrapper / integration logic around PicoRV32 (reset/irq hookup, bus interface, etc.).

### Bus / Interconnect
- `avalonmm2aximm_bridge.sv`  
  Bridge between Avalon-MM and AXI-MM.
- `avalonmm_mux.sv`  
  Avalon-MM mux / address decode (if multiple Avalon-MM targets are used).

### Memories / Registers
- `instruction_memory.sv`  
  Instruction memory (loaded by host, used by CPU fetch).
- `ram.sv`  
  RAM / data memory block (if used as CPU data memory or scratchpad).
- `register_file.sv`  
  Register block / status/control registers exposed to the bus.
