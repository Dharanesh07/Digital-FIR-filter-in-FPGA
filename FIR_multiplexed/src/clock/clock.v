module clock #(

  parameter PERIOD = 625      // 12MHz/(9600Hz*2) = 625
)(
    input clk_in,
    output reg div_clkout = 0  // Initialize output
);

  /* 9600 Hz clock generation (from 12 MHz) */
  localparam CNTR_WIDTH = $clog2(PERIOD);
  (* noglobal *) reg [CNTR_WIDTH-1:0] cntr = 0;

  always @(posedge clk_in) begin
    if (cntr == PERIOD-1) begin  // Compare before terminal count
      div_clkout <= ~div_clkout;
      cntr <= 0;
    end else begin
      cntr <= cntr + 1;
    end
  end

endmodule
