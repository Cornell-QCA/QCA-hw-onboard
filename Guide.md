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
- add section on verilator linting?
- explain what dynamic testing is?
- explain x-prop

## Physical Design Flow

We use **Synopsys Design Compiler (DC)** to synthesize our design,
which means to transform the Verilog RTL model into a Verilog
gate-level netlist where all of the gates are selected from the
standard-cell library. We need to provide Synopsys DC with abstract
logical and timing views of the standard-cell library in `.db`
format. In addition to the Verilog gate-level netlist, Synopsys DC
can also generate a `.ddc` file which contains information about the
gate-level netlist and timing, and this `.ddc` file can be inspected
using Synopsys Design Vision (DV). We will also use Synopsys DC to
generate a `.sdc` which captures timing constraints which can then be
used as input to the place-and-route tool.

We use **Cadence Innovus** to place-and-route our design, which means
to place all of the gates in the gate-level netlist into rows on the
chip and then to generate the metal wires that connect all of the
gates together. We need to provide Cadence Innovus with the same
abstract logical and timing views used in Synopsys DC, but we also
need to provide Cadence Innovus with technology information in
`.lef`, and `.captable` format and abstract physical views of the
standard-cell library also in `.lef` format. Cadence Innovus will
generate an updated Verilog gate-level netlist, a `.spef` file which
contains parasitic resistance/capacitance information about all nets
in the design, and a `.gds` file which contains the final layout. The
`.gds` file can be inspected using the open-source Klayout GDS
viewer. Cadence Innovus also generates reports which can be used to
accurately characterize area and timing.

first step is to source the setup script (if you have not already), and then to source the init.sh script in the build directory
```bash
% source /classes/c2s2/setup-c2s2-tsmc.sh
% cd <design>/build
% source init.sh
```

02. Synopsys Design Compiler for Synthesis
--------------------------------------------------------------------------

We use Synopsys Design Compiler (DC) to synthesize Verilog RTL models
into a gate-level netlist where all of the gates are from the standard
cell library. So Synopsys DC will synthesize the Verilog `+` operator
into a specific arithmetic block at the gate-level. Based on various
constraints it may synthesize a ripple-carry adder, a carry-look-ahead
adder, or even more advanced parallel-prefix adders.

```bash
% cd 02-design-compiler-synth/
% module load synopsys/synopsys-dc
$ dc_shell
```

### 02.1. Initial Setup

There are two important variables we need to set before starting to work
in Synopsys DC. The `target_library` variable specifies the standard
cells that Synopsys DC should use when synthesizing the RTL. The
`link_library` variable should search the standard cells, but can also
search other cells (e.g., SRAMs) when trying to resolve references in our
design. These other cells are not meant to be available for Synopsys DC
to use during synthesis, but should be used when resolving references.
Including `*` in the `link_library` variable indicates that Synopsys DC
should also search all cells inside the design itself when resolving
references.

```
dc_shell> set_app_var target_library "$env(STDVIEW_45)/stdcells.db"
dc_shell> set_app_var link_library   "* $env(STDVIEW_45)/stdcells.db"
```

Note that we can use `$env(STDVIEW_45)` to get access to the
`$STDVIEW_45` environment variable which specifies the directory
containing the standard cells, and that we are referencing the abstract
logical and timing views in the `.db` format.

We also need to tell Synopsys DC not use scan flip-flops and clock-gating
cells which are included in our standard-cell library. If Synopsys DC
uses these cells it can cause isses with gate-level simulation. We can do
this using the `set_dont_use` command as follows.

