# Tutorial

## Introduction

## Implementing the Design in RTL

### Pattern Detector

Implement your design in `detector/src/detector.sv`. The specs are in there. You'll be implementing an FSM (Finite state machine). If you're not familiar with system verilog or FSMs watch this [video](https://www.youtube.com/watch?v=oRy3mJ3Xvz8&list=PLRvJfry30-23Q0Zn3SCVYiDhbqYJq8ql_&index=17) by professor Zhang.

### Synchronous FIFO

Implement your design in `fifo/src/sync_fifo.sv`. The specs are in there.

## Verifying your Implementation

We will be verifying our implementations using CoCoTB. This is a form of dynamic verification because we are giving the simulator and DUT a sequence of inputs to simulate. This is different from static verification such formal which explores every possible path.

You are given some boilerplate code to work with, and an example test already implemented called `test_basic`. Let's look over some of the helper functions provided. Every test case should start with `test_init`. This helper function initializes and starts the clock, synchronizes to a rising edge, advances the simulation by 1ns, and resets the DUT. When reseting the DUT, we want to ensure we prevent unwanted X-propagation, so we initially drive all input control signals to some idle state. Note that we only need to drive the *control* signals, not datapath signals. This is because our control signals tell the DUT when and how to use the datapath signals, so we don't need to worry about the X's on input data.

We will be implementing dynamic tests similar to how is done in ECE 2300 (FA). We will only drive our input signals one time unit after the rising edge (which is why `test_init` advances time by 1ns), and we will check our output signals against what we expect one time unit before the next rising edge. This timing between driving and checking is handled by the `check` function, which takes each input and output and drives or checks it accordingly. Thus, each call of `check` advances the simulation by exactly one clock cycle. Note that in CoCoTB you must use the `await` keyword so that the function call progresses the test. Otherwise, the function will not advance simulation time at all.

Implement your directed tests similarly to how is written in `test_basic`. Call `test_init`, and then `check` with different sets of inputs and expected outputs. You can use any Python you wish around the check as well. For example, it may be easier to implement a for loop with `check` called inside.

Implementing your random tests will look a little bit different. You must still call `test_init` and test different inputs and expected outputs with `check`. However, you need a we to determine, based on a random set of inputs, what the expected output will be. This is where the functional-level (FL) model comes in. Use that to determine your inputs by driving the input signals (and *only* the input signals), and updating the outputs of the FL model with the `advance_clk` class method. It is simplest to use a for loop here.

Once you have implemented your directed and random tests, **you can run them by executing `make` in the command-line** in directory of your tests and Makefile.

We only consider our designs verified after we have reached full coverage. So, we must write enough test cases to achieve this. You can get a coverage report by running `make coverage_report` after running the tests.

### Pattern Detector



### Synchronous FIFO



##### Notes to self
- add yosys section
- add nextpnr section
- add cocotb setup and such
