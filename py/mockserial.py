class MockSerial:
    def __init__(self):
        self.buffer = bytearray()  # Buffer para almacenar datos enviados/recepcionados
        self.response_buffer = bytearray()  # Buffer para simular respuestas de la FPGA
        self.registers = [0] * 32  # Simulación de los 32 registros
        self.memory = [0] * 128    # Simulación de 128 bytes de memoria
        self.pipeline = [0] * 47   # Simulación de los registros de pipeline
        self.is_open = True
        
        # Inicializar algunos registros con valores para pruebas
        self.registers[1] = 0x12345678
        self.registers[2] = 0x00000020
        self.registers[3] = 0x00000030
        self.registers[5] = 0x00000050
        self.registers[7] = 0x00FF0000
        
        # Inicializar algunas posiciones de memoria
        self.memory[0] = 0xAABBCCDD
        self.memory[4] = 0x11223344
        self.memory[8] = 0x55667788
        
        # Inicializar pipeline
        self._init_pipeline()

    def _init_pipeline(self):
        # IF/ID
        # inst (4 bytes)
        self.pipeline[0:4] = (0x8C010000).to_bytes(4, byteorder='big')  # lw $1, 0($0)
        # pc+4 (4 bytes)
        self.pipeline[4:8] = (0x00000004).to_bytes(4, byteorder='big')
        
        # ID/EX
        # rs_data (4 bytes)
        self.pipeline[8:12] = (0x00000000).to_bytes(4, byteorder='big')
        # rt_data (4 bytes)
        self.pipeline[12:16] = (0x12345678).to_bytes(4, byteorder='big')
        # immediate (4 bytes)
        self.pipeline[16:20] = (0x00000000).to_bytes(4, byteorder='big')
        # op_code (1 byte)
        self.pipeline[20] = 0x23  # opcode para lw
        # rs_addr (1 byte)
        self.pipeline[21] = 0x00  # $0
        # rt_addr (1 byte)
        self.pipeline[22] = 0x01  # $1
        # rd_addr (1 byte)
        self.pipeline[23] = 0x00  # No aplica para lw
        # controlU (2 bytes)
        self.pipeline[24:26] = (0x0380).to_bytes(2, byteorder='big')
        
        # EX/MEM
        # alu_result (4 bytes)
        self.pipeline[26:30] = (0x00000000).to_bytes(4, byteorder='big')
        # wr_data (4 bytes)
        self.pipeline[30:34] = (0x00000000).to_bytes(4, byteorder='big')
        # addr_rd (1 byte)
        self.pipeline[34] = 0x01  # $1
        # controlU (2 bytes)
        self.pipeline[35:37] = (0x0180).to_bytes(2, byteorder='big')
        
        # MEM/WB
        # read_data (4 bytes)
        self.pipeline[37:41] = (0xAABBCCDD).to_bytes(4, byteorder='big')
        # alu_result (4 bytes)
        self.pipeline[41:45] = (0x00000000).to_bytes(4, byteorder='big')
        # addr_rd (1 byte)
        self.pipeline[45] = 0x01  # $1
        # controlU (1 byte)
        self.pipeline[46] = 0x02

    def write(self, data):
        """Simula el envío de datos a la FPGA."""
        self.buffer.extend(data)
        print(f"MockSerial: Datos enviados a la FPGA: {data}")

        # Simular respuestas basadas en el comando enviado
        if data == b'\x04':  # CMD_LOAD
            print("MockSerial: Simulando respuesta a LOAD_PROGRAM (ACK)")
            self.response_buffer.extend(b'\x01')  # Simular un ACK

        elif data == b'\x03':  # CMD_RUN
            print("MockSerial: Simulando respuesta a RUN (registros y memoria)")
            # Simular ejecución de las instrucciones del .coe
            self._simulate_run()
            # Enviar los registros y memoria como respuesta
            self.response_buffer.extend(self._get_registers_and_memory())
            # Enviar los datos de pipeline como respuesta
            self.response_buffer.extend(self._get_pipeline_data())

        elif data == b'\x05':  # CMD_STEP
            print("MockSerial: Simulando respuesta a STEP (registros y memoria)")
            # Simular ejecución de una instrucción
            self._simulate_step()
            # Enviar los registros y memoria como respuesta
            self.response_buffer.extend(self._get_registers_and_memory())
            # Enviar los datos de pipeline como respuesta
            self.response_buffer.extend(self._get_pipeline_data())

        elif data == b'\x0C':  # CMD_RESET
            print("MockSerial: Simulando respuesta a RESET (ACK)")
            self.response_buffer.extend(b'\x01')  # Simular un ACK
            # Reiniciar registros y memoria
            self.registers = [0] * 32
            self.memory = [0] * 128
            self.pipeline = [0] * 47
            # Reinicializar con algunos valores para pruebas
            self.registers[1] = 0x12345678
            self.registers[2] = 0x00000020
            self.registers[3] = 0x00000030
            self.registers[5] = 0x00000050
            self.registers[7] = 0x00FF0000
            self.memory[0] = 0xAABBCCDD
            self.memory[4] = 0x11223344
            self.memory[8] = 0x55667788
            self._init_pipeline()

    def read(self, size):
        """Simula la lectura de datos desde la FPGA."""
        if len(self.response_buffer) < size:
            print("MockSerial: No hay suficientes datos en el buffer de respuesta.")
            # Rellenar con ceros si no hay suficientes datos
            self.response_buffer.extend(b'\x00' * (size - len(self.response_buffer)))
        
        data = self.response_buffer[:size]
        self.response_buffer = self.response_buffer[size:]
        print(f"MockSerial: Datos leídos desde la FPGA: {len(data)} bytes")
        return data

    def flush(self):
        """Simula el flush del buffer."""
        print("MockSerial: Flush del buffer.")

    def close(self):
        """Simula el cierre del puerto serie."""
        print("MockSerial: Puerto serie cerrado.")
        self.is_open = False

    def _simulate_run(self):
        """Simula la ejecución de todas las instrucciones del .coe."""
        # Simular ejecución de las instrucciones
        self.registers[5] = 20  # ADDI $r5, $r5, 20
        self.registers[1] = self.registers[2] + self.registers[3]  # ADDU $r1, $r2, $r3
        self.registers[7] = 255 << 16  # LUI $r7, 255
        # J 1024 (no afecta registros ni memoria)
        # BEQ $r5, $r5, 8 (no afecta registros ni memoria)
        self.registers[1] = self.registers[2] << 5  # SLL $r1, $r2, 5
        
        # Actualizar pipeline para reflejar la última instrucción
        # IF/ID
        self.pipeline[0:4] = (0x00021140).to_bytes(4, byteorder='big')  # sll $2, $2, 5
        self.pipeline[4:8] = (0x00000018).to_bytes(4, byteorder='big')  # pc+4
        
        # ID/EX
        self.pipeline[8:12] = (0x00000000).to_bytes(4, byteorder='big')  # rs_data
        self.pipeline[12:16] = (0x00000020).to_bytes(4, byteorder='big')  # rt_data
        self.pipeline[16:20] = (0x00000005).to_bytes(4, byteorder='big')  # immediate (shift amount)
        self.pipeline[20] = 0x00  # opcode
        self.pipeline[21] = 0x00  # rs_addr
        self.pipeline[22] = 0x02  # rt_addr
        self.pipeline[23] = 0x02  # rd_addr
        self.pipeline[24:26] = (0x0040).to_bytes(2, byteorder='big')  # controlU
        
        # EX/MEM
        self.pipeline[26:30] = (0x00000400).to_bytes(4, byteorder='big')  # alu_result
        self.pipeline[30:34] = (0x00000000).to_bytes(4, byteorder='big')  # wr_data
        self.pipeline[34] = 0x02  # addr_rd
        self.pipeline[35:37] = (0x0040).to_bytes(2, byteorder='big')  # controlU
        
        # MEM/WB
        self.pipeline[37:41] = (0x00000000).to_bytes(4, byteorder='big')  # read_data
        self.pipeline[41:45] = (0x00000400).to_bytes(4, byteorder='big')  # alu_result
        self.pipeline[45] = 0x02  # addr_rd
        self.pipeline[46] = 0x01  # controlU

    def _simulate_step(self):
        """Simula la ejecución de una instrucción."""
        # Simular ejecución de una instrucción
        self.registers[5] = 20  # ADDI $r5, $r5, 20
        
        # Actualizar pipeline para reflejar la instrucción
        # IF/ID
        self.pipeline[0:4] = (0x20A50014).to_bytes(4, byteorder='big')  # addi $5, $5, 20
        self.pipeline[4:8] = (0x00000004).to_bytes(4, byteorder='big')  # pc+4
        
        # ID/EX
        self.pipeline[8:12] = (0x00000050).to_bytes(4, byteorder='big')  # rs_data
        self.pipeline[12:16] = (0x00000000).to_bytes(4, byteorder='big')  # rt_data
        self.pipeline[16:20] = (0x00000014).to_bytes(4, byteorder='big')  # immediate (20 en decimal)
        self.pipeline[20] = 0x08  # opcode para addi
        self.pipeline[21] = 0x05  # rs_addr ($5)
        self.pipeline[22] = 0x05  # rt_addr ($5)
        self.pipeline[23] = 0x00  # rd_addr (no aplica para addi)
        self.pipeline[24:26] = (0x0140).to_bytes(2, byteorder='big')  # controlU
        
        # EX/MEM
        self.pipeline[26:30] = (0x00000064).to_bytes(4, byteorder='big')  # alu_result (0x50 + 0x14 = 0x64)
        self.pipeline[30:34] = (0x00000000).to_bytes(4, byteorder='big')  # wr_data
        self.pipeline[34] = 0x05  # addr_rd
        self.pipeline[35:37] = (0x0040).to_bytes(2, byteorder='big')  # controlU
        
        # MEM/WB
        self.pipeline[37:41] = (0x00000000).to_bytes(4, byteorder='big')  # read_data
        self.pipeline[41:45] = (0x00000064).to_bytes(4, byteorder='big')  # alu_result
        self.pipeline[45] = 0x05  # addr_rd
        self.pipeline[46] = 0x01  # controlU

    def _get_registers_and_memory(self):
        """Devuelve los registros y memoria en formato de bytes."""
        # Convertir registros a bytes (32 registros de 32 bits = 128 bytes)
        reg_bytes = bytearray()
        for reg in self.registers:
            reg_bytes.extend(reg.to_bytes(4, byteorder='big'))
        
        # Convertir memoria a bytes (32 palabras de 32 bits = 128 bytes)
        mem_bytes = bytearray()
        for i in range(32):
            if i < len(self.memory) // 4:
                word = self.memory[i*4]
                mem_bytes.extend(word.to_bytes(4, byteorder='big'))
            else:
                mem_bytes.extend((0).to_bytes(4, byteorder='big'))
        
        # Combinar registros y memoria (256 bytes en total)
        return reg_bytes + mem_bytes

    def _get_pipeline_data(self):
        """Devuelve los datos de pipeline en formato de bytes."""
        return bytes(self.pipeline)