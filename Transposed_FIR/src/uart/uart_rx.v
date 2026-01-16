// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_clk)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87

module uart_rx #(
    parameter CLKS_PER_BIT = 1250,
    parameter HALF_CLK_PERIOD = 625
) (
    input        i_clk,
    input        i_uartrx,
    output       o_rxdatval,
    output       start,
    output [7:0] o_rxbyte
);

  parameter IDLE = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT = 3'b011;
  parameter CLEANUP = 3'b100;

  reg       r_rxdata_buf = 1'b1;
  reg       r_rxdata = 1'b1;
  reg       r_rxtestst = 1'b0;

  reg [15:0] r_clkcount = 0;
  reg [2:0] r_bitindex = 0;  //8 bits total
  reg [7:0] r_rxbyte = 0;
  reg       r_rxdatval = 0;
  reg [2:0] r_state = 0;

  initial begin
    r_clkcount = 1'b0;
    r_state = IDLE;
  end
  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge i_clk) begin
    r_rxdata_buf <= i_uartrx;
    r_rxdata <= r_rxdata_buf;
  end


  // Purpose: Control RX state machine
  always @(posedge i_clk) begin

    case (r_state)
      IDLE: begin
        r_rxdatval <= 1'b0;
        r_clkcount <= 1'b0;
        r_bitindex <= 1'b0;

        if (r_rxdata == 1'b0) begin  // Start bit detected
          r_state <= RX_START_BIT;
          r_rxtestst = 1'b1;
        end else r_state <= IDLE;
      end

      // Check middle of start bit to make sure it's still low
      RX_START_BIT: begin
        if (r_clkcount == HALF_CLK_PERIOD) begin
          if (r_rxdata == 1'b0) begin
            r_rxtestst = 1'b0;
            r_clkcount <= 0;  // reset counter, found the middle
            r_state <= RX_DATA_BITS;
          end else r_state <= IDLE;
        end else begin
          r_clkcount <= r_clkcount + 1;
          r_state <= RX_START_BIT;
        end
      end  // case: RX_START_BIT


      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      RX_DATA_BITS: begin
        if (r_clkcount < CLKS_PER_BIT - 1) begin
          r_clkcount <= r_clkcount + 1;
          r_state <= RX_DATA_BITS;
        end else begin
          r_clkcount           <= 0;
          r_rxbyte[r_bitindex] <= r_rxdata;

          // Check if we have received all bits
          if (r_bitindex < 7) begin
            r_bitindex <= r_bitindex + 1;
            r_state <= RX_DATA_BITS;
          end else begin
            r_bitindex <= 0;
            r_state <= RX_STOP_BIT;
          end
        end
      end  // case: RX_DATA_BITS


      // Receive Stop bit.  Stop bit = 1
      RX_STOP_BIT: begin
        // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
        if (r_clkcount < CLKS_PER_BIT - 1) begin
          r_clkcount <= r_clkcount + 1;
          r_state <= RX_STOP_BIT;
        end else begin
          r_rxdatval <= 1'b1;
          r_clkcount <= 0;
          r_state <= CLEANUP;
        end
      end  // case: RX_STOP_BIT


      // Stay here 1 clock
      CLEANUP: begin
        r_state <= IDLE;
        r_rxdatval <= 1'b0;
      end


      default: r_state <= IDLE;

    endcase
  end

  assign o_rxdatval = r_rxdatval;
  assign o_rxbyte   = r_rxbyte;
  assign start      = r_rxtestst;

endmodule  // uart_rx
