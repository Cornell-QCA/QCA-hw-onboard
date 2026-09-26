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

parameter S0 = 3'b000;
parameter S1 = 3'b001;
parameter S2 = 3'b010;
parameter S3 = 3'b011;
parameter S4 = 3'b100;

reg[2:0] state, next_state;

// This part is for handling changing the state at each rising clock input
always @(posedge clk) begin

  if( rst ) state = S0;

  else state = next_state;

end

// Combinational logic part, this actually handles what state is next
always @(*) begin

  next_state = state;

  case (state)
    S0: begin
      dout = 1'b0;
      if ( din ) next_state = S1;
      else next_state = S0;
    end

    S1: begin
      dout = 1'b0;
      if( !din ) next_state = S2;
      else next_state = S0;
    end

    S2: begin
      dout = 1'b0;
      if( din ) next_state = S3;
      else next_state = S0;
    end
    
    S3: begin
      dout = 1'b0;
      if( !din ) next_state = S4;
      else next_state = S0;
    end

    S4: begin
      dout = 1'b1;
      if ( din ) next_state = S3;
      else next_state = S0;
    end

    default: begin
      dout = 1'b0;
      next_state = state;
    end

  endcase

end

endmodule

`endif /* DETECTOR_SV */
