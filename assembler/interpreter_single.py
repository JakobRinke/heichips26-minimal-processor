


def int8_add(a, b):
    result = (a + b) & 0xFF  # Keep only the last 8 bits
    return result

class Interpreter:
    def __init__(self, memory_bin_lines):
        self.start_mem_bin = memory_bin_lines
        self.memory = [int(line, 2) for line in memory_bin_lines]  # Convert binary strings to integers
        self.pc = 0  # Program counter
        self.registers = [0] * 8  # Initialize 8 registers (R0-R7)

    def run(self, cycles=100):
        for i in range(cycles):
            self.step()

    def get_reg_val(self, reg_num, reg_id = 2):
        if reg_num < 4 and reg_id == 2:
            return 0
        if reg_num == 0:
            return 0
        if reg_num == 1:
            return (self.registers[4] & self.registers[5]) & 0xFF
        if reg_num == 2:
            return (~self.registers[4]) & 0xFF
        if reg_num == 3:
            return (self.registers[4] | self.registers[5]) & 0xFF
        return self.registers[reg_num]

    def step(self):
        instruction = (self.memory[self.pc] << 8) + self.memory[self.pc + 1]  # Combine the next two bytes to form the instruction
        opcode = (instruction) & 0x3  # Extract the opcode (first 2 bits)
        reg1 = (instruction >> 2) & 0x7  # Extract the first register (next 3 bits)
        reg2 = (instruction >> 5) & 0x7  # Extract the second register (next 3 bits)
        imm = (instruction >> 8) & 0xFF  # Extract the immediate value (last 8 bits)

        if opcode == 0:  # ADDI
            self.registers[reg2] = int8_add(self.get_reg_val(reg1, 1), imm)
            self.pc += 2
        if opcode == 1:  # JMPZ
            if self.get_reg_val(reg1, 1) == 0:
                self.pc += imm
            else:
                self.pc += 2
        if opcode == 2:  # SWAP
            temp = self.get_reg_val(reg2, 2)
            addr = self.get_reg_val(reg1, 1)
            self.registers[reg2] = self.memory[addr]
            self.memory[addr] = temp
            self.pc += 2
            
        self.pc = (self.pc + 256) % 256


import sys
if __name__ == "__main__":
    # Accept either binary file and use default 100 cycles, or accept binary file and number of cycles
    if len(sys.argv) != 2 and len(sys.argv) != 3:
        print("Usage: python interpreter_single.py <input_file>")
        print("       python interpreter_single.py <input_file> <cycles>")
        sys.exit(1)

    input_file = sys.argv[1]
    cycles = 100 if len(sys.argv) == 2 else int(sys.argv[2])

    with open(input_file, "r") as f:
        memory_bin_lines = f.readlines()

    interpreter = Interpreter(memory_bin_lines)
    interpreter.run(cycles)

    # dump the memory and registers after execution
    print("Memory after execution:")
    for i, val in enumerate(interpreter.memory):
        print(f"Address {i:03}: 0x{val:02X} ({val})")

    print("\nRegisters after execution:")
    for i, val in enumerate(interpreter.registers):
        print(f"R{i}: 0x{interpreter.get_reg_val(i, 1):02X} ({interpreter.get_reg_val(i, 1)})")

    print(f"\nProgram Counter: 0x{interpreter.pc:02X} ({interpreter.pc})")
