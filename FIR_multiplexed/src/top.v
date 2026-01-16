// Module verifies the FIR multiplexed in the FPGA.

module top (
    input      clk,
    output     uart_tx,
    output reg LED_G
);

  parameter CLK_1KHZ = 6000;
  parameter SIG_WIDTH = 16;
  parameter SIG_DEPTH = 5001;
  parameter SIG_LEN = 5000;
  parameter IP_SIG_FILE = "sig.txt";


  parameter TAP_WIDTH = 16;
  parameter TAP_COUNT = 65;
  parameter UART_BIT_WIDTH = 8;
  parameter OP_FIFO_LEN = 1000;

  wire fir_clk;
  wire fir_rstn;
  wire fir_valid;
  reg r_rstn;
  wire [SIG_WIDTH-1:0] fir_datain;
  wire [2*(SIG_WIDTH)-1:0] fir_dataout;
  wire [2*(SIG_WIDTH)-1:0] fifo_dataout;


  //wire [SIG_WIDTH-1:0] fir_dataout;
  //wire [SIG_WIDTH-1:0] fifo_dataout;
  wire fir_fifo_wren;
  reg [(2*SIG_WIDTH)-1:0] buffer;
  reg [3:0] byte_count;
  reg fifo_rd_en;


  //uart declarations
  // CLKS_PER_BIT = (Frequency of i_clk)/(Frequency of UART)
  // Example: 12 MHz Clock, 115200 baud UART
  // (12000000)/(115200) = 104.16
  // 12000000 / 9600 = 1250
  parameter TX_CLKS_PER_BIT = 625;

  reg o_uart_send;
  wire i_uart_txed;
  reg [7:0] uart_buf;
  reg [7:0] data_buf;
  wire i_uart_active;
  reg [7:0] o_uart_txbyte;

  reg rst_done = 1'b0;
  //fifo 
  wire ff_full;
  wire ff_empty;
  wire clk_buf_9600;
  wire w_sig_comp;
  wire sig_comp_12m;

  reg [32:0] j;

  reg [3:0] r_state;
  parameter START = 3'b000;
  parameter READ_FIFO = 3'b001;
  parameter READ_FIFO_WAIT = 3'b010;
  parameter UART = 3'b011;
  parameter IDLE = 3'b100;
  parameter RESET = 3'b101;
  parameter CHECK_COMPLETE = 3'b110;

  //wire w_uart32b_dataval;
  //wire [31:0] w_uart32b_datain;
  //wire fir_rx_rstn;
  //wire rx_fifo_rden;
  //wire rx_fifo_full;
  //wire rx_fifo_empty;
  //wire [31:0] rx_fifo_dataout;

  uart_tx #(
      .CLKS_PER_BIT(TX_CLKS_PER_BIT)
  ) transmitter (
      .i_clk       (clk),
      .i_rstn      (r_rstn),
      .i_txbyte    (o_uart_txbyte),
      .i_txsenddata(o_uart_send),
      .o_txdone    (i_uart_txed),
      .o_uarttx    (uart_tx),
      .o_txactive  (i_uart_active)
  );

  clock #(
      .PERIOD(CLK_1KHZ)
  ) clk_div (
      .clk_in(clk),
      .div_clkout(fir_clk)
  );
  synchronizer #(
      .WIDTH(1)
  ) sig_comp_sync (
      .i_clk(clk),
      .i_rst_n(r_rstn),
      .i_datain(w_sig_comp),
      .o_q2(sig_comp_12m)
  );

  wire fir_ready;
  // Instantiate the FIR filter module
  fir_multiplex #(
      .DATA_WIDTH(SIG_WIDTH),
      .TAP_WIDTH (TAP_WIDTH),
      .TAP_COUNT (TAP_COUNT)
  ) fir_module (
      .i_clk          (clk),
      .sample_freq_clk(fir_clk),
      //.i_sample_freq_rstn(fir_rstn),
      //.i_rstn            (r_rstn),
      .i_fir_datain   (fir_datain),
      .i_fir_en       (fir_valid),
      .o_fir_ready    (fir_ready),
      .o_fir_dataout  (fir_dataout),
      .o_fifo_wren    (fir_fifo_wren),
      .sig_comp       (w_sig_comp)
  );


  synchronizer #(
      .WIDTH(1)
  ) fir2uarttx_synch (
      .i_clk(fir_clk),
      .i_rst_n(1'b1),
      .i_datain(r_rstn),
      .o_q2(fir_rstn)
  );

  async_fifo #(
      .WIDTH(2 * SIG_WIDTH),
      .DEPTH(OP_FIFO_LEN)
  ) fir2uarttx_fifo (
      .i_wr_inc (fir_fifo_wren),
      .i_wr_clk (fir_clk),
      .i_wrrst_n(fir_rstn),
      .i_rd_inc (fifo_rd_en),
      .i_rd_clk (clk),
      .i_rdrst_n(r_rstn),
      .wr_full  (ff_full),
      .rd_empty (ff_empty),
      .i_datain (fir_dataout),
      .o_dataout(fifo_dataout)
  );


  filter_input_bram #(
      .SIG_WIDTH(SIG_WIDTH),
      .SIG_DEPTH(SIG_DEPTH),
      .SIG_FILE (IP_SIG_FILE),
      .SIG_LEN  (SIG_LEN)
  ) inst_filter_input_bram (
      .i_clk(fir_clk),
      .i_rstn(fir_rstn),
      .fir_valid(fir_valid),
      .sig_comp(w_sig_comp),
      .sig_out(fir_datain)
  );




  always @(posedge clk) begin

    case (r_state)

      START: begin
        if (!rst_done) begin
          r_state <= RESET;
          j = 0;
        end else r_state <= READ_FIFO;
      end

      RESET: begin
        r_rstn <= 1'b0;
        j <= j + 1;
        if (j > 20000) begin
          r_rstn <= 1'b1;
          j <= 0;
          byte_count <= 0;
          buffer <= 0;
          fifo_rd_en <= 1'b0;
          rst_done <= 1'b1;
          r_state <= START;
          o_uart_send <= 1'b0;
          o_uart_txbyte <= 0;
        end
      end

      // Read data from the FIFO which is automatically filled by the FIR
      // module
      READ_FIFO: begin
        o_uart_send <= 1'b0;
        if (!ff_empty) begin
          fifo_rd_en <= 1'b1;
          r_state <= READ_FIFO_WAIT;
        end else begin
          if (sig_comp_12m) begin
            r_state <= IDLE;
          end else r_state <= START;
        end
      end

      // Account for FIFO delay 
      READ_FIFO_WAIT: begin
        fifo_rd_en <= 1'b0;
        buffer <= fifo_dataout;
        byte_count <= 3'b000;
        r_state <= UART;
      end


      // Transmit data over the UART
      UART: begin
        if (byte_count < 5) begin
          if (!i_uart_active && !o_uart_send) begin
            o_uart_txbyte <= select_byte(byte_count);
            byte_count <= byte_count + 1;
            o_uart_send <= 1'b1;
          end else if (i_uart_txed) begin
            o_uart_send <= 1'b0;
            r_state <= UART;
          end else begin
          end
        end else begin
          byte_count <= 3'b000;
          r_state <= READ_FIFO;
        end
      end

      IDLE: begin
        LED_G <= 1'b0;
        o_uart_send <= 1'b0;
        fifo_rd_en <= 1'b0;
      end

      default: begin
        r_state <= START;
      end

    endcase
  end


  //assign o_ff_rden = (!ff_empty && i_uart_txed);
  //assign o_uart_send = o_ff_rden;
  //assign o_uart_txbyte = i_ff_datout;


  function [7:0] select_byte;
    input [2:0] select;
    reg [7:0] data_out;  // Declare the output variable
    begin
      case (select)
        3'b000:  data_out = 8'h49;  //MSB
        3'b001:  data_out = buffer[31:24];
        3'b010:  data_out = buffer[23:16];
        3'b011:  data_out = buffer[15:8];  //LSB
        3'b100:  data_out = buffer[7:0];  //LSB
        default: data_out = 8'b0;  // Default case (optional)
      endcase
      select_byte = data_out;  // Assign the result to the function name
    end
  endfunction


endmodule