```
dc_shell> set_dont_use -power {
  NangateOpenCellLibrary/SDFF_X1
  NangateOpenCellLibrary/SDFF_X2
  NangateOpenCellLibrary/SDFFS_X1
  NangateOpenCellLibrary/SDFFS_X2
  NangateOpenCellLibrary/SDFFR_X1
  NangateOpenCellLibrary/SDFFR_X2
  NangateOpenCellLibrary/SDFFRS_X1
  NangateOpenCellLibrary/SDFFRS_X2
  NangateOpenCellLibrary/CLKGATETST_X1
  NangateOpenCellLibrary/CLKGATETST_X2
  NangateOpenCellLibrary/CLKGATETST_X4
  NangateOpenCellLibrary/CLKGATETST_X8
}
```

### 02.2. Inputs

As an aside, if you want to learn more about any command in any Synopsys
tool, you can simply type `man toolname` at the shell prompt. We are now
ready to read in the Verilog file which contains the top-level design and
all referenced modules. We do this with two commands. The `analyze`
command reads the Verilog RTL into an intermediate internal
representation. The `elaborate` command recursively resolves all of the
module references starting from the top-level module, and also infers
various registers and/or advanced data-path components.

```
dc_shell> analyze -format sverilog ../../src/sync_fifo.sv 
dc_shell> elaborate sync_fifo
```

### 02.3. Timing Constraints

We need to create a clock constraint to tell Synopsys DC what our target
cycle time is. Synopsys DC will not synthesize a design to run "as fast
as possible". Instead, the designer gives Synopsys DC a target cycle time
and the tool will try to meet this constraint while minimizing area and
power. The `create_clock` command takes the name of the clock signal in
the Verilog (which in this course will always be `clk`), the label to
give this clock (i.e., `ideal_clock1`), and the target clock period in
nanoseconds. So in this example, we are asking Synopsys DC to see if it
can synthesize the design to run at 1.4GHz (i.e., a cycle time of 700ps).

```
dc_shell> create_clock clk -name ideal_clock1 -period 0.7
```

In addition to the clock constraint we also need to constrain the max
transition time to ensure no net takes a very long time to transition.
Here we constrain the max transition to be 250ps.

```
dc_shell> set_max_transition 0.250 sync_fifo
```

We need to constrain what kind of cells are expected to drive the input
pins and what kind of load is expected at the output pin so Synopsys DC
can properly synthesize the design. here we constrain the input cells to
be inverters with 2x drive strength and the output load to be 7fF.

```
dc_shell> set_driving_cell -no_design_rule -lib_cell INV_X2 [all_inputs]
dc_shell> set_load -pin_load 7 [all_outputs]
```

In an ideal world, all inputs would change immediately with the clock
edge. In reality, this is not the case since there will be some logic
before this block on the chip.

We need to include reasonable propagation and contamination delays for
the input ports so Synopsys DC can factor these into its timing analysis.
Here, we choose the max input delay constraint to be 50ps (i.e., the
block needs to meet the setup time constraints even if the inputs change
50ps after the rising edge of the clock), and we choose the min input
delay constraint to be 0ps (i.e., the block needs to meet the hold time
constraints even if the inputs change right on the rising edge clock).

```
dc_shell> set_input_delay -clock ideal_clock1 -max 0.050 [all_inputs -exclude_clock_ports]
dc_shell> set_input_delay -clock ideal_clock1 -min 0.000 [all_inputs -exclude_clock_ports]
```

We also need to constrain the output ports since there will be some logic
after this block on the chip.

We need to include reasonable setup and hold time constraints for the
output ports so Synopsys DC can factor these into into its timing
analysis. Here we choose a setup time constraint of 50ps meaning the
output data must be stable 50ps before the rising edge of the clock, and
we choose a hold time constraint of 0ps meaning the outputs can change
right on the rising edge of the clock.

```
dc_shell> set_output_delay -clock ideal_clock1 -max 0.050 [all_outputs]
dc_shell> set_output_delay -clock ideal_clock1 -min 0.000 [all_outputs]
```

Finally we also need to constraint any combinational paths which go
directly from the input ports to the output ports. Here we constrain such
paths to be no longer than one cycle cycle.

