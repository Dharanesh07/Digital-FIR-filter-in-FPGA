module uart_rx_16bit (
    input i_clk,
    input i_rstn,
    input uart_rx,
    output [7:0] w_rxbyte,
    output w_rxdataval,
    output reg o_datavalid,
    output reg [15:0] dataout
);

  //wire [7:0] w_rxbyte;
  reg [7:0] data_buf;
  reg count;
  //wire w_rxdataval;
  reg rstate;

  parameter CLKS_PER_BIT = 1250;
  uart_rx #(
      .CLKS_PER_BIT(CLKS_PER_BIT),
      .HALF_CLK_PERIOD(CLKS_PER_BIT / 2)

  ) receiver (
      .i_clk     (i_clk),
      .i_rstn    (i_rstn),
      .i_uartrx  (uart_rx),
      .o_rxdatval(w_rxdataval),
      .o_rxbyte  (w_rxbyte)
  );

  always @(posedge i_clk) begin

    if (!i_rstn) begin
      count <= 0;
      dataout <= 0;
      o_datavalid <= 1'b0;
      data_buf <= 0;
    end else begin
      if (w_rxdataval) begin
        if (count == 1) begin
          dataout <= {data_buf, w_rxbyte};
          o_datavalid <= 1'b1;
          count <= 1'b0;
        end else begin
          data_buf <= w_rxbyte;
          count <= 1'b1;
          o_datavalid <= 1'b0;
        end
      end else o_datavalid <= 1'b0;
    end

  end

endmodule
