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

  logic ram_data_ready_i;
  logic [15:0] data_word_in_i;

  wire [7:0] ram_addr_o;
  wire [7:0] data_word_out_o;
  wire ram_out_valid_o;
  wire ram_out_do_swap_o;

  // DUT
  cpu_core dut_cpu_core (
    .clk      (clk),
    .rst_n    (rst_n),

    .ram_data_ready_i(ram_data_ready_i),
    .data_word_in_i(data_word_in_i),

    .ram_addr_o(ram_addr_o),
    .data_word_out_o(data_word_out_o),
    .ram_out_valid_o(ram_out_valid_o),
    .ram_out_do_swap_o(ram_out_do_swap_o)

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
    #(1 * CLK_PERIOD_NS);
    rst_n = 1'b1;
    #(CLK_PERIOD_NS);

    /// Can't check since the CPU automaticly restarts with start instruction
    // if (ram_out_valid_o !== 0)
    //   $display("FAIL: ram_out_valid_o not zero after reset (got %0d)", ram_out_valid_o);
    // if (ram_out_do_swap_o !== 0)
    //   $display("FAIL: ram_out_do_swap_o not zero after reset (got %0d)", ram_out_do_swap_o);

    $display("Waiting for Start Instruction to be done!!!");
    wait(ram_out_valid_o);
    $display("Next Instruction got requested!");
    #(5 * CLK_PERIOD_NS);
    if (ram_out_valid_o !== 1) $display("FAIL: ram_out_valid_o not 1 (got %0d)", ram_out_valid_o);
    if (ram_out_do_swap_o !== 0) $display("FAIL: ram_out_do_swap_o not 0 (got %0d)", ram_out_do_swap_o);
    if (ram_addr_o !== 0) $display("FAIL: ram_out_do_swap_o not 0 (got %0d)", ram_addr_o);
    if (data_word_out_o !== 0) $display("FAIL: data_word_out_o not 0 (got %0d)", data_word_out_o);


    $display("Testing Jump And really jump because 0 Passtrough");
    @(negedge clk);
    // Jump to 
    /////////////////// IMMEDIETATE_reg2_reg_1_opcode
    data_word_in_i <= 16'b01000011_100_000_01;
    ram_data_ready_i <= 1;
    $display("SET ram_data_ready_i to high");
    @(negedge clk);
    ram_data_ready_i <= 0;
    // #10
    // $finish;
    wait (ram_out_valid_o);
    #(5 * CLK_PERIOD_NS) 
    // OUTPUT IS READY, check
    if (ram_out_valid_o !== 1) $display("FAIL: ram_out_valid_o not 1 (got %0d)", ram_out_valid_o);
    if (ram_out_do_swap_o !== 0) $display("FAIL: ram_out_do_swap_o not 0 (got %0d)", ram_out_do_swap_o);
    if (ram_addr_o !== 67) $display("FAIL: ram_addr_o not 67 (got %0d)", ram_addr_o);
    if (data_word_out_o !== 0) $display("FAIL: data_word_out_o not 0 (got %0d)", data_word_out_o);


        $finish;


    $display("Testing ADDI Passtrough");
    @(negedge clk);
    // Add 5 + register 0 and save to register 4 
    /////////////////// IMMEDIETATE_reg2_reg_1_opcode
    data_word_in_i <= 16'b00000101_100_000_00;
    ram_data_ready_i <= 1;
    $display("SET ram_data_ready_i to high");
    @(negedge clk);
    ram_data_ready_i <= 0;
    // #10
    // $finish;
    wait (ram_out_valid_o);
    #(5 * CLK_PERIOD_NS) 
    // OUTPUT IS READY, check
    if (ram_out_valid_o !== 1) $display("FAIL: ram_out_valid_o not 1 (got %0d)", ram_out_valid_o);
    if (ram_out_do_swap_o !== 0) $display("FAIL: ram_out_do_swap_o not 0 (got %0d)", ram_out_do_swap_o);
    if (ram_addr_o !== 2) $display("FAIL: ram_out_do_swap_o not 2 (got %0d)", ram_addr_o);
    if (data_word_out_o !== 0) $display("FAIL: data_word_out_o not 0 (got %0d)", data_word_out_o);
    $display("Word was saved in reg4");

    
    $display("FIRST INSTRICTION DONE!!!!!!");
    $display("Starting second instruction :=)");
    @(negedge clk);
    // Add 5 + register 4 and save to register 1 
    /////////////////// IMMEDIETATE_reg2_reg_1_opcode
    data_word_in_i <= 16'b00000101_001_100_00;
    ram_data_ready_i <= 1;
    $display("SET ram_data_ready_i to high");
    @(negedge clk);
    ram_data_ready_i <= 0;
    wait (ram_out_valid_o);
    #(5 * CLK_PERIOD_NS) 
    // OUTPUT IS READY, check
    if (ram_out_valid_o !== 1) $display("FAIL: ram_out_valid_o not 1 (got %0d)", ram_out_valid_o);
    if (ram_out_do_swap_o !== 0) $display("FAIL: ram_out_do_swap_o not 0 (got %0d)", ram_out_do_swap_o);
    // Now we are at the third instr
    if (ram_addr_o !== 2) $display("FAIL: ram_out_do_swap_o not 2 (got %0d)", ram_addr_o);
    if (data_word_out_o !== 0) $display("FAIL: data_word_out_o not 0 (got %0d)", data_word_out_o);
    

    
    $display("End ADDI Passtrough");
    









    $display("simulation complete.");
    $finish;
  end
endmodule // heichips26_digital_project_tb
