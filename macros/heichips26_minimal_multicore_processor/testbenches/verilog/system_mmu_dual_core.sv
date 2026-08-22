// SPDX-FileCopyrightText: 2026 XXX
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Description: SystemVerilog testbench for the heichips26_digital_project module.

`timescale 1ns / 1ps

module memory_communicator_tb;
  // Parameters
  parameter  real CLK_FREQ      = 50.0e6;
  localparam real CLK_PERIOD_NS = 1e9 / CLK_FREQ;

  // Signals
  logic clk    = 1'b0;
  logic rst_n  = 1'b1; 
  logic [7:0] fpga_in1  = 8'h00;
  wire [7:0] uo_out;
  logic [7:0] fpga_in2 = 8'h00;
  wire [7:0] uio_out;
  wire uio_oe;

  // DUT
  heichips26_minimal_multicore_processor heichips26_minimal_multicore_processor (
    .clk      (clk),
    .rst_n    (rst_n),

    .ui_in    (fpga_in1),
    .uo_out   (uo_out),
    .uio_in   (fpga_in2),
    .uio_out  (uio_out),
    .uio_oe   (uio_oe),
    .ena      (1'b1)
  );


  always #(CLK_PERIOD_NS / 2) clk = ~clk;
    
  reg [7:0] memory [0:255]; // 256 bytes of memory
  integer i;
  logic is_swap = 1'b0;
  logic[7:0] address = 8'h00;
  // Self-checking stimulus
  initial begin
    $dumpfile("heichips26_digital_project_tb.fst");
    // The file contains one binary byte (eight 0/1 characters) per line.
    $readmemb("./testbenches/test_pgrms/simple_dualcore.nand.mem", memory);
    $display("Memory initialized from simple_dualcore.nand.mem");
    $display("Memory contents after initialization:");
    for (i = 0; i < 256; i++) begin
      $display("Memory[%0d] = %0h (%0d)", i, memory[i], memory[i]);
    end
    $dumpvars;

    $display("STARTING TESTBENCH!, Simulating...");

    // Reset pulse (2 clock cycles)
    rst_n = 1'b0;
    #(1 * CLK_PERIOD_NS);
    rst_n = 1'b1;
    #(CLK_PERIOD_NS);
    fpga_in1 = 8'b00000011;
    fpga_in2 = 8'b00000000;
    $display("\n\n\n");
    repeat(600) begin
      // Wait for the DUT to request data
      wait(uo_out[0] == 1'b1);
      is_swap = uo_out[1];
      // $display("Testbench: Memory request received. Swap: %0b", is_swap);
      // Simulate memory latency by waiting for a few clock cycles to make sure now the address is valid
      repeat(4) @(posedge clk);
      address = uo_out;
      // $display("Testbench: Memory address received. Address: 0x%2h; Line: %3d", address, address/2 + 1);

      // Provide the requested data to the DUT
      if (is_swap) begin
        repeat(5) @(posedge clk) // Simulate Reading delay
        // Read the memory
        fpga_in2 <= memory[address];
        fpga_in1 <= 8'b00000000; /// Indicate that the read is done, we are ready for the write

        repeat(2) @(posedge clk); /// THIS 2 IS IMPORTANT (any higher number is also okay) - WE NEED TO WAIT FOR THE DUT TO ACTUALLY CHANGE THE OUTPUT

        memory[address] <= uo_out; /// Write the data back to memory);
        repeat(5) @(posedge clk); // Simulate Writing delay
        
        fpga_in1 <= 8'b00000011; /// End the transaction, reset the signal
      end
      else begin
        repeat(5) @(posedge clk) // Simulate Reading delay
        /// Read the memory
        fpga_in2 <= memory[address + 1];
        fpga_in1 <= memory[address];

        repeat(1) @(posedge clk); /// Wait
        fpga_in1 <= 8'b00000011; // End the transaction, reset the signal
      end

      // $display("\n\n");
    end


    $display("Simulation complete.");

    for (i = 0; i < 256; i++) begin
     $display("Memory[%0d] = 0x%2h (%3d)", i, memory[i], memory[i]);
    end


    $display("Output Dumped.");
    $finish;
  end
endmodule 
