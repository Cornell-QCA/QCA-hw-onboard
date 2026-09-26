// DETECTOR ////////////////////////////////////////////////////////////////
// 
// Description: Pattern Detector.
// Author: Anjelica Bian
// 
// SPECIFICATION .........................................................
// Given a stream of input bits, pulse a 1 on the output (dout) whenever 
// a b1010 sequence is detected on the input (din).
//
// When the reset signal (rst) goes high, all previously seen bits 
// on the input are no longer considered when searching for b1010.
// We are using synchronous reset, so the reset signal only takes effect
// on the positive clock edge.
//
// Input Signals
// - clk:    Clock signal
// - rst:    Active high reset signal
// - din:    Input bits
//
// Output signals
// - dout:   1 if a b1010 was detected, 0 otherwise
// - dout:   0 when resetn is active
// 
///////////////////////////////////////////////////////////////////////////

`ifndef DETECTOR_SV
`define DETECTOR_SV

module detector (
  input clk,
  input rst,
  input din,
  output logic dout
);


// to-do: implement the detector logic here

endmodule

`endif /* DETECTOR_SV */