// This module implements transposed FIR filter architecture
// Outputs computed FIR data every clock cycle

// Parameters
// DATA_WIDTH - Determines the width of data bits
// TAP_WIDTH - Determines the width of tap bits
// TAP_COUNT - Number of taps present in the FIR filter

// Signal
// i_clk - Input FIFO clock
// i_rst - FIFO active high reset signal
// i_fir_datain - Input data to the FIFO
// o_fir_dataout - Output data from the FIFO



module transposed_fir #(
    parameter DATA_WIDTH = 16,
    parameter TAP_WIDTH  = 16,
    parameter TAP_COUNT  = 8,
    parameter COEFF_FILE = "tap.txt"
) (
    input wire i_clk,
    input wire i_rstn,
    input wire signed [DATA_WIDTH-1:0] i_fir_datain,
    output reg signed [(2*DATA_WIDTH)-1:0] o_fir_dataout,
    output reg o_fifo_wren,
    input wire sig_comp
);


  // Coefficients and delay registers
  reg signed [DATA_WIDTH-1:0] coeff[TAP_COUNT-1:0];
  reg signed [(2*DATA_WIDTH)-1:0] acc[TAP_COUNT-1:0];
  integer i, k;
  reg wren_pipeline = 1'b0;
  reg signed [(2*DATA_WIDTH)-1:0] data_pipeline;

  // Load coefficients from file (if needed)



  initial begin
    o_fifo_wren = 1'b0;
    for (i = 0; i < TAP_COUNT; i = i + 1) begin
      //coeff[i] = 0;
      acc[i] = 0;
    end
    //$readmemb(COEFF_FILE, coeff, 0, (TAP_COUNT - 1));
  end

  // Transposed FIR logic
  always @(posedge i_clk) begin
      if (!i_rstn) begin
      // Reset accumulators
      coeff[0] <= 16'b1111111111111000;
      coeff[1] <= 16'b0000000000110001;
      coeff[2] <= 16'b0000001001110100;
      coeff[3] <= 16'b0000011100000001;
      coeff[4] <= 16'b0000100110011010;
      coeff[5] <= 16'b0000011100000001;
      coeff[6] <= 16'b0000001001110100;
      coeff[7] <= 16'b0000000000110001;
      coeff[8] <= 16'b1111111111111000;
      acc[0]   <= 32'b00000000000000000000000000000000;
      acc[1]   <= 32'b00000000000000000000000000000000;
      acc[2]   <= 32'b00000000000000000000000000000000;
      acc[3]   <= 32'b00000000000000000000000000000000;
      acc[4]   <= 32'b00000000000000000000000000000000;
      acc[5]   <= 32'b00000000000000000000000000000000;
      acc[6]   <= 32'b00000000000000000000000000000000;
      acc[7]   <= 32'b00000000000000000000000000000000;
      acc[8]   <= 32'b00000000000000000000000000000000;

      for (i = 0; i < TAP_COUNT; i = i + 1) begin
        acc[i] <= 0;
      end
      o_fifo_wren   <= 1'b0;
      o_fir_dataout <= 0;
      data_pipeline <= 0;
    end else begin
      // Broadcast input to all multipliers and accumulate
      acc[0] <= i_fir_datain * coeff[0];
      for (k = 1; k < TAP_COUNT; k = k + 1) begin
          // Multiply and Accumulate operation
        acc[k] <= acc[k-1] + (i_fir_datain * coeff[k]);
      end
      // Output the final accumulated value
      data_pipeline <= acc[TAP_COUNT-1];
    //data_pipeline <= i_fir_datain;
    wren_pipeline <= 1'b1;

    o_fifo_wren   <= wren_pipeline & (~sig_comp);
    o_fir_dataout <= data_pipeline;
  end
  end

endmodule

