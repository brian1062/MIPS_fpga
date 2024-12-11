`timescale 1ns / 1ps

module tb_EX;

    // Parámetros
    parameter NB_REG  = 32;
    parameter NB_ADDR = 5;
    parameter NB_OP  = 6;
    parameter ALU_OP  = 4;

    // Entradas
    reg                       i_alu_src_CU;
    reg                       i_reg_dst_CU;
    reg                       i_jal_sel_CU;
    reg        [ALU_OP-1:0]   i_alu_op_CU;
    reg        [NB_REG-1:0]   i_rs_data;
    reg        [NB_REG-1:0]   i_rt_data;
    reg        [NB_ADDR-1:0]  i_rd_from_ID;
    reg        [NB_ADDR-1:0]  i_rt_from_ID;
    reg signed [NB_REG-1:0]   i_inst_sign_extended;
    reg        [NB_REG-1:0]   i_aluResult_WB;
    reg        [NB_REG-1:0]   i_aluResult_MEM;
    reg        [NB_OP-1:0]    i_op_r_tipe;
    reg        [1:0]          i_forwardA;
    reg        [1:0]          i_forwardB;

    // Salidas
    wire       [NB_REG-1:0]   o_alu_result;
    wire       [NB_ADDR-1:0]  o_write_reg;
    wire       [NB_ADDR-1:0]   o_rd_to_WB;
    wire                      o_alu_condition_zero;

    // Instancia del módulo
    EX #(
        .NB_REG(NB_REG),
        .NB_ADDR(NB_ADDR),
        .ALU_OP(ALU_OP)
    ) u_EX (
        .i_alu_src_CU(i_alu_src_CU),
        .i_reg_dst_CU(i_reg_dst_CU),
        .i_jal_sel_CU(i_jal_sel_CU),
        .i_alu_op_CU(i_alu_op_CU),
        .i_rs_data(i_rs_data),
        .i_rt_data(i_rt_data),
        .i_rd_from_ID(i_rd_from_ID),
        .i_rt_from_ID(i_rt_from_ID),
        .i_inst_sign_extended(i_inst_sign_extended),
        .i_aluResult_WB(i_aluResult_WB),
        .i_aluResult_MEM(i_aluResult_MEM),
        .i_op_r_tipe(i_op_r_tipe),
        .i_forwardA(i_forwardA),
        .i_forwardB(i_forwardB),
        .o_alu_result(o_alu_result),
        .o_write_reg(o_write_reg),
        .o_rd_to_WB(o_rd_to_WB),
        .o_alu_condition_zero(o_alu_condition_zero)
    );

    // Monitor para visualizar cambios
    initial begin
        $display("Time\talu_src\treg_dst\tjal_sel\talu_op\trs_data\trt_data\tinst_sign_ext\trd_from_ID\trt_from_ID\taluResult_WB\taluResult_MEM\top_r_tipe\tforwardA\tforwardB\talu_result\twrite_reg\trd_to_WB\talu_zero");
        $display("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t%b\t%b\t%b\t%h\t%h\t%h\t%b",
                 $time, i_alu_src_CU, i_reg_dst_CU, i_jal_sel_CU, i_alu_op_CU, i_rs_data, i_rt_data, 
                 i_inst_sign_extended, i_rd_from_ID, i_rt_from_ID, i_aluResult_WB, i_aluResult_MEM, 
                 i_op_r_tipe, i_forwardA, i_forwardB, o_alu_result, o_write_reg, o_rd_to_WB, o_alu_condition_zero);
    end

    // Estímulos
    initial begin
        // Caso 1: Operación básica sin forwarding
        i_alu_src_CU = 0; i_reg_dst_CU = 0; i_jal_sel_CU = 0; i_alu_op_CU = 4'b0000;
        i_rs_data = 32'h00000010; i_rt_data = 32'h00000020;
        i_rd_from_ID = 5'b00001; i_rt_from_ID = 5'b00010;
        i_inst_sign_extended = 32'h00000004;
        i_aluResult_WB = 32'h00000000; i_aluResult_MEM = 32'h00000000;
        i_op_r_tipe = 6'b100000; i_forwardA = 2'b00; i_forwardB = 2'b00;
        #10;

        // Caso 2: Forwarding de MEM a A
        i_forwardA = 2'b01; i_aluResult_MEM = 32'h00000030;
        #10;

        // Caso 3: Forwarding de WB a B
        i_forwardB = 2'b10; i_aluResult_WB = 32'h00000040;
        #10;

        // Caso 4: Uso de inmediato como entrada B
        i_alu_src_CU = 1;
        #10;

        // Caso 5: JAL activa, selecciona $ra como destino
        i_jal_sel_CU = 1; i_reg_dst_CU = 1;
        #10;

        // Caso 6: RD seleccionado como destino, sin JAL
        i_jal_sel_CU = 0; i_reg_dst_CU = 1;
        #10;

        // Caso 7: Operación ALU tipo R
        i_alu_src_CU = 0; i_alu_op_CU = 4'b0010; i_op_r_tipe = 6'b100010;
        i_rs_data = 32'h00000050; i_rt_data = 32'h00000060;
        #10;

        // Caso 8: Forwarding simultáneo en A y B
        i_forwardA = 2'b01; i_forwardB = 2'b10;
        i_aluResult_MEM = 32'h00000070; i_aluResult_WB = 32'h00000080;
        #10;

        // Caso 9: Señal de cero de la ALU activa
        i_alu_op_CU = 4'b0011; i_rs_data = 32'h00000090; i_rt_data = 32'hFFFFFFFF;
        #10;

        // Caso 10: Operación combinada con JAL y forwarding
        i_jal_sel_CU = 1; i_forwardA = 2'b10; i_forwardB = 2'b01;
        i_aluResult_WB = 32'h000000A0; i_aluResult_MEM = 32'h000000B0;
        #10;

        $stop;
    end

endmodule
