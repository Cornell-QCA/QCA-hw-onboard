# C2S2 Digital on boarding Fall 2025

**Authors : Anjelica Bian, Demetrios Gavalas, Vayun Tiwari, Simeon Turner**
**Date    : August 30th, 2025**

This is the repository for onboarding for the digital subteam. Everyone will submit their individual work, but you can collaborate individually. In this repo, we have two on-boarding projects at two difficulty levels:
- **Counter**: a simple design for people who are taking ECE 2300
- **Synchronous FIFO**: a slightly more difficult design for people who are taking/have taken ECE 4750 (comp arch)

## Task
``` 
<design>
.
├── build
│   ├── 01-cocotb-rtl-sim
│   │   └── Makefile
│   ├── 02-design-compiler-synth
│   │   └── synth.tcl
│   ├── 03-cocotb-gl-sim
│   │   └── Makefile
│   ├── 04-innovus-pnr
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
