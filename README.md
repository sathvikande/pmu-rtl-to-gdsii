# pmu-rtl-to-gdsii
RTL-to-GDSII implementation of a low-power Power Management Unit (PMU) using FSM-based design in Verilog with Cadence Encounter flow.
This repository presents the complete RTL-to-GDSII implementation of a Power Management Unit (PMU) designed for low-power VLSI systems.

The PMU is modeled as a finite state machine with four operating modes—Sleep, Idle, Active, and Boost—enabling dynamic voltage scaling and clock gating based on workload conditions.

The design is implemented in Verilog HDL and synthesized, placed, and routed using the Cadence Encounter toolchain (180 nm CMOS technology). Post-layout analysis includes area estimation, clock tree synthesis, and timing validation.

This project demonstrates an efficient and scalable PMU architecture suitable for energy-aware digital systems.
