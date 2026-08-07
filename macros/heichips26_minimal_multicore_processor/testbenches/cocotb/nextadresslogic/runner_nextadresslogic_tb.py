from cocotb.runner import get_runner

runner = get_runner("icarus")

runner.build(
    sources=["nextadresslogic.sv"],
    hdl_toplevel="nextadresslogic",
    always=True,
    waves=True,
)

runner.test(
    hdl_toplevel="nextadresslogic",
    test_module="sanitytest_nextadresslogic",
    waves=True,
)
