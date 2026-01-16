`timescale 1ns / 10ps

module top_tb ();
  parameter DURATION = 10000000000;

  parameter TB_RX_CLKS_PER_BIT = 50;
  parameter BYTE_COUNT = 5000;
  // Signals
  reg            r_clk;
  wire           uart_tx;
  wire           led;
  wire           r_rstn;
  wire           loaded;
  wire           o_uart_send;
  wire           i_uart_txed;
  wire    [15:0] fir_datain;
  wire    [31:0] fir_dataout;
  wire    [ 7:0] o_uart_txbyte;
  wire           tb_w_txactive;
  wire           tb_w_rxdataval;
  wire           tb_rxline;
  wire    [ 3:0] r_state;
  wire    [ 7:0] tb_w_rxbyte;
  wire           sig_complete;

  wire           w_sig_comp;
  wire           w_uarttx;
  reg     [ 7:0] tx_bytes        [BYTE_COUNT-1:0];
  integer        i;
  reg            tx_rstn = 1'b1;

  wire           rx_fifo_rden;
  wire    [31:0] rx_fifo_dataout;
  wire    [31:0] fifo_dataout;
  wire           fir_rx_rstn;
  wire    [15:0] coeff;
  wire    [ 7:0] coeff_addr;


  parameter OUTPUT_FILE = "output.txt";
  integer file;

  /*
  top_sim #(
      .RX_CLKS_PER_BIT(RX_CLKS_PER_BIT),
      .TX_CLKS_PER_BIT(TX_CLKS_PER_BIT),
      .BYTE_COUNT(BYTE_COUNT)
  ) top_sim_module (
      .clk(r_clk),
      .r_rstn(r_rstn),
      .uart_tx(uart_tx),
      .uart_rx(uart_tb_uartline),
      .LED_G(led),
      .fir_datain(fir_datain),
      .fir_dataout(fir_dataout),
      .fir_fifo_wren(fir_fifo_wren),
      .fifo_rd_en(fifo_rd_en),
      .o_uart_send(o_uart_send),
      .ff_full(ff_full),
      .ff_empty(ff_empty),
      .fir_clk(fir_clk),
      .fir_rstn(fir_rstn),
      .fifo_dataout(fifo_dataout),
      .o_uart_txbyte(o_uart_txbyte),
      .i_uart_txed(i_uart_txed),
      .i_uart_active(tb_w_txactive),
      .r_state(r_state),
      .w_sig_comp(w_sig_comp)
  );

  */

  top top_sim_module (
      .clk(r_clk),
      .uart_tx(uart_tx),
      .LED_G(led)
  );


  uart_rx #(
      .CLKS_PER_BIT(TB_RX_CLKS_PER_BIT),
      .HALF_CLK_PERIOD(TB_RX_CLKS_PER_BIT / 2)

  ) tb_receiver (
      .i_clk     (r_clk),
      .i_rstn    (tx_rstn),
      .i_uartrx  (uart_tx),
      .o_rxdatval(tb_w_rxdataval),
      .o_rxbyte  (tb_w_rxbyte)
  );


  // Testbench Logic
  initial begin
    file = $fopen(OUTPUT_FILE, "w");
    if (!file) begin
      $display("Error: Could not open output file.");
      $finish;
    end
  end
  assign tb_rxline = tb_w_txactive ? uart_tx : 1'b1;

  always #41.6667 r_clk = ~r_clk;  //for nS

  initial begin
    r_clk = 0;
    #50 tx_rstn = 0;
    #100 tx_rstn = 1;
  end


  initial begin
    $display("Writing output file...");
    forever begin
      @(posedge tb_w_rxdataval);  // Wait for valid received data
      $fdisplay(file, "%b", tb_w_rxbyte);  // Print the received byte
      $display("%b", tb_w_rxbyte);  // Print the received byte
    end
  end


  initial begin
    // VCD dump for waveform analysis
    $dumpfile("top_tb.vcd");
    //$dumpvars(0, top_tb);
    $dumpvars(0, top_tb);
    #(DURATION);  // Duration for simulation
    $finish;
  end
endmodule

