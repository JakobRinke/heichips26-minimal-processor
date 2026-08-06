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
  logic do_swap_i = 0;

  // Flow Input
  logic done_alu_i = 0;
  logic done_pc_i = 0;

  // data input
  logic [7:0] data_1_i = 0;
  logic [7:0] data_2_i = 0;
  logic [7:0] alu_data_i = 0;
  logic [7:0] program_counter_i = 0;

  wire done_mem_o;
  wire start_decoding_o;

  wire [15:0] next_instr_o;
  wire [7:0] write_back_data_o;

  logic mem_done_i = 0;
  logic [15:0] ram_data_i = 0;

  wire [7:0] ram_addr_o;
  wire [7:0] ram_write_data_o;
  wire en_swap_o;
  wire valid;

  // DUT
  memory_communicator dut_memory_communicator (
    .clk      (clk),
    .rst_n    (rst_n),
    .do_swap_i (do_swap_i),

    // Flow Input
    .done_alu_i(done_alu_i),
    .done_pc_i(done_pc_i),

    // data input
    .data_1_i(data_1_i),
    .data_2_i(data_2_i),
    .alu_data_i(alu_data_i),
    .program_counter_i(program_counter_i),

    .done_mem_o(done_mem_o),
    .start_decoding_o(start_decoding_o),
    .next_instr_o(next_instr_o),
    .write_back_data_o(write_back_data_o),

    .mem_done_i(mem_done_i),
    .ram_data_i(ram_data_i),

    .ram_addr_o(ram_addr_o),
    .ram_write_data_o(ram_write_data_o),
    .en_swap_o(en_swap_o),
    .valid(valid)

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
    if (valid !== 0)
      $display("FAIL: valid not zero after reset (got %0d)", valid);
    if (done_mem_o !== 0)
      $display("FAIL: done_mem_o not zero after reset (got %0d)", done_mem_o);
    if (start_decoding_o !== 0)
      $display("FAIL: start_decoding_o not zero after reset (got %0d)", start_decoding_o);

    $display("Passed trough reset");

    // Hold disabled for a few cycles; value must not change
    #(5 * CLK_PERIOD_NS);
    if (valid !== 0)
      $display("FAIL: valid not zero after reset (got %0d)", valid);
    if (done_mem_o !== 0)
      $display("FAIL: done_mem_o not zero after reset (got %0d)", done_mem_o);
    if (start_decoding_o !== 0)
      $display("FAIL: done_pc_i not zero after reset (got %0d)", start_decoding_o);

    $display("Passed wait after reset");


    $display();
    $display("Testing ALU Passtrough");
    /////// NOW Test an ALU Passtrough
    data_1_i = 1;
    data_2_i = 2;
    alu_data_i = 3;
    do_swap_i = 0;
    program_counter_i = 5;
    #(CLK_PERIOD_NS)
    /// SEND PULSE!
    @(negedge clk);
    done_alu_i <= 1;
    $display("SET done_alu_i to high");
    @(negedge clk);
    done_alu_i <= 0;
    wait (done_mem_o);
    // OUTPUT IS READY, check
    if (valid !== 0) $display("FAIL: valid not zero after add (got %0d)", valid);
    if (start_decoding_o !== 0) $display("FAIL: start_decoding_o not zero after add (got %0d)", start_decoding_o);
    if (write_back_data_o !== 3) $display("FAIL: write_back_data_o not 3 after add (got %0d)", write_back_data_o);
    $display("End Alu Passtrough");
    








    $display();
    $display("Testing Request Data");
    ///// Now Test a Swap!
    data_1_i = 12; // Take the data at point 1
    data_2_i = 42; // Swap it with the value 2
    alu_data_i = 3;
    do_swap_i = 1;
    program_counter_i = 5;
    #(CLK_PERIOD_NS)
    /// SEND PULSE!
    @(negedge clk);
    done_alu_i <= 1;
    $display("SET done_alu_i to high");
    @(negedge clk);
    done_alu_i <= 0;
    // Simulate Memory being busy
    #(10 * CLK_PERIOD_NS);
    // Check if request is send to memory
    if (ram_addr_o != 12) $display("FAIL: ram_addr_o not 12 (got %0d)", ram_addr_o);
    if (ram_write_data_o != 42) $display("FAIL: ram_write_data_o not 42 (got %0d)", ram_write_data_o);
    if (valid != 1) $display("FAIL: valid not 1 (got %0d)", valid);
    if (en_swap_o != 1) $display("FAIL: en_swap_o not 1 (got %0d)", en_swap_o);

    @(negedge clk);
    ram_data_i <= 67;
    mem_done_i <= 1;
    $display("SET mem_done_i to high");
    @(negedge clk);
    mem_done_i <= 0;
    if (valid != 0) $display("FAIL: valid not 0 (got %0d)", valid);
    wait(done_mem_o);
    if (valid != 0) $display("FAIL: valid not 0 (got %0d)", valid);
    if (start_decoding_o != 0) $display("FAIL: valid not 0 (got %0d)", start_decoding_o);
    if (write_back_data_o != 67) $display("FAIL: valid not 67 (got %0d)", write_back_data_o);
    $display("End Request Data");







    $display();
    $display("Testing Request Instruction");
    ///// Now Test a Swap!
    data_1_i = 53; // Take the data at point 1
    data_2_i = 123; // Swap it with the value 2
    alu_data_i = 53;
    do_swap_i = 1;
    program_counter_i = 222;
    #(CLK_PERIOD_NS)
    /// SEND PULSE!
    @(negedge clk);
    done_pc_i <= 1;
    $display("SET done_alu_i to high");
    @(negedge clk);
    done_pc_i <= 0;
    // Simulate Memory being busy
    #(10 * CLK_PERIOD_NS);
    // Check if request is send to memory
    if (ram_addr_o != 222) $display("FAIL: ram_addr_o not 222 (got %0d)", ram_addr_o);
    if (ram_write_data_o != 0) $display("FAIL: ram_write_data_o not 0 (got %0d)", ram_write_data_o);
    if (valid != 1) $display("FAIL: valid not 1 (got %0d)", valid);
    if (en_swap_o != 0) $display("FAIL: en_swap_o not 0 (got %0d)", en_swap_o);

    @(negedge clk);
    ram_data_i <= 5301;
    mem_done_i <= 1;
    $display("SET start_decoding_o to high");
    @(negedge clk);
    mem_done_i <= 0;
    if (valid != 0) $display("FAIL: valid not 0 (got %0d)", valid);
    wait(start_decoding_o);
    if (valid != 0) $display("FAIL: valid not 0 (got %0d)", valid);
    if (done_mem_o != 0) $display("FAIL: valid not 0 (got %0d)", done_mem_o);
    if (write_back_data_o != 0) $display("FAIL: valid not 0 (got %0d)", write_back_data_o);
    if (next_instr_o != 5301) $display("FAIL: valid not 5301 (got %0d)", next_instr_o);
    $display("End Request Instruction");





    $display("simulation complete.");
    $finish;
  end
endmodule // heichips26_digital_project_tb
