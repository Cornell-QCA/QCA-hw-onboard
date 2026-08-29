#==========================================================================
# Detector Dynamic Tests
#==========================================================================

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotb.regression import TestFactory
import random

import importlib.util
import sys

spec = importlib.util.spec_from_file_location("detector_fl", "detector-fl.py")
module = importlib.util.module_from_spec(spec)
sys.modules["detector_fl"] = module
spec.loader.exec_module(module)

from detector_fl import FL_detector

CLK_PER = 10
DEBUG = True

# Helper functions --------------------------------------------------------

async def reset_dut(dut):
  """
  Resets the DUT by setting the activating the reset signal for one cycle.
  Also drives other inputs to the DUT to avoid unwanted X-prop.
  """
  dut.rst.value = 1
  dut.din.value = 0
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


async def check(dut, rst, din, dout):
  """
  Drives the input signals to the DUT, prints the trace info if DEBUG is enabled,
  and compares the DUT output signals against the expected output signals.
  """

  # Drive the input signals
  dut.rst.value = rst
  dut.din.value = din

  # Wait until #1 before the next rising edge
  await Timer(CLK_PER-2, "ns")

  # Print the debug info
  if DEBUG:
    dut._log.info(f"rst: {dut.rst.value}  din: {dut.din.value}  dout: {dut.dout.value}")

  # Assert the output signals are as expected
  await compare(dut.dout.value, dout)

  # Wait until #1 after the next rising edge
  await Timer(2, "ns")

# Dynamic tests -----------------------------------------------------------

@cocotb.test()
async def test_basic(dut):
  # Initialize the test
  await test_init(dut)

  # Test checks
  #                rst  din  dout
  await check(dut, 0,   0,   0    )
  await check(dut, 0,   1,   0    )
  await check(dut, 0,   0,   0    )
  await check(dut, 0,   1,   0    )
  await check(dut, 0,   0,   0    )
  await check(dut, 0,   0,   1    )

@cocotb.test()
async def test_cool(dut):
  # Initialize the test
  await test_init(dut)

  # Test checks
  #                rst  din  dout
  await check(dut, 0,   1,   0    )
  await check(dut, 0,   0,   0    )
  await check(dut, 0,   1,   0    )
  await check(dut, 0,   0,   0    )
  await check(dut, 0,   1,   1    )
  await check(dut, 0,   0,   0    )
  await check(dut, 0,   1,   1    )

# TODO : Implment more directed unit tests below. -------------------------

# Write a new cocotb test functions here ...

# TODO : Implement randomized tests below. --------------------------------

# Write a new cocotb test functions here ...