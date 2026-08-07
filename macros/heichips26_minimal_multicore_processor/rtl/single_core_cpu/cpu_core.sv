
module cpu_core #(parameter START_INSTRUCTION = 16'b00000000_000_000_01) (
  input wire clk,
  input wire rst_n,

  input wire ram_data_ready_i,
  input wire [15:0] data_word_in_i,

  output wire [7:0] ram_addr_o,
  output wire [7:0] data_word_out_o,
  output wire ram_out_valid_o,
  output wire ram_out_do_swap_o
);
wire [15:0] writeback_inst_and_data;
wire start_decoding_flow;
wire do_swap_ctrl;
wire [7:0] imm;

wire [2:0] addr1;
wire [2:0] addr2;
wire done_decoding_flow;
wire [7:0] data_1;
wire [7:0] data_2;
wire [7:0] wb_data;
wire done_mem_flow;

wire done_reading_flow;
wire [7:0] alu_output;
wire alu_done_flow;

wire select_jump_ctrl;
wire done_writing_flow;
wire [7:0] current_pc;
wire done_pc_flow;

// Default Start instruction is jump to zero
memory_communicator dut_memory_communicator (
  .clk      (clk),
  .rst_n    (rst_n),

  // Connected with Reg
  .data_1_i(data_1),
  .data_2_i(data_2),
  .done_mem_o(done_mem_flow),


  // Connected to Alu
  .alu_data_i(alu_output),
  .done_alu_i(alu_done_flow),

  // Connected to PC
  .program_counter_i(current_pc),
  .done_pc_i(done_pc_flow),


  // Connceted with decoder
  .start_decoding_o(start_decoding_flow),
  .writeback_inst_and_data(writeback_inst_and_data),
  .do_swap_i (do_swap_ctrl),

  ///////// OUTSIDE COMMUNICATION  ///////////////
  .mem_done_i(ram_data_ready_i),
  .ram_data_i(data_word_in_i),

  .ram_addr_o(ram_addr_o),
  .ram_write_data_o(data_word_out_o),
  .en_swap_o(ram_out_do_swap_o),
  .valid(ram_out_valid_o)

);

cpu_decoder #(.START_INSTRUCTION(START_INSTRUCTION)) cpu_decoder (
    .clk      (clk),
    .rst_n    (rst_n),

    .instruction(writeback_inst_and_data),
    .start_decoding(start_decoding_flow),
    .addr1(addr1),
    .addr2(addr2),
    .imm(imm),
    .do_swap(do_swap_ctrl),
    .select_jump(select_jump_ctrl),
    .decoder_done(done_decoding_flow)
  );

// DUT
register_file dut_register_file (
  .clk      (clk),
  .rst_n    (rst_n),

  .addr1(addr1),
  .addr2(addr2),
  .wb_data(writeback_inst_and_data[7:0]),
  .done_mem(done_mem_flow),
  .done_decoding(done_decoding_flow),
  
  .done_reading(done_reading_flow),
  .done_writing(done_writing_flow),

  .data_1(data_1),
  .data_2(data_2)
);


add8 addi_adder(
  .clk(clk),
  .rst_n(rst_n),
  .start(done_reading_flow),
  .op1(data_1),
  .op2(imm),
  .res(alu_output),
  .done(alu_done_flow)   
);


nextadresslogic dut_nextadresslogic(
	.clk(clk),
	.rst_n(rst_n),
	.imm(imm),
  .data_1(data_1),
	.select_jump(select_jump_ctrl),
	.done_writing(done_writing_flow),
	.current_pc(current_pc),
	.done_pc(done_pc_flow)
);

endmodule