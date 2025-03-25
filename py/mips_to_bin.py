import sys

# Diccionarios con opcodes y funct para instrucciones tipo R
opcode_map = {
    "SLL":  ("000000", "000000"),
    "SRL":  ("000000", "000010"),
    "SRA":  ("000000", "000011"),
    "SLLV": ("000000", "000100"),
    "SRLV": ("000000", "000110"),
    "SRAV": ("000000", "000111"),
    "ADDU": ("000000", "100001"),
    "SUBU": ("000000", "100011"),
    "AND":  ("000000", "100100"),
    "OR":   ("000000", "100101"),
    "XOR":  ("000000", "100110"),
    "NOR":  ("000000", "100111"),
    "SLT":  ("000000", "101010"),
    "SLTU": ("000000", "101011"),
    "JR":   ("000000", "001000"),
    "JALR": ("000000", "001001"),
    "HALT": ("000000", "111111")  # HALT como una instrucción especial
}

# Instrucciones tipo I y J con sus opcodes
opcode_immediate = {
    "LB":    "100000",
    "LH":    "100001",
    "LW":    "100011",
    "LWU":   "100111",
    "LBU":   "100100",
    "LHU":   "100101",
    "SB":    "101000",
    "SH":    "101001",
    "SW":    "101011",
    "ADDI":  "001000",
    "ADDIU": "001001",
    "ANDI":  "001100",
    "ORI":   "001101",
    "XORI":  "001110",
    "LUI":   "001111",
    "SLTI":  "001010",
    "SLTIU": "001011",
    "BEQ":   "000100",
    "BNE":   "000101"
}

opcode_jump = {
    "J":   "000010",
    "JAL": "000011"
}

# Validar que un registro esté en el rango válido (0 a 31)
def is_valid_register(reg):
    if reg.startswith("$") and reg[1:].isdigit():
        reg_num = int(reg[1:])
        return 0 <= reg_num <= 31
    return False

# Validar que un valor inmediato esté en el rango válido (16 bits con signo)
def is_valid_immediate(imm):
    try:
        imm_num = int(imm)
        return -32768 <= imm_num <= 32767
    except ValueError:
        return False

# Validar que un índice de salto esté en el rango válido (26 bits)
def is_valid_instr_index(index):
    try:
        index_num = int(index)
        return 0 <= index_num <= 0x3FFFFFF
    except ValueError:
        return False

# Conversión de registros a binario
def reg_to_bin(reg):
    if is_valid_register(reg):
        reg_num = int(reg[1:])
        return format(reg_num, '05b')  # Convertir a 5 bits binarios
    else:
        raise ValueError(f"Registro no válido: {reg}")

# Conversión de inmediato a 16 bits
def imm_to_bin(imm):
    if is_valid_immediate(imm):
        return format(int(imm) & 0xFFFF, '016b')
    else:
        raise ValueError(f"Valor inmediato no válido: {imm}")

# Conversión de índice de salto a 26 bits
def instr_index_to_bin(index):
    if is_valid_instr_index(index):
        return format(int(index) & 0x3FFFFFF, '026b')
    else:
        raise ValueError(f"Índice de salto no válido: {index}")

