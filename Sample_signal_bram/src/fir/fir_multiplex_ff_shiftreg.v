module fir_multiplex #(
    parameter DATA_WIDTH = 16,
    parameter TAP_WIDTH  = 16,
    parameter TAP_COUNT  = 65
) (
    input wire i_clk,
    input wire sample_freq_clk,
    input wire i_sample_freq_rstn,
    input wire i_rstn,
    input wire i_fir_valid,
    input wire signed [DATA_WIDTH-1:0] i_fir_datain,
    output reg signed [(2*DATA_WIDTH)-1:0] o_fir_dataout,
    //output wire signed [(2*DATA_WIDTH)-1:0] o_fir_dataout,
    output reg o_fifo_wren,
    input wire sig_comp
);

  //localparam CLK_1KHZ = 1200;
  localparam CLK_1KHZ = 6000;
  localparam TAP_FILE = "tap.txt";
  localparam ACC_WIDTH = 2 * DATA_WIDTH;
  localparam LEN = $clog2(TAP_COUNT + 1);


  reg [9:0] counter;
  reg [4:0] r_state;
  localparam START = 4'b0000;
  localparam SHIFT_READ = 4'b0001;
  localparam SHIFT_WRITE = 4'b0010;
  localparam SHIFT_WRITE_WAIT = 4'b0011;
  //localparam STORE_NEW_DATA = 4'b0100;
  localparam LOAD_MAC_DATAIN = 4'b0101;
  localparam LOAD_MAC_DATAIN_WAIT = 4'b0110;
  localparam LOAD_BRAM_COEFF = 4'b0111;
  localparam LOAD_BRAM_COEFF_WAIT = 4'b1000;
  localparam START_MUL = 4'b1001;
  localparam STOP_MUL = 4'b1010;
  localparam LOAD_BRAM_COEFF_SETUP = 4'b1011;
  localparam SHIFT_WAIT_READ = 4'b1100;
  localparam MUL_WAIT = 4'b1101;

  reg signed [DATA_WIDTH-1:0] mac_input;
  reg signed [DATA_WIDTH-1:0] mac_coeff;
  wire signed [(2*DATA_WIDTH)-1:0] mac_result;
  reg dsp_enable;
  reg signed [DATA_WIDTH-1:0] delay_line[0:TAP_COUNT-1];


  integer i;
  //integer load_count;
  reg o_bram_clk = 1'b0;
  reg coeff_rden = 1'b0;
  wire signed [TAP_WIDTH-1:0] i_bram_dat;
  wire [LEN-1:0] coeff_addr;
  reg coeff_loaded;
  reg [LEN:0] shift_index;
  reg [LEN-1:0] load_count;
  reg acc_rst;
  //wire sample_freq_clk;

  /*
  clock #(
      .PERIOD(CLK_1KHZ)
  ) clk_inst (
      .clk_in(i_clk),
      .div_clkout(sample_freq_clk)
  );
*/


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

  reg delaylin_wren;
  reg [LEN:0] delaylin_wr_addr;
  reg [LEN:0] delaylin_rd_addr;
  wire signed [DATA_WIDTH-1:0] delaylin_dataout;
  reg signed [DATA_WIDTH-1:0] delaylin_bufa;
  reg signed [DATA_WIDTH-1:0] delaylin_datain;
  reg signed [DATA_WIDTH-1:0] i_fir_datain_buf;
  /*
  dual_port_bram #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(TAP_COUNT - 1),
      .ADDR_WIDTH(LEN)
  ) delay_line (
      .clk     (i_clk),
      .i_rstn  (i_rstn),
      .we_en   (delaylin_wren),
      .addr_wr (delaylin_wr_addr),
      .addr_rd (delaylin_rd_addr),
      .data_in (delaylin_datain),
      .data_out(delaylin_dataout)
  );
*/
  //DSP block performs multiplication and accumulates within itself

  /*
  SB_MAC16 #(
      .MODE_8x8                (1'b0),
      .A_SIGNED                (1),
      .B_SIGNED                (1),
      .A_REG                   (1'b1),   // Input registers enabled
      .B_REG                   (1'b1),   // Input registers enabled
      .C_REG                   (1'b0),
      .D_REG                   (1'b0),
      .TOP_8x8_MULT_REG        (1'b0),
      .BOT_8x8_MULT_REG        (1'b0),
      .PIPELINE_16x16_MULT_REG1(1'b0),
      .PIPELINE_16x16_MULT_REG2(1'b0),
      .TOPOUTPUT_SELECT        (2'b01),  // accumulator top half
      .BOTOUTPUT_SELECT        (2'b01)   // accumulator bottom half
  ) mac_dsp (
      .CLK      (i_clk),
      .CE       (dsp_enable),  // Always enabled (controlled via inputs)
      .A        (mac_input),
      .B        (mac_coeff),
      .C        (16'd0),
      .D        (16'd0),
      .O        (mac_result),
      .IRSTTOP  (acc_rst),     // Reset input registers
      .IRSTBOT  (acc_rst),     // Reset input registers
      .ORSTTOP  (acc_rst),     // Reset accumulator
      .ORSTBOT  (acc_rst),     // Reset accumulator
      .OLOADTOP (1'b0),        // Don't load from C (keep as 0)
      .OLOADBOT (1'b0),        // Don't load from C (keep as 0)
      .ADDSUBTOP(1'b0),
      .ADDSUBBOT(1'b0)
  );

*/

  // DSP inference signals
  reg signed [DATA_WIDTH-1:0] a_reg, b_reg;
  reg signed [2*DATA_WIDTH-1:0] mult_result;
  reg signed [2*DATA_WIDTH-1:0] accumulator;
  reg ce_reg;
  reg acc_rst;

  // DSP inference with registered inputs and accumulation
  always @(posedge i_clk) begin
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

      mult_result <= a_reg * b_reg;

      if (acc_rst) begin
        accumulator <= 0;
      end else if (ce_reg) begin
        accumulator <= accumulator + mult_result;
      end
    end
  end

  assign mac_result = accumulator;


  //Provides input and output at 1KHz to maintain 1KHz sampling frequency
  always @(posedge sample_freq_clk) begin
    if (!i_sample_freq_rstn) begin
      o_fir_dataout <= 32'b0;
    end else begin
      i_fir_datain_buf <= i_fir_datain;
      //o_fir_dataout <= i_fir_datain;
      o_fir_dataout <= mac_result;
    end
  end

  reg signed [(2*DATA_WIDTH)-1:0] filter_result;
  reg sample_valid = 1'b0;
  reg sample_sync = 1'b0;
  reg sample_freq_sync1, sample_freq_sync2, sample_freq_sync3;


  // Proper clock domain crossing for sample trigger
  always @(posedge i_clk) begin
    if (!i_rstn) begin
      sample_freq_sync1 <= 1'b0;
      sample_freq_sync2 <= 1'b0;
      sample_freq_sync3 <= 1'b0;
      sample_valid <= 1'b0;
    end else begin
      // Synchronize sample clock to main clock domain
      sample_freq_sync1 <= sample_freq_clk;
      sample_freq_sync2 <= sample_freq_sync1;
      sample_freq_sync3 <= sample_freq_sync2;

      // Detect rising edge of sample clock
      sample_valid <= sample_freq_sync2 & ~sample_freq_sync3;
    end
  end

  assign coeff_addr = counter;

  //Main FSM
  always @(posedge i_clk) begin

    if (!i_rstn) begin
      r_state <= START;
      acc_rst <= 1'b1;
      dsp_enable <= 1;
      counter <= 0;
      prev_result <= 0;
      o_fifo_wren <= 0;
      shift_index <= 0;
      mac_input <= 0;
      mac_coeff <= 0;
      dsp_enable <= 1'b1;
      delaylin_bufa <= 0;
      delaylin_datain <= 0;
      delaylin_wr_addr <= 0;
      delaylin_rd_addr <= 0;
      delaylin_wren <= 1'b0;
      for (i = 0; i < TAP_COUNT; i = i + 1) begin
        delay_line[i] <= 0;
      end
    end else begin

      case (r_state)

        START: begin
          dsp_enable <= 1'b0;
          if (sample_valid && i_fir_valid) begin
            acc_rst <= 1'b1;
            counter <= 0;
            shift_index <= TAP_COUNT - 1;

            for (i = TAP_COUNT - 1; i > 0; i = i - 1) begin
              delay_line[i] <= delay_line[i-1];
            end
            delay_line[0] <= i_fir_datain;

            r_state <= LOAD_MAC_DATAIN_WAIT;
          end else r_state <= START;
        end

        LOAD_MAC_DATAIN_WAIT: begin
          mac_input <= delay_line[counter];
          coeff_rden <= 1'b1;
          r_state <= LOAD_BRAM_COEFF_WAIT;
        end


        LOAD_BRAM_COEFF_WAIT: begin
          r_state <= LOAD_BRAM_COEFF;
        end


        LOAD_BRAM_COEFF: begin
          if (counter == 0) acc_rst <= 1'b0;
          mac_coeff  <= i_bram_dat;
          coeff_rden <= 1'b0;
          r_state    <= START_MUL;
        end

        START_MUL: begin
          dsp_enable <= 1'b1;
          r_state <= MUL_WAIT;
        end

        MUL_WAIT: begin
          dsp_enable <= 1'b0;
          r_state <= STOP_MUL;
        end

        STOP_MUL: begin
          //dsp_enable  <= 1'b0;
          o_fifo_wren <= ~sig_comp;
          if (counter == (TAP_COUNT - 1)) begin
            counter <= 0;
            filter_result <= mac_result;
            r_state <= START;
          end else begin
            counter <= counter + 1;
            r_state <= LOAD_MAC_DATAIN_WAIT;
          end

        end

        default: begin
          r_state <= START;
        end
      endcase

    end
  end


endmodule
