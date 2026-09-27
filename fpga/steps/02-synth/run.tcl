#=========================================================================
# 02-synth/run.tcl
#=========================================================================
# Vivado synthesis. Reads the RTL and constraints, synthesizes for the
# target part, checks timing, and writes:
#
#  - outputs/post-synth.dcp : checkpoint for place and route (04-pnr)
#  - outputs/post-synth.v   : functional netlist for FFGL sim (03-ffgl)
#  - reports/*.rpt          : area and timing reports

set design_name  {{design_name}}
set part         {{fpga_part}}
set verilog_top  [file normalize {{verilog_top}}]
set src_dir      [file normalize {{src_dir}}]
set xdc_files    [list clk.xdc {{ (constraints or []) | join(' ') }}]

file mkdir outputs reports

#-------------------------------------------------------------------------
# Read sources and constraints
#-------------------------------------------------------------------------
# Submodules are pulled in with `include, so only the top file is read

read_verilog -sv $verilog_top

foreach xdc $xdc_files {
  read_xdc [file normalize $xdc]
}

#-------------------------------------------------------------------------
# Synthesis
#-------------------------------------------------------------------------

synth_design \
  -top          $design_name \
  -part         $part \
  -include_dirs [list [file dirname $verilog_top] $src_dir]

#-------------------------------------------------------------------------
# Outputs
#-------------------------------------------------------------------------

write_checkpoint -force outputs/post-synth.dcp
write_verilog    -force -mode funcsim outputs/post-synth.v

#-------------------------------------------------------------------------
# Reports
#-------------------------------------------------------------------------

check_timing                              -file reports/check-timing.rpt
report_timing_summary -max_paths 10       -file reports/timing-summary.rpt
report_utilization                        -file reports/utilization.rpt
report_utilization    -hierarchical       -file reports/utilization-hier.rpt

#-------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------
# Post-synthesis timing is an estimate (no routing yet), so negative slack
# is a warning here -- 05-sta-signoff is the real check.

source [file normalize {{scripts_dir}}/vivado-summary.tcl]

print_summary "Synthesis summary" "synthesis"
