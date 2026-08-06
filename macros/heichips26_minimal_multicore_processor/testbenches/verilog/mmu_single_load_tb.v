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
    .fpga_in1(fpga_in1),
    .fpga_in2(fpga_in2),
    .mem_done(mem_done),
    .data_out_cpu(data_out_cpu),
    .fpga_out(fpga_out)
);

task fail(integer point);
    $display("Failed at checkpoint %d", point);
    $finish;
endtask

task test_fpga_out([7:0] test, integer point);
    if (!(fpga_out == test)) fail(point);
endtask

initial begin
    $dumpfile("testbenches/waveforms/mmu_single_load.vcd");
    $dumpvars();
    #100;
    rst_ni = 1;
    reg_data = {8'd1, 8'd2};
    ram_addr = {8'd3, 8'd4};
    valid = {1, 0};
    do_swap = {0, 0};
    fpga_in1 = {8'd5};
    fpga_in2 = {8'd6};
    
    #100;

    #100;

    test_fpga_out(8'b00000001, 1);

    #100;

    test_fpga_out(8'b00000011, 2);

    #100;

    test_fpga_out(8'b00000000, 3);
    if (!(mem_done[1] == 1)) fail(4);

    #100;

    if (!(mem_done[1] == 0)) fail(5);

    $display("Finished without errors.");
    $finish;
end

endmodule 