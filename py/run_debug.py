#!/usr/bin/env python3
import serial
import sys
import time

# Parámetros de comunicación (ajusta si es necesario)
BAUDRATE = 19200
BYTESIZE = 8       # 8 bits
STOPBITS = 1       # 1 bit de stop
PARITY   = 'N'     # Sin paridad

CMD_STEP = 0x03    # Comando STEP
EXPECTED_RESPONSE_BYTES = 256  # 32 registros + 128 memorias, cada uno de 4 bytes

def read_exact(ser, n):
    """Lee exactamente n bytes desde el puerto serie (o hasta timeout)."""
    data = b''
    while len(data) < n:
        chunk = ser.read(n - len(data))
        if not chunk:
            break
        data += chunk
    return data

def print_hex_dump(data, width=16):
    """Imprime un volcado hexadecimal del bloque de datos recibido."""
    for i in range(0, len(data), width):
        chunk = data[i:i+width]
        hex_str = " ".join("{:02X}".format(b) for b in chunk)
        print("{:04X}: {}".format(i, hex_str))

def main():
    if len(sys.argv) < 2:
        print("Uso: {} <puerto_serial>".format(sys.argv[0]))
        print("Ejemplo: python3 step_debug.py /dev/ttyUSB0")
        sys.exit(1)
    
    port = sys.argv[1]
    try:
        ser = serial.Serial(
            port=port,
            baudrate=BAUDRATE,
            bytesize=BYTESIZE,
            stopbits=STOPBITS,
            parity=PARITY,
            timeout=2  # timeout de 2 segundos para la lectura
        )
    except Exception as e:
        print("Error abriendo el puerto {}: {}".format(port, e))
        sys.exit(1)
    
    # Espera un poco para estabilizar la conexión
    time.sleep(1)
    
    # Enviar comando STEP
    print("Enviando comando STEP (0x05)...")
    ser.write(bytes([CMD_STEP]))
    ser.flush()
    
    print("Esperando {} bytes de respuesta...".format(EXPECTED_RESPONSE_BYTES))
    data = read_exact(ser, EXPECTED_RESPONSE_BYTES)
    
    if len(data) < EXPECTED_RESPONSE_BYTES:
        print("Advertencia: Se recibieron solo {} bytes (se esperaban {}).".format(len(data), EXPECTED_RESPONSE_BYTES))
    else:
        print("Se recibieron {} bytes.".format(len(data)))
    
    # Opcional: Mostrar volcado completo en hexadecimal (para debug)
    print("\nVolcado hexadecimal completo:")
    print_hex_dump(data)
    
    # Procesar la respuesta: Los primeros 128 bytes corresponden a 32 registros (4 bytes cada uno)
    registros = []
    for i in range(32):
        reg = int.from_bytes(data[i*4:(i+1)*4], byteorder='big')
        registros.append(reg)
    
    # Los siguientes 512 bytes corresponden a 128 posiciones de memoria (4 bytes cada uno)
    memoria = []
    offset = 32 * 4  # 128 bytes
    for i in range(offset):
        mem = int.from_bytes(data[offset + i*4 : offset + (i+1)*4], byteorder='big')
        memoria.append(mem)
    
    # Mostrar resultados de los registros (solo si son distintos de 0)
    print("\nRegistros (solo los distintos de 0):")
    for i, reg in enumerate(registros):
        if reg != 0:
            print("R{:02d}: 0x{:08X}".format(i, reg))
    
    # Mostrar resultados de la memoria (solo posiciones no nulas)
    print("\nMemoria (solo las posiciones con valor distinto de 0):")
    for i, mem in enumerate(memoria):
        if mem != 0:
            print("Mem[{:03d}]: 0x{:08X}".format(i, mem))
    
    ser.close()

if __name__ == '__main__':
    main()
