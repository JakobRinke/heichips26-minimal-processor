# heichips2026_nextadresslogic_tb.py (extended)

import cocotb
from cocotb.triggers import FallingEdge, Timer


import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def generate_clock(dut):
    """Generate clock pulses."""
    # initial vals for output
    for _ in range(20):
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def sanitytest_nextadresslogic(dut):
    """Try accessing the design."""
    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"


    dut.rst_n.value = 0
    dut.imm.value = 0
    dut.select_jump.value = 0
    dut.data_1.value = 0
    dut.done_writing.value = 0


    await RisingEdge(dut.clk)
    dut.rst_n.value = 1


    dut.done_writing.value = 1
    dut.select_jump.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


    dut.select_jump.value = 1
    dut.data_1.value = 10
    dut.imm.value = 5

    await RisingEdge(dut.clk)


    dut.done_writing.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


    cocotb.log.info("PC is %s", dut.current_pc.value)

