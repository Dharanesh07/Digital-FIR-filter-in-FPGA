`timescale 1us / 1ns

module bram_tb ();
  parameter WIDTH = 8;
  parameter DEPTH = 16;
  parameter LEN = $clog2(DEPTH);
  parameter FILE = "mem8b.mem";
  // Signals
  reg clk;
  reg read_en;
  wire [WIDTH-1:0] data_out;
  reg [LEN-1:0] addr;
  // Array to hold expected data for comparison
  reg [WIDTH-1:0] refdata[0:DEPTH-1];
  reg [WIDTH-1:0] wdata;
  integer i, j;

  bram #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH),
      .INIT_FILE(FILE)
  ) uut (
      .i_clkrd  (clk),
      .i_rden   (read_en),
      .o_dataout(data_out),
      .i_rdaddr (addr)
  );
  /*
  // Clock generation
  initial begin
    clk = 0;
    forever #41.67 clk = ~clk;  // 10ns clock period
  end
*/
  initial begin
    if (FILE != 0) begin
      $display("Load init file '%s' into reference array", FILE);
      $readmemh(FILE, refdata);
    end
  end


  initial begin
    read_en = 0;
    addr = 0;
    clk = 0;
    read_en = 1;
    $display("Reading Blcok RAM Memory");
    for (j = 0; j < DEPTH; j = j + 1) begin

      addr = j;
      #10 clk = 1;
      #5 wdata = data_out;
      //read_en = 0;
      if (wdata !== refdata[j]) begin
        $display("Comparison Failed at time %0t: Expected %h, Got %h", $time, refdata[j], wdata);
      end else begin
        $display("Comparison Passed at time %0t: Expected %h, Got %h", $time, refdata[j], wdata);
      end
      //$display("%h", refdata[j]);
      clk = 0;
    end
  end

  initial begin
    // VCD dump for waveform analysis
    $dumpfile("bram_tb.vcd");
    $dumpvars(0, bram_tb);
    #10000;  // Duration for simulation
    $finish;
  end
endmodule
