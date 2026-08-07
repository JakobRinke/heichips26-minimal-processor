`default_nettype none

module memory_interface #(
    parameter int SRAM_READ_LATENCY = 1
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [7:0]  fpga_out,
    output logic [7:0] fpga_in1,
    output logic [7:0] fpga_in2,

    output logic [9:0]  sram_addr,
    output logic [31:0] sram_din,
    output logic [31:0] sram_bm,
    output logic        sram_wen,
    output logic        sram_men,
    output logic        sram_ren,
    input  wire  [31:0] sram_dout
);

    localparam S_IDLE       = 3'd0;
    localparam S_ADDR       = 3'd1;
    localparam S_READ_WAIT  = 3'd2;
    localparam S_READ_READY = 3'd3;
    localparam S_WRITE_WAIT = 3'd4;   
    localparam S_WRITE      = 3'd5;
    localparam S_WRITE_DONE = 3'd6;

    logic [2:0] state;
    logic       is_swap;
    logic [5:0] block;    // ADDR[7:2]
    logic [1:0] offset;   // ADDR[1:0]
    logic [3:0] wait_cnt;

    always_comb begin
        sram_addr = {4'b0000, (state == S_ADDR) ? fpga_out[7:2] : block};
        sram_men  = 1'b0;
        sram_wen  = 1'b0;
        sram_ren  = 1'b0;
        sram_din  = 32'b0;
        sram_bm   = 32'b0;

        if (state == S_ADDR) begin
            sram_men = 1'b1;
            sram_ren = 1'b1;

        end else if (state == S_WRITE) begin
            sram_men = 1'b1;
            sram_wen = 1'b1;
            case (offset)
                2'b00: begin sram_din = {24'b0, fpga_out};       sram_bm = 32'h0000_00FF; end
                2'b01: begin sram_din = {16'b0, fpga_out, 8'b0}; sram_bm = 32'h0000_FF00; end
                2'b10: begin sram_din = {8'b0, fpga_out, 16'b0}; sram_bm = 32'h00FF_0000; end
                2'b11: begin sram_din = {fpga_out, 24'b0};       sram_bm = 32'hFF00_0000; end
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            wait_cnt <= 4'd0;
            fpga_in1 <= 8'h03;   // busy
            fpga_in2 <= 8'h00;

        end else if (state == S_IDLE) begin //command load or swap
            fpga_in1 <= 8'h03;
            if (fpga_out[0]) begin
                is_swap <= fpga_out[1];
                state   <= S_ADDR;
            end

        end else if (state == S_ADDR) begin //adress slicing
            block    <= fpga_out[7:2];
            offset   <= fpga_out[1:0];
            wait_cnt <= 4'd0;
            state    <= S_READ_WAIT;

        end else if (state == S_READ_WAIT) begin
            if (wait_cnt == SRAM_READ_LATENCY[3:0] - 1) begin
                state <= S_READ_READY;
            end else begin
                wait_cnt <= wait_cnt + 1'b1;
            end

        end else if (state == S_READ_READY) begin //read out sram sliced
            case (offset)
                2'b00: begin fpga_in1 <= sram_dout[7:0];   fpga_in2 <= sram_dout[15:8];  end
                2'b01: begin fpga_in1 <= sram_dout[15:8];  fpga_in2 <= sram_dout[23:16]; end
                2'b10: begin fpga_in1 <= sram_dout[23:16]; fpga_in2 <= sram_dout[31:24]; end
                2'b11: begin fpga_in1 <= sram_dout[31:24]; fpga_in2 <= sram_dout[7:0];   end
            endcase
            state <= is_swap ? S_WRITE_WAIT : S_IDLE; //write if is_swap, idle if load

        end else if (state == S_WRITE_WAIT) begin
            fpga_in1 <= 8'h00;   // busy
            state    <= S_WRITE;

        end else if (state == S_WRITE) begin
            fpga_in1 <= 8'h00;   // busy during write
            state    <= S_WRITE_DONE;

        end else begin // S_WRITE_DONE
            fpga_in1 <= 8'h03;   // ready, "11" back - no opcode 
            state    <= S_IDLE;
        end
    end

endmodule
