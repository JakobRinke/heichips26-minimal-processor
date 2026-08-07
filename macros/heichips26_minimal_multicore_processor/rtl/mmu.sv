`timescale 1ns/100ps
typedef enum {
    IDLE,
    RAM_INST,
    RAM_ADDR,
    WAIT_READ,
    WAIT_WRITE
} State;

module mmu #(
    parameter CPU_COUNT = 2, // problem for mem_mgr_top to split into more/less
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(


//CPU
    input logic clk_i,
    input logic rst_ni,

    input logic [ADDR_WIDTH-1:0] reg_data [CPU_COUNT-1:0],
    input logic [ADDR_WIDTH-1:0] ram_addr [CPU_COUNT-1:0],
    input logic valid[CPU_COUNT-1:0],
    input logic do_swap[CPU_COUNT-1:0],
    output reg mem_done[CPU_COUNT-1:0],

    output reg [DATA_WIDTH*2-1:0] data_out_cpu, //shared -> only read when mem_done_x enabled

    //FPGA
    input [DATA_WIDTH - 1:0] fpga_in1,
    input [DATA_WIDTH - 1:0] fpga_in2,
    output reg [DATA_WIDTH - 1:0] fpga_out
);

    State state;

    localparam TARGET_CPU_NUM_LEN = $clog2(CPU_COUNT);
    reg [TARGET_CPU_NUM_LEN - 1 : 0]target_cpu;

    reg swap;

    task set_swap (input [TARGET_CPU_NUM_LEN - 1 : 0]cpu);
        if (do_swap[cpu]) swap <= 1;
        else swap <= 0;
    endtask

    // Counter implementation
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            state <= IDLE;
            swap <= 0;
            target_cpu <= {TARGET_CPU_NUM_LEN{1'd0}};
        end else begin
            case (state)
                IDLE: begin
                    mem_done[target_cpu] <= 1'b0;
                    // TODO: Make CPU selection parameterized
                    if (valid[0]) begin 
                        target_cpu <= {TARGET_CPU_NUM_LEN{1'd0}};
                        set_swap(0);
                        state <= RAM_INST;
                    end else if (valid[1]) begin 
                        target_cpu <= {TARGET_CPU_NUM_LEN{1'd1}};
                        set_swap(1);
                        state <= RAM_INST;
                    end
                end
                RAM_INST: begin
                    // second-LSB: operation, LSB: enable
                    fpga_out <= {6'd0, do_swap[target_cpu], 1'd1};
                    state <= RAM_ADDR;
                end
                RAM_ADDR: begin
                    fpga_out <= ram_addr[target_cpu];
                    state <= WAIT_READ;
                end
                WAIT_READ: begin
                    // TODO: determine how long to wait for RAM results
                    if(fpga_in1[1:0] != 2'b11) begin
                        if (do_swap[target_cpu]) begin
                            data_out_cpu <= {fpga_in1, fpga_in2};
                            fpga_out <= reg_data[target_cpu];
                            state <= WAIT_WRITE;
                        end else begin
                            data_out_cpu <= {fpga_in2, fpga_in1};
                            fpga_out <= 8'h00;
                            state <= IDLE;
                            mem_done[target_cpu] <= 1'b1;
                        end
                    end
                end
                WAIT_WRITE: begin
                    if (fpga_in1[1:0] == 2'b11) begin
                        mem_done[target_cpu] <= 1'b1;
                        state <= IDLE;
                    end 
                end
            endcase
        end
    end

endmodule
