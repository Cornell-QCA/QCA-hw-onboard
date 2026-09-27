#=========================================================================
# vivado-summary.tcl
#=========================================================================
# Summary shared by the Vivado steps (02-synth, 04-pnr). Source it after
# the design is loaded, then call:
#
#   print_summary <title> <stage> [<label> <value> ...]
#
# which prints resource usage and worst setup/hold slack, warns if timing
# is not met after <stage>, and appends any extra label/value lines.

proc num_cells { group } {
  return [llength [get_cells -hierarchical -quiet -filter "PRIMITIVE_GROUP == $group"]]
}

proc worst_slack { type } {
  set path [get_timing_paths -quiet -$type -max_paths 1]
  if { $path eq "" } {
    return "n/a"
  }
  return [get_property SLACK $path]
}

proc print_summary { title stage args } {

  set part [get_property PART [current_design]]
  set wns  [worst_slack setup]
  set whs  [worst_slack hold]

  puts ""
  puts "==================================================================="
  puts " $title: [get_property TOP [current_design]] ($part)"
  puts "==================================================================="
  puts " LUTs       : [num_cells LUT]"
  puts " FFs        : [num_cells FLOP_LATCH]"
  puts " LUTRAMs    : [num_cells DMEM]"
  puts " BRAMs      : [num_cells BMEM]"
  puts " DSPs       : [num_cells MULT]"
  puts " IOs        : [num_cells IO]"
  puts " WNS (ns)   : $wns"
  puts " WHS (ns)   : $whs"
  foreach { label value } $args {
    puts [format " %-10s : %s" $label $value]
  }
  if { $wns ne "n/a" && $wns < 0 } {
    puts " WARNING    : setup timing not met after $stage"
  }
  if { $whs ne "n/a" && $whs < 0 } {
    puts " WARNING    : hold timing not met after $stage"
  }
  puts "==================================================================="
  puts ""
}
