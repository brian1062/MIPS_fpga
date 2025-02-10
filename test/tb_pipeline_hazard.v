module tb_pipeline_hazard;

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

        //----------- Riesgo de Datos -----------

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
        #10;

        // ----------- Riesgo de Control -----------

        // BEQ tomada: $1 = 5, $2 = 5 → Se toma el salto (offset = 4 instrucciones)

        // // ADDI: Guardar 5 en $1 de la memoria de registros
        // i_dunit_addr = 32'h0000_00010; 
        // i_dunit_data_if = 32'b001000_00000_00001_00000_00000_000101; // ADDI $1, $0, 5
        // // Acción esperada: $1 = 5
        // #10;

        // // ADDI: Guardar 5 en $2 de la memoria de registros
        // i_dunit_addr = 32'h0000_0014; 
        // i_dunit_data_if = 32'b001000_00000_00010_00000_00000_000101; // ADDI $2, $0, 5
        // // Acción esperada: $2 = 5
        // #10;

        // BEQ: Comparar si $1 (valor: 5) es igual a $2 (valor: 5), si son iguales, se toma el salto
        i_dunit_addr = 32'h0000_0018; 
        i_dunit_data_if = 32'b000100_00001_00010_00000_00000_000100; // BEQ $1, $2, offset=4
        // Acción esperada: Se toma el salto, el PC se incrementa en 4 instrucciones.
        #10;

        // ADDI: Guardar 1 en $6 de la memoria de registros
        i_dunit_addr = 32'h0000_001C;
        i_dunit_data_if = 32'b001000_00000_00110_00000_00000_000001; // ADDI $6, $0, 1
        // Acción esperada: $6 = 1 (No debe ejecutarse)
        #10;

        // ADDI: Guardar 2 en $7 de la memoria de registros
        i_dunit_addr = 32'h0000_002C;
        i_dunit_data_if = 32'b001000_00000_00111_00000_00000_000010; // ADDI $7, $0, 2
        // Acción esperada: $7 = 2 (Debe ejecutarse después del salto)
        #10;

        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;
        i_dunit_clk_en = 1;

        // ------------------ Monitoreo del Pipeline ------------------
        
        #10;//Primer fetch

        for (i = 1; i <= 20; i = i + 1) begin
            $display("======================================");
            $display(" Ciclo %0d", i);
            $display("======================================");

            // IF Stage
            $display(" IF: PC=%h" , uut.uu_IF.u_pc.pc);

            // ID Stage
            $display(" ID: rs=%b, rt=%b, rd=%b", 
                     uut.u_ID_EX.i_rs_addr,
                     uut.u_ID_EX.i_rt_addr,
                     uut.u_ID_EX.i_rd_addr);

            // EX Stage
            $display(" EX: ALUOp=%b, ALU input A= %h, ALU input B= %h, ALU Result=%h, WriteData =%h, RdtoWB =%b",
                     uut.uu_EX.i_alu_op_CU,
                     uut.uu_EX.u_alu.alu_input_A,
                     uut.uu_EX.u_alu.alu_input_B,
                     uut.u_EX_M.i_alu_result,
                     uut.u_EX_M.i_w_data,
                     uut.u_EX_M.i_data_addr);

            // MEM Stage
            $display(" MEM: MemRead=%b, MemWrite=%b",
                     uut.u_MEM.i_mem_read_CU,
                     uut.u_MEM.i_mem_write_CU);

            // WB Stage
            $display(" WB: Data to Reg=%h, WB rd =%b",
                     uut.u_WB.o_data_to_reg,
                     uut.u_M_WB.data_addr_reg);

            #10;
        end

        // Finalizar simulación
        #600;
        $stop;
    end

endmodule