# Tutorial

## Introduction

This guide walks you through the onboarding project from start to finish. You will:

1. Implement your design in SystemVerilog (`sim/<design>/src`).
2. Verify it with cocotb until you reach full coverage (`sim/<design>/test`).
3. Take it through the FPGA implementation flow (`fpga/`): lint, RTL simulation, synthesis, and eventually place and route and a bitstream.

Before you start, source the QCA setup script to load the tools (VCS, cocotb, Verilator, Vivado, pyhflow):

```
% source /classes/qca/setup-qca.sh
```

You need to do this in every new terminal. To have it done automatically when you log in, run `source /classes/qca/setup-qca.sh --enable-auto-setup` once.

## Implementing the Design in RTL

### Pattern Detector

Implement your design in `sim/detector/src/detector.sv`. The specs are in there. You'll be implementing an FSM (Finite state machine). If you're not familiar with SystemVerilog or FSMs, watch this [video](https://www.youtube.com/watch?v=oRy3mJ3Xvz8&list=PLRvJfry30-23Q0Zn3SCVYiDhbqYJq8ql_&index=17) by Professor Zhang.

### Synchronous FIFO

Implement your design in `sim/fifo/src/sync_fifo.sv`. The specs are in there.

## Verifying your Implementation

We will be verifying our implementations using cocotb. This is a form of dynamic verification because we are giving the simulator and DUT a sequence of inputs to simulate. This is different from static verification such as formal, which explores every possible path.

The tests for each design live in `sim/<design>/test`:

- `<design>-test.py`: the cocotb tests
- `<design>-fl.py`: the functional-level (FL) model, a Python model of how the design should behave
- `Makefile`: runs the tests with Synopsys VCS

You are given some boilerplate code to work with, and an example test already implemented called `test_basic`. Let's look over some of the helper functions provided. Every test case should start with `test_init`. This helper function initializes and starts the clock, synchronizes to a rising edge, advances the simulation by 1ns, and resets the DUT. When resetting the DUT, we want to prevent unwanted X-propagation, so we initially drive all input control signals to some idle state. Note that we only need to drive the *control* signals, not datapath signals. This is because our control signals tell the DUT when and how to use the datapath signals, so we don't need to worry about the X's on input data.

We will be implementing dynamic tests similar to how it is done in ECE 2300. We will only drive our input signals one time unit after the rising edge (which is why `test_init` advances time by 1ns), and we will check our output signals against what we expect one time unit before the next rising edge. This timing between driving and checking is handled by the `check` function, which takes each input and output and drives or checks it accordingly. Thus, each call of `check` advances the simulation by exactly one clock cycle. Note that in cocotb you must use the `await` keyword so that the function call progresses the test. Otherwise, the function will not advance simulation time at all.

Implement your directed tests similarly to how `test_basic` is written. Call `test_init`, and then `check` with different sets of inputs and expected outputs. You can use any Python you wish around the check as well. For example, it may be easier to implement a for loop with `check` called inside.

Implementing your random tests will look a little bit different. You must still call `test_init` and test different inputs and expected outputs with `check`. However, you need a way to determine, based on a random set of inputs, what the expected output will be. This is where the FL model comes in. Use that to determine your expected outputs by driving the FL model's input signals (and *only* the input signals), and updating the outputs of the FL model with the `advance_clk` class method. It is simplest to use a for loop here.

Once you have implemented your directed and random tests, **you can run them by executing `make` in the command-line** from your design's test directory:

```
% cd sim/fifo/test
% make
```

We only consider our designs verified after we have reached full coverage. So, we must write enough test cases to achieve this. You can get a coverage report by running `make coverage_report` after running the tests. Run `make clean_all` to remove everything the simulation generated.

## FPGA Flow

Once your design is verified, we take it through an FPGA implementation flow. The flow lives in `fpga/`:

```
fpga
├── designs
│   ├── fifo.yml            # flow config for the FIFO
│   └── fifo
│       └── pins.xdc        # physical constraints for the FIFO
├── scripts                 # helpers shared between steps
│   ├── cocotb-sim.mk
│   └── check-cocotb-results
└── steps                   # one directory per step (templates)
    ├── 00-lint
    ├── 01-cocotb-rtl-sim
    ├── 02-synth
    └── ...
```

Right now steps `00-lint` through `03-ffgl` are implemented. Steps `04` to `07` (place and route, timing signoff, back-annotated gate-level simulation, and bitstream generation) are still to come.

### How the Flow is Generated

The flow is generated with **pyhflow**. Each directory in `fpga/steps` is a *template*: its files contain placeholders like `{{design_name}}` or `{{clock_period}}`. The design yml (for example `fpga/designs/fifo.yml`) lists which steps to use and gives a value for every placeholder. When you run pyhflow, it:

1. copies each step listed under `steps:` in the yml into your build directory,
2. fills in the placeholders in every file with the values from the yml, and
3. writes a `run-flow` script that runs all of the steps in order.

The main variables in the yml are:

| Variable | Meaning |
| --- | --- |
| `design_name` | top-level module name (e.g. `sync_fifo`) |
| `clock_port`, `clock_period` | clock input port and target clock period in ns |
| `fpga_part` | Vivado part name of the target FPGA |
| `src_dir`, `verilog_top` | RTL source directory and top-level Verilog file |
| `tb_dir`, `tb_module` | cocotb test directory and test module name (without `.py`) |
| `tests` | the subset of cocotb tests to run in the flow's simulation steps |
| `constraints` | xdc files with physical constraints (pins, placement, routing) |
| `dump_vcd` | set to `true` to dump waveforms in the simulation steps |

All paths in the yml are relative to a step directory inside the build directory (e.g. `fpga/build-fifo/01-cocotb-rtl-sim`), so always create your build directory inside `fpga/`. Every placeholder a step uses must be defined in the yml; pyhflow stops with an error if one is missing.

Note that the flow does **not** run every test in `sim/<design>/test`. It only runs the tests listed under `tests:`, using the same test file, so there is only one copy of the tests. Add your directed and random tests to that list once they are written.

### Building the Flow

Create a build directory in `fpga/` and run pyhflow on your design's yml:

```
% cd fpga
% mkdir -p build-fifo
% cd build-fifo
% pyhflow ../designs/fifo.yml
```

This creates a directory for each step and a `run-flow` script:

```
build-fifo
├── 00-lint
├── 01-cocotb-rtl-sim
├── 02-synth
├── 03-ffgl
├── ...
└── run-flow
```

If you change the yml or anything in `fpga/steps`, rerun pyhflow to regenerate the build directory. Use `pyhflow --one-test ../designs/fifo.yml` for a quick run that only uses the first test in `tests:`. Build directories are ignored by git.

### Running the Flow

Run a single step with its `run` script, or every step in order with `run-flow`:

```
% ./00-lint/run
% ./01-cocotb-rtl-sim/run
% ./02-synth/run
% ./03-ffgl/run
% ./run-flow
```

Each step writes its output to a `run.log` in its step directory and prints a green `[ PASSED ]` or red `[ FAILED ]` at the end. Note that `run-flow` does not stop when a step fails, so check the output of every step. You can run a step as many times as you like; each run starts fresh.

### 00-lint: Verilator Lint

This step runs Verilator in lint-only mode (`verilator --lint-only -Wall`) on your top-level Verilog file. Linting checks your RTL for common mistakes without simulating it, such as width mismatches, unused signals, and inferred latches. The step fails on any warning, so fix everything it reports in `00-lint/run.log` before moving on.

### 01-cocotb-rtl-sim: RTL Simulation

This step runs the tests listed under `tests:` in the yml on your RTL, using VCS and the cocotb testbench in `sim/<design>/test`. At the end it prints each test as PASSED, FAILED, or MISSING. MISSING means the test never ran, usually because its name in the yml has a typo or the design did not compile; look in `01-cocotb-rtl-sim/run.log` for cocotb's error message. If `dump_vcd` is `true`, the step also writes `waves.vcd`.

The later gate-level simulation steps (`03-ffgl` and `06-bagl`) will use the same tests and the same shared harness (`fpga/scripts/cocotb-sim.mk`). The only difference is that they simulate the synthesized or placed-and-routed netlist instead of your RTL.

### 02-synth: Vivado Synthesis

This step synthesizes your design with Vivado. The `run` script starts Vivado in batch mode, which runs `run.tcl`. The script:

1. reads your top-level Verilog file, the clock constraint, and the xdc files listed under `constraints:`,
2. synthesizes the design for `fpga_part`,
3. writes the outputs and reports, and
4. prints a summary of resource usage (LUTs, flip-flops, LUTRAM, BRAM, DSPs, IOs) and timing slack.

The clock constraint is generated from `clock_port` and `clock_period` in the yml (see `02-synth/clk.xdc`), so change the clock period in the yml, not in an xdc file. Physical constraints such as pin assignments go in the xdc files in `fpga/designs/<design>/`.

The step produces:

| File | Contents |
| --- | --- |
| `outputs/post-synth.dcp` | Vivado checkpoint of the synthesized design, for place and route |
| `outputs/post-synth.v` | synthesized netlist, for gate-level simulation |
| `reports/utilization.rpt` | resources used (area) |
| `reports/utilization-hier.rpt` | resources used, broken down by module |
| `reports/timing-summary.rpt` | timing summary and the 10 worst paths |
| `reports/check-timing.rpt` | constraint problems, such as unconstrained ports or clocks |

**WNS** (worst negative slack) is the slack on the slowest setup path; if it is negative, the design is too slow for `clock_period`. **WHS** is the same for hold. Timing after synthesis is only an estimate because nothing has been placed or routed yet, so negative slack is reported as a warning, not a failure. The real timing check will be done after place and route in `05-sta-signoff`.

### 03-ffgl: Fast-Functional Gate-Level Simulation

This step runs the same tests as `01-cocotb-rtl-sim`, but on the netlist that synthesis produced (`02-synth/outputs/post-synth.v`) instead of your RTL. Run `02-synth` first. It checks that synthesis did not change what your design does. For example, RTL that simulates correctly but relies on behavior synthesis treats differently (such as a missing reset or an incomplete `always_comb`) can fail here. "Fast-functional" means there are no gate or wire delays; timing is checked separately.

The netlist is built from Xilinx primitives (`LUT6`, `FDRE`, `MUXF7`, `IBUF`, and so on) instead of your modules. VCS gets their simulation models from the Vivado install, in `data/verilog/src/unisims`. These primitives also connect to a global module called `glbl`, which models the FPGA's global set/reset (GSR). The step compiles `glbl.v` as a second top-level module. It also sets `glbl.ROC_WIDTH` to 0 so that GSR does not hold the flip-flops in reset for the first 100 ns; your test's reset controls the design, as it does in RTL simulation.

The output is the same as in `01-cocotb-rtl-sim`: each test is reported as PASSED, FAILED, or MISSING, with details in `03-ffgl/run.log`. If a test passes in `01` but fails here, compare the two `run.log` files and set `dump_vcd` to `true` to compare waveforms.

### Adding Your Own Design to the Flow

To run a different design through the flow, copy `fpga/designs/fifo.yml` and the `fpga/designs/fifo/` directory, then update the design name, source paths, test module, test list, and constraints. Build it in its own build directory (e.g. `fpga/build-detector`).
