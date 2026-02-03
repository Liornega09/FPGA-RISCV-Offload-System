# FPGA-Based Sideband Protocol Offload System with RISC-V

## Overview
This project implements a programmable offload engine on an FPGA to manage sideband protocol logic autonomously, reducing host CPU workload and system latency. The system is designed for Intel's prototyping environments, bridging the gap between **HAPS-80** hardware fabric and **Simics** software models via the **FGT (FPGA to Guest Transport)** layer. 

The architecture features an embedded **PicoRV32 RISC-V** core, a custom **AvalonMM-to-AXIMM bridge**, and a memory-mapped register file with integrated write logic for dynamic firmware updates.

### Key Results
**Performance Gain**: Achieved a **7,314x speedup** compared to host-based software processing. 
**Latency Reduction**: Total latency reduced by **>99.9%** (from seconds to sub-millisecond range). 
**Concurrency**: Verified 100% success rate in concurrent register access between the host and RISC-V core. 

---

## ⚠️ Proprietary IP Note
This repository contains the custom-developed RTL and firmware for the project. **It does not include proprietary Intel/Vendor IP cores** (e.g., PCIe-to-AXI-MM bridge).  To build the system, users must provide their own instances of these IPs and integrate them using the provided top-level wrappers.

---

## Repository Structure

### Hardware (`/riscv_hw`)
Contains the SystemVerilog source files for the FPGA logic: 
`picorv32.v`: The open-source, size-optimized RISC-V (RV32I) soft-processor core
`avalonmm2aximm_bridge.sv`: Custom FSM-based protocol translator. 
`register_file.sv`: Shared communication space with integrated **Instruction Write Logic**.
`instruction_memory.sv`: Dedicated memory block for firmware execution. 
`avalonmm_mux.sv`: Arbiter for instruction memory access. 
`riscv_top.sv`: Top-level system integration wrapper.

### Software (`/riscv_sw`)
Contains the C-based firmware and build system: 
`/src`: Firmware source code for sideband protocol management.
`/scripts`: Custom linker scripts for HAPS-80 memory mapping. 
`CMakeLists.txt`: Automated build configuration for the RISC-V GCC toolchain. 

---

## How to Use

### 1. Firmware Compilation
The firmware is compiled using the `riscv64-unknown-elf-gcc` toolchain.

chmod +x cmake.runme.sh
./cmake.runme.sh riscv_test 28 28 0 1


## Credits
This project utilizes the following open-source components:
* **PicoRV32**: A size-optimized RISC-V CPU core developed by Claire Xenia Wolf. [GitHub Repository](https://github.com/YosysHQ/picorv32)
