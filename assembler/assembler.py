
def num_to_8bit_hex(num:int):
    if num < 0:
        num = (1 << 8) + num  # Convert negative to two's complement
    return "0x" + format(num, '02x')

def hex_or_dec_to_8bit_binary(value):
    v = 0
    if value.startswith("0x"):
        v = int(value, 16)
    else:
        v = int(value)
    if v < 0:
        v = (1 << 8) + v  # Convert negative to two's complement
    return format(v, '08b')

def reg_code_to_3bit_binary(reg):
    # format xi where i is 0-7
    if reg.startswith("x"):
        reg_num = int(reg[1:])
        if 0 <= reg_num <= 7:
            return format(reg_num, '03b')
    else:
        raise ValueError(f"Invalid register name: {reg}")

def remove_white_spaces(lines):
    return [l.strip(" \t\n") for l in lines]

def remove_comments(lines:list):
    new_lines = []
    for l in lines:
        if str(l).startswith("//"):
            pass # skip comment lines
        elif "//" in str(l):
            new_lines.append(str(l).split("//")[0])
        else:
            new_lines.append(l)
    return new_lines

def merge_markers_with_inst(lines:list):
    current_marker_buffer = ""
    new_lines = []
    for l in lines:
        if str(l).endswith(":"):
            current_marker_buffer += str(l)
        else:
            # normal line
            new_lines.append(current_marker_buffer + l)
            current_marker_buffer = ""
    return new_lines

def detect_double_markers(lines:list):
    marker_merge = {}
    new_lines = []
    for l in lines:
        if str(l).count(":") > 1:
            markers = str(l).split(":")[:-1]
            instruction = str(l).split(":")[-1]
            merged_name = "_".join(markers)
            for m in markers:
                marker_merge[m] = merged_name
            line_with_merged_markers = merged_name + ":" + instruction
            new_lines.append(line_with_merged_markers)
        else:
            new_lines.append(l)

    # Now replace all marker references with the merged marker names
    for i in range(len(new_lines)):
        for old_marker, new_marker in marker_merge.items():
            new_lines[i] = new_lines[i].replace(old_marker + ":", new_marker + ":")
    return new_lines

def resolve_markers(lines:list):
    marker_dict = {}
    for i, l in enumerate(lines):
        if ":" in str(l):
            marker_name = str(l).split(":")[0]
            marker_dict[marker_name] = i

    new_lines = []
    for i, l in enumerate(lines):
        if "JMPZ" in str(l):
            parts = str(l).split(",")
            mark = parts[-1].strip()
            if not mark in marker_dict:
                raise Exception(f"Marker {mark} not found in the code.")
            relative_offset = (marker_dict[mark] - i) * 2 # Each instruction is 2 bytes
            new_lines.append(str(l).replace(mark, num_to_8bit_hex(relative_offset)))
        else:
            new_lines.append(l)

    newer_lines = []
    for l in new_lines:
        # remove the marker from the line if it exists
        newer_lines.append(str(l).split(":")[-1])

    return newer_lines

def convert_binary(lines:list):
    binary_lines = []
    for l in lines:
        opcode = ""
        reg1 = ""
        reg2 = ""
        imm = ""
        if l.startswith("ADDI"):
            operators = l[5:].split(",")
            if len(operators) != 3:
                raise Exception(f"ADDI instruction requires 3 operands, got {len(operators)}: {l}")
            opcode = "00"
            reg1 = reg_code_to_3bit_binary(operators[1].strip())
            reg2 = reg_code_to_3bit_binary(operators[0].strip())
            imm = hex_or_dec_to_8bit_binary(operators[2].strip())
        elif l.startswith("JMPZ"):
            operators = l[5:].split(",")
            if len(operators) != 2:
                raise Exception(f"JMPZ instruction requires 2 operands, got {len(operators)}: {l}")
            opcode = "01"
            reg1 = reg_code_to_3bit_binary(operators[0].strip())
            reg2 = "000" # Unused for JMPZ
            imm = hex_or_dec_to_8bit_binary(operators[1].strip())
        elif l.startswith("SWAP"):
            operators = l[5:].split(",")
            if len(operators) != 2:
                raise Exception(f"SWAP instruction requires 2 operands, got {len(operators)}: {l}")
            opcode = "10"
            reg1 = reg_code_to_3bit_binary(operators[0].strip())
            print(l)
            print(operators)
            reg2 = reg_code_to_3bit_binary(operators[1].strip())
            imm = "00000000"  # Unused for SWAP
        else:
            raise Exception(f"Unknown instruction: {l}")

        binary_lines.append(reg2 + reg1 + opcode)
        binary_lines.append(imm)
        


    return binary_lines




def assemble_single(lines:list):
    lines = remove_white_spaces(lines)
    lines = remove_comments(lines)
    lines = merge_markers_with_inst(lines)
    lines = detect_double_markers(lines)
    lines = resolve_markers(lines)
    for l in lines:
        print(l)
    binary_lines = convert_binary(lines)
    return binary_lines

import sys
if __name__ == "__main__":
    if len(sys.argv) != 2 and len(sys.argv) != 3:
        print("Usage: python assembler.py <input_file>")
        print("       python assembler.py <input_file> <output_file>")
        sys.exit(1)
    input_file = sys.argv[1]
    output_file = input_file + ".bin" if len(sys.argv) == 2 else sys.argv[2] 

    with open(input_file, "r") as f:
        lines = f.readlines()

    binary_lines = assemble_single(lines)
    output= ""
    for line in binary_lines:
        output += line + "\n"
    q = len(binary_lines)
    for i in range(q, 256):
        output += "00000000\n"
    output = output.strip()  # Remove the trailing newline

    with open(output_file, "w") as f:
        f.write(output)