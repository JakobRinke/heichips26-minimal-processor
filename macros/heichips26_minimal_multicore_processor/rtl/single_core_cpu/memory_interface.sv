
module memory_interface #(
    parameter int LOAD_LATENCY = 1   // Read
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n

    input wire [7:0] ui_in, // Memory Controller input
    output logic [7:0] uo_out, 

    input wire [7:0] uio_in, //SRAM Input
    output logic [7:0] uio_out,
    output logic [7:0] uio_oe,

);

    logic [2:0] byte_idx;
    logic       we;          
    logic [3:0] wait_cnt;    

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_idx <= 3'd0;
            we       <= 1'b0;
            wait_cnt <= 4'd0;
            uo_out   <= 8'h00;
            uio_out  <= 8'h00;
            uio_oe   <= 8'h00;
        end else if (byte_idx == 0) begin
            // wair for start
            uio_oe <= 8'h00;
            if (ui_in[0]) begin              // en = 1  new command
                we       <= ui_in[1];
                byte_idx <= 3'd1;           // = 1
            end

        end else if (byte_idx == 1) begin 
            // ADDR-Byte to SRAM
            uio_out <= ui_in;
            uio_oe  <= 8'hFF;
            if (we) begin
                byte_idx <= 3'd2;            // write: data byte next
            end else begin
                byte_idx <= 3'd3;            // load: wait
                wait_cnt <= 4'd0;
            end

        end else if (byte_idx == 2) begin
            // DATA-Byte (write)
            uio_out  <= ui_in;
            uio_oe   <= 8'hFF;
            byte_idx <= 3'd0;

        end else begin
            uio_oe <= 8'h00;                 // release bus, sram drives uio_in
            if (wait_cnt == LOAD_LATENCY[3:0] - 1) begin
                uo_out   <= uio_in;          // data to controller
                byte_idx <= 3'd0;
            end else begin
                wait_cnt <= wait_cnt + 1'b1;
            end
        end
    end

endmodule
