# heichips2026_nextadresslogic_tb.py (extended)

import cocotb
from cocotb.triggers import FallingEdge, Timer

"""
	input wire clk
	input wire rst_n,
	input wire [7:0] imm,
	input wire select_jump,
	input wire done_writing,
	output reg [7:0] current_pc,
	output reg done_pc
"""


async def generate_clock(dut):
    """Generate clock pulses."""
    # initial vals for output
    dut.current_pc.value = 0
    dut.done_pc.value = 0
    for _ in range(10):
        dut.clk.value = 0
        dut.rst_n.value = 1
        dut.imm.value = 2
        dut.select_jump.value = 1
        dut.done_writing.value = 1
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def my_second_test(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    cocotb.log.info("PC is %s", dut.current_pc.value)

