iverilog -o dump.out \
    rtl/single_core_cpu/add8.sv \
    rtl/single_core_cpu/cpu_core.sv \
    rtl/single_core_cpu/decoder.sv \
    rtl/single_core_cpu/memory_communicator.sv \
    rtl/single_core_cpu/nextadresslogic.sv \
    rtl/single_core_cpu/register_file.sv  \
    testbenches/verilog/single_core_cpu/cpu_core_jump_tb.sv \
    && vvp dump.out