```
dc_shell> set_max_delay 0.7 -from [all_inputs -exclude_clock_ports] -to [all_outputs]
```

Once we have finished setting all of the constraints we can use
`check_timing` to make sure there are no unconstrained paths or other
issues.

### 02.4. Synthesis

We can use the `check_design` command to make sure there are no obvious
errors in our Verilog RTL.

```
dc_shell> check_design
```

It is _critical_ that you carefully review all warnings and errors when
you analyze and elaborate a design with Synopsys DC. There may be many
warnings, but you should still skim through them. Often times there will
be something very wrong in your Verilog RTL which means any results from
using the ASIC tools is completely bogus. Synopsys DC will output a
warning, but Synopsys DC will usually just keep going, potentially
producing a completely incorrect gate-level model!

Finally, the `compile` command will do the synthesis.

```
dc_shell> compile
```

During synthesis, Synopsys DC will display information about its
optimization process. It will report on its attempts to map the RTL into
standard-cells, optimize the resulting gate-level netlist to improve the
delay, and then optimize the final design to save area.

The `compile` command does not _flatten_ your design. Flatten means to
remove module hierarchy boundaries; so instead of having module A and
module B within module C, Synopsys DC will take all of the logic in
module A and module B and put it directly in module C. You can enable
flattening with the `-ungroup_all` option. Without extra hierarchy
boundaries, Synopsys DC is able to perform more optimizations and
potentially achieve better area, energy, and timing. However, an
unflattened design is much easier to analyze, since if there is a module
A in your RTL design that same module will always be in the synthesized
gate-level netlist.

The `compile` command does not perform many optimizations. Synopsys DC
also includes `compile_ultra` which does many more optimizations and will
likely produce higher quality of results. Keep in mind that the `compile`
command _will not_ flatten your design by default, while the
`compile_ultra` command _will_ flattened your design by default. You can
turn off flattening by using the `-no_autoungroup` option with the
`compile_ultra` command. `compile_ultra` also has the option
`-gate_clock` which automatically performs clock gating on your design,
which can save quite a bit of power. Once you finish this tutorial, feel
free to go back and experiment with this command.

