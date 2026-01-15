// BRAM Implementation
// This module implements BRAM based read only ROM
// When the address bits are set, it takes one clock cycle to send the data
// through the output.


//Parameters
//WIDTH - Determines the width of data bits
//DEPTH - Determines the length of storage
//INIT_FILE - File which has to be preloaded at startup


//Signals
// i_bram_clkrd - Input clock to the BRAM
// i_bram_rstn  - Active low reset signal
// i_bram_rden  - Read enable signal 
// o_bram_dataout - Data output for BRAM
// i_bram_rdaddr - Read address


module bram #(
    parameter WIDTH = 16,
    parameter DEPTH = 101,
    parameter INIT_FILE = "mem.txt",
    parameter END_COUNT = 8,
    parameter LEN = $clog2(DEPTH)
) (
    input wire i_bram_clkrd,
    input wire i_bram_rstn,
    input wire i_bram_rden,
    output reg [WIDTH-1:0] o_bram_dataout,
    input wire [LEN-1:0] i_bram_rdaddr
);

  (* ram_style = "block" *) reg [WIDTH-1:0] block_ram[0:DEPTH-1];

  initial begin
    $display("Loading init file '%s' into bram", INIT_FILE);
    $readmemb(INIT_FILE, block_ram, 0, END_COUNT - 1);
  end

  always @(posedge i_bram_clkrd) begin
    if (!i_bram_rstn) begin
      o_bram_dataout <= 0;
    end else if (i_bram_rden) begin
      o_bram_dataout <= block_ram[i_bram_rdaddr];
    end
  end
endmodule
