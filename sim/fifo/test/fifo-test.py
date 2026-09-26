# =========================================================================
# FIFO Dynamic Tests
# =========================================================================

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotb.regression import TestFactory
import random

import importlib.util
import os
import sys

# Load the FL model relative to this file so the test can be run from any
# directory (e.g., the FPGA flow's simulation steps)
spec = importlib.util.spec_from_file_location(
  "fifo_fl", os.path.join(os.path.dirname(os.path.abspath(__file__)), "fifo-fl.py"))
module = importlib.util.module_from_spec(spec)
sys.modules["fifo_fl"] = module
spec.loader.exec_module(module)

from fifo_fl import FL_sync_fifo

CLK_PER = 10
DEBUG = True

# Helper functions --------------------------------------------------------

async def reset_dut(dut):
  """
  Resets the DUT by setting the activating the reset signal for one cycle.
  Also drives other inputs to the DUT to avoid unwanted X-prop.
  """
  dut.rst.value = 1
  dut.in_val.value = 0
  dut.out_rdy.value = 0
  await Timer(CLK_PER, "ns")
  dut.rst.value = 0


async def test_init(dut):
  """
  Initializes the test by starting the clock, synchronizing to the next 
  rising edge, and reseting the DUT.
  """
  clk = Clock(dut.clk, CLK_PER, units="ns")
  cocotb.start_soon(clk.start())
  await RisingEdge(dut.clk)
  await Timer(1, "ns")
  await reset_dut(dut)


async def compare(dut_value, exp_value):
  """
  Simple helper function to compare DUT value against the expected value.
  """
  assert dut_value == exp_value, \
    f"Expected value was {exp_value}. Actual output was {dut_value}."


async def check(dut, rst, in_val, in_rdy, in_data, out_val, out_rdy, out_data):
  """
  Drives the input signals to the DUT, prints the trace info if DEBUG is enabled,
  and compares the DUT output signals against the expected output signals.
  """

  # Drive the input signals
  dut.rst.value = rst
  dut.in_val.value = in_val
  dut.in_data.value = in_data
  dut.out_rdy.value = out_rdy

  # Wait until #1 before the next rising edge
  await Timer(CLK_PER-2, "ns")

  # Print the debug info
  if DEBUG:
    trace = f""

    if dut.in_val.value and dut.in_rdy.value:
      trace += f"{dut.in_data.value}"
    elif dut.in_val.value:
      trace += f" * "
    elif dut.in_rdy.value:
      trace += f" # "
    else:
      trace += f"   "
    
    trace += " | "

    if dut.out_val.value and dut.out_rdy.value:
      trace += f"{dut.out_data.value}"
    elif dut.out_val.value:
      trace += f" * "
    elif dut.out_rdy.value:
      trace += f" # "
    else:
      trace += f"   "
    
    dut._log.info(trace)

  # Assert the output signals are as expected
  await compare(dut.in_rdy.value, in_rdy)
  await compare(dut.out_val.value, out_val)
  if (out_val and out_rdy):
    await compare(dut.out_data.value, out_data)

  # Wait until #1 after the next rising edge
  await Timer(2, "ns")

# Dynamic tests -----------------------------------------------------------

@cocotb.test()
async def test_basic(dut):
  # Initialize the test
  await test_init(dut)

  # Test checks
  #                rst  in_val  in_rdy  in_data  out_val  out_rdy  out_data
  await check(dut, 0,   0,      1,      0,       0,       0,       0       )
  await check(dut, 0,   1,      1,      1,       0,       0,       0       )
  await check(dut, 0,   0,      1,      0,       1,       0,       0       )
  await check(dut, 0,   0,      1,      0,       1,       1,       1       )
  await check(dut, 0,   0,      1,      0,       0,       0,       0       )

# TODO : Implment more directed unit tests below. -------------------------

# Write a new cocotb test functions here ...

# TODO : Implement randomized tests below. --------------------------------

# Write a new cocotb test functions here ...