```
dc_shell> compile_ultra -no_autoungroup -gate_clock`
```

### 02.5. Outputs

Now that we have synthesized the design, we output the resulting
gate-level netlist in two different file formats: `.ddc` (which we will
use with Synopsys DesignVision) and Verilog. We also output an `.sdc`
file which contains the constraint information we gave Synopsys DC. We
will pass this same constraint information to Cadence Innovus during the
place and route portion of the flow.

```
dc_shell> file mkdir outputs
dc_shell> write -format ddc -hierarchy -output outputs/post-synth.ddc
dc_shell> write -format verilog -hierarchy -output outputs/post-synth.v
dc_shell> write_sdc outputs/post-synth.sdc
```

We can use various commands to generate reports about timing and area.
The `report_timing` command will show the critical path through the
design.

```
dc_shell> file mkdir reports
dc_shell> report_timing -nets > reports/timing.rpt
```
This timing report uses _static timing analysis_ to find the critical
path. Static timing analysis checks the timing across all paths in the
design (regardless of whether these paths can actually be used in
practice) and finds the longest path.

The difference between the required arrival time and the actual arrival
time is called the _slack_. In the above report we just meet timing with
zero slack. Positive slack means the path arrived before it needed to
while negative slack means the path arrived after it needed to. If you
end up with negative slack, then you need to rerun the tools with a
longer target clock period until you can meet timing with no negative
slack. The process of tuning a design to ensure it meets timing is called
"timing closure". In this course, we are primarily interested in
design-space exploration as opposed to meeting some externally defined
target timing specification. So you will need to sweep a range of target
clock periods. **Your goal is to choose the shortest possible clock
period which still meets timing without any negative slack!** This will
result in a well-optimized design and help identify the "fundamental"
performance of the design. Alternatively, if you are comparing multiple
designs, sometimes the best situation is to tune the baseline so it meets
timing and then ensure the alternative designs have similar cycle times.
This will enable a fair comparison since all designs will be running at
the same cycle time.

The `report_area` command will show how much area is required to
implement each module in the design.

```
dc_shell> report_area > reports/area.rpt
```

Finally, we go ahead and exit Synopsys DC.

```
dc_shell> exit
```

Take a few minutes to examine the resulting Verilog gate-level netlist.

### 02.6. Synopsys Design Vision

We can use the Synopsys Design Vision (DV) tool for browsing the
resulting gate-level netlist, plotting critical path histograms, and
generally analyzing our design. Start Synopsys DV (with gui, X-forwarding) and setup the
`target_library` and `link_library` variables as before.

```
% design_vision-xg
design_vision> set_app_var target_library "$env(STDVIEW_45)/stdcells.db"
design_vision> set_app_var link_library   "* $env(STDVIEW_45)/stdcells.db"
```

You can use the following steps to open the `.ddc` file generated during
synthesis.

 - Choose _File > Read_ from the menu
 - Open the `outputs/post-synth.dcc` file

You can then use the following steps to browse the gate-level schematic.
First select a module in the Logical Hierarchy panel. Then choose
_Schematic > New Schematic View_. You can double click on modules to
expand them. You might also want to try this approach to see the entire
design at once:

 - Select the `sync_fifo` module in the Logical Hierarchy panel
 - Choose _Select > Cells > Leaf Cells of Selected Cells_ from the menu
 - Choose _Schematic > New Schematic View_ from the menu
 - Choose _Select > Clear_ from the menu

You can use the following steps to view a histogram of path slack, and
also to open a gave-level schematic of just the critical path.

 - Choose _Timing > Path Slack_ from the menu
 - Click _OK_ in the pop-up window
 - Select the left-most bar in the histogram to see list of most critical paths
 - Select one of the paths in the path list to highlight the path in the schematic view

Or you can right click on a path and choose _Path Schematic_ to see just
the gates that lie on the critical path. Notice that there eight levels
of logic (including the register at the start) on the critical path. The
number of levels of logic on the critical path can provide some very
rough first-order intuition on whether or not we might want to explore a
more aggressive clock constraint and/or adding more pipeline stages. If
there are just a few levels of logic on the critical path then our design
is probably very simple (as in this case!), while if there are more than
50 levels of logic then there is potentially room for signficant
improvement. We almost always prefer exploring the
post-place-and-route results, so we will not really use Synopsys DV that
often.

### 02.7. Synopsys Design Vision

You can automate the above steps by putting a sequence of commands in a
`.tcl` file and run Synopsys DC using those commands in one step like
this:

```bash
% dc_shell -f synth.tcl
```

3. Synopsys VCS for Fast-Functional Gate-Level Simulation
--------------------------------------------------------------------------

@simeon

2. Cadence Innovus for Place-and-Route
--------------------------------------------------------------------------

We use Cadence Innovus for placing standard cells in rows and then
automatically routing all of the nets between these standard cells. We
also use Cadence Innovus to route the power and ground rails in a grid
and connect this grid to the power and ground pins of each standard cell,
and to automatically generate a clock tree to distribute the clock to all
sequential state elements with hopefully low skew.

We will be running Cadence Innovus in a separate directory to keep the
files separate from the other tools.

```bash
% cd /04-innovus-pnr
```

### 04.1. Timing Analysis Setup File

Before starting Cadence Innovus, we need to create a file to setup the
timing analysis. This file specifies what "corner" to use for our timing
analysis. A corner is a characterization of the standard cell library and
technology with specific assumptions about the process, temperature, and
voltage (PVT). So we might have a "fast" corner which assumes best-case
process variability, low temperature, and high voltage, or we might have
a "slow" corner which assumes worst-case variability, high temperature,
and low voltage. To ensure our design will work across a range of
operating conditions, we need to evaluate our design across a range of
corners. In this tutorial, we will keep things simple by only considering a
"typical" corner (i.e., average PVT). Open the file named
`setup-timing.tcl`.

The `create_rc_corner` command loads in the `.captable` file that we
examined earlier. This file includes information about the resistance and
capacitance of every metal layer. Notice that we are loading in the
"typical" captable and we are specifying an "average" operating
temperature of 25 degC. The `create_library_set` command loads in the
`.lib` file that we examined earlier. This file includes information
about the input/output capacitance of each pin in each standard cell
along with the delay from every input to every output in the standard
cell. The `create_delay_corner` specifies a specific corner that we would
like to use for our timing analysis by putting together a `.captable` and
a `.lib` file. In this specific example, we are creating a typical corner
by putting together the typical `.captable` and typical `.lib` we just
loaded. The `create_constraint_mode` command loads in the post-synthesis
`.sdc` file which captures all of the timing constraints after synthesis.
The `create_analysis_view` command puts together constraints with a
specific corner, and the `set_analysis_view` command tells Cadence
Innovus that we would like to use this specific analysis view for both
setup and hold time analysis.

### 04.2. Initial Setup

Now that we have created our `setup-timing.tcl` file we can start Cadence
Innovus:

```bash
% innovus
```

As we enter commands we will be able use the GUI to see incremental
progress towards a fully placed-and-routed design. We need to set various
variables before starting to work in Cadence Innovus. These variables
tell Cadence Innovus the location of the MMMC file, the location of the
Verilog gate-level netlist, the name of the top-level module in our
design, the location of the `.lef` files, and finally the names of the
power and ground nets.

```
innovus> set init_mmmc_file "setup-timing.tcl"
innovus> set init_verilog   "../02-design-compiler-synth/outputs/post-synth.v"
innovus> set init_top_cell  "sync_fifo"
innovus> set init_lef_file  "$env(STDVIEW_45)/rtk-tech.lef  $env(STDVIEW_45)/stdcells.lef"
innovus> set init_gnd_net   "VSS"
innovus> set init_pwr_net   "VDD"
```

We are now ready to use the `init_design` command to read in the verilog,
set the design name, setup the timing analysis views, read the technology
`.lef` for layer information, and read the standard cell `.lef` for
physical information about each cell used in the design.

```
innovus> init_design
```

We also need to tell Cadence Innovus the process node are using so it can
roughly estimate specific technology parameters.

```
innovus> setDesignMode -process 45
```

Cadence Innovus includes many advanced timing-driven optimizations by
default. Two examples include signal integrity analysis (e.g., capacitive
coupling across signal wires) and useful clock skew (e.g., purposefully
introducing clock skew to give more time for critical paths at the
expense of other paths). To simply our timing analysis we will turn these
optimizations off as follows.

```
innovus> setDelayCalMode -SIAware false
innovus> setOptMode -usefulSkew false
```

Cadence Innovus can fix hold-time violations by inserting extra buffers
to delay certain paths. We add an extra hold-time target slack so that
Cadence Innovus will work extra hard to meet the hold-time, and we need
to tell Cadence Innovus which standard cells to use when fixing hold-time
violations as follows.

```
innovus> setOptMode -holdTargetSlack 0.010
innovus> setOptMode -holdFixingCells {
  BUF_X1 BUF_X1 BUF_X2 BUF_X4 BUF_X8 BUF_X16 BUF_X32
}
```
### 04.3. Floorplanning

The next substep is floorplaning. This is where we broadly organize the
chip in terms of its overall dimensions and the placement of any
previously designed blocks. For now we just do some very simple
floorplanning using the `floorPlan` command.

```
innovus> floorPlan -r 1.0 0.70 4.0 4.0 4.0 4.0
```

In this example, we have chosen the aspect ratio to be 1.0 and a target
cell utilization to be 70%. The cell utilization is the percentage of the
final chip that will actually contain useful standard cells as opposed to
just "filler" cells (i.e., empty cells). Ideally, we would like the cell
utilization to be 100% but this is simply not reasonable. If the cell
utilization is too high, Cadence Innovus will spend way too much time
trying to optimize the design and will eventually simply give up. A
target cell utilization of 70% makes it more likely that Cadence Innovus
can successfuly place and route the design. We have also added 4.0um of
margin around the top, bottom, left, and right of the chip to give us
room for the power ring which will go around the entire chip.

You can use the _View > Fit_ menu option to see the entire chip.

### 2.4. Placement

The next substep is cell placement. We can do the placement and initial
routing of the standard cells using the `place_opt_design` command:

```
innovus> place_opt_design
```

Note that Cadence Innovus has only done a very preliminary routing,
primarily to help improve placement.

If our design has any constant values, then we need to insert special
standard cells to "tie" those constant values to either VDD or ground
using the `addTieHiLo` command.

```
innovus> addTieHiLo -cell "LOGIC1_X1 LOGIC0_X1"
```

After placement and tie cell insertion, we can assign IO pin locations
for our block-level design. Since this is not a full chip with IO pads,
or a hierarchical block, we don't really care exactly where all of the
pins line up, so we'll let the tool assign the location for all of the
pins.

```
innovus> assignIoPins -pin *
```

### 04.5. Power Routing

The next substep is power routing. Recall that each standard cell has
internal M1 power and ground rails which will connect via abutment when
the cells are placed into rows. If we were just to supply power to cells
using these rails we would likely have large IR drop and the cells in the
middle of the chip would effectively be operating at a much lower
voltage. During power routing, we create a grid of power and ground wires
on the top metal layers and then connect this grid down to the M1 power
rails in each row. We also create a power ring around the entire
floorplan. Before doing the power routing, we need to use the
`globalNetCommand` command to tell Cadence Innovus which nets are power
and which nets are ground (there are _many_ possible names for power and
ground!).

```
innovus> globalNetConnect VDD -type pgpin -pin VDD -all -verbose
innovus> globalNetConnect VSS -type pgpin -pin VSS -all -verbose
innovus> globalNetConnect VDD -type tiehi -pin VDD -all -verbose
innovus> globalNetConnect VSS -type tielo -pin VSS -all -verbose
```

We can now draw M1 "rails" for the power and ground rails that go along
each row of standard cells.

```
innovus> sroute -nets {VDD VSS}
```

We now create a power ring around our chip using the `addRing` command. A
power ring ensures we can easily get power and ground to all standard
cells. The command takes parameters specifying the width of each wire in
the ring, the spacing between the two rings, and what metal layers to use
for the ring. We will put the power ring on M7 and M8; we often put the
power routing on the top metal layers since these are fundamentally
global routes and these top layers have low resistance which helps us
minimize static IR drop and di/dt noise. These top layers have high
capacitance but this is not an issue since the power and ground rails are
not switching (and indeed this extra capacitance can serve as a very
modest amount of decoupling capacitance to smooth out time variations in
the power supply).

```
innovus> addRing \
  -nets {VDD VSS} -width 0.8 -spacing 0.8 \
  -layer [list top 9 bottom 9 left 8 right 8]
