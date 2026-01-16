module ice40_pll #(
    parameter FB_PATH     = "SIMPLE",
    parameter REF_CLK_DIV = 4'b0000,
    parameter FB_CLK_DIV  = 7'b0111111,
    parameter OUT_CLK_DIV = 3'b100,
    parameter FILT_RANGE  = 3'b001

) (
    input wire i_clk,  // Input clock (e.g., 12 MHz)
    output wire o_pll_clk  // Output clock from PLL
);

  // PLL parameters
  wire pll_lock;  // PLL lock signal
  wire pll_feedback;  // PLL feedback signal

  // Instantiate the PLL
  SB_PLL40_CORE #(
      .FEEDBACK_PATH(FB_PATH),      // Feedback path (SIMPLE, DELAY, PHASE_AND_DELAY)
      .DIVR         (REF_CLK_DIV),  // Reference clock divider (0-15)
      .DIVF         (FB_CLK_DIV),   // Feedback divider (0-127)
      .DIVQ         (OUT_CLK_DIV),  // Output divider (0-7)
      .FILTER_RANGE (FILT_RANGE)    // Filter range (0-7)
  ) pll_inst (
      .REFERENCECLK   (i_clk),      // Input reference clock
      .PLLOUTCORE     (o_pll_clk),  // Output clock
      .PLLOUTGLOBAL   (),           // Global clock output (unused)
      .EXTFEEDBACK    (1'b0),       // External feedback (unused)
      .DYNAMICDELAY   (8'b0),       // Dynamic delay (unused)
      .RESETB         (1'b1),       // PLL reset (active low)
      .BYPASS         (1'b0),       // Bypass PLL (active high)
      .LATCHINPUTVALUE(1'b0),       // Latch input value (unused)
      .LOCK           (pll_lock),   // PLL lock signal
      .SDI            (1'b0),       // Serial data input (unused)
      .SDO            (),           // Serial data output (unused)
      .SCLK           (1'b0)        // Serial clock (unused)
  );

endmodule
