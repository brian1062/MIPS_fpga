module tb_pipeline;

    // Parameters
    parameter NB_REG   = 32;
    parameter NB_WIDHT = 9;
    parameter NB_OP    = 6;
    parameter NB_ADDR  = 5;

    // Testbench Signals
    reg                   i_clk;
    reg                   i_reset;
    reg                   i_dunit_clk_en;
    reg                   i_dunit_reset_pc;
    reg                   i_dunit_w_en;
    reg                   i_dunit_r_data;
    reg [NB_REG-1:0]    i_dunit_addr;
    reg [NB_REG-1:0]      i_dunit_data_if;
    wire [NB_REG-1:0]     o_dunit_mem_data;
    wire [NB_REG-1:0]     o_dunit_reg;

    // Clock Generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // 10 ns clock period
        forever #5 i_dunit_clk_en = ~i_dunit_clk_en;  // 10 ns clock period
    end

    // DUT (Device Under Test)
    pipeline #(
        .NB_REG(NB_REG),
        .NB_WIDHT(NB_WIDHT),
        .NB_OP(NB_OP),
        .NB_ADDR(NB_ADDR)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_dunit_reset_pc(i_dunit_reset_pc),
        .i_dunit_w_mem(i_dunit_w_en),
        .i_dunit_addr(i_dunit_addr),
        .i_dunit_data_if(i_dunit_data_if),
        .o_dunit_reg(o_dunit_reg),
        .o_dunit_mem_data(o_dunit_mem_data)
    );

    // Test Scenarios
    initial begin
        // Initialize inputs
        i_reset          = 1;
        i_dunit_clk_en   = 0;
        i_dunit_reset_pc = 0;
        i_dunit_w_en     = 0;
        i_dunit_r_data   = 0;
        i_dunit_addr     = 0;
        i_dunit_data_if   = 0;

        // Wait for a few cycles
        #15;
        i_reset = 0;  // Release reset
        i_dunit_reset_pc = 1;
        i_dunit_clk_en = 1;
        i_dunit_w_en=1;

        // // ----------- Operaciones -----------

        // // Carga de datos para operaciones R

        // // 1. ADDI: Guardar 1 en $1 de la memoria de registros
        // i_dunit_addr = 32'h0000_0004; 
        // i_dunit_data_if = 32'b001000_00000_00001_00000_00000_000001; // ADDI $1, $0, 1
        // // Acción esperada: $1 = 1
        // #10;

        // // 2. ADDI: Guardar 2 en $2 de la memoria de registros
        // i_dunit_addr = 32'h0000_0008;
        // i_dunit_data_if = 32'b001000_00000_00010_00000_00000_000010; // ADDI $2, $0, 2
        // // Acción esperada: $2 = 2
        // #10;

        // // Carga de datos para operaciones I

        // // 1. ADDI: Guardar un valor grande en $1 de la memoria de registros
        // i_dunit_addr = 32'h0000_0004; 
        // i_dunit_data_if = 32'b001000_00000_00001_01111_11111_111111; // ADDI $1, $0, 32767
        // // Acción esperada: $1 = 32767 (0x00007FFF)
        // #10;

        // // 2. ADDI: Guardar un valor negativo en $2 de la memoria de registros para pruebas con signo
        // i_dunit_addr = 32'h0000_0008; 
        // i_dunit_data_if = 32'b001000_00000_00010_11111_11111_111110; // ADDI $2, $0, -2
        // // Acción esperada: $2 = -2 (0xFFFFFFFE)
        // #10;

        // // --- Instrucciones de retorno para saltos ---

        // // Dirección 0x0100: Instrucción de retorno del JALR
        // i_dunit_addr = 32'h0000_0100;
        // i_dunit_data_if = 32'b000000_11111_00000_00000_00000_001000; // JR $31
        // // Acción esperada: Regresa al flujo principal después del JALR.
        // #10;

        // // Dirección 0x0104: Instrucción de retorno del JR
        // i_dunit_addr = 32'h0000_0104;
        // i_dunit_data_if = 32'b000000_11111_00000_00000_00000_001000; // JR $31
        // // Acción esperada: Regresa al flujo principal después del JR.
        // #10;

        // //TEST DE OPERACIONES TIPO R

        // // SLL: Shift lógico a la izquierda sobre el contenido de $2 por 2 posiciones y guardar el resultado en $3
        // i_dunit_addr = 32'h0000_000C;
        // i_dunit_data_if = 32'b000000_00000_00010_00011_00010_000000; // SLL $3, $2, 2
        // //Resultado esperado: 8
        // #10;

        // // SRL: Shift lógico a la derecha sobre el contenido de $1 por 1 posición y guardar el resultado en $4
        // i_dunit_addr = 32'h0000_0010;
        // i_dunit_data_if = 32'b000000_00000_00001_00100_00001_000010; // SRL $4, $1, 1
        // //Resultado esperado: 0
        // #10;

        // // SRA: Shift aritmético a la derecha sobre el contenido de $1 por 1 posición y guardar el resultado en $5
        // i_dunit_addr = 32'h0000_0014;
        // i_dunit_data_if = 32'b000000_00000_00001_00101_00001_000011; // SRA $5, $1, 1
        // // Resultado esperado: 0 (ya que $1 contiene un valor positivo, no se extiende el bit de signo)
        // #10;

        // // SLLV: Shift lógico a la izquierda sobre el contenido de $2 por la cantidad indicada en $1 y guardar el resultado en $6
        // i_dunit_addr = 32'h0000_0018;
        // i_dunit_data_if = 32'b000000_00001_00010_00110_00000_000100; // SLLV $6, $2, $1
        // // Resultado esperado: 4 (ya que $2 = 2 y $1 = 1; 2 << 1 = 4)
        // #10;

        // // SRLV: Shift lógico a la derecha sobre el contenido de $3 por la cantidad indicada en $1 y guardar el resultado en $7
        // i_dunit_addr = 32'h0000_001C;
        // i_dunit_data_if = 32'b000000_00001_00011_00111_00000_000110; // SRLV $7, $3, $1
        // // Resultado esperado: 4 (ya que $3 = 8 y $1 = 1; 8 >> 1 = 4)
        // #10;

        // // SRAV: Shift aritmético a la derecha sobre el contenido de $2 por la cantidad indicada en $1 y guardar el resultado en $8
        // i_dunit_addr = 32'h0000_0020;
        // i_dunit_data_if = 32'b000000_00001_00010_01000_00000_000111; // SRAV $8, $2, $1
        // // Resultado esperado: 1 (ya que $2 = 2 y $1 = 1; 2 >> 1 = 1)
        // #10;

        // // ADDU: Sumar sin signo el contenido de $1 y $2, guardar el resultado en $9
        // i_dunit_addr = 32'h0000_0024;
        // i_dunit_data_if = 32'b000000_00001_00010_01001_00000_100001; // ADDU $9, $1, $2
        // // Resultado esperado: 3 (ya que $1 = 1 y $2 = 2; 1 + 2 = 3)
        // #10;

        // // SUBU: Restar sin signo el contenido de $2 menos $1, guardar el resultado en $10
        // i_dunit_addr = 32'h0000_0028;
        // i_dunit_data_if = 32'b000000_00010_00001_01010_00000_100011; // SUBU $10, $2, $1
        // // Resultado esperado: 1 (ya que $2 = 2 y $1 = 1; 2 - 1 = 1)
        // #10;

        // // AND: Realizar una operación AND entre $1 y $2, guardar el resultado en $11
        // i_dunit_addr = 32'h0000_002C;
        // i_dunit_data_if = 32'b000000_00001_00010_01011_00000_100100; // AND $11, $1, $2
        // // Resultado esperado: 0 (ya que $1 = 1 y $2 = 2; 1 AND 2 = 0)
        // #10;

        // // OR: Realizar una operación OR entre $1 y $2, guardar el resultado en $12
        // i_dunit_addr = 32'h0000_0030;
        // i_dunit_data_if = 32'b000000_00001_00010_01100_00000_100101; // OR $12, $1, $2
        // // Resultado esperado: 3 (ya que $1 = 1 y $2 = 2; 1 OR 2 = 3)
        // #10;

        // // XOR: Realizar una operación XOR entre $1 y $2, guardar el resultado en $13
        // i_dunit_addr = 32'h0000_0034;
        // i_dunit_data_if = 32'b000000_00001_00010_01101_00000_100110; // XOR $13, $1, $2
        // // Resultado esperado: 3 (ya que $1 = 1 y $2 = 2; 1 XOR 2 = 3)
        // #10;

        // // NOR: Realizar una operación NOR entre $1 y $2, guardar el resultado en $14
        // i_dunit_addr = 32'h0000_0038;
        // i_dunit_data_if = 32'b000000_00001_00010_01110_00000_100111; // NOR $14, $1, $2
        // // Resultado esperado: 0xFFFFFFFC (ya que $1 = 1 y $2 = 2; NOT(1 OR 2) = -4 en complemento a 2)
        // #10;

        // // SLT: Comparar si $1 es menor que $2, guardar el resultado en $15
        // i_dunit_addr = 32'h0000_003C;
        // i_dunit_data_if = 32'b000000_00001_00010_01111_00000_101010; // SLT $15, $1, $2
        // // Resultado esperado: 1 (ya que $1 = 1 y $2 = 2; 1 < 2 = True)
        // #10;

        // // SLTU: Comparar sin signo si $1 es menor que $2, guardar el resultado en $16
        // i_dunit_addr = 32'h0000_0040;
        // i_dunit_data_if = 32'b000000_00001_00010_10000_00000_101011; // SLTU $16, $1, $2
        // // Resultado esperado: 1 (ya que $1 = 1 y $2 = 2; 1 < 2 = True sin signo)
        // #10

        // // TEST DE OPERACIONES TIPO I

        // // SW: Guardar el contenido de $2 (valor: -2) en la posición 4 de la memoria de datos
        // i_dunit_addr = 32'h0000_0044;
        // i_dunit_data_if = 32'b101011_00000_00010_00000_00000_000100; // SW $2, 4($0)
        // // Acción esperada: El valor -2 de $2 (0xFFFFFFFE) se almacena en la dirección 4 de la memoria de datos.
        // #10;

        // // SB: Guardar el byte menos significativo de $1 (valor: 0x00007FFF) en la posición 8 de la memoria de datos
        // i_dunit_addr = 32'h0000_0048;
        // i_dunit_data_if = 32'b101000_00000_00001_00000_00000_001000; // SB $1, 8($0)
        // // Acción esperada: El byte menos significativo de $1 (0xFF) se almacena en la dirección 8 de la memoria de datos.
        // #10;

        // // SH: Guardar el halfword menos significativo de $1 (valor: 0x00007FFF) en la posición 12 de la memoria de datos
        // i_dunit_addr = 32'h0000_004C;
        // i_dunit_data_if = 32'b101001_00000_00001_00000_00000_001100; // SH $1, 12($0)
        // // Acción esperada: El halfword menos significativo de $1 (0x7FFF) se almacena en la dirección 12 de la memoria de datos.
        // #10;

        // // LW: Cargar el contenido de la dirección 4 de la memoria de datos en $17
        // i_dunit_addr = 32'h0000_0050;
        // i_dunit_data_if = 32'b100011_00000_10001_00000_00000_000100; // LW $17, 4($0)
        // // Resultado esperado: $17 = -2 (0xFFFFFFFE, cargado desde la dirección 4 de la memoria de datos, con extensión de signo)
        // #10;

        // // LB: Cargar el byte de la dirección 8 de la memoria de datos en $18
        // i_dunit_addr = 32'h0000_0054;
        // i_dunit_data_if = 32'b100000_00000_10010_00000_00000_001000; // LB $18, 8($0)
        // // Resultado esperado: $18 = -1 (0xFFFFFFFF, cargado desde la dirección 8 de la memoria de datos, con extensión de signo)
        // #10;

        // // LH: Cargar el halfword de la dirección 12 de la memoria de datos en $19
        // i_dunit_addr = 32'h0000_0058;
        // i_dunit_data_if = 32'b100001_00000_10011_00000_00000_001100; // LH $19, 12($0)
        // // Resultado esperado: $19 = 32767 (0x00007FFF, cargado desde la dirección 12 de la memoria de datos, con extensión de signo)
        // #10;

        // // LWU: Cargar el contenido de la dirección 4 de la memoria de datos en $20
        // i_dunit_addr = 32'h0000_005C;
        // i_dunit_data_if = 32'b100100_00000_10100_00000_00000_000100; // LWU $20, 4($0)
        // // Resultado esperado: $20 = 0xFFFFFFFE (cargado desde la dirección 4 de la memoria de datos, sin extensión de signo)
        // #10;

        // // LBU: Cargar el byte de la dirección 8 de la memoria de datos en $21
        // i_dunit_addr = 32'h0000_0060;
        // i_dunit_data_if = 32'b100101_00000_10101_00000_00000_001000; // LBU $21, 8($0)
        // // Resultado esperado: $21 = 0x000000FF (cargado desde la dirección 8 de la memoria de datos, sin extensión de signo)
        // #10;

        // // LHU: Cargar el halfword de la dirección 12 de la memoria de datos en $22
        // i_dunit_addr = 32'h0000_0064;
        // i_dunit_data_if = 32'b100110_00000_10110_00000_00000_001100; // LHU $22, 12($0)
        // // Resultado esperado: $22 = 0x00007FFF (cargado desde la dirección 12 de la memoria de datos, sin extensión de signo)
        // #10;

        // // ANDI: Realizar una operación AND entre $1 (valor: 0x00007FFF) y el inmediato 0xFF, guardar el resultado en $23
        // i_dunit_addr = 32'h0000_0068;
        // i_dunit_data_if = 32'b001000_00001_10111_00000_00000_111111; // ANDI $23, $1, 0xFF
        // // Resultado esperado: $23 = 0x00007FFF AND 0xFF = 0x000000FF
        // #10;

        // // ORI: Realizar una operación OR entre $1 (valor: 0x00007FFF) y el inmediato 0xFF00, guardar el resultado en $24
        // i_dunit_addr = 32'h0000_006C;
        // i_dunit_data_if = 32'b001001_00001_11000_00000_00000_111111; // ORI $24, $1, 0xFF00
        // // Resultado esperado: $24 = 0x00007FFF OR 0xFF00 = 0x0000FFFF
        // #10;

        // // XORI: Realizar una operación XOR entre $1 (valor: 0x00007FFF) y el inmediato 0xFFFF, guardar el resultado en $25
        // i_dunit_addr = 32'h0000_0070;
        // i_dunit_data_if = 32'b001010_00001_11001_00000_00000_111111; // XORI $25, $1, 0xFFFF
        // // Resultado esperado: $25 = 0x00007FFF XOR 0xFFFF = 0x00008000
        // #10;

        // // LUI: Cargar el inmediato 0xABCD en los 16 bits más significativos de $26
        // i_dunit_addr = 32'h0000_0074;
        // i_dunit_data_if = 32'b001011_00000_11010_1010_1100_1101_0000; // LUI $26, 0xABCD
        // // Resultado esperado: $26 = 0xABCD0000
        // #10;

        // // SLTI: Comparar si $1 (valor: 0x00007FFF) es menor que el inmediato 0x7FFFFFFF, guardar el resultado en $27
        // i_dunit_addr = 32'h0000_0078;
        // i_dunit_data_if = 32'b001100_00001_11011_01111_11111_111111; // SLTI $27, $1, 0x7FFFFFFF
        // // Resultado esperado: $27 = 1 (0x00007FFF < 0x7FFFFFFF)
        // #10;

        // // SLTIU: Comparar si $1 (valor: 0x00007FFF) es menor que el inmediato 0xFFFFFFFF, guardar el resultado en $28
        // i_dunit_addr = 32'h0000_007C;
        // i_dunit_data_if = 32'b001101_00001_11100_11111_11111_111111; // SLTIU $28, $1, 0xFFFFFFFF
        // // Resultado esperado: $28 = 1 (0x00007FFF < 0xFFFFFFFF en comparación sin signo)
        // #10;

        // // BEQ: Comparar si $1 (valor: 0x00007FFF) es igual a $2 (valor: -2), si no son iguales, no hay salto
        // i_dunit_addr = 32'h0000_0080;
        // i_dunit_data_if = 32'b000100_00001_00010_00000_00000_000010; // BEQ $1, $2, offset = 2
        // // Acción esperada: No hay salto, el PC se incrementa normalmente.
        // #10;

        // // Preparar $1 con la dirección de salto del JALR
        // i_dunit_addr = 32'h0000_0084;
        // i_dunit_data_if = 32'b001000_00000_00001_0000_0001_000000; // ADDI $1, $0, 0x0100
        // // Acción esperada: $1 = 0x0100 (dirección de salto del JALR)
        // #10;

        // // Preparar $2 con la dirección de salto del JR
        // i_dunit_addr = 32'h0000_0088;
        // i_dunit_data_if = 32'b001000_00000_00010_0000_0001_000100; // ADDI $2, $0, 0x0104
        // // Acción esperada: $2 = 0x0104 (dirección de salto del JR)
        // #10;

        // // JALR: Guardar la dirección de retorno en $31 y saltar a la dirección almacenada en $1
        // i_dunit_addr = 32'h0000_008C;
        // i_dunit_data_if = 32'b000000_00001_00000_11111_00000_001001; // JALR $31, $1
        // // Acción esperada: $31 = PC actual + 8, PC = 0x0100.
        // #10;

        // // JR: Saltar a la dirección almacenada en $2
        // i_dunit_addr = 32'h0000_0090;
        // i_dunit_data_if = 32'b000000_00010_00000_00000_00000_001000; // JR $2
        // // Acción esperada: El PC se actualiza a la dirección contenida en $2 (PC = 0x0104).
        // #10;

        // ----------- Riesgo de Datos (RAW) -----------

        // 1. ADDI: Guardar 1 en $3 de la memoria de registros
        i_dunit_addr = 32'h0000_0004; 
        i_dunit_data_if = 32'b001000_00000_00011_00000_00000_000001; // ADDI $3, $0, 1  ($3 = 1)
        // Acción esperada: $3 = 1
        #10;
        
        // 2. ADDI: Guardar 2+$3 en $4 de la memoria de registros
        i_dunit_addr = 32'h0000_0008; 
        i_dunit_data_if = 32'b001000_00011_00100_00000_00000_000010; // ADDI $4, $3, 2  ($4 = $3 + 2)
        // Acción esperada: $4 = 3
        #10;

        // 3. ADDI: Guardar 3+$4 en $5 de la memoria de registros
        i_dunit_addr = 32'h0000_000C;
        i_dunit_data_if = 32'b001000_00100_00101_00000_00000_000011; // ADDI $5, $4, 3  ($5 = $4 + 3)

        // // ----------- Riesgo de Control (BEQ) -----------

        // // 1. ADDI: Guardar 1 en $6 de la memoria de registros
        // i_dunit_addr = 32'h0000_00B0; 
        // i_dunit_data_if = 32'b001000_00000_00110_00000_00000_000001; // ADDI $6, $0, 1  ($6 = 1)
        // #10;

        // // 2. ADDI: Guardar 1 en $7 de la memoria de registros
        // i_dunit_addr = 32'h0000_00B4; 
        // i_dunit_data_if = 32'b001000_00000_00111_00000_00000_000001; // ADDI $7, $0, 1  ($7 = 1)
        // #10;

        // i_dunit_addr = 32'h0000_00B8; 
        // i_dunit_data_if = 32'b000100_00110_00111_00000_00000_000010; // BEQ $6, $7, salto (si $6 == $7, salta a "salto")
        // #10;

        // i_dunit_addr = 32'h0000_00BC; 
        // i_dunit_data_if = 32'b001000_00000_01000_00000_00000_000011; // ADDI $8, $0, 3  ($8 = 3) - Instrucción después del salto
        // #10;

        // // Etiqueta "salto"
        // i_dunit_addr = 32'h0000_00C0; 
        // i_dunit_data_if = 32'b001000_00000_01001_00000_00000_000100; // ADDI $9, $0, 4  ($9 = 4)
        // #10;

        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;

        // //----------- Test de funcionamiento operaciones R-----------

        // #10;//Empieza el primer ADDI
        // $display(" Primer ciclo - Start: ADDI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // #10;//Empieza el segundo ADDI
        // $display(" Segundo ciclo - Start: ADDI2");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // #10;//Empieza el SLL
        // $display(" Tercer ciclo - Start: SLL");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // #10;//Empieza el SRL
        // $display(" Cuarto ciclo - Start: SRL");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // #10;//Termina la primer instruccion ADDI y empieza el SRA
        // $display(" Quinto ciclo - Start: SRA - Finish: ADDI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina la segunda instruccion ADDI y empieza el SSLV
        // $display(" Sexto ciclo - Start: SSLV - Finish: ADDI2");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SLL y empieza el SRLV
        // $display(" Septimo ciclo - Start: SRLV - Finish: SLL");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SRL y empieza el SRAV
        // $display(" Octavo ciclo - Start: SRAV - Finish: SRL");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SRA y empieza el ADDU
        // $display(" Noveno ciclo - Start: ADDU - Finish: SRA");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SSLV y empieza el SUBU
        // $display(" Decimo ciclo - Start: SUBU - Finish: SSLV");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el SRLV y empieza el AND
        // $display(" Onceavo ciclo - Start: AND - Finish: SRLV");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el SRAV y empieza el OR
        // $display(" Doceavo ciclo - Start: OR - Finish: SRAV");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el ADDU y empieza el XOR
        // $display(" Treceavo ciclo - Start: XOR - Finish: ADDU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el SUBU y empieza el NOR
        // $display(" Catorceavo ciclo - Start: NOR - Finish: SUBU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el AND y empieza el SLT
        // $display(" Quinceavo ciclo - Start: SLT - Finish: AND");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el OR y empieza el SLTU
        // $display(" Dieciseisavo ciclo - Start: SLTU - Finish: OR");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el XOR
        // $display(" Diecisieteavo ciclo - Start: SW - Finish: XOR");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el NOR
        // $display(" Dieciochoavo ciclo - Start: LW - Finish: NOR");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SLT
        // $display(" Diecinueveavo ciclo - Start: ANDI - Finish: SLT");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el SLTU
        // $display(" Veinteavo ciclo - Start: ORI - Finish: SLTU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);

        // //----------------- Test de funcionamiento operaciones I -----------------

        // #10;//Empieza el primer ADDI
        // $display(" Primer ciclo - Start: ADDI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // #10;//Empieza el segundo ADDI
        // $display(" Segundo ciclo - Start: ADDI2");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // #10;//Empieza el SW
        // $display(" Tercer ciclo - Start: SW");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // #10;//Empieza el SB
        // $display(" Cuarto ciclo - Start: SB");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // #10;//Termina la primer instruccion ADDI y empieza el SH
        // $display(" Quinto ciclo - Start: SH - Finish: ADDI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina la segunda instruccion ADDI y empieza el LW
        // $display(" Sexto ciclo - Start: LW - Finish: ADDI2");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SW y empieza el LB
        // $display(" Septimo ciclo - Start: LB - Finish: SW");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SB y empieza el LH
        // $display(" Octavo ciclo - Start: LH - Finish: SB");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el SH y empieza el LWU
        // $display(" Noveno ciclo - Start: LWU - Finish: SH");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el LW y empieza el LBU
        // $display(" Decimo ciclo - Start: LBU - Finish: LW");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el LB y empieza el LHU
        // $display(" Onceavo ciclo - Start: LHU - Finish: LB");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el LH y empieza el ANDI
        // $display(" Doceavo ciclo - Start: ANDI - Finish: LH");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el LWU y empieza el ORI
        // $display(" Treceavo ciclo - Start: ORI - Finish: LWU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el LBU y empieza el XORI
        // $display(" Catorceavo ciclo - Start: XORI - Finish: LBU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el LHU y empieza el LUI
        // $display(" Quinceavo ciclo - Start: LUI - Finish: LHU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el ANDI y empieza el SLTI
        // $display(" Dieciseisavo ciclo - Start: SLTI - Finish: ANDI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el ORI y empieza el SLTIU
        // $display(" Diecisieteavo ciclo - Start: SLTIU - Finish: ORI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el XORI y empieza el BEQ
        // $display(" Dieciochoavo ciclo - Start: BEQ - Finish: XORI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//Termina el LUI y empieza el ADDI para salto
        // $display(" Diecinueveavo ciclo - Start: ADDI - Finish: LUI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el SLTI y empieza el ADDI2 para salto
        // $display(" Veinteavo ciclo - Start: ADDI2 - Finish: SLTI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el SLTIU y empieza el JALR
        // $display(" Veintiunavo ciclo - Start: JALR - Finish: SLTIU");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el BEQ y empieza el JR
        // $display(" Veintidosavo ciclo - Start: JR - Finish: BEQ");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el ADDI para salto
        // $display(" Veintitresavo ciclo - Finish: ADDI");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el ADDI2 para salto
        // $display(" Veinticuatroavo ciclo - Finish: ADDI2");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el JALR
        // $display(" Veinticincoavo ciclo - Finish: JALR");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10;//Termina el JR
        // $display(" Veintiseisavo ciclo - Finish: JR");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//debug
        // $display(" Veintisieteavo ciclo - debug"); 
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//debug
        // $display(" Veintiochoavo ciclo - debug");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        // #10//debug
        // $display(" Veintinueveavo ciclo - debug");
        // $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        // $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        // $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        // $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        // $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);

        //----------------- Test de funcionamiento Riesgo de datos -----------------

        #10;//Empieza el ADDI1
        $display(" Primer ciclo - Start: ADDI1");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        #10;//Empieza el ADDI2
        $display(" Segundo ciclo - Start: ADDI2");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" ForwardingUnit ID: forwardA=%b, forwardB=%b, rsID=%b, rtID=%b, rdEX/M=%b, regWriteEX/M=%b", uut.uu_ID.i_forwardA, uut.uu_ID.i_forwardB, uut.u_forwarding_unit_ID.i_rs_id , uut.u_forwarding_unit_ID.i_rt_id, uut.u_forwarding_unit_ID.i_rd_ex_m, uut.u_forwarding_unit_ID.i_regWrite_ex_m);
        #10;//Empieza el ADDI3
        $display(" Tercer ciclo - Start: ADDI3");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" ForwardingUnit ID: forwardA=%b, forwardB=%b, rsID=%b, rtID=%b, rdEX/M=%b, regWriteEX/M=%b", uut.uu_ID.i_forwardA, uut.uu_ID.i_forwardB, uut.u_forwarding_unit_ID.i_rs_id , uut.u_forwarding_unit_ID.i_rt_id, uut.u_forwarding_unit_ID.i_rd_ex_m, uut.u_forwarding_unit_ID.i_regWrite_ex_m);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" ForwardUnit EX: forwardA=%b, forwardB=%b , Rs_id=%b, Rt_id=%b, Rd_m=%b, Rd_wb=%b, RegWrite_m=%b, RegWrite_wb=%b", uut.uu_EX.i_forwardA, uut.uu_EX.i_forwardB, uut.u_forwarding_unit_EX.i_rs_from_ID, uut.u_forwarding_unit_EX.i_rt_from_ID, uut.u_forwarding_unit_EX.i_rd_from_M, uut.u_forwarding_unit_EX.i_rd_from_WB, uut.u_forwarding_unit_EX.i_RegWrite_from_M, uut.u_forwarding_unit_EX.i_RegWrite_from_WB);
        #10;
        $display(" Cuarto ciclo");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" ForwardingUnit ID: forwardA=%b, forwardB=%b, rsID=%b, rtID=%b, rdEX/M=%b, regWriteEX/M=%b", uut.uu_ID.i_forwardA, uut.uu_ID.i_forwardB, uut.u_forwarding_unit_ID.i_rs_id , uut.u_forwarding_unit_ID.i_rt_id, uut.u_forwarding_unit_ID.i_rd_ex_m, uut.u_forwarding_unit_ID.i_regWrite_ex_m);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" ForwardUnit EX: forwardA=%b, forwardB=%b , Rs_id=%b, Rt_id=%b, Rd_m=%b, Rd_wb=%b, RegWrite_m=%b, RegWrite_wb=%b", uut.uu_EX.i_forwardA, uut.uu_EX.i_forwardB, uut.u_forwarding_unit_EX.i_rs_from_ID, uut.u_forwarding_unit_EX.i_rt_from_ID, uut.u_forwarding_unit_EX.i_rd_from_M, uut.u_forwarding_unit_EX.i_rd_from_WB, uut.u_forwarding_unit_EX.i_RegWrite_from_M, uut.u_forwarding_unit_EX.i_RegWrite_from_WB);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        #10;//Termina el primer ADDI1
        $display(" Quinto ciclo - Finish: ADDI1");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" ForwardingUnit ID: forwardA=%b, forwardB=%b, rsID=%b, rtID=%b, rdEX/M=%b, regWriteEX/M=%b", uut.uu_ID.i_forwardA, uut.uu_ID.i_forwardB, uut.u_forwarding_unit_ID.i_rs_id , uut.u_forwarding_unit_ID.i_rt_id, uut.u_forwarding_unit_ID.i_rd_ex_m, uut.u_forwarding_unit_ID.i_regWrite_ex_m);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" ForwardUnit EX: forwardA=%b, forwardB=%b , Rs_id=%b, Rt_id=%b, Rd_m=%b, Rd_wb=%b, RegWrite_m=%b, RegWrite_wb=%b", uut.uu_EX.i_forwardA, uut.uu_EX.i_forwardB, uut.u_forwarding_unit_EX.i_rs_from_ID, uut.u_forwarding_unit_EX.i_rt_from_ID, uut.u_forwarding_unit_EX.i_rd_from_M, uut.u_forwarding_unit_EX.i_rd_from_WB, uut.u_forwarding_unit_EX.i_RegWrite_from_M, uut.u_forwarding_unit_EX.i_RegWrite_from_WB);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el ADDI2
        $display(" Sexto ciclo - Finish: ADDI2");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" ForwardingUnit ID: forwardA=%b, forwardB=%b, rsID=%b, rtID=%b, rdEX/M=%b, regWriteEX/M=%b", uut.uu_ID.i_forwardA, uut.uu_ID.i_forwardB, uut.u_forwarding_unit_ID.i_rs_id , uut.u_forwarding_unit_ID.i_rt_id, uut.u_forwarding_unit_ID.i_rd_ex_m, uut.u_forwarding_unit_ID.i_regWrite_ex_m);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" ForwardUnit EX: forwardA=%b, forwardB=%b , Rs_id=%b, Rt_id=%b, Rd_m=%b, Rd_wb=%b, RegWrite_m=%b, RegWrite_wb=%b", uut.uu_EX.i_forwardA, uut.uu_EX.i_forwardB, uut.u_forwarding_unit_EX.i_rs_from_ID, uut.u_forwarding_unit_EX.i_rt_from_ID, uut.u_forwarding_unit_EX.i_rd_from_M, uut.u_forwarding_unit_EX.i_rd_from_WB, uut.u_forwarding_unit_EX.i_RegWrite_from_M, uut.u_forwarding_unit_EX.i_RegWrite_from_WB);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el ADDI3
        $display(" Septimo ciclo - Finish: ADDI3");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" ForwardingUnit ID: forwardA=%b, forwardB=%b, rsID=%b, rtID=%b, rdEX/M=%b, regWriteEX/M=%b", uut.uu_ID.i_forwardA, uut.uu_ID.i_forwardB, uut.u_forwarding_unit_ID.i_rs_id , uut.u_forwarding_unit_ID.i_rt_id, uut.u_forwarding_unit_ID.i_rd_ex_m, uut.u_forwarding_unit_ID.i_regWrite_ex_m);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" ForwardUnit EX: forwardA=%b, forwardB=%b , Rs_id=%b, Rt_id=%b, Rd_m=%b, Rd_wb=%b, RegWrite_m=%b, RegWrite_wb=%b", uut.uu_EX.i_forwardA, uut.uu_EX.i_forwardB, uut.u_forwarding_unit_EX.i_rs_from_ID, uut.u_forwarding_unit_EX.i_rt_from_ID, uut.u_forwarding_unit_EX.i_rd_from_M, uut.u_forwarding_unit_EX.i_rd_from_WB, uut.u_forwarding_unit_EX.i_RegWrite_from_M, uut.u_forwarding_unit_EX.i_RegWrite_from_WB);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        
        // i_dunit_addr=4;
        // #10
        // i_dunit_addr=14;
        // #10

        // End simulation
        #200;
        $stop;
    end
endmodule