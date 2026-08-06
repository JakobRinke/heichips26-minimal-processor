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
  logic start = 0;
  logic [7:0] op1;
  logic [7:0] op2;
  wire [7:0] res;
  wire done;
  // DUT
  add8 dut_add8 (
    .clk      (clk),
    .rst_n    (rst_n),

    .start(start),
    .op1(op1),
    .op2(op2),
    .res(res),
    .done(done)
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
  
    if (done !== 0) $display("FAIL: done not zero after add (got %0d)", done);
    
    $display();
    $display("Test Add");
    @(negedge clk);
    op1 <= 3;
    op2 <= 2;
    start <= 1;
    $display("SET start to high");
    @(negedge clk);
    start <= 0;
    wait(done);
    if (res != 5) $display("FAIL: res not 5 (got %d)", res);
    #(15 * CLK_PERIOD_NS)
    if (res != 5) $display("FAIL: res not 5 (got %d)", res);
    if (done !== 0) $display("FAIL: done not zero after add (got %0d)", done);
    
    $display("End test Add Decode");






    $display("simulation complete.");
    $finish;
  end
endmodule // heichips26_digital_project_tb
