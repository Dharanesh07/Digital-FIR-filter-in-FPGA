`timescale 1us / 1ns

module filter_input_tb ();

  reg clk;
  reg rst;
  wire [15:0] sig_out;
  wire o_bram_clk;
  wire bram_rden;
  wire sig_complete;

  parameter LEN = 100;
  parameter WIDTH = 16;
  parameter DURATION = 10000000;
  parameter CLKS_PER_BIT = 1250;
  // Instantiate the DUT (Device Under Test)
  filter_input #() uut (
      .i_clk(clk),
      .i_rstn(rst),
      .sig_out(sig_out),
      .sig_complete(sig_complete)
  );


  // Clock generation
  initial begin
    clk = 0;
    forever #41.677 clk = ~clk;
  end

  // Monitor the received UART data
  initial begin
    rst = 0;
    #40 rst = 1;
  end

  initial begin
    // VCD dump for waveform analysis
    $dumpfile("filter_input_tb.vcd");
    $dumpvars(0, filter_input_tb);
    #(DURATION);  // Duration for simulation
    $finish;
  end

endmodule
