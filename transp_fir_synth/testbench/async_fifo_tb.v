//--------------DESCRIPTION--------------
// This is a testbench for the FIFO module.
// The testbench generates random data and writes it to the FIFO, 
// then reads it back and compares the results.
//---------------------------------------

`timescale 1us / 1ns

module async_fifo_tb ();

  parameter DSIZE = 8;  // Data bus size
  parameter DEPTH = 16;  // Depth of the FIFO memory
  parameter ADDR_SIZE = $clog2(DEPTH);
  parameter DURATION = 100000;

  reg  [DSIZE-1:0] wdata;  // Input data
  wire [DSIZE-1:0] rdata;  // Output data
  wire wfull, rempty;  // Write full and read empty signals
  reg winc, rinc, wclk, rclk, wrst_n, rrst_n;  // Write and read signals

  wire [ADDR_SIZE:0] rptr, wptr;
  async_fifo #(
      .WIDTH(DSIZE),
      .DEPTH(DEPTH)
  ) inst_async_fifo (
      .i_wr_clk(wclk),
      .i_wr_inc(winc),
      .i_rd_clk(rclk),
      .i_rd_inc(rinc),
      .i_wrrst_n(wrst_n),
      .i_rdrst_n(rrst_n),
      .i_datain(wdata),
      .o_dataout(rdata),
      .wr_full(wfull),
      .rd_empty(rempty),
      .rptr(rptr),
      .wptr(wptr)

  );
  integer i = 0;
  integer seed = 1;

  // Read and write clock in loop
  always #5 wclk = ~wclk;  // faster writing
  always #10 rclk = ~rclk;  // slower reading

  initial begin
    // Initialize all signals
    wclk   = 0;
    rclk   = 0;
    wrst_n = 1;  // Active low reset
    rrst_n = 1;  // Active low reset
    winc   = 0;
    rinc   = 0;
    wdata  = 0;

    // Reset the FIFO
    #40 wrst_n = 0;
    rrst_n = 0;
    #40 wrst_n = 1;
    rrst_n = 1;

    // TEST CASE 1: Write data and read it back
    rinc   = 1;
    for (i = 0; i < 10; i = i + 1) begin
      wdata = $random(seed) % 256;
      winc  = 1;
      #10;
      winc = 0;
      #10;
    end

    // TEST CASE 2: Write data to make FIFO full and try to write more data
    rinc = 0;
    winc = 1;
    for (i = 0; i < DEPTH + 3; i = i + 1) begin
      wdata = $random(seed) % 256;
      #10;
    end

    // TEST CASE 3: Read data from empty FIFO and try to read more data
    winc = 0;
    rinc = 1;
    for (i = 0; i < DEPTH + 3; i = i + 1) begin
      #20;
    end

  end

  initial begin
    // VCD dump for waveform analysis
    $dumpfile("async_fifo_tb.vcd");
    $dumpvars(0, async_fifo_tb);
    #(DURATION);  // Duration for simulation
    $finish;
  end

endmodule

//----------------------------EXPLANATION-----------------------------------------------
// The testbench for the FIFO module generates random data and writes it to the FIFO,
// then reads it back and compares the results. The testbench includes three test cases:
// 1. Write data and read it back.
// 2. Write data to make the FIFO full and try to write more data.
// 3. Read data from an empty FIFO and try to read more data. The testbench uses
// clock signals for writing and reading, and includes reset signals to initialize
// the FIFO. The testbench finishes after running the test cases.
//--------------------------------------------------------------------------------------
