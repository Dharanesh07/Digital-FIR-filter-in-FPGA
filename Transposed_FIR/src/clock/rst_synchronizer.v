module rst_synchronizer (
    input  i_clk,
    input  i_async_rst_n,
    output o_sync_rst_n
);
  reg q1, q2;

  always @(posedge i_clk or negedge i_async_rst_n) begin
    if (!i_async_rst_n) begin
      q1 <= 1'b0;
      q2 <= 1'b0;
    end else begin
      q1 <= 1'b1;
      q2 <= q1;
    end
  end

  assign o_sync_rst_n = q2;
endmodule
