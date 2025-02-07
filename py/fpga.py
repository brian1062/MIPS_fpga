#!/usr/bin/env python3
import serial
import time
import sys
import signal

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

# Número total de bytes que se esperan como respuesta:
# 32 registros (32 x 32 bits = 128 bytes) + 128 posiciones de memoria (128 x 8 bits = 128 bytes)
EXPECTED_RESPONSE_BYTES = 256

def parse_coe(filename):
    """
    Lee un archivo .coe donde cada línea contiene al menos 32 dígitos (bits) en formato binario.
    Se ignora cualquier cosa que siga después del primer espacio.
    Solo se toman los primeros 32 caracteres de cada línea.
    Si se encuentra la instrucción HALT (00000000000000000000000000111111) se detiene la lectura.
    """
    instrucciones = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue  # Salta líneas vacías
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
    """Envía todos los bytes en data_bytes por el puerto serie"""
    ser.write(data_bytes)
    ser.flush()

def leer_respuesta(ser, total_bytes):
    """
    Lee 'total_bytes' desde el puerto serie y retorna los datos.
    Como la comunicación es bloqueante, se espera recibir la cantidad esperada.
    """
    recibido = b''
    while len(recibido) < total_bytes:
        chunk = ser.read(total_bytes - len(recibido))
        if not chunk:
            break
        recibido += chunk
    return recibido

def mostrar_registros_memoria(data):
    """
    Procesa la respuesta recibida (256 bytes esperados):
      - Los primeros 128 bytes corresponden a 32 registros (cada uno de 32 bits).
      - Los siguientes 128 bytes corresponden a 128 bytes de memoria, agrupados en 32 palabras de 32 bits.
    Se muestran en consola únicamente aquellos registros y palabras de memoria con valor distinto de 0.
    """
    if len(data) < EXPECTED_RESPONSE_BYTES:
        print("Datos incompletos recibidos.")
        return

    print("\n--- Registros (32 x 32 bits) ---")
    for i in range(32):
        reg = int.from_bytes(data[i*4:(i+1)*4], byteorder='big')
        if reg != 0:
            print("R{:02d}: 0x{:08X}".format(i, reg))
    
    print("\n--- Memoria (32 x 32 bits) ---")
    offset = 32 * 4  # Los primeros 128 bytes son para los registros
    for i in range(32):
        mem_word = int.from_bytes(data[offset + i*4 : offset + (i+1)*4], byteorder='big')
        if mem_word != 0:
            print("Mem[{:02d}]: 0x{:08X}".format(i, mem_word))
    print("-----------------------------\n")

def signal_handler(sig, frame, ser):
    print("\nSe recibió SIGINT. Cerrando puerto serie y saliendo.")
    ser.close()
    sys.exit(0)

def main():
    if len(sys.argv) < 2:
        print("Uso: {} <puerto>".format(sys.argv[0]))
        print("Ejemplo para hardware real: /dev/ttyUSB0")
        print("Ejemplo para simulación: socket://localhost:5000")
        sys.exit(1)
    puerto = sys.argv[1]
    try:
        ser = serial.Serial(
            port=puerto,
            baudrate=BAUDRATE,
            bytesize=BYTESIZE,
            stopbits=STOPBITS,
            parity=PARITY,
            timeout=None  # Bloqueante
        )
    except Exception as e:
        print("Error abriendo el puerto {}: {}".format(puerto, e))
        sys.exit(1)
    
    signal.signal(signal.SIGINT, lambda s, f: signal_handler(s, f, ser))
    
    print("Puerto serie {} abierto a {} bauds.".format(puerto, BAUDRATE))
    
    while True:
        print("Menú de opciones:")
        print("1 - LOAD_PROGRAM")
        print("2 - RUN")
        print("3 - STEP")
        print("4 - RESET")
        opcion = input("Seleccione opción (1/2/3/4) o 'q' para salir: ").strip()
        if opcion.lower() == 'q':
            break
        if opcion not in ['1', '2', '3', '4']:
            print("Opción inválida.")
            continue
        
        if opcion == '1':
            archivo = input("Ingrese el nombre del archivo .coe a cargar: ").strip()
            try:
                instrucciones = parse_coe(archivo)
            except Exception as e:
                print("Error al leer el archivo: ", e)
                continue
            if not instrucciones:
                print("No se encontraron instrucciones en el archivo.")
                continue
            print("Enviando comando LOAD_PROGRAM (0x04)...")
            enviar_datos(ser, bytes([CMD_LOAD]))
            time.sleep(0.1)
            print("Enviando programa ({} instrucciones)...".format(len(instrucciones)))
            for instr in instrucciones:
                data_instr = instr.to_bytes(4, byteorder='big')
                enviar_datos(ser, data_instr)
                if instr == HALT_INSTR:
                    print("Se envió la instrucción HALT (0x0000003F). Finalizando carga.")
                    break
            print("Carga de programa finalizada.\n")
        
        elif opcion == '2':
            print("Enviando comando RUN (0x03)...")
            enviar_datos(ser, bytes([CMD_RUN]))
            print("Esperando respuesta de la FPGA (registros y memoria)...")
            data = leer_respuesta(ser, EXPECTED_RESPONSE_BYTES)
            mostrar_registros_memoria(data)
        
        elif opcion == '3':
            print("Enviando comando STEP (0x05)...")
            enviar_datos(ser, bytes([CMD_STEP]))
            print("Esperando respuesta de la FPGA (registros y memoria)...")
            data = leer_respuesta(ser, EXPECTED_RESPONSE_BYTES)
            mostrar_registros_memoria(data)
        
        elif opcion == '4':
            print("Enviando comando RESET (0x0C)...")
            enviar_datos(ser, bytes([CMD_RESET]))
            print("Comando RESET enviado.\n")
    
    ser.close()
    print("Puerto serie cerrado. Adiós.")

if __name__ == '__main__':
    main()
