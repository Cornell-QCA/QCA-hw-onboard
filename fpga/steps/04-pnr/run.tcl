#=========================================================================
# 04-pnr/run.tcl
#=========================================================================
# Vivado place and route. Opens the synthesized checkpoint from 02-synth
# (which carries the part and constraints), places and routes it, checks
# timing, and writes:
#
#  - outputs/post-route.dcp : checkpoint for signoff and bitstream
#                             (05-sta-signoff, 07-bitstream)
#  - outputs/post-route.v   : timing netlist for BAGL sim (06-bagl)
#  - outputs/post-route.sdf : routed delays for BAGL sim (06-bagl)
#  - reports/*.rpt          : area, timing, DRC, routing, and IO reports

file mkdir outputs reports

open_checkpoint [file normalize ../02-synth/outputs/post-synth.dcp]

#-------------------------------------------------------------------------
# Place and route
#-------------------------------------------------------------------------

opt_design
place_design
phys_opt_design
route_design

#-------------------------------------------------------------------------
# Outputs
#-------------------------------------------------------------------------
# The SDF is not referenced from the netlist (-sdf_anno false); 06-bagl
# passes it to the simulator directly.

write_checkpoint -force outputs/post-route.dcp
write_verilog    -force -mode timesim -sdf_anno false outputs/post-route.v
write_sdf        -force outputs/post-route.sdf

#-------------------------------------------------------------------------
# Reports
#-------------------------------------------------------------------------

check_timing                              -file reports/check-timing.rpt
report_timing_summary -max_paths 20       -file reports/timing-summary.rpt
report_utilization                        -file reports/utilization.rpt
report_utilization    -hierarchical       -file reports/utilization-hier.rpt
report_drc                                -file reports/drc.rpt
report_route_status                       -file reports/route-status.rpt
report_io                                 -file reports/io.rpt

#-------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------
# Timing is checked with routed delays here but only warned about --
# 05-sta-signoff is the real check. Incomplete routing is an error.

source [file normalize {{scripts_dir}}/vivado-summary.tcl]

set drc_errors   [llength [get_drc_violations -quiet -filter {SEVERITY == Error}]]
set drc_warnings [llength [get_drc_violations -quiet -filter {SEVERITY == "Critical Warning"}]]
set bad_nets     [llength [get_nets -hierarchical -quiet -filter {ROUTE_STATUS == UNROUTED || ROUTE_STATUS == CONFLICTS}]]

print_summary "Place and route summary" "routing" \
  "DRC errors" $drc_errors \
  "DRC crit"   $drc_warnings \
  "Bad nets"   $bad_nets

if { $bad_nets > 0 } {
  error "$bad_nets nets are unrouted or have routing conflicts -- see reports/route-status.rpt"
}
