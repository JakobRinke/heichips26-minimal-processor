// SPDX-FileCopyrightText: 2026 XXX
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Description: SystemVerilog testbench for the heichips26_digital_project module.

`timescale 1ns / 1ps

module memory_communicator_tb;
  // Parameters
  parameter  real CLK_FREQ      = 50.0e6;
  localparam real CLK_PERIOD_NS = 1e9 / CLK_FREQ;

  // Signals
  logic                 clk    = 1'b0;
  logic                 rst_n  = 1'b1; // active-low reset
  logic [15:0] instruction;
  logic start_decoding;
  // Data Signals
  wire [2:0] addr1;
  wire [2:0] addr2;
  wire [7:0] imm;
  // Control Signals
  wire do_swap;
  wire select_jump;
  // Timing / Flow Signals
  wire decoder_done;

  // DUT
  cpu_decoder cpu_decoder (
    .clk      (clk),
    .rst_n    (rst_n),

    .instruction(instruction),
    .start_decoding(start_decoding),
    .addr1(addr1),
    .addr2(addr2),
    .imm(imm),
    .do_swap(do_swap),
    .select_jump(select_jump),
    .decoder_done(decoder_done)
  );

  // Clock generation
  /* verilator lint_off STMTDLY */
  always #(CLK_PERIOD_NS / 2) clk = ~clk;
  /* verilator lint_on STMTDLY */

  // Self-checking stimulus
  initial begin
    $dumpfile("heichips26_digital_project_tb.fst");
    $dumpvars;

    $display("STARTING TESTBENCH!");

    // Reset pulse (2 clock cycles)
    rst_n = 1'b0;
    #(2 * CLK_PERIOD_NS);
    rst_n = 1'b1;
    #(CLK_PERIOD_NS);
  
    if (decoder_done !== 0) $display("FAIL: decoder_done not zero after add (got %0d)", decoder_done);
    
    $display();
    $display("Decode ADDI");
    @(negedge clk);
    // Format Immediate (8)   |    reg 2 (read-write)    |    reg 1(read)   |    opcode
    instruction = 16'b10010110_110_001_00;
    start_decoding <= 1;
    $display("SET done_alu_i to high");
    @(negedge clk);
    start_decoding <= 0;
    wait(decoder_done);
    if (imm != 8'b10010110) $display("FAIL: imm not 10010110 (got %0b)", imm);
    if (addr1 != 3'b001) $display("FAIL: addr1 not 110 (got %0b)", addr1);
    if (addr2 != 3'b110) $display("FAIL: addr2 not 001 (got %0b)", addr2);
    if (do_swap != 1'b0) $display("FAIL: do_swap not 0 (got %0b)", do_swap);
    if (select_jump != 1'b0) $display("FAIL: select_jump not 0 (got %0b)", select_jump);
    $display("End ADDI Decode");


    $display();
    $display("Decode Jump");
    @(negedge clk);
    // Format Immediate (8)   |    reg 2 (read-write)    |    reg 1(read)   |    opcode
    instruction = 16'b10010110_010_111_01;
    start_decoding <= 1;
    $display("SET done_alu_i to high");
    @(negedge clk);
    start_decoding <= 0;
    wait(decoder_done);
    if (imm != 8'b10010110) $display("FAIL: imm not 10010110 (got %0b)", imm);
    if (addr1 != 3'b111) $display("FAIL: addr1 not 111 (got %0b)", addr1);
    // Reg 2 not important:::: if (addr2 != 3'b010) $display("FAIL: addr2 not 010 (got %0b)", addr2);
    if (do_swap != 1'b0) $display("FAIL: do_swap not 0 (got %0b)", do_swap);
    if (select_jump != 1'b1) $display("FAIL: select_jump not 1 (got %0b)", select_jump);
    $display("End Jump Decode");

    $display();
    $display("Decode SWAP");
    @(negedge clk);
    // Format Immediate (8)   |    reg 2 (read-write)    |    reg 1(read)   |    opcode
    instruction = 16'b10010110_101_000_10;
    start_decoding <= 1;
    $display("SET done_alu_i to high");
    @(negedge clk);
    start_decoding <= 0;
    wait(decoder_done);
    // IMMEDIATE DOES NOT MATTER if (imm != 8'b10010110) $display("FAIL: imm not 10010110 (got %0b)", imm);
    if (addr1 != 3'b000) $display("FAIL: addr1 not 000 (got %0b)", addr1);
    if (addr2 != 3'b101) $display("FAIL: addr2 not 101 (got %0b)", addr2);
    if (do_swap != 1'b1) $display("FAIL: do_swap not 1 (got %0b)", do_swap);
    if (select_jump != 1'b0) $display("FAIL: select_jump not 0 (got %0b)", select_jump);
    $display("End SWAP Decode");




    $display("simulation complete.");
    $finish;
  end
endmodule // heichips26_digital_project_tb
