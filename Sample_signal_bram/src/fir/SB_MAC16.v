module SB_MAC16 #(

    parameter MODE_8x8 = 0,
    parameter A_SIGNED = 0,
    parameter B_SIGNED = 0,
    parameter A_REG = 0,
    parameter B_REG = 0,
    parameter C_REG = 0,
    parameter D_REG = 0,
    parameter TOP_8x8_MULT_REG = 0,
    parameter BOT_8x8_MULT_REG = 0,
    parameter PIPELINE_16x16_MULT_REG1 = 0,
    parameter PIPELINE_16x16_MULT_REG2 = 0,
    parameter TOPOUTPUT_SELECT = 0,  //accumulator top half
    parameter BOTOUTPUT_SELECT = 0  //accumulator bottom half
) (
    input wire CLK,
    input wire CE,
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [15:0] C,
    input wire [15:0] D,
    output reg [31:0] O,
    input wire IRSTTOP,
    input wire IRSTBOT,
    input wire ORSTTOP,
    input wire ORSTBOT,
    input wire OLOADTOP,
    input wire OLOADBOT
);
  /*
always @(posedge CLK) begin
    if (CE) begin
      O <= $signed(A) * $signed(B) + {C, D};
    end
  end

*/

  wire signed [31:0] product;
  assign product = $signed(A) * $signed(B);

  // Accumulator with synchronous reset
  always @(posedge CLK) begin
    if (ORSTTOP | ORSTBOT) begin
      O <= 32'b0;
    end else if (CE) begin
      O <= O + product;
    end
  end



endmodule