```

We have power and ground rails along each row of standard cells and a
power ring, so now we need to hook these up. We can use the `addStripe`
command to draw wires and automatically insert vias whenever wires cross.
First, we draw the horizontal "stripes".

```
innovus> addStripe \
  -nets {VSS VDD} -layer 9 -direction horizontal \
  -width 0.8 -spacing 4.8 \
  -set_to_set_distance 11.2 -start_offset 2.4
```

And then we draw the vertical "stripes".

```
innovus> addStripe \
  -nets {VSS VDD} -layer 8 -direction vertical \
  -width 0.8 -spacing 4.8 \
  -set_to_set_distance 11.2 -start_offset 2.4
```

You can toggle the visibility of metal layers by using the panel on the
right. Click the checkbox in the V column to toggle the visibility of the
corresponding layer. You can also simply use the number keys on your
keyboard.

### 04.6. Clock-Tree Synthesis

The next substep is clock-tree synthesis. First, let's display the
preliminary clock tree created in the previous step so we can clearly see
the impact of optimized clock tree routing. In the right panel click on
_Net_ and then deselect the checkbox in the V column next to _Signal_,
_Special Net_, _Power_, and _Ground_ so that only _Clock_ is selected.
You should be able to see the clock snaking around the chip connecting
the clock port of all of the registers. Now use the `ccopt_design`
command to optimize the clock tree routing.

```
innovus> create_ccopt_clock_tree_spec
innovus> set_ccopt_property update_io_latency false
innovus> clock_opt_design
```

By default, Cadence Innovus can optimize the clock tree by adding a
"clock source insertion latency". Essentially this means that Cadence
Innovus might decide that the top-level chip should adjust the delay
between the input pins and the clock. Unfortunately, this makes it more
difficult for us to perform block-level back-annotated gate-level
simulation so for now we will disable this optimization.

If you watch closely you should see a significant difference in the clock
tree routing before and after optimization.

The routes are straighter, shorter, and well balanced. This will result
in much lower clock skew.

We should now use the `optDesign` command to try and fix both setup time
violations (e.g., by choosing different standard cells to reduce the
delay of the critical path) and hold time violations (e.g., by inserting
buffers to increase the delay of certain fast paths).

```
innovus> optDesign -postCTS -setup
innovus> optDesign -postCTS -hold
```

### 04.7. Routing

The next substep is routing. Although we already did a preliminary
routing during the placement substep, we now want to optimize this signal
routing. Display just the signals but not the power and ground routing by
clicking on the checkbox in the V column next to _Signal_ in the left
panel. Then use the `routeDesign` command to optimize the signal routing.
We follow this with another iteration of `optDesign` to fix any violating
paths that were created during `routeDesign`.

```
innovus> routeDesign
```

If you watch closely you should see a significant difference in the
signal routing before and after optimization.

Again the routes are straighter and shorter. This will reduce the
interconnect resistance and capacitance and thus improve the delay and
energy of our design.

Once again, we can now use the `optDesign` command to try and fix both
setup time violations (e.g., by choosing different standard cells to
reduce the delay of the critical path) and hold time violations (e.g., by
inserting buffers to increase the delay of certain fast paths).

```
innovus> optDesign -postRoute -setup
innovus> optDesign -postRoute -hold
```

Now that our design is fully placed and routed, we can extract the
parasitic resistance and capacitances to enable more accurate timing and
power analysis.

```
innovus> extractRC
```

### 04.8. Finishing

One final step is to insert "filler" cells. Filler cells are essentially
empty standard cells whose sole purpose is to connect the wells across
each standard cell row.

```
innovus> setFillerMode -core {FILLCELL_X4 FILLCELL_X2 FILLCELL_X1}
innovus> addFiller
```

Zoom in to see some of the detailed routing and take a moment to
appreciate how much effort the tools have done for us automatically to
synthesize, place, and route this design.

Notice how each metal layer always goes in the same direction. So M2 is
always vertical, M3 is always horizontal, M4 is always vertical, etc.
This helps reduce capacitive coupling across layers and also simplifies
the routing algorithm. Actually, if you look closely in the above screen
shot you can see situations on M2 (red) and M3 (green) where the router
has generated a little "jog" meaning that on a single layer the wire goes
both vertically and horizontally. This is an example of the sophisticated
algorithms used in these tools.

Another final step do is verify that the gate-level netlist matches what
is really in the final layout. We can do this using the
`verifyConnectivity` command. We can also do a preliminary "design rule
check" to make sure that the generated metal interconnect does not
violate any design rules with the `verify_drc` command.

```
innovus> verifyConnectivity
innovus> verify_drc
```

### 04.9. Outputs and Reports

Now we can generate various output files and reports. We start by saving
the design so we can reload the design into Cadence Innovus for later
analysis using the GUI.

```
innovus> saveDesign post-pnr.enc
```

We also need to save the final gate-level netlist to enable
back-annotated gate-level simulation, since Cadence Innovus will often
insert new cells or change cells during its optimization passes.

```
innovus> saveNetlist post-pnr.v
```

We can write parasitic information to a special `.spef` file. This file
can be used for later power analysis.

```
innovus> file mkdir outputs
innovus> rcOut -rc_corner typical -spef post-pnr.spef
```

You may get an error regarding open nets. This is actually more of a
warning message, and for the purposes of RC extraction we can ignore
this.

We also need to extract delay information and write this to an `.sdf`
(Standard Delay Format) file, which we'll use for our back-annotated
gate-level simulations.

```
innovus> write_sdf outputs/post-pnr.sdf
```

Finally, we of course need to generate the real layout as a `.gds` file.
This is what we will send to the foundry when we are ready to tapeout the
chip.

```
innovus> streamOut outputs/post-pnr.gds \
  -merge "$env(STDVIEW_45)/stdcells.gds" \
  -mapFile "$env(STDVIEW_45)/rtk-stream-out.map"
