module tb_coe2;

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
        // forever #5 i_dunit_clk_en = ~i_dunit_clk_en;  // 10 ns clock period
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
        #10;
        i_reset = 0;  // Release reset
        i_dunit_reset_pc = 0;
        i_dunit_clk_en = 0;
        i_dunit_w_en=1;

        //----------- Riesgo de Datos -----------
        // i_dunit_addr = 32'h0000_0000; 
        // i_dunit_data_if = 32'b00100000000000010000000000000011; //add $1, $0, 0b11 
        // // Acción esperada: $3 = 1
        // #10;
        
        // // 2. ADDI: Guardar 2+$3 en $4 de la memoria de registros
        // i_dunit_addr = 32'h0000_0004; 
        // i_dunit_data_if = 32'b00100000000000100000000000000011; // add $2, $0, 0b11 
        // // Acción esperada: $4 = 3
        // #10;

        // // 3. ADDI: Guardar 3+$4 en $5 de la memoria de registros
        // i_dunit_addr = 32'h0000_0008;
        // // i_dunit_data_if = 32'b00001000000000000000000001111100; 
        // i_dunit_data_if = 32'b00010100001000100000000000001000; // bne  $2, $1 6 
        // // i_dunit_data_if = 32'b00010000001000100000000000001000; // beq  $2, $1 6 
        // #10;
        // i_dunit_addr = 32'h0000_000c;
        // i_dunit_data_if = 32'b00000000001000100010000000100001; // addu $4, $1, $2 
        // #10;
        // i_dunit_addr = 32'h0000_0010;
        // i_dunit_data_if = 32'b10101100000001000000000001111100; // sw $4, 124($0) (SW rt, offset(base)) 
        // #10;
        // i_dunit_addr = 32'h0000_0014;
        // i_dunit_data_if = 32'b10001100000001010000000001111100; //lw $5, 124($0) 
        // #10;
        // i_dunit_addr = 32'h0000_0018;
        // i_dunit_data_if = 32'b00000000001001010011000000101010; //slt $6, $1, $5 //stall forward
        // #10;
        // i_dunit_addr = 32'h0000_001c;
        // i_dunit_data_if = 32'b10001100000001110000000001111100; //lw $7, 124($0)
        // #10;
        // i_dunit_addr = 32'h0000_0020;
        // i_dunit_data_if = 32'b00110100011001000000000000001111; //ori $4, $3, 15 stall  
        // #10;
        // i_dunit_addr = 32'h0000_0024;
        // i_dunit_data_if = 32'b00000000000000000000000000111111; //lw $5, 124($0)

        //tb shift
        i_dunit_addr = 32'h0000_0000; 
        i_dunit_data_if = 32'b00100000001010000000000000000001; //addi $8, $1, 0b1
        #10;
        i_dunit_addr = 32'h0000_0004; 
        i_dunit_data_if = 32'b00100000001010010000000000000010;//   addi $9, $1, 0b10
        #10;
        i_dunit_addr = 32'h0000_0008; 
        i_dunit_data_if = 32'b00000000000010000001000010000000;//   SLL $2, $8, 2 rd ← rt << sa
        #10;

        i_dunit_addr = 32'h0000_000c; 
        i_dunit_data_if = 32'b00000001000000100001100001000010;//   SRL $3, $2, 1
        #10;
        i_dunit_addr = 32'h0000_0010; 
        i_dunit_data_if = 32'b00000000000000100010000001000011;//   SRA $4, $2, 1
        #10;

        i_dunit_addr = 32'h0000_0014; 
        i_dunit_data_if = 32'b00000001001010000110100000000100;//   SLLV $13, $8, $9 // 13 ← 1 << 2 RESULT 4
        #10;

        i_dunit_addr = 32'h0000_0018; 
        i_dunit_data_if = 32'b00000001000010010111000000000110;//  SRLV $14, $9, $8  rd ← 2 >> 1  RESULT 1
        #10;
        i_dunit_addr = 32'h0000_001c; 
        i_dunit_data_if = 32'b00000001000010010111100000000111;//   SRAV $15, $9, $8  rd ← rt >> rs 
        #10;
        i_dunit_addr = 32'h0000_0020; 
        i_dunit_data_if = 32'b00000000000000000000000000111111;//   halñt
        #10;



        
        #15;
        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;
        i_dunit_clk_en = 1;

        #10;//Primer fetch
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
                #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
                #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
                #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
                #50;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #100;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #100;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #100;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #100;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;
        #100;//Primer fetch
        i_dunit_clk_en = 1;
        #10;
        i_dunit_clk_en = 0;

        // Finalizar simulación
        #600;
        $stop;
    end

endmodule