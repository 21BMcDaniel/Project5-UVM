`include "uvm_macros.svh"
// Single Port RAM
// Drives the DUT pins:
interface dut_if;
  logic        clk;      // Clock
  logic        rst_n;    // Active-low reset
  logic        wr_en;    // Write enable
  logic        rd_en;    // Read enable
  logic [7:0]  addr;     // Address
  logic [31:0] data_in;  // Data input
  logic [31:0] data_out; // Data output
endinterface

// Single-port memory module
module memory (
  input  logic        clk,      // Clock
  input  logic        rst_n,    // Active-low reset
  input  logic        wr_en,    // Write enable
  input  logic        rd_en,    // Read enable
  input  logic [7:0]  addr,     // Address
  input  logic [31:0] data_in,  // Data input
  output logic [31:0] data_out  // Data output
);

  // Memory array
  logic [31:0] mem [0:255];

  // Reset and write operation
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all memory locations to 0
      for (int i = 0; i < 256; i++) begin
        mem[i] <= 32'h0;
      end
      data_out <= 32'h0;
    end
    else begin
      // Write operation
      if (wr_en) begin
        mem[addr] <= data_in;
      end

      // Read operation
      if (rd_en) begin
        data_out <= mem[addr];
      end
    end
  end

endmodule
