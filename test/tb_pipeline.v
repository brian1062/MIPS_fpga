module tb_pipeline;

    // Parameters
    parameter NB_REG   = 32;
    parameter NB_WIDHT = 9;
    parameter NB_OP    = 6;
    parameter NB_ADDR  = 5;
    parameter NB_IFID =64 ;
    parameter NB_IDEX =144;
    parameter NB_EXM  =88 ;
    parameter NB_MWB  =80 ;

    // Testbench Signals
    reg                   i_clk;
    reg                   i_reset;
    reg                   i_dunit_clk_en;
    reg                   i_dunit_reset_pc;
    reg                   i_dunit_w_en;
    reg                   i_dunit_r_data;
    reg  [NB_REG-1:0]     i_dunit_addr    ;
    reg  [NB_REG-1:0]     i_dunit_data_if ;
    wire [NB_REG-1:0]     o_dunit_mem_data;
    wire [NB_REG-1:0]     o_dunit_reg     ;
    wire [NB_IFID-1:0]    o_IF_ID         ;
    wire [NB_IDEX-1:0]    o_ID_EX         ;
    wire [NB_EXM -1:0]    o_EX_M          ;
    wire [NB_MWB -1:0]    o_M_WB          ;
    wire                  o_halt          ;

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
        .o_dunit_mem_data(o_dunit_mem_data),
        .o_IF_ID         (o_IF_ID),
        .o_ID_EX         (o_ID_EX),
        .o_EX_M          (o_EX_M),
        .o_M_WB          (o_M_WB),
        .o_halt          (o_halt)
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
        // ADDI: No debe ejecutarse (está después del salto)
        i_dunit_addr = 32'h0000_0000;
        i_dunit_data_if = 32'b001000_00000_00110_00000_00000_001011; // ADDI $6, $0, 10
        //Accion esperada: No se ejecuta
        #10;
        

        // JUMP incondicional: Salto a 0x40
        i_dunit_addr = 32'h0000_0004;
        i_dunit_data_if = 32'b000010_00000_00000_00000_00000_010000; // J 0x40
        //Accion esperada: PC = 0x40
        #10;

        // ADDI: No debe ejecutarse (está después del salto)
        i_dunit_addr = 32'h0000_0008;
        i_dunit_data_if = 32'b001000_00000_00110_00000_00000_001011; // ADDI $6, $0, 10
        //Accion esperada: No se ejecuta
        #10;

        i_dunit_addr = 32'h0000_0040;
        i_dunit_data_if = 32'b001000_00000_00111_00000_00000_001100; // ADDI $7, $0, 11
        #10;
        i_dunit_addr = 32'h0000_0050;
        i_dunit_data_if = 32'b10101100000001100000000001111100;  // sw  $6, 0x0($0)
        #10;
        
        // JAL: Salto a 0x50 y guarda PC+4 en $31
        //i_dunit_addr = 32'h0000_0040;
        //i_dunit_data_if = 32'b000011_00000_00000_00000_00000_010100; // JAL 0x50
        //Accion esperada: PC = 0x50, $31 = 0x44
        #10;
        
        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;
        i_dunit_clk_en = 1;
        i_dunit_addr = 32'b00000000000000000000000001111100;

        // ------------------ Monitoreo del Pipeline ------------------
        
        #10;//Primer fetch

        for (i = 1; i <= 10; i = i + 1) begin
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
            $display(" EX: ALUOp=%b, ALU Result=%h, WriteData =%h, RdtoWB =%b",
                     uut.uu_EX.i_alu_op_CU,
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