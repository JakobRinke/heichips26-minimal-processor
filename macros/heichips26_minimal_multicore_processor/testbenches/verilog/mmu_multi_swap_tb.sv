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
endtask

task test_cpu_out([15:0] expected_cpu, integer point);
    if (!(data_out_cpu == expected_cpu)) begin
        fail(point);
    end
endtask

task test_fpga_out([7:0] test, integer point);
    if (!(fpga_out == test)) begin
        fail(point);
    end
endtask

initial begin
    $dumpfile("testbenches/waveforms/mmu_multi_swap.vcd");
    $dumpvars();
    $display("\n\n------------ Start Test ---------------\n\n");
    #50;
    rst_ni = 1;

    reg_data = {32, 0};
    ram_addr = {4, 0};
    valid = {1, 0};
    do_swap = {1, 0};

    fpga_in1 = 0;
    fpga_in2 = 0;
    
    #100;

    test_cpu_out(0, 1);
    test_fpga_out(0, 2);
    #100;

    valid = {1, 1};
    do_swap = {1, 1};
    reg_data = {32, 22};
    ram_addr = {4, 9};

    test_cpu_out(0, 2);
    test_fpga_out(8'b00000001, 3);

    #100;

    test_cpu_out(0, 4);
    test_fpga_out(8'b00000100, 5);

    fpga_in1 = 0;
    fpga_in2 = 4;

    #100;
    test_cpu_out(16'b00000000_00000100, 6);
    test_fpga_out(8'b00000011, 7);

    #100
    test_cpu_out(16'b00000000_00000100, 8);
    test_fpga_out(8'b00000100, 9);

    #100
    test_cpu_out(16'b00000000_00000100, 10);
    test_fpga_out(8'b00100000, 11);

    if (!(mem_done[1] == 1)) begin
        fail(12);
    end 

    valid = {0, 1};
    do_swap = {0, 1};
    reg_data = {0, 22};
    ram_addr = {0, 9};
    #100;

    test_fpga_out(0, 14);

    if (!(mem_done[1] == 0)) begin
        fail(15);
    end 

    #100

    test_fpga_out(0, 140);

    #100

    test_fpga_out(8'b00000001, 16);

    #100

    test_fpga_out(8'b00001001, 17);
    fpga_in1 = 0;
    fpga_in2 = 32;
    #100

    test_fpga_out(8'b00000011, 18);

    #100

    test_fpga_out(8'b00001001, 19);


    #100

    test_fpga_out(8'b00010110, 20);
    test_cpu_out(16'b00000000_00100000, 21);

    if (!(mem_done[0] == 1)) begin
        fail(22);
    end 

    #100

    if (!(mem_done[0] == 0)) begin
        fail(23);
    end 

    $display("Finished without errors.");
    $finish;
end

endmodule 