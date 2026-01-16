module dual_port_bram #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 128,
    parameter ADDR_WIDTH = $clog2(DEPTH + 1)
) (
    input  wire                  clk,
    input  wire                  i_rstn,
    input  wire                  we_en,
    input  wire [  ADDR_WIDTH:0] addr_wr,
    input  wire [  ADDR_WIDTH:0] addr_rd,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out
);

  (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem[0:DEPTH];
  parameter INIT_FILE = "dualportbram.txt";

  initial begin
    $display("Loading init file '%s' into bram", INIT_FILE);
    $readmemb(INIT_FILE, mem, 0, DEPTH);
  end

  always @(posedge clk) begin
    if (!i_rstn) data_out <= 0;
    else if (we_en) mem[addr_wr] <= data_in;
    data_out <= mem[addr_rd];
  end

endmodule

/*

module dual_port_bram #(

    parameter DATA_WIDTH = 16,
    parameter DEPTH = 128,
    parameter ADDR_WIDTH = $clog2(DEPTH + 1)

) (

    input  wire                  clk,
    input  wire                  we_en,
    input  wire                  i_rstn,
    input  wire [           6:0] addr_rd,  // 7 bits for 128 locations
    input  wire [           6:0] addr_wr,  // 7 bits for 128 locations
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

  wire [15:0] data;

  SB_RAM40_4K #(
      .WRITE_MODE(1'b0),    // 0 = write-through (output reflects write)
      .READ_MODE (1'b0),    // 0 = synchronous read
      .INIT_0    (256'h0),
      .INIT_1    (256'h0),  // You can initialize more INIT_x as needed
      .INIT_2    (256'h0),
      .INIT_3    (256'h0),
      .INIT_4    (256'h0),
      .INIT_5    (256'h0),
      .INIT_6    (256'h0),
      .INIT_7    (256'h0)
  ) ram_inst (
      .RCLK(clk),
      .RCLKE(1'b1),
      .RE(1'b1),

      .WCLK(clk),
      .WCLKE(1'b1),
      .WE(we),

      .RADDR(addr_rd),
      .WADDR(addr_wr),

      .WDATA(data_in),
      .MASK (16'h0000),  // No write masking
      .RDATA(data_out)
  );

endmodule

*/
