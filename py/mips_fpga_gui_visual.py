import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import serial
import serial.tools.list_ports
import time
import sys
import threading
import os
from tkinter.font import Font
import re

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

# Parámetros de comunicación
BAUDRATE = 19200
BYTESIZE = serial.EIGHTBITS
STOPBITS = serial.STOPBITS_ONE
PARITY   = serial.PARITY_NONE

# Comandos definidos (en byte)
CMD_LOAD  = 0x04  # LOAD_PROGRAM
CMD_RUN   = 0x03  # RUN
CMD_STEP  = 0x05  # STEP
CMD_RESET = 0x0C  # RESET

# Valor de HALT en 32 bits
HALT_INSTR = 0x0000003F

# Número total de bytes que se esperan como respuesta
EXPECTED_RESPONSE_BYTES = 256
# Número de bytes de los registros de pipeline
PIPELINE_BYTES = 47

# Funciones del script mips_to_bin.py
def is_valid_register(reg):
    if reg.startswith("$") and reg[1:].isdigit():
        reg_num = int(reg[1:])
        return 0 <= reg_num <= 31
    return False

def is_valid_immediate(imm):
    try:
        imm_num = int(imm)
        return -32768 <= imm_num <= 32767
    except ValueError:
        return False

def is_valid_instr_index(index):
    try:
        index_num = int(index)
        return 0 <= index_num <= 0x3FFFFFF
    except ValueError:
        return False

def reg_to_bin(reg):
    if is_valid_register(reg):
        reg_num = int(reg[1:])
        return format(reg_num, '05b')
    else:
        raise ValueError(f"Registro no válido: {reg}")

def imm_to_bin(imm):
    if is_valid_immediate(imm):
        return format(int(imm) & 0xFFFF, '016b')
    else:
        raise ValueError(f"Valor inmediato no válido: {imm}")

def instr_index_to_bin(index):
    if is_valid_instr_index(index):
        return format(int(index) & 0x3FFFFFF, '026b')
    else:
        raise ValueError(f"Índice de salto no válido: {index}")

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

def convert_asm_to_coe(input_text, output_file=None):
    instructions = input_text.splitlines()
    binary_instructions = []
    start_processing = True  # En la GUI procesamos todo el texto
    errors = []

    for line_num, instr in enumerate(instructions, start=1):
        instr = instr.strip()

        # Ignorar comentarios y líneas vacías
        if not instr or instr.startswith("#"):
            continue

        try:
            binary_instr = process_instruction(instr)
            if binary_instr:
                binary_instructions.append(binary_instr)
        except ValueError as e:
            errors.append(f"Error en la línea {line_num}: {e}")

    # Si se proporciona un archivo de salida, escribir en él
    if output_file:
        with open(output_file, "w") as coe_file:
            for i, bin_instr in enumerate(binary_instructions):
                coe_file.write(bin_instr + (",\n" if i < len(binary_instructions) - 1 else ";\n"))
    
    return binary_instructions, errors

# Funciones del script fpga.py
def parse_coe(filename):
    instrucciones = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            token = line.split()[0]
            if len(token) < 32:
                print(f"Línea ignorada (menos de 32 bits): {line}")
                continue
            bits = token[:32]
            if not all(c in '01' for c in bits):
                print(f"Línea ignorada (no es una cadena binaria válida): {line}")
                continue
            try:
                instr = int(bits, 2)
            except ValueError:
                print(f"Error al convertir la línea a entero: {line}")
                continue
            instrucciones.append(instr)
            if instr == HALT_INSTR:
                break
    return instrucciones

def enviar_datos(ser, data_bytes):
    ser.write(data_bytes)
    ser.flush()

def leer_respuesta(ser, total_bytes):
    recibido = b''
    while len(recibido) < total_bytes:
        chunk = ser.read(total_bytes - len(recibido))
        if not chunk:
            break
        recibido += chunk
    return recibido

def print_field(label, value, bits):
    hex_width = bits // 4
    bin_width = bits
    hex_str = format(value, '0{}X'.format(hex_width))
    bin_str = format(value, '0{}b'.format(bin_width))
    hex_field = f"0x{hex_str}"
    return f"{label:<12}: {hex_field:<10}   {bin_str:>{bin_width}}"

# Clase para el editor de texto con resaltado de sintaxis
class SyntaxHighlightingText(scrolledtext.ScrolledText):
    def __init__(self, master=None, **kwargs):
        super().__init__(master, **kwargs)
        self.configure(font=('Consolas', 11))
        
        # Configurar etiquetas para resaltado de sintaxis
        self.tag_configure("instruction", foreground="#0066cc")
        self.tag_configure("register", foreground="#cc6600")
        self.tag_configure("number", foreground="#009900")
        self.tag_configure("comment", foreground="#999999", font=('Consolas', 11, 'italic'))
        
        # Patrones para resaltado
        self.instruction_pattern = r'\b(SLL|SRL|SRA|SLLV|SRLV|SRAV|ADDU|SUBU|AND|OR|XOR|NOR|SLT|SLTU|JR|JALR|LB|LH|LW|LWU|LBU|LHU|SB|SH|SW|ADDI|ADDIU|ANDI|ORI|XORI|LUI|SLTI|SLTIU|BEQ|BNE|J|JAL)\b'
        self.register_pattern = r'\$\d+'
        self.number_pattern = r'\b\d+\b'
        self.comment_pattern = r'#.*$'
        
        # Vincular eventos
        self.bind('<KeyRelease>', self.highlight_syntax)
        
    def highlight_syntax(self, event=None):
        # Eliminar resaltado existente
        for tag in ["instruction", "register", "number", "comment"]:
            self.tag_remove(tag, "1.0", "end")
        
        # Aplicar resaltado
        content = self.get("1.0", "end-1c")
        lines = content.split('\n')
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Resaltar instrucciones
            for match in re.finditer(self.instruction_pattern, line, re.IGNORECASE):
                start = f"{line_num}.{match.start()}"
                end = f"{line_num}.{match.end()}"
                self.tag_add("instruction", start, end)
            
            # Resaltar registros
            for match in re.finditer(self.register_pattern, line):
                start = f"{line_num}.{match.start()}"
                end = f"{line_num}.{match.end()}"
                self.tag_add("register", start, end)
            
            # Resaltar números
            for match in re.finditer(self.number_pattern, line):
                start = f"{line_num}.{match.start()}"
                end = f"{line_num}.{match.end()}"
                self.tag_add("number", start, end)
            
            # Resaltar comentarios
            for match in re.finditer(self.comment_pattern, line):
                start = f"{line_num}.{match.start()}"
                end = f"{line_num}.{match.end()}"
                self.tag_add("comment", start, end)

