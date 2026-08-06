
module memory_communicator (
  input wire clk,
  input wire rst_n,


  /////////////////    CPU COMM   //////////////////////////
  // Control Input:
  input wire do_swap_i,

  // Flow Input
  input wire done_alu_i,
  input wire done_pc_i,

  // data input
  input wire [7:0] data_1_i,
  input wire [7:0] data_2_i,
  input wire [7:0] alu_data_i,
  input wire [7:0] program_counter_i,

  // Flow Output
  output reg done_mem_o,
  output reg start_decoding_o,

  // data output
  output reg [15:0] next_instr_o,
  output reg [7:0] write_back_data_o,



  ///////////////   OUTSIDE COMM /////////////////////////
  input wire mem_done_i,
  input wire [15:0] ram_data_i,

  output reg [7:0] ram_addr_o,
  output reg [7:0] ram_write_data_o,
  output reg en_swap_o,
  output reg valid

);

localparam IDLE = 2'b00;
localparam WAITING_FOR_INSTRUCTION = 2'b01;
localparam WAITING_FOR_SWAP = 2'b10;

reg [1:0] current_state;

always @(clk) begin

  // Always reset pulse registers
  if (done_mem_o != 0) done_mem_o <= 0;
  if (start_decoding_o != 0) start_decoding_o <= 0;

  if (rst_n==0) begin
    // reset all outputs
    next_instr_o <= 0;
    write_back_data_o <= 0;
    ram_addr_o <= 0;
    ram_write_data_o <= 0;
    en_swap_o <= 0;
    valid <= 0;
    done_mem_o <= 0;
    start_decoding_o <= 0;
    current_state <= IDLE;
  end else begin
    case (current_state) 
      IDLE: begin
        if (done_alu_i==1) begin
          
          if (do_swap_i==1) begin
            $display("Got Swap Request By ALU!");
            // Swap requested!   -> Send a request to the Ram
            ram_addr_o <= data_1_i;
            ram_write_data_o <= data_2_i;
            en_swap_o <= 1;
            valid <= 1;
            current_state <= WAITING_FOR_SWAP;
          end else begin
            $display("Got Passtrough Request By ALU!");
            /// Just send the alu data to the output
            write_back_data_o <= alu_data_i;
            done_mem_o <= 1; // Start the writeback
          end
        end else if (done_pc_i) begin
          $display("Got Request by PC!");
          /// Instruction requested, send request to the Ram 
          ram_addr_o <= program_counter_i;
          ram_write_data_o <= 0;
          en_swap_o <= 0;
          valid <= 1;
          current_state <= WAITING_FOR_INSTRUCTION;
        end
      end


      WAITING_FOR_INSTRUCTION: begin
        if (mem_done_i) begin
          next_instr_o = ram_data_i;
          write_back_data_o = 0;
          /// IMPORTANT!!! INVALIDATE; End the request
          valid = 0;
          current_state = IDLE;
          start_decoding_o = 1;
        end
      end

      WAITING_FOR_SWAP: begin
        if (mem_done_i) begin
             // Send the ram output back as data
            write_back_data_o = ram_data_i[7:0];
            /// IMPORTANT!!! INVALIDATE; End the request
            valid = 0;
            current_state = IDLE;
            done_mem_o = 1; // Start the writeback
        end
      end

    endcase
  end


end;

endmodule