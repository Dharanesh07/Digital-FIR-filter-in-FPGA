// FIR Multiplexed with one DSP block implementation 
// This module implements FIR multiplexed version with a single DSP block 
// The filter computation runs at higher frequency to that of the sampling
// frequncy. Ensure that input clock is more than the sampling frequency 
// Module has active low reset and enabled with i_fir_en signal to initate the
// conversion

//Parameters
// DATA_WIDTH - Determines the width of data bits
// TAP_WIDTH - Determines the width of tap bits
// TAP_COUNT - Number of taps present in the FIR filter
// TAP_FILE - Tap values stored in fixed point format

//Signals
// i_clk - Input clock which should be higher than the sample frequency clock
// sample_freq_clk - Sample frequency clock which is the frequency at which
// the filter should work
// i_fir_en - Filter enable  
// i_fir_datain - Input data to the FIFO
// o_fir_dataout - Output data from the FIFO
// o_fir_ready - indicates FIR has completed calculation
// o_fifo_wren - fifo write enable signal to start writing to output FIFO
// sig_comp - Used to stop fifo write operation

module fir_multiplex #(
    parameter DATA_WIDTH = 16,
    parameter TAP_WIDTH  = 16,
    parameter TAP_COUNT  = 65
) (
    input wire i_clk,
    input wire sample_freq_clk,
    input wire i_fir_en,
    input wire signed [DATA_WIDTH-1:0] i_fir_datain,
    output reg signed [(2*DATA_WIDTH)-1:0] o_fir_dataout,
    output reg o_fir_ready,
    output reg o_fifo_wren,
    input wire sig_comp
);

  localparam CLK_1KHZ = 6000;
  localparam TAP_FILE = "tap.txt";
  localparam ACC_WIDTH = 2 * DATA_WIDTH + 4;  // Extra bits for overflow detection
  localparam OUTPUT_WIDTH = 2 * DATA_WIDTH;
  localparam LEN = $clog2(TAP_COUNT);
  localparam POWER_ON_RESET_CYCLES = 5;
  localparam SKIP_CYCLES = TAP_COUNT;

  // Saturation limits for 32-bit signed output
  localparam signed [OUTPUT_WIDTH-1:0] MAX_VALUE = 32'h7FFFFFFF;  // +2^31-1
  localparam signed [OUTPUT_WIDTH-1:0] MIN_VALUE = 32'h80000000;  // -2^31

  reg [LEN-1:0] output_skip_counter;
  reg [9:0] counter;
  reg [2:0] r_state;
  localparam START = 3'b000;
  localparam LOAD_MAC_DATAIN = 3'b001;
  localparam LOAD_MAC_DATAIN_WAIT = 3'b010;
  localparam LOAD_BRAM_COEFF = 3'b011;
  localparam LOAD_BRAM_COEFF_WAIT = 3'b100;
  localparam START_MUL = 3'b101;
  localparam STOP_MUL = 3'b110;
  localparam MUL_WAIT = 3'b111;

  reg signed [DATA_WIDTH-1:0] mac_input;
  reg signed [DATA_WIDTH-1:0] mac_coeff;
  wire signed [(2*DATA_WIDTH)-1:0] mac_result;
  reg dsp_enable;

  integer i;
  reg o_bram_clk = 1'b0;
  reg coeff_rden = 1'b0;
  wire signed [TAP_WIDTH-1:0] i_bram_dat;
  wire [LEN-1:0] coeff_addr;
  reg coeff_loaded;
  reg [LEN-1:0] load_count;
  reg acc_rst;

  // Internal reset signals
  reg i_rstn = 0;
  reg [15:0] reset_counter = 0;
  wire i_sample_freq_rstn;

  // Generate power-on reset
  always @(posedge sample_freq_clk) begin
    if (reset_counter < POWER_ON_RESET_CYCLES) begin
      reset_counter <= reset_counter + 1;
      i_rstn <= 1'b0;
    end else begin
      i_rstn <= 1'b1;
    end
  end

  synchronizer #(
      .WIDTH(1)
  ) fir2uarttx_synch (
      .i_clk(sample_freq_clk),
      .i_rst_n(1'b1),
      .i_datain(i_rstn),
      .o_q2(i_sample_freq_rstn)
  );

  // Circular buffer pointers
  reg [LEN-1:0] write_ptr;  // Points to next position to write
  reg [LEN-1:0] read_ptr;  // For reading delay line
  reg [LEN-1:0] oldest_ptr;  // Points to oldest sample

  bram #(
      .WIDTH    (TAP_WIDTH),
      .DEPTH    (TAP_COUNT),
      .INIT_FILE(TAP_FILE),
      .END_COUNT(TAP_COUNT)
  ) coeff_mem_bram (
      .i_bram_clkrd  (i_clk),
      .i_bram_rstn (i_rstn),
      .i_bram_rden   (coeff_rden),
      .o_bram_dataout(i_bram_dat),
      .i_bram_rdaddr (coeff_addr)
  );

  assign coeff_addr = counter;

  reg delaylin_wren;
  wire signed [DATA_WIDTH-1:0] delaylin_dataout;
  reg signed [DATA_WIDTH-1:0] delaylin_datain;
  reg signed [DATA_WIDTH-1:0] i_fir_datain_buf;

  dual_port_bram #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(TAP_COUNT),
      .ADDR_WIDTH(LEN)
  ) delay_line (
      .clk     (i_clk),
      .i_rstn  (i_rstn),
      .we_en   (delaylin_wren),
      .addr_wr (write_ptr),
      .addr_rd (read_ptr),
      .data_in (delaylin_datain),
      .data_out(delaylin_dataout)
  );

  // DSP inference with saturation
  reg signed [DATA_WIDTH-1:0] a_reg, b_reg;
  reg signed [2*DATA_WIDTH-1:0] mult_result;
  reg signed [ACC_WIDTH-1:0] accumulator;  // Extended accumulator for overflow detection
  reg ce_reg;

  // Saturation function
  function signed [OUTPUT_WIDTH-1:0] saturate;
    input signed [ACC_WIDTH-1:0] acc_value;
    begin
      if (acc_value > MAX_VALUE)
        saturate = MAX_VALUE;
      else if (acc_value < MIN_VALUE)
        saturate = MIN_VALUE;
      else
        saturate = acc_value[OUTPUT_WIDTH-1:0];
    end
  endfunction

  // DSP inference with registered inputs and accumulation
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      a_reg <= 0;
      b_reg <= 0;
      mult_result <= 0;
      accumulator <= 0;
      ce_reg <= 0;
    end else begin
      ce_reg <= dsp_enable;

      if (dsp_enable) begin
        a_reg <= mac_input;
        b_reg <= mac_coeff;
      end
      //DSP by inference
      mult_result <= a_reg * b_reg;
      // Reset accumulator for every newer input
      if (acc_rst) begin
        accumulator <= 0;
      end else if (ce_reg) begin
        accumulator <= accumulator + {{(ACC_WIDTH-2*DATA_WIDTH){mult_result[2*DATA_WIDTH-1]}}, mult_result};
      end
    end
  end

  // Apply saturation to output
  assign mac_result = saturate(accumulator);

  // Provides input and output at 1KHz
  always @(posedge sample_freq_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      output_skip_counter <= 0;
      i_fir_datain_buf <= 16'b0;
      o_fir_dataout <= 32'b0;
    end else begin
      i_fir_datain_buf <= i_fir_datain;
      // Skip counter is to avoid the overshoot
      if (output_skip_counter > SKIP_CYCLES) o_fir_dataout <= mac_result;
      else o_fir_dataout <= 32'b0;
  end
  end
  reg sample_valid = 1'b0;
  reg sample_sync = 1'b0;
  reg sample_freq_sync1, sample_freq_sync2, sample_freq_sync3;

  // Clock domain crossing for sample trigger
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      sample_freq_sync1 <= 1'b0;
      sample_freq_sync2 <= 1'b0;
      sample_freq_sync3 <= 1'b0;
      sample_valid <= 1'b0;
    end else begin
      sample_freq_sync1 <= sample_freq_clk;
      sample_freq_sync2 <= sample_freq_sync1;
      sample_freq_sync3 <= sample_freq_sync2;
      sample_valid <= sample_freq_sync2 & ~sample_freq_sync3;
    end
  end

  // Main FSM with circular buffer
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      r_state <= 0;
      acc_rst <= 1'b1;
      dsp_enable <= 0;
      counter <= 0;
      o_fifo_wren <= 0;
      mac_input <= 0;
      mac_coeff <= 0;
      o_fir_ready <= 1'b1;
      delaylin_datain <= 16'b0;
      delaylin_wren <= 1'b0;
      write_ptr <= 0;
      read_ptr <= 0;
      oldest_ptr <= 0;
      o_fir_ready <= 1'b0;
      output_skip_counter <= 0;
    end else begin
      case (r_state)
        START: begin
          dsp_enable  <= 1'b0;
          o_fir_ready <= 1'b1;
          if (sample_valid && i_fir_en) begin
            if(output_skip_counter <= SKIP_CYCLES) output_skip_counter <= output_skip_counter + 1;
            o_fir_ready <= 1'b0;
            acc_rst <= 1'b1;
            counter <= 0;
            // Store new sample in circular buffer
            delaylin_datain <= i_fir_datain_buf;
            delaylin_wren <= 1'b1;
            r_state <= LOAD_MAC_DATAIN;
          end
        end

        LOAD_MAC_DATAIN: begin
          delaylin_wren <= 1'b0;
          // Calculate read pointer (oldest_ptr - counter, modulo TAP_COUNT)
          read_ptr <= (oldest_ptr >= counter) ? 
                     (oldest_ptr - counter) : 
                     (TAP_COUNT + oldest_ptr - counter);
          r_state <= LOAD_MAC_DATAIN_WAIT;
        end

        LOAD_MAC_DATAIN_WAIT: begin
          // Wait for BRAM read latency
          r_state <= LOAD_BRAM_COEFF;
        end

        LOAD_BRAM_COEFF: begin
          if (counter == 0) acc_rst <= 1'b0;
          mac_input <= delaylin_dataout;
          coeff_rden <= 1'b1;
          r_state <= LOAD_BRAM_COEFF_WAIT;
        end

        LOAD_BRAM_COEFF_WAIT: begin
          // Wait for coefficient BRAM read
          r_state <= START_MUL;
        end
        //initiate DSP multiplicaton
        START_MUL: begin
          coeff_rden <= 1'b0;
          mac_coeff <= i_bram_dat;
          dsp_enable <= 1'b1;
          r_state <= MUL_WAIT;
        end
        // Wait for 1 cycle
        MUL_WAIT: begin
          dsp_enable <= 1'b0;
          r_state <= STOP_MUL;
        end
        // Stop multiplication
        STOP_MUL: begin
          o_fifo_wren <= ~sig_comp;
          if (counter == (TAP_COUNT - 1)) begin
            counter <= 0;
            // Update write pointer (circular)
            write_ptr <= (write_ptr == TAP_COUNT - 1) ? 0 : write_ptr + 1;
            // Oldest sample is now at the new write pointer location
            oldest_ptr <= write_ptr;
            o_fir_ready <= 1'b1;
            r_state <= START;
          end else begin
            counter <= counter + 1;
            r_state <= LOAD_MAC_DATAIN;
          end
        end

        default: begin
          r_state <= START;
        end
      endcase
    end
  end
endmodule
