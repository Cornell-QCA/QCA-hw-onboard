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
// PARAMETERS ............................................................
// - DATA_WIDTH: integer indicating the bitwidth of each FIFO entry.
// - FIFO_DEPTH: integer specificying how many maximum size of the FIFO.
// 
///////////////////////////////////////////////////////////////////////////

`ifndef SYNC_FIFO_SV
`define SYNC_FIFO_SV

module sync_fifo #(
  parameter DATA_WIDTH = 8,
  parameter FIFO_DEPTH  = 8
) (
  input  logic                  clk,
  input  logic                  rst,

  // Input data (tail of the FIFO)

  output logic                  in_rdy,
  input  logic                  in_val,
  input  logic [DATA_WIDTH-1:0] in_data,

  // Output data (head of the FIFO)

  input  logic                  out_rdy,
  output logic                  out_val,
  output logic [DATA_WIDTH-1:0] out_data
);

  logic [$clog2(FIFO_DEPTH):0] rd_ptr, wr_ptr;

  logic [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      fifo_mem[0] <= 0;
    end
    else begin
      if (in_val && in_rdy) begin
        fifo_mem[wr_ptr%FIFO_DEPTH] <= in_data;
        wr_ptr <= (wr_ptr + 1);
      end
      // Read operation
      if (out_val && out_rdy) begin
        rd_ptr <= (rd_ptr + 1);
      end
    end
  end

  always_comb begin
    out_data = fifo_mem[rd_ptr%FIFO_DEPTH];
  end

  always_comb begin
    if ((wr_ptr == rd_ptr)) begin
      out_val = 0;
    end else begin
      out_val = 1;
    end
    if (((rd_ptr[$clog2(FIFO_DEPTH)-1:0]) == (wr_ptr[$clog2(FIFO_DEPTH)-1:0])) && (rd_ptr[$clog2(FIFO_DEPTH)] != wr_ptr[$clog2(FIFO_DEPTH)])) begin
      in_rdy = 0;
    end else begin
      in_rdy = 1;
    end
  end
endmodule

`endif /* FIFO_SV */
