module top (
    input      clk,
    output     uart_tx,
    output reg LED_G
);

  parameter CLK_1KHZ = 6000;

  parameter SIG_DEPTH = 101;
  parameter SIG_WIDTH = 16;
  parameter SIG_FILE = "sig.txt";
  parameter SIG_LEN = 100;
  parameter TAP_WIDTH = 16;
  parameter TAP_COUNT = 8;
  parameter TAP_FILE = "tap.txt";

  wire fir_clk;
  wire fir_rstn;
  wire [SIG_WIDTH-1:0] fir_datain;
  wire [2*(SIG_WIDTH)-1:0] fir_dataout;
  wire [2*(SIG_WIDTH)-1:0] fifo_dataout;
  wire fir_fifo_wren;
  reg [(2*SIG_WIDTH)-1:0] buffer;
  reg [3:0] byte_count;
  reg fifo_rd_en;


  //uart declarations
  // CLKS_PER_BIT = (Frequency of i_clk)/(Frequency of UART)
  // Example: 12 MHz Clock, 115200 baud UART
  // (12000000)/(115200) = 104.16
  // 12000000 / 9600 = 1250
  parameter UART_CPB = 625;
  reg r_rstn;
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
  wire sig_complete;
  wire sig_comp_12m;

  integer i, j;
  reg [3:0] r_state;
  parameter START = 3'b000;
  parameter READ_FIFO = 3'b001;
  parameter READ_FIFO_WAIT = 3'b010;
  parameter UART = 3'b011;
  parameter IDLE = 3'b100;
  parameter RESET = 3'b101;
  parameter CHECK_COMPLETE = 3'b110;


  initial begin
    r_rstn = 1'b1;
    r_state = 3'b000;
    buffer = 0;
    byte_count = 0;
    fifo_rd_en = 0;
    o_uart_send = 0;
    o_uart_txbyte = 0;
  end

  uart_tx #(
      .CLKS_PER_BIT(UART_CPB)
  ) transmitter (
      .i_clk       (clk),
      .i_txbyte    (o_uart_txbyte),
      .i_txsenddata(o_uart_send),
      .o_txdone    (i_uart_txed),
      .o_uarttx    (uart_tx),
      .o_txactive  (i_uart_active)
  );


  clock #(
      .PERIOD(CLK_1KHZ)
  ) inst (
      .clk_in(clk),
      .div_clkout(fir_clk)
  );
  /* 
  clock_divider #(
      .COUNT(CLK_1KHZ)
  ) fir_clk_div (
      .i_clk    (clk),
      .i_rstn   (1'b1),
      .o_div_clk(fir_clk)
  );
*/

  filter_input #(
      .SIG_DEPTH(SIG_DEPTH),
      .SIG_WIDTH(SIG_WIDTH),
      .SIG_FILE (SIG_FILE),
      .SIG_LEN  (SIG_LEN)
  ) inst_filter_input (
      .i_clk(fir_clk),
      .i_rstn(r_rstn),
      .sig_out(fir_datain),
      .sig_complete(sig_complete)
  );

  // Instantiate the FIR filter module
  transposed_fir #(
      .DATA_WIDTH(SIG_WIDTH),
      .TAP_WIDTH (TAP_WIDTH),
      .TAP_COUNT (TAP_COUNT),
      .COEFF_FILE(TAP_FILE)
  ) uut (
      .i_clk        (fir_clk),
      .i_rstn       (r_rstn),
      .i_fir_datain (fir_datain),
      .o_fir_dataout(fir_dataout),
      .o_fifo_wren  (fir_fifo_wren),
      .sig_comp     (sig_complete)
  );


  synchronizer #(
      .WIDTH(1)
  ) sig_comp_sync (
      .i_clk(clk),
      .i_rst_n(r_rstn),
      .i_datain(sig_complete),
      .o_q2(sig_comp_12m)
  );
  rst_synchronizer inst_rst_synchronizer (
      .i_clk(fir_clk),
      .i_async_rst_n(r_rstn),
      .o_sync_rst_n(fir_rstn)
  );

  async_fifo #(
      .WIDTH((2 * SIG_WIDTH)),
      .DEPTH(100)
  ) inst_async_fifo (
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



  always @(posedge clk) begin
    case (r_state)

      START: begin
        if (!rst_done) begin
          r_state <= RESET;
          j <= 0;
        end else r_state <= READ_FIFO;
      end

      // Initialize all the modules on reset
      RESET: begin
        r_rstn <= 1'b0;
        j <= j + 1;
        if (j > 10000) begin
          r_rstn <= 1'b1;
          j <= 0;
          rst_done <= 1'b1;
          r_state <= START;
        end
      end

      // Read data from the FIFO which is automatically filled by the FIR
      // module
      READ_FIFO: begin
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
        if (byte_count < 4) begin
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


  function [7:0] select_byte;
    input [2:0] select;
    reg [7:0] data_out;  // Declare the output variable
    begin
      case (select)
        3'b000:  data_out = buffer[31:24];  //MSB
        3'b001:  data_out = buffer[23:16];
        3'b010:  data_out = buffer[15:8];
        3'b011:  data_out = buffer[7:0];  //LSB
        default: data_out = 8'b0;  // Default case (optional)
      endcase
      select_byte = data_out;  // Assign the result to the function name
    end
  endfunction


endmodule