# Clase para el botón personalizado con hover effect
class HoverButton(tk.Canvas):
    def __init__(self, master=None, text="", command=None, width=120, height=40, 
                 bg_color="#4a86e8", hover_color="#3a76d8", text_color="white", 
                 corner_radius=10, **kwargs):
        super().__init__(master, width=width, height=height, 
                         highlightthickness=0, bg=self.get_bg_color(master), **kwargs)
        
        self.bg_color = bg_color
        self.hover_color = hover_color
        self.text_color = text_color
        self.corner_radius = corner_radius
        self.command = command
        
        # Crear el botón redondeado
        self.create_rounded_rect(0, 0, width, height, self.corner_radius, fill=self.bg_color, outline="")
        self.text_id = self.create_text(width//2, height//2, text=text, fill=self.text_color, 
                                        font=('Segoe UI', 10, 'bold'))
        
        # Vincular eventos
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
        self.bind("<Button-1>", self.on_click)
        self.bind("<ButtonRelease-1>", self.on_release)
    
    def get_bg_color(self, widget):
        """Obtiene el color de fondo de un widget ttk."""
        if isinstance(widget, ttk.Frame):
            # Para ttk.Frame, usa el estilo para obtener el color de fondo
            style = ttk.Style()
            return style.lookup(widget.winfo_class(), 'background')
        else:
            # Para otros widgets, usa cget
            try:
                return widget.cget('bg')
            except:
                return "#f0f0f0"  # Color por defecto
    
    def create_rounded_rect(self, x1, y1, x2, y2, radius, **kwargs):
        points = [
            x1+radius, y1,
            x2-radius, y1,
            x2, y1,
            x2, y1+radius,
            x2, y2-radius,
            x2, y2,
            x2-radius, y2,
            x1+radius, y2,
            x1, y2,
            x1, y2-radius,
            x1, y1+radius,
            x1, y1
        ]
        return self.create_polygon(points, smooth=True, **kwargs)
    
    def on_enter(self, event):
        self.itemconfig(1, fill=self.hover_color)
    
    def on_leave(self, event):
        self.itemconfig(1, fill=self.bg_color)
    
    def on_click(self, event):
        self.itemconfig(1, fill="#2a66c8")
    
    def on_release(self, event):
        self.itemconfig(1, fill=self.hover_color)
        if self.command:
            self.command()
    
    def configure(self, **kwargs):
        if "text" in kwargs:
            self.itemconfig(self.text_id, text=kwargs["text"])
        
        if "state" in kwargs:
            if kwargs["state"] == "disabled":
                self.itemconfig(1, fill="#cccccc")
                self.unbind("<Enter>")
                self.unbind("<Leave>")
                self.unbind("<Button-1>")
                self.unbind("<ButtonRelease-1>")
            elif kwargs["state"] == "normal":
                self.itemconfig(1, fill=self.bg_color)
                self.bind("<Enter>", self.on_enter)
                self.bind("<Leave>", self.on_leave)
                self.bind("<Button-1>", self.on_click)
                self.bind("<ButtonRelease-1>", self.on_release)
        
        # Eliminar la opción "text" de kwargs antes de pasarla a super().configure
        kwargs.pop("text", None)
        super().configure(**kwargs)
    
    def config(self, **kwargs):
        self.configure(**kwargs)

# Clase para el panel de información con estilo moderno
class InfoPanel(tk.Frame):
    def __init__(self, master=None, title="", **kwargs):
        super().__init__(master, **kwargs)
        self.configure(bg="#f5f5f5", padx=10, pady=10)
        
        # Título
        self.title_label = tk.Label(self, text=title, font=('Segoe UI', 12, 'bold'), 
                                   bg="#f5f5f5", fg="#333333")
        self.title_label.pack(anchor="w", pady=(0, 5))
        
        # Separador
        separator = ttk.Separator(self, orient="horizontal")
        separator.pack(fill="x", pady=5)
        
        # Contenido
        self.content_frame = tk.Frame(self, bg="#f5f5f5")
        self.content_frame.pack(fill="both", expand=True)
    
    def add_field(self, label, value=""):
        frame = tk.Frame(self.content_frame, bg="#f5f5f5")
        frame.pack(fill="x", pady=2)
        
        label_widget = tk.Label(frame, text=label, width=15, anchor="w", 
                               font=('Segoe UI', 10), bg="#f5f5f5", fg="#555555")
        label_widget.pack(side="left")
        
        value_widget = tk.Label(frame, text=value, anchor="w", 
                               font=('Segoe UI', 10, 'bold'), bg="#f5f5f5", fg="#333333")
        value_widget.pack(side="left", fill="x", expand=True)
        
        return value_widget
    
    def update_field(self, label_widget, value):
        label_widget.config(text=value)

# Clase para visualizar registros en formato de tabla
class RegistersTable(tk.Frame):
    def __init__(self, master=None, **kwargs):
        super().__init__(master, **kwargs)
        self.configure(bg="#ffffff")
        
        # Crear tabla de registros
        self.create_table()
        
        # Inicializar valores
        self.clear_values()
    
    def create_table(self):
        # Crear encabezados
        header_frame = tk.Frame(self, bg="#4a86e8")
        header_frame.pack(fill="x")
        
        headers = ["Registro", "Valor (Hex)", "Valor (Bin)"]
        widths = [100, 120, 320]
        
        for i, header in enumerate(headers):
            tk.Label(header_frame, text=header, font=('Segoe UI', 10, 'bold'), 
                    bg="#4a86e8", fg="white", width=widths[i]//10).grid(row=0, column=i, padx=2, pady=5, sticky="w")
        
        # Crear contenedor para filas de registros
        self.rows_frame = tk.Frame(self, bg="#ffffff")
        self.rows_frame.pack(fill="both", expand=True)
        
        # Crear canvas y scrollbar para permitir desplazamiento
        self.canvas = tk.Canvas(self.rows_frame, bg="#ffffff", highlightthickness=0)
        scrollbar = ttk.Scrollbar(self.rows_frame, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=scrollbar.set)
        
        scrollbar.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)
        
        # Frame dentro del canvas para las filas
        self.table_frame = tk.Frame(self.canvas, bg="#ffffff")
        self.canvas_window = self.canvas.create_window((0, 0), window=self.table_frame, anchor="nw")
        
        # Configurar eventos para redimensionar el canvas
        self.table_frame.bind("<Configure>", self.on_frame_configure)
        self.canvas.bind("<Configure>", self.on_canvas_configure)
        
        # Crear filas para los 32 registros
        self.reg_labels = []
        self.hex_labels = []
        self.bin_labels = []
        
        for i in range(32):
            row_frame = tk.Frame(self.table_frame, bg="#ffffff" if i % 2 == 0 else "#f5f5f5")
            row_frame.pack(fill="x")
            
            reg_label = tk.Label(row_frame, text=f"R{i}", font=('Consolas', 10), 
                               bg=row_frame["bg"], width=10, anchor="w")
            reg_label.grid(row=0, column=0, padx=2, pady=2, sticky="w")
            
            hex_label = tk.Label(row_frame, text="0x00000000", font=('Consolas', 10), 
                               bg=row_frame["bg"], width=12, anchor="w")
            hex_label.grid(row=0, column=1, padx=2, pady=2, sticky="w")
            
            bin_label = tk.Label(row_frame, text="00000000000000000000000000000000", font=('Consolas', 10), 
                               bg=row_frame["bg"], width=32, anchor="w")
            bin_label.grid(row=0, column=2, padx=2, pady=2, sticky="w")
            
            self.reg_labels.append(reg_label)
            self.hex_labels.append(hex_label)
            self.bin_labels.append(bin_label)
    
    def on_frame_configure(self, event):
        # Actualizar región de desplazamiento del canvas
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))
    
    def on_canvas_configure(self, event):
        # Ajustar el ancho del frame interno al ancho del canvas
        self.canvas.itemconfig(self.canvas_window, width=event.width)
    
    def update_register(self, reg_num, value):
        if 0 <= reg_num < 32:
            hex_value = f"0x{value:08X}"
            bin_value = f"{value:032b}"
            
            self.hex_labels[reg_num].config(text=hex_value)
            self.bin_labels[reg_num].config(text=bin_value)
            
            # Resaltar el registro actualizado
            row_frame = self.hex_labels[reg_num].master
            orig_bg = "#ffffff" if reg_num % 2 == 0 else "#f5f5f5"
            
            # Efecto de resaltado temporal
            row_frame.config(bg="#e6f2ff")
            self.reg_labels[reg_num].config(bg="#e6f2ff")
            self.hex_labels[reg_num].config(bg="#e6f2ff")
            self.bin_labels[reg_num].config(bg="#e6f2ff")
            
            # Restaurar color original después de un tiempo
            self.after(1500, lambda: self.restore_color(reg_num, orig_bg))
    
    def restore_color(self, reg_num, color):
        row_frame = self.hex_labels[reg_num].master
        row_frame.config(bg=color)
        self.reg_labels[reg_num].config(bg=color)
        self.hex_labels[reg_num].config(bg=color)
        self.bin_labels[reg_num].config(bg=color)
    
    def clear_values(self):
        for i in range(32):
            self.hex_labels[i].config(text="0x00000000")
            self.bin_labels[i].config(text="00000000000000000000000000000000")

