`timescale 1ns / 1ps

module top_tb ();
  parameter WIDTH = 32;
  parameter DURATION = 1000000000;
  parameter CLKS_PER_BIT = 625;
  // Signals
  reg r_clk;
  wire uart_tx;
  wire led;
  wire r_rstn;
  wire loaded;
  wire o_uart_send;
  wire i_uart_txed;
  wire [15:0] fir_datain;
  wire [WIDTH-1:0] fir_dataout;
  wire [7:0] o_uart_txbyte;
  wire w_txactive;
  wire w_rxdataval;
  wire w_uartline;
  wire [3:0] r_state;
  wire [7:0] w_rxbyte;
  wire [31:0] buffer;
  wire sig_complete;
  top uut (
      .clk(r_clk),
      .r_rstn(r_rstn),
      .uart_tx(uart_tx),
      .LED_G(led),
      .fir_datain(fir_datain),
      .fir_dataout(fir_dataout),
      .fir_fifo_wren(fir_fifo_wren),
      .fifo_rd_en(fifo_rd_en),
      .o_uart_send(o_uart_sendk),
      .ff_full(ff_full),
      .ff_empty(ff_empty),
      .fir_clk(fir_clk),
      .fir_rstn(fir_rstn),
      .o_uart_txbyte(o_uart_txbyte),
      .i_uart_txed(i_uart_txed),
      .i_uart_active(w_txactive),
      .r_state(r_state),
      .buffer(buffer),
      .sig_comp_12m(sig_comp_12m)
  );
  uart_rx #(
      .CLKS_PER_BIT(CLKS_PER_BIT),
      .HALF_CLK_PERIOD(CLKS_PER_BIT / 2)

  ) receiver (
      .i_clk     (r_clk),
      .i_uartrx  (w_uartline),
      .o_rxdatval(w_rxdataval),
      .o_rxbyte  (w_rxbyte)
  );

  assign w_uartline = w_txactive ? uart_tx : 1'b1;

  // Clock generation
  initial begin
    r_clk = 0;
    forever #41.67 r_clk = ~r_clk;

  end

  initial begin
    $display("Starting UART RX Monitor...");
    forever begin
      @(posedge w_rxdataval);  // Wait for valid received data
      $display("%b", w_rxbyte);  // Print the received byte
    end
  end
  initial begin
    // VCD dump for waveform analysis
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    #(DURATION);  // Duration for simulation
    $finish;
  end
endmodule
