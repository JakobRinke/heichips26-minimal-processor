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

  logic done_decoding = 0;
  logic done_mem = 0;
  logic [2:0] addr1 = 0;
  logic [2:0] addr2 = 0;
  logic [7:0] wb_data = 0;
  
 
  wire done_reading;
  wire done_writing;
  wire [7:0] data_1;
  wire [7:0] data_2;


  // DUT
  register_file dut_register_file (
    .clk      (clk),
    .rst_n    (rst_n),

    .addr1(addr1),
    .addr2(addr2),
    .wb_data(wb_data),
    .done_mem(done_mem),
    .done_decoding(done_decoding),
    
    .done_reading(done_reading),
    .done_writing(done_writing),
    .data_1(data_1),
    .data_2(data_2)

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
  
    if (done_reading !== 0) $display("FAIL: done_reading not zero after add (got %0d)", done_reading);
    if (done_writing !== 0) $display("FAIL: done_writing not zero after add (got %0d)", done_writing);
    
    $display();
    $display("Test Writing into registers");
    @(negedge clk);
    addr1 = 101;
    addr2 = 010;
    wb_data = 67;
    done_mem <= 1;
    $display("SET done_mem to high");
    @(negedge clk);
    done_mem <= 0;
    wait(done_writing);
    if (done_reading !== 0) $display("FAIL: done_reading not zero after add (got %0d)", done_reading);
    if (data_1 !== 0) $display("FAIL: data_1 not zero after add (got %0d)", data_1);
    if (data_2 !== 0) $display("FAIL: data_2 not zero after add (got %0d)", data_2);
    $display("End Register Writing");

    $display();
    $display("Test Writing into zero");
    @(negedge clk);
    addr1 = 111;
    addr2 = 000;
    wb_data = 169;
    done_mem <= 1;
    $display("SET done_mem to high");
    @(negedge clk);
    done_mem <= 0;
    wait(done_writing);
    if (done_reading !== 0) $display("FAIL: done_reading not zero after add (got %0d)", done_reading);
    if (data_1 !== 0) $display("FAIL: data_1 not zero after add (got %0d)", data_1);
    if (data_2 !== 0) $display("FAIL: data_2 not zero after add (got %0d)", data_2);
    $display("End zero Writing");

    $display();
    $display("Test Reading After Writing Reg and zero");
    @(negedge clk);
    addr1 = 010;
    addr2 = 000;
    wb_data = 69;
    done_decoding <= 1;
    $display("SET done_decoding to high");
    @(negedge clk);
    done_decoding <= 0;
    wait(done_reading);
    if (done_writing !== 0) $display("FAIL: done_writing not zero after add (got %0d)", done_writing);
    if (data_1 !== 67) $display("FAIL: data_1 not 67 after add (got %0d)", data_1);
    if (data_2 !== 0) $display("FAIL: data_2 not zero after add (got %0d)", data_2);
    $display("End zero Writing");





    $display("simulation complete.");
    $finish;
  end
endmodule // heichips26_digital_project_tb
