from interpreter_single import int8_add, Interpreter
import random


class MMU:
    def __init__(self, memory_bin_lines):
        self.memory = [0] * 256  # Initialize 256 bytes of memory
        for i, line in enumerate(memory_bin_lines):
            self.memory[i] = int(line.strip(), 2)  # Convert binary string to integer

class CPU_Core (Interpreter):

    def __init__(self, mmu, core_id):
        self.mmu = mmu
        self.memory = mmu.memory
        self.core_id = core_id
        self.pc = core_id * 2 #16 bit instructions, so each core starts at a different instruction
        self.registers = [0] * 8  # Initialize 8 registers (R0-R7)



class DualCoreInterpreter:
    def __init__(self, memory_bin_lines):
        self.mmu = MMU(memory_bin_lines)
        self.core0 = CPU_Core(self.mmu, 0)
        self.core1 = CPU_Core(self.mmu, 1)

    def run(self, cycles=100):
        for i in range(cycles):
            # Randomly choose which core to step
            if random.choice([True, False]):
                self.core0.step()
            else:
                self.core1.step()

if __name__ == "__main__":
    import sys
    # Accept either binary file and use default 100 cycles, or accept binary file and number of cycles
    if len(sys.argv) != 2 and len(sys.argv) != 3:
        print("Usage: python interpreter_dual.py <input_file>")
        print("       python interpreter_dual.py <input_file> <cycles>")
        sys.exit(1)

    input_file = sys.argv[1]
    cycles = 100 if len(sys.argv) == 2 else int(sys.argv[2])

    with open(input_file, 'r') as f:
        memory_bin_lines = f.readlines()

    interpreter = DualCoreInterpreter(memory_bin_lines)
    interpreter.run(cycles)

    # dump the memory and registers after execution
    print("Memory after execution:")
    for i, val in enumerate(interpreter.mmu.memory):
        print(f"Address {i:03}: 0x{val:02X} ({val})")

    print("\nRegisters1 after execution:")
    for i, val in enumerate(interpreter.core0.registers):
        print(f"R{i}: 0x{val:02X} ({val})")
    print("\nRegisters2 after execution:")
    for i, val in enumerate(interpreter.core1.registers):
        print(f"R{i}: 0x{val:02X} ({val})")

    print(f"\nProgram Counter 0: 0x{interpreter.core0.pc:02X} ({interpreter.core0.pc})")
    print(f"Program Counter 1: 0x{interpreter.core1.pc:02X} ({interpreter.core1.pc})")
