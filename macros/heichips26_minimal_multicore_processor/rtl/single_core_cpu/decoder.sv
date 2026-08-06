
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
    output reg do_swap;
    output reg select_jump;


    // Timing / Flow Signals
    output reg decoder_done,

);


always @(posedge clk) begin
    decoder_done <= 0;
    if (rst_n = 0) begin
        addr1 <= 3'b0;
        addr2 <= 3'b0;
        imm <= 8'b0;
        do_swap <= 1'b0;
        select_jump <= 1'b0;
    end else if (start_decoding) begin
        // Data Signals are always mapped the same :)
        addr1[2:0] <= instruction[4:2];
        addr2[2:0] <= instruction[7:5];
        imm[7:0] <= instruction[15:8];
        
        // Set Control Signals
        do_jump <= instruction[0];
        do_swap <= instruction[1]; 

        // Send the decode is done signal
        decoder_done <= 1;
      end
end 




endmodule