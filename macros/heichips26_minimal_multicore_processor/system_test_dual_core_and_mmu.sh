iverilog -g2012 -o dump.out \
    rtl/single_core_cpu/add8.sv \
    rtl/single_core_cpu/cpu_core.sv \
    rtl/single_core_cpu/decoder.sv \
    rtl/single_core_cpu/memory_communicator.sv \
    rtl/single_core_cpu/nextadresslogic.sv \
    rtl/single_core_cpu/register_file.sv \
    rtl/mmu.sv \
    rtl/heichips26_digital_project.sv \
    testbenches/verilog/system_mmu_dual_core.sv \
    && vvp dump.out