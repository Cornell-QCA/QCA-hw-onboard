# QCA Hardware onboarding project FA2026

**Authors : Ivan Mokeyev**

**Date    : August 29th, 2026**

This is the repository for onboarding for the hardware team. Everyone will submit their individual work, but you can collaborate individually. In this repo, we have two on-boarding projects at two difficulty levels:
- **Counter**: a simple design for people who are taking ECE 2300 or are new to Verilog and Digital Logic
- **Synchronous FIFO**: a slightly more difficult design for people who are taking/have taken ECE 4750 (comp arch), or if you have first done the detector design.

## Task
``` 
<design>
.
├── build
│   ├── 01-cocotb-rtl-sim
│   │   └── Makefile
│   ├── 02-yosys-synth
│   │   └── synth.tcl
│   ├── 03-cocotb-gl-sim
│   │   └── Makefile
│   ├── 04-nextpnr-par
│   │   └── pnr.tcl
│   ├── 05-cocotb-ba-sim
│   │   └── Makefile
│   └── init.sh
├── src
│   └── <design>.sv
└── test
    ├── <design>_fl.py
    ├── <design>-test.py
    └── Makefile
```

For detailed instructions, follow guide.md.