# Clase para visualizar memoria en formato de tabla
class MemoryTable(tk.Frame):
    def __init__(self, master=None, **kwargs):
        super().__init__(master, **kwargs)
        self.configure(bg="#ffffff")
        
        # Crear tabla de memoria
        self.create_table()
        
        # Inicializar valores
        self.clear_values()
    
    def create_table(self):
        # Crear encabezados
        header_frame = tk.Frame(self, bg="#4a86e8")
        header_frame.pack(fill="x")
        
        headers = ["Dirección", "Valor (Hex)", "Valor (Bin)"]
        widths = [100, 120, 320]
        
        for i, header in enumerate(headers):
            tk.Label(header_frame, text=header, font=('Segoe UI', 10, 'bold'), 
                    bg="#4a86e8", fg="white", width=widths[i]//10).grid(row=0, column=i, padx=2, pady=5, sticky="w")
        
        # Crear contenedor para filas de memoria
        self.rows_frame = tk.Frame(self, bg="#ffffff")
        self.rows_frame.pack(fill="both", expand=True)
        
        # Crear canvas y scrollbar para permitir desplazamiento
        self.canvas = tk.Canvas(self.rows_frame, bg="#ffffff", highlightthickness=0)
        scrollbar = ttk.Scrollbar(self.rows_frame, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=scrollbar.set)
        
        scrollbar.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)
        
        # Frame dentro del canvas para las filas
        self.table_frame = tk.Frame(self.canvas, bg="#ffffff")
        self.canvas_window = self.canvas.create_window((0, 0), window=self.table_frame, anchor="nw")
        
        # Configurar eventos para redimensionar el canvas
        self.table_frame.bind("<Configure>", self.on_frame_configure)
        self.canvas.bind("<Configure>", self.on_canvas_configure)
        
        # Crear filas para las 32 posiciones de memoria
        self.addr_labels = []
        self.hex_labels = []
        self.bin_labels = []
        
        for i in range(32):
            row_frame = tk.Frame(self.table_frame, bg="#ffffff" if i % 2 == 0 else "#f5f5f5")
            row_frame.pack(fill="x")
            
            addr_label = tk.Label(row_frame, text=f"Mem[{i}]", font=('Consolas', 10), 
                                bg=row_frame["bg"], width=10, anchor="w")
            addr_label.grid(row=0, column=0, padx=2, pady=2, sticky="w")
            
            hex_label = tk.Label(row_frame, text="0x00000000", font=('Consolas', 10), 
                               bg=row_frame["bg"], width=12, anchor="w")
            hex_label.grid(row=0, column=1, padx=2, pady=2, sticky="w")
            
            bin_label = tk.Label(row_frame, text="00000000000000000000000000000000", font=('Consolas', 10), 
                               bg=row_frame["bg"], width=32, anchor="w")
            bin_label.grid(row=0, column=2, padx=2, pady=2, sticky="w")
            
            self.addr_labels.append(addr_label)
            self.hex_labels.append(hex_label)
            self.bin_labels.append(bin_label)
    
    def on_frame_configure(self, event):
        # Actualizar región de desplazamiento del canvas
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))
    
    def on_canvas_configure(self, event):
        # Ajustar el ancho del frame interno al ancho del canvas
        self.canvas.itemconfig(self.canvas_window, width=event.width)
    
    def update_memory(self, addr, value):
        if 0 <= addr < 32:
            hex_value = f"0x{value:08X}"
            bin_value = f"{value:032b}"
            
            self.hex_labels[addr].config(text=hex_value)
            self.bin_labels[addr].config(text=bin_value)
            
            # Resaltar la dirección de memoria actualizada
            row_frame = self.hex_labels[addr].master
            orig_bg = "#ffffff" if addr % 2 == 0 else "#f5f5f5"
            
            # Efecto de resaltado temporal
            row_frame.config(bg="#e6f2ff")
            self.addr_labels[addr].config(bg="#e6f2ff")
            self.hex_labels[addr].config(bg="#e6f2ff")
            self.bin_labels[addr].config(bg="#e6f2ff")
            
            # Restaurar color original después de un tiempo
            self.after(1500, lambda: self.restore_color(addr, orig_bg))
    
    def restore_color(self, addr, color):
        row_frame = self.hex_labels[addr].master
        row_frame.config(bg=color)
        self.addr_labels[addr].config(bg=color)
        self.hex_labels[addr].config(bg=color)
        self.bin_labels[addr].config(bg=color)
    
    def clear_values(self):
        for i in range(32):
            self.hex_labels[i].config(text="0x00000000")
            self.bin_labels[i].config(text="00000000000000000000000000000000")

