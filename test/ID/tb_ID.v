`timescale 1ns/1ps

module tb_ID;
    // Parámetros de módulo
    parameter NB_REG  = 32;
    parameter NB_ADDR =  5;

    // Señales del testbench
    reg                    i_clk;
    reg                    i_reset;
    reg                    i_dunit_clk_en;
    reg                    i_regWrite_from_WB;
    reg                    i_forwardA;
    reg                    i_forwardB;
    reg [NB_REG-1:0]       i_inst_from_IF;
    reg [NB_REG-1:0]       i_pcplus4;
    reg [NB_ADDR-1:0]      i_WB_addr;
    reg [NB_REG-1:0]       i_WB_data;
    reg [NB_REG-1:0]       i_aluResult;
    reg                    i_isBeq;
    reg                    i_branch;

    // Salidas observables
    wire [NB_REG-1:0]      o_pc_jsel_to_IF;
    wire                   o_PCSrc_to_IF;
    wire [NB_REG-1:0]      o_branch_target;
    wire [NB_REG-1:0]      o_pcplus8;
    wire signed [NB_REG-1:0] o_inst_sign_extended;
    wire [NB_REG-1:0]      o_rs_data;
    wire [NB_ADDR-1:0]     o_op_r_tipe;
    wire [NB_ADDR-1:0]     o_rs_addr;
    wire [NB_ADDR-1:0]     o_rt_addr;
    wire [NB_ADDR-1:0]     o_rd_addr;
    wire [NB_REG-1:0]      o_rt_data;

    // Instancia del módulo ID
    ID #(
        .NB_REG(NB_REG),
        .NB_ADDR(NB_ADDR)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_regWrite_from_WB(i_regWrite_from_WB),
        .i_forwardA(i_forwardA),
        .i_forwardB(i_forwardB),
        .i_inst_from_IF(i_inst_from_IF),
        .i_pcplus4(i_pcplus4),
        .i_WB_addr(i_WB_addr),
        .i_WB_data(i_WB_data),
        .i_branch(i_branch),
        .i_aluResult(i_aluResult),
        .i_isBeq(i_isBeq),
        .o_pc_jsel_to_IF(o_pc_jsel_to_IF),
        .o_PCSrc_to_IF(o_PCSrc_to_IF),
        .o_branch_target(o_branch_target),
        .o_pcplus8(o_pcplus8),
        .o_inst_sign_extended(o_inst_sign_extended),
        .o_rs_data(o_rs_data),
        .o_op_r_tipe(o_op_r_tipe),
        .o_rs_addr(o_rs_addr),
        .o_rt_addr(o_rt_addr),
        .o_rd_addr(o_rd_addr),
        .o_rt_data(o_rt_data)
    );

    // Reloj
    always #5 i_clk = ~i_clk; // Periodo de 10 ns
    parameter NUM_REGS = 32;
integer i;
// Procedimiento de prueba
initial begin
    // Inicialización
    i_clk = 0;
    i_reset = 1;
    i_dunit_clk_en = 1;
    i_regWrite_from_WB = 0;
    i_forwardA = 0;
    i_forwardB = 0;
    i_inst_from_IF = 32'h00000000;
    i_pcplus4 = 32'h00000004;
    i_WB_addr = 5'b0;
    i_WB_data = 32'h0;
    i_aluResult = 32'h0;
    i_isBeq = 0;
    i_branch = 0;

    // Liberar reset
    #20 i_reset = 0;
    #5;
    
    // Prueba: Escribir en register_mem
    #10 i_regWrite_from_WB = 1;
    i_WB_addr = 5'd1;           // Dirección de registro para escribir
    i_WB_data = 32'hDEADBEEF;   // Datos para escribir en register_mem
     // Llenar la memoria con valores i<sniciales
     
    for (i = 0; i < NUM_REGS; i = i + 1) begin
        i_WB_addr = i;
        i_WB_data = 32'hDEAD_BEEF + i;  // Usa un patrón para ver cada registro (puedes cambiar el patrón)
        #10;  // Espera para asegurar que el dato se escriba
    end
    
    // Desactiva escritura de memoria después de cargar los datos
    i_regWrite_from_WB = 0;
    #10
    // Prueba: Leer desde register_mem
    #10 i_regWrite_from_WB = 0;
    i_inst_from_IF = {6'h0, 5'd1, 5'd2, 16'h0001}; // Set rs_addr y rt_addr

    // Probar señal `o_branch_target`
    i_pcplus4 = 32'h00000008;
    #10 i_inst_from_IF = {6'h0, 5'd0, 5'd0, 16'h0004}; // Offset de salto
    
    #10 i_isBeq = 1; // Activa comparación BEQ
    i_branch = 1;
    i_forwardA = 0;
    i_forwardB = 0;
    
    #10 $display("Debugging signals:");
    $display("o_branch_target: %h", o_branch_target);
    $display("o_pc_jsel_to_IF: %h, o_PCSrc_to_IF: %b", o_pc_jsel_to_IF, o_PCSrc_to_IF);
    $display("rs_equals_rt: , o_rs_data: %h, o_rt_data: %h" , o_rs_data, o_rt_data);

    // Fin de la simulación
    #20 $finish;
end
endmodule
