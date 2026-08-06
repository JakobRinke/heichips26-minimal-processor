

typedef enum {
    RESET,
    CHECK_CPU_0,
    CHECK_CPU_1,
    QUERY_SRAM_0,
    QUERY_SRAM_1
} State

module mem_mgr #(
    parameter CPU_COUNT = 2, // problem for mem_mgr_top to split into more/less
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16,
)(


//CPU
    input logic               clk_i,
    input logic               rst_ni,

    input [CPU_COUNT-1:0] logic [ADDR_WIDTH-1:0] reg_data,
    input [CPU_COUNT-1:0] logic [ADDR_WIDTH-1:0] ram_addr,
    input logic [CPU_COUNT-1:0] valid,
    input logic [CPU_COUNT-1:0] do_swap,
    output logic [CPU_COUNT-1:0] mem_done,

    output logic [DATA_WIDTH-1:0] data_out_cpu, //shared -> only read when mem_done_x enabled

    //FPGA
    input logic [DATA_WIDTH-1:0]   data_in,

    output logic [DATA_WIDTH-1:0]  sram_addr,
    output logic [INSTR_WIDTH-1]   data_out

);

    State current_state, next_state



    // Counter implementation
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            current_state <= RESET;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        case (current_state)
            RESET : begin
                next_state = CHECK_CPU_0;
            end
            CHECK_CPU_0: begin
                if (conditions) begin
                    
                end
                next_state = CHECK_CPU_1;
            end
            CHECK_CPU_1: begin
                next_state = CHECK_CPU_0;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
