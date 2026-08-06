
module cpu_decoder(
    input wire clk,
    input wire rst_n,
    input wire [15:0] instruction,
    input wire start_decoding,

    // Data Signals
    output reg addr1[2:0],
    output reg addr2[2:0],
    output reg imm[7:0],

    // Control Signals
    output reg we_addr2,
    output reg enable_alu,
    output reg enable_eq_z_select,
    output reg enable_memory_mgr,


    // Timing / Flow Signals
    output reg decoder_done,

);


always @(posedge clk) begin
    decoder_done <= 0;
    if (rst_n = 0) begin
        addr1 <= 3'b0;
        addr2 <= 3'b0;
        imm <= 8'b0;
        we_addr2 <= 1'b0;
        enable_alu <= 1'b0;
        enable_eq_z_select <= 1'b0;
        enable_memory_mgr <= 1'b0;
    end else if (start_decoding) begin
        // Data Signals are always mapped the same :)
        addr1[2:0] <= instruction[4:2];
        addr2[2:0] <= instruction[7:5];
        imm[7:0] <= instruction[15:8];
        
        // Control Signals Add Instruction 
        if (instruction[1:0] == 1'b00) begin
            we_addr2 <= 1;
            enable_alu <= 1;
            enable_eq_z_select <= 0;
            enable_memory_mgr <= 0;
        // Control Signals Jump Instruction
        end else if (instruction == 1'b01) begin
            we_addr2 <= 0;
            enable_alu <= 0;
            enable_eq_z_select <= 1;
            enable_memory_mgr <= 0;
        end
        // Control Signals Swap Instruction
        end else if (instruction == 1'101) begin
            we_addr2 <= 0;
            enable_alu <= 0;
            enable_eq_z_select <= 0;
            enable_memory_mgr <= 1;
        end

        
        // Send the decode is done signal
        decoder_done <= 1;
    end 

end


endmodule