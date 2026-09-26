#=========================================================================
# clk.xdc
#=========================================================================
# Clock constraint generated from clock_port/clock_period in the design
# yml. Physical constraints (pins, placement, routing) belong in the xdc
# files under designs/<design>/ listed in `constraints:`.

create_clock -name {{clock_port}} -period {{clock_period}} [get_ports {{clock_port}}]
