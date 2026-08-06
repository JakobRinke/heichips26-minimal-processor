typedef enum {
    IDLE,
    LOAD_INST,
    LOAD_ADDR,
    LOAD_WAIT,
    SWAP_INST,
    SWAP_ADDR,
    SWAP_DATA,
    SWAP_END
} State;

module mem_mgr #(
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
        end else begin
            case (state)
                IDLE: begin
                    mem_done[target_cpu] <= 0;
                    // TODO: Make CPU selection parameterized
                    if (valid[0]) begin 
                        target_cpu <= {TARGET_CPU_NUM_LEN{1'd0}};
                        set_swap(0);
                        state <= LOAD_INST;
                    end else if (valid[1]) begin 
                        target_cpu <= {TARGET_CPU_NUM_LEN{1'd1}};
                        set_swap(1);
                        state <= LOAD_INST;
                    end
                end
                LOAD_INST: begin
                    // second-LSB: Load operation, LSB: enable
                    fpga_out <= {6'd0, 1'd0, 1'd1};
                    state <= LOAD_ADDR;
                end
                LOAD_ADDR: begin
                    fpga_out <= ram_addr[target_cpu];
                    state <= LOAD_WAIT;
                end
                LOAD_WAIT: begin
                    fpga_out <= 8'b0;
                    // TODO: determine how long to wait for RAM results
                    data_out_cpu <= {fpga_in1, fpga_in2};
                    if (swap) begin
                        state <= SWAP_INST;
                    end else begin
                        state <= IDLE;
                        mem_done[target_cpu] <= 1;
                    end
                end
                SWAP_INST: begin
                    // second-LSB: Write operation, LSB: enable
                    fpga_out <= {6'd0, 1'd1, 1'd1};
                    state <= SWAP_ADDR;
                end
                SWAP_ADDR: begin
                    fpga_out <= ram_addr[target_cpu];
                    state <= SWAP_DATA;
                end
                SWAP_DATA: begin
                    fpga_out <= reg_data[target_cpu];
                    state <= SWAP_DATA;
                end
                SWAP_END: begin
                    fpga_out <= 8'b0;
                    state <= IDLE;
                    mem_done[target_cpu] <= 1;
                end
            endcase
        end
    end

endmodule
