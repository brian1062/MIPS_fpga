Ejemplo de ejecución:

# Las instrucciones deben escribirse en el siguiente formato:
# - Registros: Usar números decimales (por ejemplo, $5, $10).
# - Valores inmediatos: Usar números decimales (por ejemplo, 20, 255).
# - Saltos: Usar números decimales (por ejemplo, 1024).

# Ejemplos válidos:
# ADDI $5, $10, 20     # Suma inmediata
# ADDU $1, $2, $3      # Suma sin signo
# LUI $7, 255          # Cargar valor inmediato en la mitad superior
# J 1024               # Salto incondicional
# BEQ $5, $10, 8       # Salto condicional si igual

--------fin del ejemplo-----

# A partir de aquí, escribe las instrucciones que deseas convertir:

# Instrucciones válidas
ADDI $5, $10, 20
ADDU $1, $2, $3
LUI $7, 255
J 1024
BEQ $5, $10, 8

# Registros fuera de rango
ADDI $40, $10, 20      # Registro $40 no válido (rango es 0-31)
ADDU $1, $2, $35       # Registro $35 no válido (rango es 0-31)

# Valores inmediatos fuera de rango
ADDI $5, $10, 70000    # Valor inmediato no válido (rango es -32768 a 32767)
LUI $7, 100000         # Valor inmediato no válido (rango es 0 a 65535)

# Instrucciones mal formateadas
ADDI $5, $10           # Faltan operandos
ADDU $1, $2, $3, $4    # Demasiados operandos
LUI $7                 # Faltan operandos

# Instrucciones no reconocidas
FOO $1, $2, $3         # Instrucción no válida
BAR $5, $10, 20        # Instrucción no válida

# Comentarios y líneas vacías
# Este es un comentario y debe ser ignorado

# Otra línea vacía

# Instrucción válida después de comentarios y líneas vacías
SLL $1, $2, 5
HALT
