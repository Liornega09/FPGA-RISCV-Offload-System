# Software (SW)

This directory contains the software stack for the project, including the RISC-V firmware
that runs on the sideband PicoRV32 CPU and supporting build/run scripts.

## Directory Layout

- `src/`  
  Firmware sources (C/C++), headers, and any project-specific modules.
- `scripts/`  
  Helper scripts (build automation, packaging, bring-up helpers, etc.).
- `CMakeLists.txt`  
  Top-level CMake build definition.
- `esr_riscv.cmake`  
  Toolchain / platform CMake include (RISC-V compiler flags, linker options, etc.).
- `cmake_runme.sh`  
  Convenience script to configure + build using CMake.
- `runme_cmd.txt`  
  Notes / example commands for building or running (optional; may be migrated into this README).
- `build/` *(generated)*  
  Build output directory (not tracked in Git).

## Prerequisites

- A RISC-V bare-metal toolchain (example):
  - `riscv64-unknown-elf-gcc`, `riscv64-unknown-elf-ld`, `objcopy`, `objdump`
- CMake (recommended 3.16+)
- Make or Ninja

Verify toolchain is in PATH:
```bash
riscv64-unknown-elf-gcc --version
cmake --version
