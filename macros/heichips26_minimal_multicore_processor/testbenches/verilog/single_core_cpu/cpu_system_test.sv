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


  always #(CLK_PERIOD_NS / 2) clk = ~clk;
    
  reg [7:0] memory [0:255]; // 256 bytes of memory
  logic [15:0] temp_data_word;
  integer i;
  // Self-checking stimulus
  initial begin
    $dumpfile("heichips26_digital_project_tb.fst");
    // The file contains one binary byte (eight 0/1 characters) per line.
    $readmemb("./testbenches/test_pgrms/add_2_const_single.mem", memory);
    $display("Memory initialized from add_2_const_single.mem");
    $display("Memory contents after initialization:");
    for (i = 0; i < 256; i++) begin
      $display("Memory[%0d] = %0h (%0d)", i, memory[i], memory[i]);
    end
    $dumpvars;

    $display("STARTING TESTBENCH!, Simulating for 500 ");

    // Reset pulse (2 clock cycles)
    rst_n = 1'b0;
    #(1 * CLK_PERIOD_NS);
    rst_n = 1'b1;
    #(CLK_PERIOD_NS);
    
    repeat(500) begin
      // Wait for the DUT to request data
      @(posedge ram_out_valid_o);
      // Wait for a few clock cycles to simulate memory access time
      repeat (3) @(posedge clk);
      
      temp_data_word = {memory[ram_addr_o + 1], memory[ram_addr_o]};
      if (ram_out_do_swap_o) begin
        memory[ram_addr_o] = data_word_out_o;
      end
      data_word_in_i = temp_data_word;
      ram_data_ready_i = 1'b1;
      @(posedge clk);
      ram_data_ready_i = 1'b0;
    end


    $display("Simulation complete.");

    for (i = 0; i < 256; i++) begin
      $display("Memory[%0d] = %0h (%0d)", i, memory[i], memory[i]);
    end


    $display("Output Dumped.");
    $finish;
  end
endmodule 
