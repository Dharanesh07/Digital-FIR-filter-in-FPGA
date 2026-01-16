// Filter Input module 
// This module provides filter input at 1KHz. This is to ensure that the
// inputs are provided at the given sampling frequency 

// Parameters
// SIG_WIDTH - Determines the width of data bits
// SIG_DEPTH - Determines the length of storage
// SIG_FILE - File containing the signal values 
// SIG_LEN - Length of the input signal 

//Signals
// i_clk - Input FIFO clock
// i_rstn - active low reset signal 
// sig_out - data to the FIR filter 
// sig_complete - indicates complete condition 


module filter_input #(
    parameter SIG_WIDTH = 16,
    parameter SIG_DEPTH = 101,
    parameter SIG_FILE  = "sig.txt",
    parameter SIG_LEN   = 100
) (
    input i_clk,
    input i_rstn,
    output wire [SIG_WIDTH-1:0] sig_out,
    output reg sig_complete
);

  //Block ram 
  parameter LEN = $clog2(SIG_DEPTH);
  reg o_bram_rden;
  wire o_bram_clk;
  reg [LEN-1:0] o_bram_addr;
  wire [SIG_WIDTH-1:0] i_bram_dat;
  reg [SIG_WIDTH-1:0] bram_data_reg;
  reg [LEN-1:0] count;


  initial begin
    sig_complete = 0;
    count = 0;
    bram_data_reg = 0;
  end
  bram #(
      .WIDTH    (SIG_WIDTH),
      .DEPTH    (SIG_DEPTH),
      .INIT_FILE(SIG_FILE),
      .END_COUNT(SIG_LEN),
      .LEN      (LEN)
  ) coeff_mem (
      .i_bram_clkrd  (i_clk),
      .i_bram_rstn   (i_rstn),
      .i_bram_rden   (o_bram_rden),
      .o_bram_dataout(i_bram_dat),
      .i_bram_rdaddr (o_bram_addr)
  );

  always @(posedge i_clk) begin
    if (!i_rstn) begin
      o_bram_rden <= 1'b0;
      o_bram_addr <= 0;
      bram_data_reg <= 0;
      count <= 0;
      sig_complete <= 1'b0;
    end else begin

      o_bram_rden <= 1'b1;
      if (count < SIG_LEN) begin
        o_bram_addr <= count;
        bram_data_reg <= i_bram_dat;
        count <= count + 1;
      end else begin
        sig_complete <= 1'b1;
        o_bram_rden  <= 1'b0;
      end
    end
  end
  assign sig_out = bram_data_reg;

endmodule