# Clase para visualizar el pipeline
class PipelineVisualizer(tk.Frame):
    def __init__(self, master=None, **kwargs):
        super().__init__(master, **kwargs)
        self.configure(bg="#ffffff", padx=10, pady=10)
        
        # Diccionarios para almacenar las etiquetas de los campos
        self.if_id_labels = {}
        self.id_ex_labels = {}
        self.ex_mem_labels = {}
        self.mem_wb_labels = {}
        
        # Crear visualización del pipeline
        self.create_pipeline_view()
        
        # Inicializar valores
        self.clear_values()
    
    def create_pipeline_view(self):
        # Título
        title_label = tk.Label(self, text="Pipeline MIPS", font=('Segoe UI', 12, 'bold'), 
                              bg="#ffffff", fg="#333333")
        title_label.pack(anchor="center", pady=(0, 10))
        
        # Diagrama del pipeline
        pipeline_frame = tk.Frame(self, bg="#ffffff")
        pipeline_frame.pack(fill="x", pady=10)
        
        # Crear etapas del pipeline
        stages = ["IF", "ID", "EX", "MEM", "WB"]
        stage_frames = []
        
        # Usar un grid para mejor alineación
        for i, stage in enumerate(stages):
            # Crear un frame contenedor para cada etapa y su flecha
            container = tk.Frame(pipeline_frame, bg="#ffffff")
            container.grid(row=0, column=i, padx=2)
            
            # Etapa
            stage_frame = tk.Frame(container, bg="#4a86e8", width=60, height=40)
            stage_frame.pack(side="left", padx=0)
            stage_frame.pack_propagate(False)  # Mantener tamaño fijo
            
            stage_label = tk.Label(stage_frame, text=stage, font=('Segoe UI', 11, 'bold'), 
                                  bg="#4a86e8", fg="white")
            stage_label.pack(expand=True)
            
            stage_frames.append(stage_frame)
            
            # Agregar flecha después de cada etapa excepto la última
            if i < len(stages) - 1:
                arrow_frame = tk.Frame(container, bg="#ffffff", width=30, height=40)
                arrow_frame.pack(side="left", padx=0)
                arrow_frame.pack_propagate(False)  # Mantener tamaño fijo
                
                # Usar un canvas para dibujar una flecha mejor
                arrow_canvas = tk.Canvas(arrow_frame, bg="#ffffff", 
                                        width=30, height=40, 
                                        highlightthickness=0)
                arrow_canvas.pack(expand=True)
                
                # Dibujar una flecha más elegante
                arrow_canvas.create_line(5, 20, 25, 20, 
                                        width=2, fill="#333333", 
                                        arrow=tk.LAST, arrowshape=(10, 12, 5))
    
        # Crear notebook para detalles de cada etapa
        self.pipeline_notebook = ttk.Notebook(self)
        self.pipeline_notebook.pack(fill="both", expand=True, pady=10)
        
        # Crear pestañas para cada registro del pipeline
        self.if_id_frame = self.create_pipeline_register_frame("IF/ID", self.if_id_labels)
        self.id_ex_frame = self.create_pipeline_register_frame("ID/EX", self.id_ex_labels)
        self.ex_mem_frame = self.create_pipeline_register_frame("EX/MEM", self.ex_mem_labels)
        self.mem_wb_frame = self.create_pipeline_register_frame("MEM/WB", self.mem_wb_labels)
        
        self.pipeline_notebook.add(self.if_id_frame, text="IF/ID")
        self.pipeline_notebook.add(self.id_ex_frame, text="ID/EX")
        self.pipeline_notebook.add(self.ex_mem_frame, text="EX/MEM")
        self.pipeline_notebook.add(self.mem_wb_frame, text="MEM/WB")
    
    def create_pipeline_register_frame(self, title, labels_dict):
        frame = ttk.Frame(self.pipeline_notebook)
        
        # Crear tabla para los campos del registro
        table_frame = tk.Frame(frame, bg="#ffffff")
        table_frame.pack(fill="both", expand=True, padx=10, pady=10)
        
        # Encabezados
        header_frame = tk.Frame(table_frame, bg="#4a86e8")
        header_frame.pack(fill="x")
        
        headers = ["Campo", "Valor (Hex)", "Valor (Bin)"]
        widths = [120, 120, 320]
        
        for i, header in enumerate(headers):
            tk.Label(header_frame, text=header, font=('Segoe UI', 10, 'bold'), 
                    bg="#4a86e8", fg="white", width=widths[i]//10).grid(row=0, column=i, padx=2, pady=5, sticky="w")
        
        # Contenido
        content_frame = tk.Frame(table_frame, bg="#ffffff")
        content_frame.pack(fill="both", expand=True)
        
        # Función para agregar un campo
        def add_field(row, name):
            field_frame = tk.Frame(content_frame, bg="#ffffff" if row % 2 == 0 else "#f5f5f5")
            field_frame.pack(fill="x")
            
            name_label = tk.Label(field_frame, text=name, font=('Consolas', 10), 
                                 bg=field_frame["bg"], width=12, anchor="w")
            name_label.grid(row=0, column=0, padx=2, pady=2, sticky="w")
            
            hex_label = tk.Label(field_frame, text="0x00000000", font=('Consolas', 10), 
                               bg=field_frame["bg"], width=12, anchor="w")
            hex_label.grid(row=0, column=1, padx=2, pady=2, sticky="w")
            
            bin_label = tk.Label(field_frame, text="00000000000000000000000000000000", font=('Consolas', 10), 
                               bg=field_frame["bg"], width=32, anchor="w")
            bin_label.grid(row=0, column=2, padx=2, pady=2, sticky="w")
            
            labels_dict[name] = (hex_label, bin_label, field_frame)
        
        # Agregar campos según el registro del pipeline
        if title == "IF/ID":
            add_field(0, "inst")
            add_field(1, "pc+4")
        elif title == "ID/EX":
            add_field(0, "rs_data")
            add_field(1, "rt_data")
            add_field(2, "immediate")
            add_field(3, "op_code")
            add_field(4, "rs_addr")
            add_field(5, "rt_addr")
            add_field(6, "rd_addr")
            add_field(7, "controlU")
        elif title == "EX/MEM":
            add_field(0, "alu_result")
            add_field(1, "wr_data")
            add_field(2, "addr_rd")
            add_field(3, "controlU")
        elif title == "MEM/WB":
            add_field(0, "read_data")
            add_field(1, "alu_result")
            add_field(2, "addr_rd")
            add_field(3, "controlU")
        
        return frame
    
    def update_pipeline_register(self, register_name, field_name, value, bits=32):
        # Seleccionar el diccionario de etiquetas correcto
        if register_name == "IF/ID":
            labels_dict = self.if_id_labels
        elif register_name == "ID/EX":
            labels_dict = self.id_ex_labels
        elif register_name == "EX/MEM":
            labels_dict = self.ex_mem_labels
        elif register_name == "MEM/WB":
            labels_dict = self.mem_wb_labels
        else:
            return
        
        if field_name in labels_dict:
            hex_label, bin_label, field_frame = labels_dict[field_name]
        
        # Formatear valores según el número de bits
        if bits == 32:
            hex_value = f"0x{value:08X}"
            bin_value = f"{value:032b}"
        elif bits == 16:
            hex_value = f"0x{value:04X}"
            bin_value = f"{value:016b}"
        elif bits == 9:
            hex_value = f"0x{value:03X}"
            bin_value = f"{value:09b}"  # Corregido: Eliminado el 0x
        elif bits == 6:
            hex_value = f"0x{value:02X}"
            bin_value = f"{value:06b}"
        elif bits == 5:
            hex_value = f"0x{value:02X}"
            bin_value = f"{value:05b}"
        elif bits == 4:
            hex_value = f"0x{value:01X}"
            bin_value = f"{value:04b}"
        else:
            hex_value = f"0x{value:X}"
            bin_value = f"{value:b}"
        
        hex_label.config(text=hex_value)
        bin_label.config(text=bin_value)
        
        # Resaltar el campo actualizado
        orig_bg = "#ffffff" if field_name in ["inst", "rs_data", "alu_result", "read_data"] else "#f5f5f5"
        
        # Efecto de resaltado temporal
        field_frame.config(bg="#e6f2ff")
        for widget in field_frame.winfo_children():
            widget.config(bg="#e6f2ff")
        
        # Restaurar color original después de un tiempo
        self.after(1500, lambda: self.restore_color(field_frame, orig_bg))
    
    def restore_color(self, frame, color):
        frame.config(bg=color)
        for widget in frame.winfo_children():
            widget.config(bg=color)
    
    def clear_values(self):
        for register_name in ["IF/ID", "ID/EX", "EX/MEM", "MEM/WB"]:
            # Seleccionar el diccionario de etiquetas correcto
            if register_name == "IF/ID":
                labels_dict = self.if_id_labels
            elif register_name == "ID/EX":
                labels_dict = self.id_ex_labels
            elif register_name == "EX/MEM":
                labels_dict = self.ex_mem_labels
            elif register_name == "MEM/WB":
                labels_dict = self.mem_wb_labels
            
            for field_name, (hex_label, bin_label, _) in labels_dict.items():
                if field_name in ["op_code", "rs_addr", "rt_addr", "rd_addr", "addr_rd"]:
                    hex_label.config(text="0x00")
                    bin_label.config(text="00000")
                elif field_name == "controlU" and register_name == "ID/EX":
                    hex_label.config(text="0x0000")
                    bin_label.config(text="0000000000000000")
                elif field_name == "controlU" and register_name == "EX/MEM":
                    hex_label.config(text="0x000")
                    bin_label.config(text="000000000")
                elif field_name == "controlU" and register_name == "MEM/WB":
                    hex_label.config(text="0x0")
                    bin_label.config(text="0000")
                else:
                    hex_label.config(text="0x00000000")
                    bin_label.config(text="00000000000000000000000000000000")

# Clase principal para la GUI
class MipsFpgaGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("MIPS FPGA Interface")
        self.geometry("1200x800")
        self.ser = None
        self.binary_instructions = []
        self.dark_mode = False
        
        # Configurar colores
        self.colors = {
            "light": {
                "bg": "#f5f5f5",
                "fg": "#333333",
                "accent": "#4a86e8",
                "accent_hover": "#3a76d8",
                "text_area_bg": "#ffffff",
                "text_area_fg": "#333333",
                "panel_bg": "#ffffff",
                "panel_fg": "#333333",
                "success": "#4caf50",
                "warning": "#ff9800",
                "error": "#f44336",
                "sash": "#e0e0e0"
            },
            "dark": {
                "bg": "#2d2d2d",
                "fg": "#e0e0e0",
                "accent": "#4a86e8",
                "accent_hover": "#3a76d8",
                "text_area_bg": "#3d3d3d",
                "text_area_fg": "#e0e0e0",
                "panel_bg": "#3d3d3d",
                "panel_fg": "#e0e0e0",
                "success": "#81c784",
                "warning": "#ffb74d",
                "error": "#e57373",
                "sash": "#555555"
            }
        }
        
        # Configurar estilo
        self.style = ttk.Style()
        self.style.theme_use('clam')
        self.apply_theme()
        
        # Frame principal
        self.main_frame = tk.Frame(self, bg=self.current_colors["bg"])
        self.main_frame.pack(fill="both", expand=True)
        
        # Barra superior
        self.top_bar = tk.Frame(self.main_frame, bg=self.current_colors["accent"], height=50)
        self.top_bar.pack(fill="x")
        
        # Título de la aplicación
        title_label = tk.Label(self.top_bar, text="MIPS FPGA Interface", 
                              font=('Segoe UI', 16, 'bold'), 
                              bg=self.current_colors["accent"], fg="white")
        title_label.pack(side="left", padx=20, pady=10)
        
        # Botón de modo oscuro
        self.theme_btn = tk.Button(self.top_bar, text="🌙 Modo Oscuro", 
                                  font=('Segoe UI', 10), 
                                  bg=self.current_colors["accent"], fg="white",
                                  bd=0, padx=10, command=self.toggle_theme)
        self.theme_btn.pack(side="right", padx=20, pady=10)
        
        # Crear notebook para pestañas
        self.notebook = ttk.Notebook(self.main_frame)
        self.notebook.pack(fill="both", expand=True, padx=10, pady=10)
        
        # Pestaña de conversión MIPS a binario
        self.converter_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.converter_tab, text="Convertidor MIPS a Binario")
        self.setup_converter_tab()
        
        # Pestaña de comunicación FPGA
        self.fpga_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.fpga_tab, text="Comunicación FPGA")
        self.setup_fpga_tab()
        
        # Barra de estado
        self.status_frame = tk.Frame(self.main_frame, bg=self.current_colors["accent"], height=30)
        self.status_frame.pack(fill="x", side="bottom")
        
        self.status_bar = tk.Label(self.status_frame, text="Listo", 
                                  font=('Segoe UI', 10), 
                                  bg=self.current_colors["accent"], fg="white")
        self.status_bar.pack(side="left", padx=20, pady=5)
        
        # Configurar cierre de puerto serie al cerrar la aplicación
        self.protocol("WM_DELETE_WINDOW", self.on_closing)

    def apply_theme(self):
        self.current_colors = self.colors["dark" if self.dark_mode else "light"]
        
        # Configurar estilo para ttk widgets
        self.style.configure("TFrame", background=self.current_colors["bg"])
        self.style.configure("TNotebook", background=self.current_colors["bg"])
        self.style.configure("TNotebook.Tab", background=self.current_colors["bg"], 
                            foreground=self.current_colors["fg"], padding=[10, 5])
        self.style.map("TNotebook.Tab", background=[("selected", self.current_colors["accent"])],
                      foreground=[("selected", "white")])
        self.style.configure("TLabelframe", background=self.current_colors["bg"], 
                            foreground=self.current_colors["fg"])
        self.style.configure("TLabelframe.Label", background=self.current_colors["bg"], 
                            foreground=self.current_colors["fg"], font=('Segoe UI', 11, 'bold'))
        self.style.configure("TButton", background=self.current_colors["accent"], 
                            foreground="white", font=('Segoe UI', 10))
        self.style.map("TButton", background=[("active", self.current_colors["accent_hover"])])
        self.style.configure("TLabel", background=self.current_colors["bg"], 
                            foreground=self.current_colors["fg"], font=('Segoe UI', 10))
        self.style.configure("TCombobox", fieldbackground=self.current_colors["text_area_bg"], 
                            foreground=self.current_colors["text_area_fg"])
        
        # Configurar estilo para PanedWindow
        self.style.configure("TPanedwindow", background=self.current_colors["bg"])
        self.style.configure("Sash", background=self.current_colors["sash"], 
                            gripcount=0, handlesize=8)
        
        # Actualizar colores de widgets existentes
        if hasattr(self, 'main_frame'):
            self.main_frame.configure(bg=self.current_colors["bg"])
            self.top_bar.configure(bg=self.current_colors["accent"])
            self.theme_btn.configure(bg=self.current_colors["accent"], 
                                    text="☀️ Modo Claro" if self.dark_mode else "🌙 Modo Oscuro")
            self.status_frame.configure(bg=self.current_colors["accent"])
            self.status_bar.configure(bg=self.current_colors["accent"])
            
            # Actualizar colores de los editores de texto
            if hasattr(self, 'mips_text'):
                self.mips_text.configure(bg=self.current_colors["text_area_bg"], 
                                        fg=self.current_colors["text_area_fg"],
                                        insertbackground=self.current_colors["text_area_fg"])
                self.binary_text.configure(bg=self.current_colors["text_area_bg"], 
                                          fg=self.current_colors["text_area_fg"],
                                          insertbackground=self.current_colors["text_area_fg"])
                self.error_text.configure(bg=self.current_colors["text_area_bg"], 
                                         fg=self.current_colors["text_area_fg"],
                                         insertbackground=self.current_colors["text_area_fg"])

    def toggle_theme(self):
        self.dark_mode = not self.dark_mode
        self.apply_theme()

    def setup_converter_tab(self):
        # Crear un PanedWindow vertical para dividir la parte superior e inferior
        main_paned = ttk.PanedWindow(self.converter_tab, orient=tk.VERTICAL)
        main_paned.pack(fill="both", expand=True, padx=10, pady=10)
        
        # Frame superior para entrada y salida
        top_frame = ttk.Frame(main_paned)
        main_paned.add(top_frame, weight=80)
        
        # PanedWindow horizontal para dividir entrada y salida
        top_paned = ttk.PanedWindow(top_frame, orient=tk.HORIZONTAL)
        top_paned.pack(fill="both", expand=True)
        
        # Frame izquierdo para entrada de código MIPS
        left_frame = ttk.LabelFrame(top_paned, text="Código MIPS")
        top_paned.add(left_frame, weight=50)
        
        # Área de texto para entrada de código MIPS con resaltado de sintaxis
        self.mips_text = SyntaxHighlightingText(left_frame, wrap="word",
                                              bg=self.current_colors["text_area_bg"], 
                                              fg=self.current_colors["text_area_fg"],
                                              insertbackground=self.current_colors["text_area_fg"])
        self.mips_text.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Frame derecho para salida binaria
        right_frame = ttk.LabelFrame(top_paned, text="Código Binario")
        top_paned.add(right_frame, weight=50)
        
        # Área de texto para salida binaria
        self.binary_text = scrolledtext.ScrolledText(right_frame, wrap="word",
                                                   font=('Consolas', 11),
                                                   bg=self.current_colors["text_area_bg"], 
                                                   fg=self.current_colors["text_area_fg"],
                                                   insertbackground=self.current_colors["text_area_fg"])
        self.binary_text.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Frame inferior para botones
        bottom_frame = ttk.Frame(main_paned)
        main_paned.add(bottom_frame, weight=20)
        
        # Botones personalizados
        button_frame = ttk.Frame(bottom_frame)
        button_frame.pack(pady=10)
        
        self.convert_btn = HoverButton(button_frame, text="Convertir MIPS a Binario", 
                                      command=self.convert_mips_to_binary,
                                      width=200, height=40, bg_color="#4a86e8")
        self.convert_btn.grid(row=0, column=0, padx=10)
        
        self.load_mips_btn = HoverButton(button_frame, text="Cargar Archivo MIPS", 
                                        command=self.load_mips_file,
                                        width=180, height=40, bg_color="#4caf50")
        self.load_mips_btn.grid(row=0, column=1, padx=10)
        
        self.save_binary_btn = HoverButton(button_frame, text="Guardar Archivo Binario", 
                                          command=self.save_binary_file,
                                          width=180, height=40, bg_color="#ff9800")
        self.save_binary_btn.grid(row=0, column=2, padx=10)
        
        # Frame para mensajes de error
        error_frame = ttk.LabelFrame(bottom_frame, text="Mensajes")
        error_frame.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Área de texto para mensajes de error
        self.error_text = scrolledtext.ScrolledText(error_frame, wrap="word",
                                                  font=('Consolas', 11),
                                                  bg=self.current_colors["text_area_bg"], 
                                                  fg=self.current_colors["text_area_fg"],
                                                  insertbackground=self.current_colors["text_area_fg"])
        self.error_text.pack(fill="both", expand=True, padx=5, pady=5)

    def setup_fpga_tab(self):
        # Panel principal con PanedWindow horizontal
        main_paned = ttk.PanedWindow(self.fpga_tab, orient=tk.HORIZONTAL)
        main_paned.pack(fill="both", expand=True, padx=10, pady=10)
        
        # Panel izquierdo para controles
        left_panel = ttk.Frame(main_paned)
        main_paned.add(left_panel, weight=30)
        
        # PanedWindow vertical para los controles
        left_paned = ttk.PanedWindow(left_panel, orient=tk.VERTICAL)
        left_paned.pack(fill="both", expand=True)
        
        # Panel de conexión
        conn_frame = ttk.LabelFrame(left_paned, text="Conexión Serial")
        left_paned.add(conn_frame, weight=20)
        
        # Controles de conexión
        port_frame = ttk.Frame(conn_frame)
        port_frame.pack(fill="x", padx=10, pady=10)
        
        ttk.Label(port_frame, text="Puerto:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        
        # Combobox para puertos seriales
        self.port_combo = ttk.Combobox(port_frame, width=15)
        self.port_combo.grid(row=0, column=1, padx=5, pady=5, sticky="w")
        self.refresh_ports()
        
        # Botones de conexión
        btn_frame = ttk.Frame(conn_frame)
        btn_frame.pack(fill="x", padx=10, pady=(0, 10))
        
        self.refresh_btn = HoverButton(btn_frame, text="Refrescar Puertos", 
                                      command=self.refresh_ports,
                                      width=150, height=35, bg_color="#4caf50")
        self.refresh_btn.grid(row=0, column=0, padx=5, pady=5)
        
        self.connect_btn = HoverButton(btn_frame, text="Conectar", 
                                      command=self.toggle_connection,
                                      width=150, height=35, bg_color="#4a86e8")
        self.connect_btn.grid(row=0, column=1, padx=5, pady=5)
        
        # Panel de comandos
        cmd_frame = ttk.LabelFrame(left_paned, text="Comandos FPGA")
        left_paned.add(cmd_frame, weight=40)
        
        # Botones de comandos
        cmd_btn_frame = ttk.Frame(cmd_frame)
        cmd_btn_frame.pack(fill="x", padx=10, pady=10)
        
        self.load_btn = HoverButton(cmd_btn_frame, text="LOAD_PROGRAM", 
                                   command=self.load_program,
                                   width=150, height=35, bg_color="#4a86e8")
        self.load_btn.grid(row=0, column=0, padx=5, pady=5)
        self.load_btn.configure(state="disabled")
        
        self.run_btn = HoverButton(cmd_btn_frame, text="RUN", 
                                  command=self.run_program,
                                  width=150, height=35, bg_color="#4a86e8")
        self.run_btn.grid(row=1, column=0, padx=5, pady=5)
        self.run_btn.configure(state="disabled")
        
        self.step_btn = HoverButton(cmd_btn_frame, text="STEP", 
                                   command=self.step_program,
                                   width=150, height=35, bg_color="#4a86e8")
        self.step_btn.grid(row=2, column=0, padx=5, pady=5)
        self.step_btn.configure(state="disabled")
        
        self.reset_btn = HoverButton(cmd_btn_frame, text="RESET", 
                                    command=self.reset_program,
                                    width=150, height=35, bg_color="#ff9800")
        self.reset_btn.grid(row=3, column=0, padx=5, pady=5)
        self.reset_btn.configure(state="disabled")
        
        # Panel de información
        info_frame = ttk.LabelFrame(left_paned, text="Estado")
        left_paned.add(info_frame, weight=40)
        
        self.info_panel = InfoPanel(info_frame, title="Información de Conexión")
        self.info_panel.pack(fill="x", padx=10, pady=10)
        
        self.conn_status = self.info_panel.add_field("Estado:", "Desconectado")
        self.port_info = self.info_panel.add_field("Puerto:", "-")
        self.baud_info = self.info_panel.add_field("Baudrate:", str(BAUDRATE))
        
        # Panel derecho para visualización
        right_panel = ttk.Frame(main_paned)
        main_paned.add(right_panel, weight=70)
        
        # Notebook para visualización de datos
        self.fpga_notebook = ttk.Notebook(right_panel)
        self.fpga_notebook.pack(fill="both", expand=True)
        
        # Pestaña de registros
        self.registers_tab = ttk.Frame(self.fpga_notebook)
        self.fpga_notebook.add(self.registers_tab, text="Registros")
        
        # Pestaña de memoria
        self.memory_tab = ttk.Frame(self.fpga_notebook)
        self.fpga_notebook.add(self.memory_tab, text="Memoria")
        
        # Pestaña de pipeline
        self.pipeline_tab = ttk.Frame(self.fpga_notebook)
        self.fpga_notebook.add(self.pipeline_tab, text="Pipeline")
        
        # Pestaña de log
        self.log_tab = ttk.Frame(self.fpga_notebook)
        self.fpga_notebook.add(self.log_tab, text="Log")
        
        # Crear visualizadores
        self.registers_table = RegistersTable(self.registers_tab)
        self.registers_table.pack(fill="both", expand=True, padx=10, pady=10)
        
        self.memory_table = MemoryTable(self.memory_tab)
        self.memory_table.pack(fill="both", expand=True, padx=10, pady=10)
        
        self.pipeline_visualizer = PipelineVisualizer(self.pipeline_tab)
        self.pipeline_visualizer.pack(fill="both", expand=True)
        
        # Área de texto para log
        self.log_frame = ttk.LabelFrame(self.log_tab, text="Mensajes del Sistema")
        self.log_frame.pack(fill="both", expand=True, padx=10, pady=10)
        
        self.output_text = scrolledtext.ScrolledText(self.log_frame, wrap="word",
                                                   font=('Consolas', 11),
                                                   bg=self.current_colors["text_area_bg"], 
                                                   fg=self.current_colors["text_area_fg"],
                                                   insertbackground=self.current_colors["text_area_fg"])
        self.output_text.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Configurar etiquetas para colorear la salida
        self.output_text.tag_configure("success", foreground="#4caf50")
        self.output_text.tag_configure("info", foreground="#4a86e8")
        self.output_text.tag_configure("warning", foreground="#ff9800")
        self.output_text.tag_configure("error", foreground="#f44336")
        self.output_text.tag_configure("header", foreground="#9c27b0", font=('Consolas', 11, 'bold'))
        self.output_text.tag_configure("subheader", foreground="#673ab7", font=('Consolas', 11, 'bold'))

    def refresh_ports(self):
        ports = [port.device for port in serial.tools.list_ports.comports()]
        ports.append("mock")  # Añadir la opción de simulación
        self.port_combo['values'] = ports
        if ports:
            self.port_combo.current(0)

    def toggle_connection(self):
        if self.ser is None or not self.ser.is_open:
            port = self.port_combo.get()
            
            # Si el puerto es "mock", usar MockSerial
            if port == "mock":
                try:
                    from mockserial import MockSerial
                    self.ser = MockSerial()
                    self.log_output(f"Conectado al simulador MIPS.", "success")
                except ImportError:
                    messagebox.showerror("Error", "No se pudo importar MockSerial. Asegúrate de que el archivo mockserial.py esté en el mismo directorio.")
                    return
            else:
                try:
                    self.ser = serial.Serial(
                        port=port,
                        baudrate=BAUDRATE,
                        bytesize=BYTESIZE,
                        stopbits=STOPBITS,
                        parity=PARITY,
                        timeout=1
                    )
                    self.log_output(f"Conectado a {port} a {BAUDRATE} bauds.", "success")
                except Exception as e:
                    messagebox.showerror("Error de conexión", str(e))
                    self.log_output(f"Error de conexión: {str(e)}", "error")
                    return
            
            # Actualizar estado de la interfaz
            self.connect_btn.configure(text="Desconectar")
            self.load_btn.configure(state="normal")
            self.run_btn.configure(state="normal")
            self.step_btn.configure(state="normal")
            self.reset_btn.configure(state="normal")
            self.status_bar.config(text=f"Conectado a {port}")
            self.conn_status.config(text="Conectado", fg=self.current_colors["success"])
            self.port_info.config(text=port)
        else:
            self.ser.close()
            self.ser = None
            self.connect_btn.configure(text="Conectar")
            self.load_btn.configure(state="disabled")
            self.run_btn.configure(state="disabled")
            self.step_btn.configure(state="disabled")
            self.reset_btn.configure(state="disabled")
            self.status_bar.config(text="Desconectado")
            self.conn_status.config(text="Desconectado", fg=self.current_colors["error"])
            self.port_info.config(text="-")
            self.log_output("Desconectado del puerto serial.", "info")

    def convert_mips_to_binary(self):
        mips_code = self.mips_text.get("1.0", tk.END)
        if not mips_code.strip():
            messagebox.showwarning("Advertencia", "No hay código MIPS para convertir.")
            return
        
        self.binary_text.delete("1.0", tk.END)
        self.error_text.delete("1.0", tk.END)
        
        try:
            binary_instructions, errors = convert_asm_to_coe(mips_code)
            self.binary_instructions = binary_instructions
            
            # Mostrar instrucciones binarias
            for i, instr in enumerate(binary_instructions):
                self.binary_text.insert(tk.END, f"{instr}")
                if i < len(binary_instructions) - 1:
                    self.binary_text.insert(tk.END, ",\n")
                else:
                    self.binary_text.insert(tk.END, ";\n")
            
            # Mostrar errores si los hay
            if errors:
                for error in errors:
                    self.error_text.insert(tk.END, error + "\n")
                self.status_bar.config(text=f"Conversión completada con {len(errors)} errores.")
            else:
                self.status_bar.config(text=f"Conversión completada. {len(binary_instructions)} instrucciones generadas.")
                messagebox.showinfo("Éxito", f"Conversión completada. {len(binary_instructions)} instrucciones generadas.")
        
        except Exception as e:
            self.error_text.insert(tk.END, f"Error durante la conversión: {str(e)}\n")
            self.status_bar.config(text="Error durante la conversión.")
            messagebox.showerror("Error", f"Error durante la conversión: {str(e)}")

    def load_mips_file(self):
        file_path = filedialog.askopenfilename(
            title="Seleccionar archivo MIPS",
            filetypes=[("Archivos de ensamblador", "*.asm"), ("Todos los archivos", "*.*")]
        )
        if file_path:
            try:
                with open(file_path, 'r') as file:
                    content = file.read()
                self.mips_text.delete("1.0", tk.END)
                self.mips_text.insert(tk.END, content)
                self.mips_text.highlight_syntax()
                self.status_bar.config(text=f"Archivo cargado: {file_path}")
            except Exception as e:
                messagebox.showerror("Error", f"No se pudo cargar el archivo: {str(e)}")

    def save_binary_file(self):
        if not self.binary_instructions:
            messagebox.showwarning("Advertencia", "No hay instrucciones binarias para guardar.")
            return
        
        file_path = filedialog.asksaveasfilename(
            title="Guardar archivo binario",
            defaultextension=".coe",
            filetypes=[("Archivos COE", "*.coe"), ("Todos los archivos", "*.*")]
        )
        if file_path:
            try:
                with open(file_path, 'w') as file:
                    for i, instr in enumerate(self.binary_instructions):
                        file.write(instr + (",\n" if i < len(self.binary_instructions) - 1 else ";\n"))
                self.status_bar.config(text=f"Archivo guardado: {file_path}")
                messagebox.showinfo("Éxito", f"Archivo guardado correctamente en:\n{file_path}")
            except Exception as e:
                messagebox.showerror("Error", f"No se pudo guardar el archivo: {str(e)}")

    def load_program(self):
        file_path = filedialog.askopenfilename(
            title="Seleccionar archivo COE",
            filetypes=[("Archivos COE", "*.coe"), ("Todos los archivos", "*.*")]
        )
        if not file_path:
            return
        
        try:
            instrucciones = parse_coe(file_path)
            if not instrucciones:
                messagebox.showwarning("Advertencia", "No se encontraron instrucciones en el archivo.")
                return
            
            self.log_output(f"Enviando comando LOAD_PROGRAM (0x04)...", "info")
            enviar_datos(self.ser, bytes([CMD_LOAD]))
            time.sleep(0.1)
            
            self.log_output(f"Enviando programa ({len(instrucciones)} instrucciones)...", "info")
            for instr in instrucciones:
                data_instr = instr.to_bytes(4, byteorder='big')
                enviar_datos(self.ser, data_instr)
                if instr == HALT_INSTR:
                    self.log_output("Se envió la instrucción HALT (0x0000003F). Finalizando carga.", "success")
                    break
            
            self.log_output("Carga de programa finalizada.", "success")
            self.status_bar.config(text=f"Programa cargado: {file_path}")
        
        except Exception as e:
            self.log_output(f"Error al cargar el programa: {str(e)}", "error")
            messagebox.showerror("Error", f"Error al cargar el programa: {str(e)}")

    def run_program(self):
        self.execute_command(CMD_RUN, "RUN")

    def step_program(self):
        self.execute_command(CMD_STEP, "STEP")

    def reset_program(self):
        try:
            self.log_output("Enviando comando RESET (0x0C)...", "info")
            enviar_datos(self.ser, bytes([CMD_RESET]))
            self.log_output("Comando RESET enviado.", "success")
            self.status_bar.config(text="FPGA reiniciada")
            
            # Limpiar visualizadores
            self.registers_table.clear_values()
            self.memory_table.clear_values()
            self.pipeline_visualizer.clear_values()
            
        except Exception as e:
            self.log_output(f"Error al enviar comando RESET: {str(e)}", "error")
            messagebox.showerror("Error", f"Error al enviar comando RESET: {str(e)}")

    def execute_command(self, cmd, cmd_name):
        try:
            self.log_output(f"Enviando comando {cmd_name} (0x{cmd:02X})...", "info")
            enviar_datos(self.ser, bytes([cmd]))
            
            self.log_output("Esperando respuesta de la FPGA (registros y memoria)...", "info")
            
            # Usar un hilo para no bloquear la interfaz
            threading.Thread(target=self.read_fpga_response, args=(cmd_name,), daemon=True).start()
            
        except Exception as e:
            self.log_output(f"Error al enviar comando {cmd_name}: {str(e)}", "error")
            messagebox.showerror("Error", f"Error al enviar comando {cmd_name}: {str(e)}")

    def read_fpga_response(self, cmd_name):
        try:
            data = leer_respuesta(self.ser, EXPECTED_RESPONSE_BYTES)
            regs = leer_respuesta(self.ser, PIPELINE_BYTES)
            
            # Procesar y mostrar los datos en la interfaz
            self.after(0, lambda: self.display_fpga_data(data, regs, cmd_name))
            
        except Exception as e:
            self.after(0, lambda: self.log_output(f"Error al leer respuesta: {str(e)}", "error"))

    def display_fpga_data(self, data, regs, cmd_name):
        if len(data) < EXPECTED_RESPONSE_BYTES or len(regs) < PIPELINE_BYTES:
            self.log_output("Datos incompletos recibidos.", "warning")
            return
        
        # Actualizar registros
        for i in range(32):
            reg = int.from_bytes(data[i*4:(i+1)*4], byteorder='big')
            if reg != 0:
                self.registers_table.update_register(i, reg)
                self.log_output(f"R{i:02d}: 0x{reg:08X}", "info")
        
        # Actualizar memoria
        offset = 32 * 4
        for i in range(32):
            mem_word = int.from_bytes(data[offset + i*4 : offset + (i+1)*4], byteorder='big')
            if mem_word != 0:
                self.memory_table.update_memory(i, mem_word)
                self.log_output(f"Mem[{i:02d}]: 0x{mem_word:08X}", "info")
        
        # Parseo de IF_ID
        if_id = regs[0:8]
        if_id_inst = int.from_bytes(if_id[0:4], byteorder='big')
        if_id_pc = int.from_bytes(if_id[4:8], byteorder='big')
        
        # Parseo de ID_EX
        id_ex = regs[8:26]
        id_ex_rs_data   = int.from_bytes(id_ex[0:4], byteorder='big')
        id_ex_rt_data   = int.from_bytes(id_ex[4:8], byteorder='big')
        id_ex_immediate = int.from_bytes(id_ex[8:12], byteorder='big')
        id_ex_op_code   = id_ex[12]
        id_ex_rs_addr   = id_ex[13]
        id_ex_rt_addr   = id_ex[14]
        id_ex_rd_addr   = id_ex[15]
        id_ex_controlU  = int.from_bytes(id_ex[16:18], byteorder='big')
        
        # Parseo de EX_M
        ex_m = regs[26:37]
        ex_m_alu_result = int.from_bytes(ex_m[0:4], byteorder='big')
        ex_m_wr_data    = int.from_bytes(ex_m[4:8], byteorder='big')
        ex_m_addr_rd    = ex_m[8]
        ex_m_controlU   = int.from_bytes(ex_m[9:11], byteorder='big')
        
        # Parseo de M_WB
        m_wb = regs[37:47]
        m_wb_read_data   = int.from_bytes(m_wb[0:4], byteorder='big')
        m_wb_alu_result  = int.from_bytes(m_wb[4:8], byteorder='big')
        m_wb_addr_rd     = m_wb[8]
        m_wb_controlU    = m_wb[9]
        
        # Actualizar visualizador de pipeline
        self.pipeline_visualizer.update_pipeline_register("IF/ID", "inst", if_id_inst)
        self.pipeline_visualizer.update_pipeline_register("IF/ID", "pc+4", if_id_pc)
        
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "rs_data", id_ex_rs_data)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "rt_data", id_ex_rt_data)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "immediate", id_ex_immediate)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "op_code", id_ex_op_code & 0x3F, 6)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "rs_addr", id_ex_rs_addr & 0x1F, 5)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "rt_addr", id_ex_rt_addr & 0x1F, 5)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "rd_addr", id_ex_rd_addr & 0x1F, 5)
        self.pipeline_visualizer.update_pipeline_register("ID/EX", "controlU", id_ex_controlU, 16)
        
        self.pipeline_visualizer.update_pipeline_register("EX/MEM", "alu_result", ex_m_alu_result)
        self.pipeline_visualizer.update_pipeline_register("EX/MEM", "wr_data", ex_m_wr_data)
        self.pipeline_visualizer.update_pipeline_register("EX/MEM", "addr_rd", ex_m_addr_rd & 0x1F, 5)
        self.pipeline_visualizer.update_pipeline_register("EX/MEM", "controlU", ex_m_controlU & 0x1FF, 9)
        
        self.pipeline_visualizer.update_pipeline_register("MEM/WB", "read_data", m_wb_read_data)
        self.pipeline_visualizer.update_pipeline_register("MEM/WB", "alu_result", m_wb_alu_result)
        self.pipeline_visualizer.update_pipeline_register("MEM/WB", "addr_rd", m_wb_addr_rd & 0x1F, 5)
        self.pipeline_visualizer.update_pipeline_register("MEM/WB", "controlU", m_wb_controlU & 0xF, 4)
        
        # Mostrar mensaje de éxito
        self.log_output(f"Comando {cmd_name} ejecutado correctamente", "success")
        self.status_bar.config(text=f"Comando {cmd_name} ejecutado correctamente")
        
        # Cambiar a la pestaña de pipeline para mostrar los resultados
        self.fpga_notebook.select(2)  # Seleccionar la pestaña de pipeline

    def log_output(self, message, tag=None):
        self.output_text.insert(tk.END, message + "\n", tag)
        self.output_text.see(tk.END)  # Desplazar al final

    def on_closing(self):
        if self.ser and self.ser.is_open:
            self.ser.close()
        self.destroy()

if __name__ == "__main__":
    app = MipsFpgaGUI()
    app.mainloop()