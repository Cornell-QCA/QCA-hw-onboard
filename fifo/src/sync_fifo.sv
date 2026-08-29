// FIFO ///////////////////////////////////////////////////////////////////
// 
// Description: FIFO implementation with val/rdy enqueue/dequeue interface.
// Author: Anjelica Bian
// 
// SPECIFICATION .........................................................
// Input Signals
// - clk:     Clock signal
// - rst:     Active high, reset signal
// - in_val:  Active-high, input valid signal
// - in_data: FIFO input data
// - out_rdy: Active-high, output ready signal
//
// Output Signals
// - in_rdy:  Active-high, input ready signal
// - out_val: Active-high, output valid signal
// - out_data:   FIFO output data
// - full:   Full FIFO indicator
// - empty:  Empty FIFO indicator
//
// Implement a FIFO with the following behavior:
// - Data width and depth of the FIFO should be 8
// - `rd_ptr` always points to the head (first entry) of the FIFO.
// - `wr_ptr` always points to the tail (last entry) + 1 of the FIFO.
// - If `rst` is high, the FIFO should become empty.
// - If `in_val` and `in_rdy` are high and not `rst`, then the FIFO writes
//   the `in_data` at address `wr_ptr` and increments `wr_ptr` by one, both
//   operations by the next clock cycle.
// - The FIFO combinationally output `out_data` at the entry pointed by `rd_ptr`
// - If `out_val` and `out_rdy` are high `rd_ptr` is incremented on the next clock cycle.
// 
// You should think about:
// - When is input ready?
// - When is output valid? 
// - When is the fifo full or empty?
// Hint: Just check the relative positions of `rd_ptr` and `wr_ptr`
// 
///////////////////////////////////////////////////////////////////////////

`ifndef SYNC_FIFO_SV
`define SYNC_FIFO_SV

module sync_fifo #(
  input  logic                  clk,
  input  logic                  rst,

  // Input data (tail of the FIFO)

  output logic                  in_rdy,
  input  logic                  in_val,
  input  logic [7:0] in_data,

  // Output data (head of the FIFO)

  input  logic                  out_rdy,
  output logic                  out_val,
  output logic [7:0] out_data
);

  // TODO : Implement the FIFO here.
  
endmodule

`endif /* FIFO_SV */
