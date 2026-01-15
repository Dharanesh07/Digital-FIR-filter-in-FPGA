module filter_input_fifo #(
    parameter SIG_WIDTH = 16
) (
    input i_clk,
    input i_rstn,
    input i_ff_empty,
    input i_ff_full,
    input i_ff_half_full,
    input [SIG_WIDTH-1:0] fifo_dataout,
    output reg sig_comp,
    output reg data_valid,
    output reg o_fifo_rden,
    output reg [SIG_WIDTH-1:0] sig_out
);

  reg is_half_filled;

  always @(posedge i_clk) begin
    if (!i_rstn) begin
      sig_comp    <= 1'b0;
      o_fifo_rden <= 1'b0;
      sig_out     <= {SIG_WIDTH{1'b0}};
    end else begin
      if (!i_ff_empty && is_half_filled) begin
        o_fifo_rden <= 1'b1;
        sig_comp <= 1'b0;
        sig_out <= fifo_dataout;
      end else begin
        sig_comp <= 1'b1;
        o_fifo_rden <= 1'b0;
      end
    end
  end

  always @(posedge i_clk) begin
    if (!i_rstn) begin
      is_half_filled <= 1'b0;
      data_valid <= 1'b0;
    end else begin
      if (i_ff_half_full) begin
        is_half_filled <= 1'b1;
        data_valid <= 1'b1;
      end
    end
  end
endmodule