# Procesamiento de una instrucción
def process_instruction(instr):
    # Eliminar comentarios de la línea
    instr = instr.split("#")[0].strip()
    if not instr:
        return None

    parts = instr.replace(",", "").split()
    if not parts:
        return None

    op = parts[0]

    # Caso especial para HALT
    if op == "HALT":
        if len(parts) != 1:
            raise ValueError(f"Instrucción mal formateada: {instr} (HALT no requiere operandos)")
        return "00000000000000000000000000111111"

    # Validar que la instrucción tenga el número correcto de operandos
    if op in opcode_map:
        # Instrucciones tipo R
        if op in ["JR", "JALR"]:
            if len(parts) != 2 and len(parts) != 3:
                raise ValueError(f"Instrucción mal formateada: {instr} (faltan operandos)")
        elif op in ["SLL", "SRL", "SRA"]:
            if len(parts) != 4:
                raise ValueError(f"Instrucción mal formateada: {instr} (faltan operandos)")
        else:
            if len(parts) != 4:
                raise ValueError(f"Instrucción mal formateada: {instr} (faltan operandos)")
    elif op in opcode_immediate:
        # Instrucciones tipo I
        if op == "LUI":
            if len(parts) != 3:
                raise ValueError(f"Instrucción mal formateada: {instr} (faltan operandos)")
        else:
            if len(parts) != 4:
                raise ValueError(f"Instrucción mal formateada: {instr} (faltan operandos)")
    elif op in opcode_jump:
        # Instrucciones tipo J
        if len(parts) != 2:
            raise ValueError(f"Instrucción mal formateada: {instr} (faltan operandos)")
    else:
        raise ValueError(f"Instrucción no reconocida: {op}")

    # Instrucciones tipo R
    if op in opcode_map:
        opcode, funct = opcode_map[op]

        if op == "JR":
            rs = reg_to_bin(parts[1])
            return opcode + rs + "00000" + "00000" + "00000" + funct

        elif op == "JALR":
            rs = reg_to_bin(parts[1])
            rd = reg_to_bin(parts[2])
            return opcode + rs + "00000" + rd + "00000" + funct

        elif op in ["SLL", "SRL", "SRA"]:
            rd = reg_to_bin(parts[1])
            rt = reg_to_bin(parts[2])
            sa = format(int(parts[3]), '05b')
            return opcode + "00000" + rt + rd + sa + funct

        else:
            rd = reg_to_bin(parts[1])
            rs = reg_to_bin(parts[2])
            rt = reg_to_bin(parts[3])
            return opcode + rs + rt + rd + "00000" + funct

    # Instrucciones tipo I
    elif op in opcode_immediate:
        opcode = opcode_immediate[op]

        if op == "LUI":
            rt = reg_to_bin(parts[1])
            imm = imm_to_bin(parts[2])
            return opcode + "00000" + rt + imm

        else:
            rt = reg_to_bin(parts[1])
            rs = reg_to_bin(parts[2])
            imm = imm_to_bin(parts[3])
            return opcode + rs + rt + imm

    # Instrucciones tipo J
    elif op in opcode_jump:
        opcode = opcode_jump[op]
        instr_index = instr_index_to_bin(parts[1])
        return opcode + instr_index

    return None

# Convertir archivo .asm a .coe
def convert_asm_to_coe(input_file, output_file):
    with open(input_file, "r") as asm_file:
        instructions = asm_file.readlines()

    binary_instructions = []
    start_processing = False  # Bandera para indicar cuándo empezar a procesar

    for line_num, instr in enumerate(instructions, start=1):
        instr = instr.strip()

        # Ignorar todo antes de "--------fin del ejemplo-----"
        if "--------fin del ejemplo-----" in instr:
            start_processing = True
            continue  # Saltar la línea del marcador

        # Ignorar la línea específica con el mensaje
        if "# A partir de aquí, escribe las instrucciones que deseas convertir:" in instr:
            continue  # Saltar esta línea

        # Ignorar comentarios y líneas vacías
        if not start_processing or not instr or instr.startswith("#"):
            continue

        # Procesar solo si la bandera está activada
        try:
            binary_instr = process_instruction(instr)
            if binary_instr:
                binary_instructions.append(binary_instr)
        except ValueError as e:
            print(f"Error en la línea {line_num}: {e}")

    with open(output_file, "w") as coe_file:
        # Escribir las instrucciones binarias directamente
        for i, bin_instr in enumerate(binary_instructions):
            coe_file.write(bin_instr + (",\n" if i < len(binary_instructions) - 1 else ";\n"))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python mips_to_bin.py input.asm output.coe")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert_asm_to_coe(input_file, output_file)
    print(f"Conversión completada. Archivo guardado en {output_file}")