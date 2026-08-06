`timescale 1ns/100ps
module mmu_load_tb ();

localparam CPU_COUNT = 2;
localparam ADDR_WIDTH = 8;
localparam DATA_WIDTH = 8;

reg clk_i;
reg rst_ni = 0;
reg [ADDR_WIDTH-1:0] reg_data [CPU_COUNT-1:0];
reg [ADDR_WIDTH-1:0] ram_addr [CPU_COUNT-1:0];
reg valid[CPU_COUNT-1:0];
reg do_swap[CPU_COUNT-1:0];
reg [DATA_WIDTH - 1:0] fpga_in1;
reg [DATA_WIDTH - 1:0] fpga_in2;

wire mem_done[CPU_COUNT-1:0];
wire [DATA_WIDTH*2-1:0] data_out_cpu;
wire [DATA_WIDTH - 1:0] fpga_out;

always @(*) begin
    clk_i = ~clk_i;
    #50;
end

mmu #(
    .CPU_COUNT(CPU_COUNT),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .reg_data(reg_data),
    .ram_addr(ram_addr),
    .valid(valid),
    .do_swap(do_swap),
    .mem_done(mem_done),
    .data_out_cpu(data_out_cpu),

    .fpga_in1(fpga_in1),
    .fpga_in2(fpga_in2),

    .fpga_out(fpga_out) //in
);

task fail(integer point);
    $display("Failed at checkpoint %d", point);
    //$finish;
endtask

task automatic test_valid([15:0] expected_cpu, [7:0] expected_fpga, integer point);
    if (!(data_out_cpu == expected_cpu)) begin
        fail(point+1);
    end

    if (!(fpga_out == expected_fpga)) begin
        fail(point+2);
    end
endtask //automatic

initial begin
    $dumpfile("testbenches/waveforms/mmu_single_swap.vcd");
    $dumpvars();
    $display("\n\n------------ Start Test ---------------\n\n");
    #50;
    rst_ni = 1;

    reg_data = {8'd32, 8'd2};
    ram_addr = {8'd4, 8'd4};
    valid = {1'd1, 1'd0};
    do_swap = {1'd1, 1'd0};

    fpga_in1 = {8'd0};
    fpga_in2 = {8'd0};
    
    #100;

    test_valid(16'd0, 8'd0, 10);
    #100;

    test_valid(16'b0000000000000000, 8'b00000001, 20);

    #100;

    test_valid(16'b0000000000000000, 8'b00000100, 30);

    fpga_in1 = {8'd0};
    fpga_in2 = {8'd4};

    #100;

    test_valid(16'b00000000_00000100, 8'b00000011, 40);

    #100

    test_valid(16'b0000000000000100, 8'b00000100, 50);

    #100

    test_valid(16'b0000000000000100, 8'b00100000, 60);

    if (!(mem_done[1] == 1)) fail(63);

    #100;

    if (!(mem_done[1] == 0)) fail(64);

    $display("Finished without errors.");
    $finish;
end

endmodule 