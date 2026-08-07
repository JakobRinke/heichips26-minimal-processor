// SPDX-FileCopyrightText: © 2026 XXX Authors
// SPDX-License-Identifier: Apache-2.0

// Adapted from the Tiny Tapeout template

`default_nettype none

module heichips26_minimal_multicore_processor (
`ifdef USE_POWER_PINS
    inout  wire VPWR,
    inout  wire VGND,
`endif
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

localparam CPU_COUNT = 2;
localparam ADDR_WIDTH = 8;
localparam DATA_WIDTH = 8;

assign uio_oe = 8'h00;
assign uio_out = 8'h00;

wire mem_done[CPU_COUNT-1:0];
wire [DATA_WIDTH*2-1:0] data_out_cpu;
wire [ADDR_WIDTH-1:0] reg_data [CPU_COUNT-1:0];
wire [ADDR_WIDTH-1:0] ram_addr [CPU_COUNT-1:0];
wire valid[CPU_COUNT-1:0];
wire do_swap[CPU_COUNT-1:0];

genvar i;
generate
    for (i = 0; i < CPU_COUNT; i = i + 1) begin
        cpu_core cpu (
            .clk(clk),
            .rst_n(rst_n),
            .ram_data_ready_i(mem_done[i]),
            .data_word_in_i(data_out_cpu),
            .ram_addr_o(ram_addr[i]),
            .data_word_out_o(reg_data[i]),
            .ram_out_valid_o(valid[i]),
            .ram_out_do_swap_o(do_swap[i])
        );
    end
endgenerate

mmu #(
    .CPU_COUNT(CPU_COUNT),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .reg_data(reg_data),
    .ram_addr(ram_addr),
    .valid(valid),
    .do_swap(do_swap),
    .fpga_in1(ui_in),
    .fpga_in2(uio_in),
    .mem_done(mem_done),
    .data_out_cpu(data_out_cpu),
    .fpga_out(uo_out)
);

endmodule
