
module cpu_decoder  #(parameter START_INSTRUCTION = 16'b00000000_000_000_01) (
    input wire clk,
    input wire rst_n,
    input wire [15:0] instruction,
    input wire start_decoding,

    // Data Signals
    output reg [2:0] addr1,
    output reg [2:0] addr2,
    output reg [7:0] imm,

    // Control Signals
    output reg do_swap,
    output reg select_jump,


    // Timing / Flow Signals
    output reg decoder_done
);


always @(posedge clk) begin
    if (decoder_done == 1) decoder_done <= 0;
    if (rst_n == 0) begin
        // Kickstart The CPUS
        addr1[2:0] <= START_INSTRUCTION[4:2];
        addr2[2:0] <= START_INSTRUCTION[7:5];
        imm[7:0] <= START_INSTRUCTION[15:8];
        
        // Set Control Signals
        select_jump <= START_INSTRUCTION[0];
        do_swap <= START_INSTRUCTION[1]; 

        // Send the decode is done signal
        decoder_done <= 1;
        $display("Sending initial instruction Request :D!!!");
    end else if (start_decoding == 1) begin
        // Data Signals are always mapped the same :)
        addr1[2:0] <= instruction[4:2];
        addr2[2:0] <= instruction[7:5];
        imm[7:0] <= instruction[15:8];
        
        // Set Control Signals
        select_jump <= instruction[0];
        do_swap <= instruction[1]; 

        // Send the decode is done signal
        decoder_done <= 1;
        $display("Processed Decode Request :D!!!");
      end
end 




endmodule