```

We can also use Cadence Innovus to do timing, area, and power analysis
similar to what we did with Synopsys DC. These post-pnr results will be
_much_ more accurate than the preliminary post-synthesis results. Let's
start with a basic setup timing report.

```
innovus> file mkdir reports
innovus> report_timing -late > reports/setup.rpt
```

Note that it is very likely that the critical path identified by
Synsopsys DC after synthesis will _not_ be the same critical path
identified by Cadence Innovus after place-and-route. This is because
Synopsys DC can only guess the final placement of the cells and
interconnect during static timing analysis, while Cadence Innovus can use
the real placement of the cells and interconnect during static timing
analysis. For the same reason, there is no guarantee that if your design
meets timing after synthesis that it will still meet timing after
place-and-route! It is very possible that your design _will_ meet timing
after synthesis and then _will not_ meet timing after place-and-route.
**If your design does not meet timing after place-and-route you must go
back and use a longer target clock period for synthesis!**

You can use the following steps in Cadence Innovus to display where the
critical path is on the actual chip.

 - Choose _Timing > Debug Timing_ from the menu
 - Click _OK_ in the pop-up window
 - Right click on first path in the _Path List_
 - Choose _Highlight > Only This Path > Color_

In addition to checking to see if we met our setup time constraints, we
also must check to see if we have met our hold time constraints.

```
innovus> report_timing -early > reports/hold.rpt
```

As in Synopsys DC, the `report_area` command can show the area each
module uses and can enable detailed area breakdown analysis. These area
results will be far more accurate than the post-synthesis results.

```
innovus> report_area -verbose > reports/area.rpt
```

innovus> report_power -hierarchy all > reports/power.rpt

### 04.10. Final Layout

We can now look at the actual `.gds` file for our design to see the final
layout including all of the cells and the interconnect using the
open-source Klayout GDS viewer. Choose _Display > Full Hierarchy_ from
the menu to display the entire design. Zoom in and out to see the
individual transistors as well as the entire chip.

```bash
% cd 04-cadence-innovus-pnr/
% klayout -l $env(STDVIEW_45)/klayout.lyp post-pnr.gds
```

### 04.11. Automating Place and Route

You can automate the above steps by putting a sequence of commands in a
`.tcl` file and run Cadence Innovus using those commands in one step like
this:

```bash
% cd 04-cadence-innovus-pnr/
% innovus -no_gui -files pnr.tcl
```

5. Using Synopsys VCS for Back-Annotated Gate-Level Simulation
--------------------------------------------------------------------------
