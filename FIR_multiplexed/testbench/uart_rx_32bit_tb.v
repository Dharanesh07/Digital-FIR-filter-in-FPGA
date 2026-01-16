`timescale 1ns / 10ps

module uart_rx_32bit_tb();

  reg         clk = 0;
  reg         rstn = 0;
  reg         uart_rx = 1;  // idle state high
  wire [31:0] dataout;

  wire        w_rxdataval;
  wire        o_datavalid;
  reg         r_txsenddata;
  wire        w_uartline;
  wire        w_uarttx;
  wire        w_txactive;
  wire        w_txdone;
  wire [ 2:0] r_state;
  reg  [ 7:0] r_txbyte = 0;
  wire [ 7:0] w_rxbyte;

  parameter DURATION = 10000000;
  parameter CLOCK_PERIOD_NS = 41;
  parameter CLKS_PER_BIT = 625;
  parameter BIT_PERIOD = 8600;

  // DUT instantiation
  uart_rx_32bit #(
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) dut (
      .i_clk(clk),
      .i_rstn(rstn),
      .uart_rx(w_uartline),
      .o_datavalid(o_datavalid),
      .dataout(dataout)
  );

  uart_tx #(
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) transmitter (
      .i_clk(clk),
      .i_rstn(rstn),
      .i_txsenddata(r_txsenddata),
      .i_txbyte(r_txbyte),
      .o_txactive(w_txactive),
      .o_uarttx(w_uarttx),
      .o_txdone(w_txdone)
  );

  always #(CLOCK_PERIOD_NS / 2) clk <= !clk;
  assign w_uartline = w_txactive ? w_uarttx : 1'b1;

  // Main Testing:
  initial begin
    // Initialize
    r_txsenddata = 0;
    r_txbyte = 0;

    // Reset sequence
    #50 rstn = 0;
    #100 rstn = 1;

    // Wait after reset
    //repeat (10) @(posedge clk);

    // Send first byte
    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'hB1;
    @(posedge clk);
    r_txsenddata <= 1'b0;

    // Wait for completion
    @(posedge w_txdone);


    // Send second byte
    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h0A;
    @(posedge clk);
    r_txsenddata <= 1'b0;
    // Wait for completion
    @(posedge w_txdone);

    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h79;
    @(posedge clk);
    r_txsenddata <= 1'b0;
    // Wait for completion
    @(posedge w_txdone);


    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h12;
    @(posedge clk);
    r_txsenddata <= 1'b0;
    // Wait for completion
    @(posedge w_txdone);



    // Send first byte
    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h00;
    @(posedge clk);
    r_txsenddata <= 1'b0;

    // Wait for completion
    @(posedge w_txdone);


    // Send second byte
    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h10;
    @(posedge clk);
    r_txsenddata <= 1'b0;
    // Wait for completion
    @(posedge w_txdone);

    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h50;
    @(posedge clk);
    r_txsenddata <= 1'b0;
    // Wait for completion
    @(posedge w_txdone);


    @(posedge clk);
    r_txsenddata <= 1'b1;
    r_txbyte <= 8'h60;
    @(posedge clk);
    r_txsenddata <= 1'b0;
    // Wait for completion
    @(posedge w_txdone);


    // Wait for data to be received
    @(posedge o_datavalid);
    $display("Received data: %h", dataout);

  end

  initial begin
    $dumpfile("uart_rx_32bit_tb.vcd");
    $dumpvars(0, uart_rx_32bit_tb);
    #(DURATION);
    $finish;
  end

endmodule
