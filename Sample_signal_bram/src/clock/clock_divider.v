// as clock inputs to other flip-flops. Us the tick pulse in combination with
// other logic to determine when to perform some action.
//
// Based on work by: https://github.com/Paebbels


module clock_divider #(
    parameter COUNT = 12000000
) (
    input  i_clk,
    input  i_rstn,
    output tick
);

  // Calculate number of bits needed for the counter
  localparam WIDTH = (COUNT == 1) ? 1 : $clog2(COUNT);

  // Internal storage elements
  (*noglobal*) reg [WIDTH-1:0] count = 0;

  // Tick is high for one clock cycle at max count
  assign tick = (count == COUNT - 1) ? 1'b1 : 1'b0;

  // Count up, reset on tick pulse
  always @(posedge i_clk) begin
    if (!i_rstn | tick == 1'b1) begin
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end

endmodule
