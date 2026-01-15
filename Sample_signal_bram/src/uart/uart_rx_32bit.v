module uart_rx_32bit #(
    parameter RX_CLKS_PER_BIT = 625
) (
    input             i_clk,
    input             i_rstn,
    input             uart_rx,
    input             i_ff_full,
    output            w_rxdataval,
    output     [ 7:0] w_rxbyte,
    output reg [ 7:0] buf0,
    output reg [ 7:0] buf1,
    output reg [ 7:0] buf2,
    output reg [ 7:0] buf3,
    output reg        half_full,
    output reg        o_datavalid,
    output reg [31:0] count,
    output reg [31:0] dataout
);

  //wire [7:0] w_rxbyte;
  //reg [7:0] buf0, buf1, buf2, buf3;
  //wire w_rxdataval;
  reg [2:0] rstate;
  //reg [32:0] count;

  parameter HALF_COUNT = 500;
  parameter BYTE0 = 3'b000;
  parameter BYTE1 = 3'b001;
  parameter BYTE2 = 3'b010;
  parameter BYTE3 = 3'b011;
  parameter CONCAT = 3'b100;


  uart_rx #(
      .CLKS_PER_BIT(RX_CLKS_PER_BIT),
      .HALF_CLK_PERIOD(RX_CLKS_PER_BIT / 2)

  ) uart_rx_fifo_in (
      .i_clk     (i_clk),
      //      .i_rstn    (i_rstn),
      .i_uartrx  (uart_rx),
      .o_rxdatval(w_rxdataval),
      .o_rxbyte  (w_rxbyte)
  );

  always @(posedge i_clk) begin

    if (!i_rstn) begin
      rstate <= BYTE0;
      dataout <= 0;
      o_datavalid <= 1'b0;
      buf0 <= 0;
      buf1 <= 0;
      buf2 <= 0;
      buf3 <= 0;
      count <= 0;
      half_full <= 1'b0;
    end else begin
      case (rstate)
        BYTE0: begin
          o_datavalid <= 1'b0;
          if (w_rxdataval) begin
            buf0   <= w_rxbyte;
            rstate <= BYTE1;
          end
        end
        BYTE1: begin
          o_datavalid <= 1'b0;
          if (w_rxdataval) begin
            buf1   <= w_rxbyte;
            rstate <= BYTE2;
          end
        end
        BYTE2: begin
          o_datavalid <= 1'b0;
          if (w_rxdataval) begin
            buf2   <= w_rxbyte;
            rstate <= BYTE3;
          end
        end
        BYTE3: begin
          o_datavalid <= 1'b0;
          if (w_rxdataval) begin
            buf3   <= w_rxbyte;
            rstate <= CONCAT;
          end
        end

        CONCAT: begin
          dataout <= {buf0, buf1, buf2, buf3};
          if (i_ff_full) begin
            rstate <= CONCAT;
          end else begin
            o_datavalid <= 1'b1;
            count <= count + 1;
            if (count > HALF_COUNT) begin
              half_full <= 1'b1;
            end
            rstate <= BYTE0;
          end
        end
        default: begin
          rstate <= BYTE0;
          o_datavalid <= 1'b0;
        end
      endcase
    end
  end

endmodule
