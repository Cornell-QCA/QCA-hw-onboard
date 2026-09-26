#=========================================================================
# cocotb-sim.mk
#=========================================================================
# Shared cocotb harness for every simulation step in the FPGA flow
# (01-cocotb-rtl-sim, 03-ffgl, 06-bagl). The steps only differ in which
# Verilog sources they pass in -- the testbench (in sim/<design>/test)
# and the list of tests (from the design yml) are shared.
#
# Required (set on the make command line by the step's run script):
#
#   VERILOG_SOURCES : Verilog files (RTL, or netlist + cell sim models)
#   TOP             : top-level module name
#   TB_DIR          : directory containing the cocotb test module
#   TB_MODULE       : cocotb test module name (python file without .py)
#   TESTS           : space-separated cocotb test names to run
#
# Optional:
#
#   SIM                : simulator (default: vcs)
#   INCLUDE_DIRS       : directories searched for `include files and
#                        submodules
#   EXTRA_COMPILE_ARGS : extra simulator compile arguments
#                        (e.g., +define+GL, timing options)
#   GEN_WAVES          : True to dump waves.vcd

TOPLEVEL_LANG := verilog
SIM           ?= vcs
SIM_BUILD     ?= $(CURDIR)/sim_build

# Make the testbench (and its FL model) importable from the step directory

export PYTHONPATH := $(TB_DIR):$(PYTHONPATH)

#-------------------------------------------------------------------------
# Test selection
#-------------------------------------------------------------------------
# cocotb 1.x selects tests with a comma-separated TESTCASE, cocotb 2.x
# with a COCOTB_TEST_FILTER regex. Anchor the regex so test_basic does
# not also select test_basic_random.

comma := ,
empty :=
space := $(empty) $(empty)

COCOTB_MAJOR := $(shell cocotb-config --version | cut -d. -f1)

ifeq ($(COCOTB_MAJOR),1)
  TOPLEVEL := $(TOP)
  MODULE   := $(TB_MODULE)
  TESTCASE := $(subst $(space),$(comma),$(strip $(TESTS)))
else
  COCOTB_TOPLEVEL     := $(TOP)
  COCOTB_TEST_MODULES := $(TB_MODULE)
  COCOTB_TEST_FILTER  := ^($(subst $(space),|,$(strip $(TESTS))))$$
endif

#-------------------------------------------------------------------------
# Simulator arguments
#-------------------------------------------------------------------------

ifeq ($(SIM),vcs)
  COMPILE_ARGS += -sverilog

  # "tells VCS to do something sane with xpropagation" -Prof.Batten
  COMPILE_ARGS += -xprop=tmerge

  COMPILE_ARGS += $(foreach d,$(INCLUDE_DIRS),+incdir+$(d) -y $(d))
  COMPILE_ARGS += +libext+.v+.sv

  ifeq ($(GEN_WAVES),True)
    EXTRA_ARGS += +vcs+dumpvars+waves.vcd
  endif
endif

ifeq ($(SIM),icarus)
  COMPILE_ARGS += -g2012
  COMPILE_ARGS += $(foreach d,$(INCLUDE_DIRS),-I $(d) -y $(d))
  COMPILE_ARGS += -Y .sv
endif

COMPILE_ARGS += $(EXTRA_COMPILE_ARGS)

# ***DO NOT REMOVE***
include $(shell cocotb-config --makefiles)/Makefile.sim
