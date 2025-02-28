module tb_pipeline_R;

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

    integer i;

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
        i_dunit_clk_en = 0;
        i_dunit_w_en=1;

        // ----------- Operaciones -----------

        // Carga de datos para operaciones R

        // 1. ADDI: Guardar 1 en $1 de la memoria de registros
        i_dunit_addr = 32'h0000_0004; 
        i_dunit_data_if = 32'b001000_00000_00001_00000_00000_000001; // ADDI $1, $0, 1
        // Acción esperada: $1 = 1
        #10;

        // 2. ADDI: Guardar 2 en $2 de la memoria de registros
        i_dunit_addr = 32'h0000_0008;
        i_dunit_data_if = 32'b001000_00000_00010_00000_00000_000010; // ADDI $2, $0, 2
        // Acción esperada: $2 = 2
        #10;

        //TEST DE OPERACIONES TIPO R

        // SLL: Shift lógico a la izquierda sobre el contenido de $2 por 2 posiciones y guardar el resultado en $3
        i_dunit_addr = 32'h0000_000C;
        i_dunit_data_if = 32'b000000_00000_00010_00011_00010_000000; // SLL $3, $2, 2
        //Resultado esperado: 8
        #10;

        // SRL: Shift lógico a la derecha sobre el contenido de $1 por 1 posición y guardar el resultado en $4
        i_dunit_addr = 32'h0000_0010;
        i_dunit_data_if = 32'b000000_00000_00001_00100_00001_000010; // SRL $4, $1, 1
        //Resultado esperado: 0
        #10;

        // SRA: Shift aritmético a la derecha sobre el contenido de $1 por 1 posición y guardar el resultado en $5
        i_dunit_addr = 32'h0000_0014;
        i_dunit_data_if = 32'b000000_00000_00001_00101_00001_000011; // SRA $5, $1, 1
        // Resultado esperado: 0 (ya que $1 contiene un valor positivo, no se extiende el bit de signo)
        #10;

        // SLLV: Shift lógico a la izquierda sobre el contenido de $2 por la cantidad indicada en $1 y guardar el resultado en $6
        i_dunit_addr = 32'h0000_0018;
        i_dunit_data_if = 32'b000000_00001_00010_00110_00000_000100; // SLLV $6, $2, $1
        // Resultado esperado: 4 (ya que $2 = 2 y $1 = 1; 2 << 1 = 4)
        #10;

        // SRLV: Shift lógico a la derecha sobre el contenido de $3 por la cantidad indicada en $1 y guardar el resultado en $7
        i_dunit_addr = 32'h0000_001C;
        i_dunit_data_if = 32'b000000_00001_00011_00111_00000_000110; // SRLV $7, $3, $1
        // Resultado esperado: 4 (ya que $3 = 8 y $1 = 1; 8 >> 1 = 4)
        #10;

        // SRAV: Shift aritmético a la derecha sobre el contenido de $2 por la cantidad indicada en $1 y guardar el resultado en $8
        i_dunit_addr = 32'h0000_0020;
        i_dunit_data_if = 32'b000000_00001_00010_01000_00000_000111; // SRAV $8, $2, $1
        // Resultado esperado: 1 (ya que $2 = 2 y $1 = 1; 2 >> 1 = 1)
        #10;

        // ADDU: Sumar sin signo el contenido de $1 y $2, guardar el resultado en $9
        i_dunit_addr = 32'h0000_0024;
        i_dunit_data_if = 32'b000000_00001_00010_01001_00000_100001; // ADDU $9, $1, $2
        // Resultado esperado: 3 (ya que $1 = 1 y $2 = 2; 1 + 2 = 3)
        #10;

        // SUBU: Restar sin signo el contenido de $2 menos $1, guardar el resultado en $10
        i_dunit_addr = 32'h0000_0028;
        i_dunit_data_if = 32'b000000_00010_00001_01010_00000_100011; // SUBU $10, $2, $1
        // Resultado esperado: 1 (ya que $2 = 2 y $1 = 1; 2 - 1 = 1)
        #10;

        // AND: Realizar una operación AND entre $1 y $2, guardar el resultado en $11
        i_dunit_addr = 32'h0000_002C;
        i_dunit_data_if = 32'b000000_00001_00010_01011_00000_100100; // AND $11, $1, $2
        // Resultado esperado: 0 (ya que $1 = 1 y $2 = 2; 1 AND 2 = 0)
        #10;

        // OR: Realizar una operación OR entre $1 y $2, guardar el resultado en $12
        i_dunit_addr = 32'h0000_0030;
        i_dunit_data_if = 32'b000000_00001_00010_01100_00000_100101; // OR $12, $1, $2
        // Resultado esperado: 3 (ya que $1 = 1 y $2 = 2; 1 OR 2 = 3)
        #10;

        // XOR: Realizar una operación XOR entre $1 y $2, guardar el resultado en $13
        i_dunit_addr = 32'h0000_0034;
        i_dunit_data_if = 32'b000000_00001_00010_01101_00000_100110; // XOR $13, $1, $2
        // Resultado esperado: 3 (ya que $1 = 1 y $2 = 2; 1 XOR 2 = 3)
        #10;

        // NOR: Realizar una operación NOR entre $1 y $2, guardar el resultado en $14
        i_dunit_addr = 32'h0000_0038;
        i_dunit_data_if = 32'b000000_00001_00010_01110_00000_100111; // NOR $14, $1, $2
        // Resultado esperado: 0xFFFFFFFC (ya que $1 = 1 y $2 = 2; NOT(1 OR 2) = -4 en complemento a 2)
        #10;

        // SLT: Comparar si $1 es menor que $2, guardar el resultado en $15
        i_dunit_addr = 32'h0000_003C;
        i_dunit_data_if = 32'b000000_00001_00010_01111_00000_101010; // SLT $15, $1, $2
        // Resultado esperado: 1 (ya que $1 = 1 y $2 = 2; 1 < 2 = True)
        #10;

        // SLTU: Comparar sin signo si $1 es menor que $2, guardar el resultado en $16
        i_dunit_addr = 32'h0000_0040;
        i_dunit_data_if = 32'b000000_00001_00010_10000_00000_101011; // SLTU $16, $1, $2
        // Resultado esperado: 1 (ya que $1 = 1 y $2 = 2; 1 < 2 = True sin signo)
        #10
        
        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;
        i_dunit_clk_en = 1;

        //----------- Test de funcionamiento operaciones R-----------

        #10;//Empieza el primer ADDI
        $display(" Primer ciclo - Start: ADDI");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        #10;//Empieza el segundo ADDI
        $display(" Segundo ciclo - Start: ADDI2");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        #10;//Empieza el SLL
        $display(" Tercer ciclo - Start: SLL");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        #10;//Empieza el SRL
        $display(" Cuarto ciclo - Start: SRL");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        #10;//Termina la primer instruccion ADDI y empieza el SRA
        $display(" Quinto ciclo - Start: SRA - Finish: ADDI");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina la segunda instruccion ADDI y empieza el SSLV
        $display(" Sexto ciclo - Start: SSLV - Finish: ADDI2");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10//Termina el SLL y empieza el SRLV
        $display(" Septimo ciclo - Start: SRLV - Finish: SLL");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10//Termina el SRL y empieza el SRAV
        $display(" Octavo ciclo - Start: SRAV - Finish: SRL");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10//Termina el SRA y empieza el ADDU
        $display(" Noveno ciclo - Start: ADDU - Finish: SRA");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10//Termina el SSLV y empieza el SUBU
        $display(" Decimo ciclo - Start: SUBU - Finish: SSLV");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el SRLV y empieza el AND
        $display(" Onceavo ciclo - Start: AND - Finish: SRLV");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el SRAV y empieza el OR
        $display(" Doceavo ciclo - Start: OR - Finish: SRAV");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el ADDU y empieza el XOR
        $display(" Treceavo ciclo - Start: XOR - Finish: ADDU");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el SUBU y empieza el NOR
        $display(" Catorceavo ciclo - Start: NOR - Finish: SUBU");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el AND y empieza el SLT
        $display(" Quinceavo ciclo - Start: SLT - Finish: AND");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el OR y empieza el SLTU
        $display(" Dieciseisavo ciclo - Start: SLTU - Finish: OR");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el XOR
        $display(" Diecisieteavo ciclo - Start: SW - Finish: XOR");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10//Termina el NOR
        $display(" Dieciochoavo ciclo - Start: LW - Finish: NOR");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10//Termina el SLT
        $display(" Diecinueveavo ciclo - Start: ANDI - Finish: SLT");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);
        #10;//Termina el SLTU
        $display(" Veinteavo ciclo - Start: ORI - Finish: SLTU");
        $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);
        $display(" ID: rs=%b, rt=%b, rd=%b", uut.u_ID_EX.i_rs_addr, uut.u_ID_EX.i_rt_addr, uut.u_ID_EX.i_rd_addr);
        $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b", uut.uu_EX.i_alu_op_CU, uut.u_EX_M.i_alu_result, uut.u_EX_M.i_w_data, uut.u_EX_M.i_data_addr);
        $display(" MEM: MemRead=%b, MemWrite=%b", uut.u_MEM.i_mem_read_CU, uut.u_MEM.i_mem_write_CU);
        $display(" WB: Data to Reg=%h, WB rd =%b", uut.u_WB.o_data_to_reg, uut.u_M_WB.data_addr_reg);

        // Finalizar simulación
        #600;
        $stop;
    end

endmodule